import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:unchained/pages/Home/view.dart';
import 'package:unchained/pages/Settings/view.dart';
import 'package:unchained/utils/client.dart';

class NavigationWidget extends StatefulWidget {
  const NavigationWidget({super.key});

  @override
  NavigationWidgetState createState() => NavigationWidgetState();
}

class NavigationWidgetState extends State<NavigationWidget> {
  int _selectedIndex = 0;

  final List<NavigationPaneItem> _items = [
    PaneItem(
      icon: const Icon(FluentIcons.home),
      title: const Text('主页'),
      body: const HomePage(),
    ),
    PaneItem(
        icon: const Icon(FluentIcons.settings),
        title: const Text('设置'),
        body: const SettingsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        leading: const Icon(FluentIcons.virtual_network),
        title: const Text('Unchained'),
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: MoveWindow(),
            ),
            SizedBox(
              width: 50,
              height: 60,
              child: MinimizeWindowButton(),
            ),
            SizedBox(
              width: 50,
              height: 60,
              child: CloseWindowButton(
                onPressed: () async {
                  await stopCommand();
                  appWindow.close();
                },
              ),
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        size: const NavigationPaneSize(openWidth: 150),
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        items: _items,
      ),
    );
  }
}
