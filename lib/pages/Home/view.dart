import 'package:fluent_ui/fluent_ui.dart';
import 'dart:io';
import 'package:toml/toml.dart';
import 'package:unchained/utils/client.dart';
import 'package:unchained/widgets/notification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController remoteAddrController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController localAddrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readFile();
  }

  Future<void> _readFile() async {
    try {
      final file = File('assets/client.toml');
      final content = await file.readAsString();
      final tomlDocument = TomlDocument.parse(content);
      final tomlMap = tomlDocument.toMap();
      final client = tomlMap['client'] as Map<String, dynamic>;
      final services = client['services'] as Map<String, dynamic>;
      final myNasSsh = services['my_nas_ssh'] as Map<String, dynamic>;

      setState(() {
        remoteAddrController.text = client['remote_addr'] ?? '';
        tokenController.text = myNasSsh['token'] ?? '';
        localAddrController.text = myNasSsh['local_addr'] ?? '';
      });
    } catch (e) {
      setState(() {
        remoteAddrController.text = 'Error reading file: $e';
        tokenController.text = 'Error reading file: $e';
        localAddrController.text = 'Error reading file: $e';
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    final userName = Platform.environment['USERNAME'] ?? '用户';
    if (hour < 11) {
      return '早上好, $userName';
    } else if (hour < 14) {
      return '中午好, $userName';
    } else if (hour < 18) {
      return '下午好，$userName';
    } else {
      return '晚上好, $userName';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: Padding(
        padding: const EdgeInsets.only(left: 25.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            getGreeting(),
            style: FluentTheme.of(context)
                .typography
                .title
                ?.copyWith(fontSize: 38),
          ),
        ),
      ),
      content: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.only(left: 25, right: 500),
            child: Column(
              children: [
                InfoLabel(
                  label: '远程服务器地址：',
                  child: TextBox(
                    controller: remoteAddrController,
                  ),
                ),
                const SizedBox(height: 15),
                InfoLabel(
                  label: '远程服务器Token：',
                  child: TextBox(
                    controller: tokenController,
                  ),
                ),
                const SizedBox(height: 15),
                InfoLabel(
                  label: '本地服务地址：',
                  child: TextBox(
                    controller: localAddrController,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(left: 376),
            child: Row(
              children: [
                FilledButton(
                  child: const Text('保存'),
                  onPressed: () {
                    saveFile(remoteAddrController.text, tokenController.text,
                            localAddrController.text)
                        ? showContentDialog(context, "成功", "保存成功！")
                        : showContentDialog(context, "错误", "保存失败，请重试！");
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
