import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shade/utils/constants.dart';
import 'package:shade/utils/functions.dart';
import 'package:shade/utils/providers.dart';
import 'package:shade/utils/theme.dart';
import 'package:shade/utils/widgets.dart';

class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({Key? key}) : super(key: key);

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor>
    with AutomaticKeepAliveClientMixin {
  late TabController tabController;
  late List<CodeBlockConfig> fragmentConfigs = [];

  int currentTab = 0;

  @override
  void initState() {
    super.initState();

    fragmentConfigs = [
      CodeBlockConfig(
        name: "build",
        returnVariable: "data",
        body: """
float sD = length(ray) - 1.0;
float sID = 1.0;
vec2 s = vec2(sD, sID);

float pD = dot(ray, vec3(0.0, 1.0, 0.0)) + 1.0;
float pID = 2.0;
vec2 p = vec2(pD, pID);

data = join(p, s);
""",
        returnType: "vec2",
        parameters: ["vec3 ray"],
        fixed: true,
        documentation:
            "This is the method in which your entire scene is built. "
            "This method returns the data which contains the shortest "
            "distance from this 'ray' to any shape in your scene as well "
            "as the ID needed to color it appropriately in the material function.",
      ),
      CodeBlockConfig(
        name: "material",
        returnVariable: "color",
        returnType: "vec3",
        parameters: ['vec3 ray', 'float ID'],
        fixed: true,
        body: """
if(ID == 1.0) {
    color = vec3(0.9, 0.9, 0.0);
} else if(ID == 2.0) {
    color = vec3(0.0, 0.5, 0.5);
}
""",
        documentation: "This is the method in which lighting and textures are "
            "applied to your scene. This method should return the final "
            "color information calculated for this 'ray' based on the value of 'ID'. ",
      ),
    ];
  }

  Future<String> _assembleShader() async {
    StringBuffer buffer = StringBuffer();
    buffer.write(defaultDeclarations);
    buffer.write("\n\n");
    buffer.write(join);
    buffer.write("\n\n");
    buffer.write(fragmentConfigs[0].getCode());
    buffer.write("\n\n");
    buffer.write(fragmentConfigs[1].getCode());
    buffer.write("\n\n");
    buffer.write(rayMarch);
    buffer.write("\n\n");
    buffer.write(normal);
    buffer.write("\n\n");
    buffer.write(lighting);
    buffer.write("\n\n");
    buffer.write(render);
    buffer.write("\n\n");
    buffer.write(uv);
    buffer.write("\n\n");
    buffer.write(mainFragment);
    buffer.write("\n\n");

    log(buffer.toString());

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    bool addNewBlock = ref.watch(newCodeBlockProvider);
    if (addNewBlock) {
      setState(() {
        fragmentConfigs.add(
          CodeBlockConfig(name: "empty ${fragmentConfigs.length}"),
        );
      });

      Future.delayed(const Duration(milliseconds: 100),
          () => ref.watch(newCodeBlockProvider.notifier).state = false);
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      int renderFlag = ref.watch(renderProvider);
      if (renderFlag == 1) {
        ref.watch(renderStateProvider.notifier).state = "Compiling";

        _assembleShader().then((shader) {
          ref.watch(fragmentShaderProvider.notifier).state = shader;
          ref.watch(renderStateProvider.notifier).state = "Rendering";
          ref.watch(renderProvider.notifier).state = 2;
        });
      }
    });

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: neutral2.withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    unFocus();
                    ref.watch(newCodeBlockProvider.notifier).state = true;
                  },
                  icon: Icon(Icons.add_rounded,
                      color: containerGreen, size: 20.r),
                  splashRadius: 0.01,
                ),
                IconButton(
                  onPressed: () {},
                  icon:
                      Icon(Boxicons.bx_file, color: selectedWhite, size: 18.r),
                  splashRadius: 0.01,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10.h,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                SizedBox(
                  height: 650.h,
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      if (index == fragmentConfigs.length) {
                        return SizedBox(height: 50.h);
                      }

                      return CodeBlock(
                        config: fragmentConfigs[index],
                        onDelete: () => setState(
                          () => fragmentConfigs.removeAt(index),
                        ),
                        onEdit: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => FunctionCreator(
                                  config: fragmentConfigs[index],
                                ),
                              ),
                            )
                            .then(
                              (_) => setState(() {}),
                            ),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(height: 30.h),
                    itemCount: fragmentConfigs.length + 1,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class FunctionCreator extends StatefulWidget {
  final CodeBlockConfig config;

  const FunctionCreator({super.key, required this.config});

  @override
  State<FunctionCreator> createState() => _FunctionCreatorState();
}

class _FunctionCreatorState extends State<FunctionCreator> {
  late TextEditingController nameController, paramController;
  late String initial;
  final GlobalKey<ReturnTypesState> returnKey = GlobalKey();

  final List<String> params = [];

  @override
  void initState() {
    super.initState();
    paramController = TextEditingController();
    nameController = TextEditingController(text: widget.config.name);
    initial = widget.config.returnType;
    params.addAll(widget.config.parameters);
  }

  @override
  void dispose() {
    nameController.dispose();
    paramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CodeBlockConfig config = widget.config;

    return Scaffold(
      backgroundColor: mainDark,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: mainDark,
        automaticallyImplyLeading: false,
        title: Text(
          "Edit Function Block",
          style: context.textTheme.headlineSmall!.copyWith(color: theme),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50.h),
                Text(
                  "Name",
                  style: context.textTheme.bodyMedium!
                      .copyWith(color: theme, fontWeight: FontWeight.w700),
                ),
                SpecialForm(
                  controller: nameController,
                  width: 250.w,
                  height: 35.h,
                  fillColor: Colors.transparent,
                  borderColor: neutral3,
                ),
                SizedBox(
                  height: 30.h,
                ),
                Text(
                  "Parameters",
                  style: context.textTheme.bodyMedium!
                      .copyWith(color: theme, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5.h),
                Wrap(
                  spacing: 5.0,
                  children: List.generate(
                    params.length,
                    (index) => Chip(
                      onDeleted: () => setState(() => params.removeAt(index)),
                      deleteIcon:
                          Icon(Boxicons.bx_x, color: headerColor, size: 18.r),
                      label: Text(
                        params[index].toString(),
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: mainDark,
                        ),
                      ),
                      elevation: 1,
                      backgroundColor: appYellow,
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
                SpecialForm(
                  controller: paramController,
                  hint: "Parameter Declaration",
                  width: 170.w,
                  height: 40.h,
                ),
                SizedBox(height: 15.h),
                ElevatedButton(
                  onPressed: () {
                    String text = paramController.text.trim();
                    if (text.isEmpty) {
                      return;
                    }

                    setState(() {
                      params.add(text);
                      paramController.clear();
                    });
                    unFocus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appYellow,
                    minimumSize: Size(60.w, 30.h),
                  ),
                  child: Text(
                    "Add",
                    style: context.textTheme.bodyLarge!
                        .copyWith(color: mainDark, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 30.h),
                Text(
                  "Return Type",
                  style: context.textTheme.bodyMedium!
                      .copyWith(color: theme, fontWeight: FontWeight.w700),
                ),
                ReturnTypes(
                  key: returnKey,
                  initial: initial,
                ),
                SizedBox(height: 100.h),
                ElevatedButton(
                  onPressed: () {
                    config.name = nameController.text;
                    config.returnType = returnKey.currentState!.selected.name;
                    config.parameters = params;
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appYellow,
                    minimumSize: Size(100.w, 35.h),
                  ),
                  child: Text(
                    "Apply",
                    style: context.textTheme.bodyLarge!
                        .copyWith(color: mainDark, fontWeight: FontWeight.w500),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
