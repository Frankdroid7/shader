import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shade/pages/others/help.dart';
import 'package:shade/pages/editor/editor.dart';
import 'package:shade/pages/editor/preview.dart';
import 'package:shade/pages/editor/settings.dart';
import 'package:shade/pages/others/settings.dart';
import 'package:shade/utils/constants.dart';
import 'package:shade/utils/functions.dart';
import 'package:shade/utils/providers.dart';
import 'package:shade/utils/theme.dart';

const List<Widget> pages = [CodeEditor(), ShaderPreview(), SceneSettings()];

class SceneEditor extends ConsumerStatefulWidget {
  const SceneEditor({Key? key}) : super(key: key);

  @override
  ConsumerState<SceneEditor> createState() => _SceneEditorState();
}

class _SceneEditorState extends ConsumerState<SceneEditor> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    int page = ref.watch(tabProvider);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: mainDark,
      endDrawer: SizedBox(
        child: Drawer(
          backgroundColor: mainDark,
          child: Column(
            children: [
              SizedBox(
                height: 50.h,
              ),
              ListTile(
                leading: Icon(
                  Icons.help,
                  color: appYellow,
                  size: 18.r,
                ),
                title: Text(
                  "Help",
                  style: context.textTheme.bodyLarge!
                      .copyWith(color: theme, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "All you need to know about Shade",
                  style: context.textTheme.bodyMedium!.copyWith(color: theme),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Help(),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.settings,
                  color: appYellow,
                  size: 18.r,
                ),
                title: Text(
                  "Settings",
                  style: context.textTheme.bodyLarge!
                      .copyWith(color: theme, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Tweak and customize Shade",
                  style: context.textTheme.bodyMedium!.copyWith(color: theme),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: mainDark,
        elevation: 0.0,
        title: Text(
          "Shade",
          style: context.textTheme.headlineSmall!.copyWith(color: appYellow),
        ),
        actions: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 15.w),
              child: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: appYellow,
                  size: 18.r,
                ),
                onPressed: () {
                  unFocus();
                  scaffoldKey.currentState?.openEndDrawer();
                },
                splashRadius: 0.01,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: page,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: mainDark,
        currentIndex: page,
        unselectedItemColor: neutral4,
        selectedFontSize: 14.r,
        unselectedFontSize: 14.r,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.code_rounded,
              size: 20.r,
            ),
            label: "Editor",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.image_rounded,
              size: 20.r,
            ),
            label: "Preview",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings_rounded,
              size: 20.r,
            ),
            label: "Settings",
          ),
        ],
        onTap: (index) => ref.watch(tabProvider.notifier).state = index,
      ),
      floatingActionButton: page == 1
          ? FloatingActionButton(
              elevation: 2.0,
              tooltip: 'Start/Stop Render',
              child: Icon(
                (ref.watch(renderProvider) == 2
                    ? Icons.stop_rounded
                    : ref.watch(renderProvider) == 1
                        ? Boxicons.bx_loader
                        : Icons.play_arrow_rounded),
                color: mainDark,
                size: 26.r,
              ),
              onPressed: () {
                unFocus();

                int lastState = ref.watch(renderProvider.notifier).state;
                int newState = lastState == 0 ? 1 : 0;
                ref.watch(renderProvider.notifier).state = newState;

                if (newState == 0) {
                  ref.watch(renderStateProvider.notifier).state = "Stopped";
                }

                if (newState == 1) {
                  createNewShader(ref);
                }
              },
            )
          : null,
    );
  }
}
