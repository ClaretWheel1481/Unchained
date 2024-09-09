import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future loadURL(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: Padding(
        padding: const EdgeInsets.only(left: 50.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "设置",
            style: FluentTheme.of(context)
                .typography
                .title
                ?.copyWith(fontSize: 38),
          ),
        ),
      ),
      children: [
        const SizedBox(height: 30),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 30),
              child: const Text("关于此应用",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.only(left: 30),
              child:
                  const Text("Unchained 1.0", style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 25),
            Row(children: [
              Container(
                  padding: const EdgeInsets.only(left: 20),
                  child: HyperlinkButton(
                      onPressed: () {
                        loadURL('https://github.com/rapiz1/rathole');
                      },
                      child: const Text("Rathole项目"))),
              Container(
                  padding: const EdgeInsets.only(left: 20),
                  child: HyperlinkButton(
                      onPressed: () {
                        loadURL('https://github.com/ClaretWheel1481/Unchained');
                      },
                      child: const Text("Unchained源码"))),
            ]),
          ],
        ),
      ],
    );
  }
}
