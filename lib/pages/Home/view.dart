import 'package:fluent_ui/fluent_ui.dart';
import 'dart:io';
import 'dart:convert';
import 'package:toml/toml.dart';
import 'package:unchained/utils/client.dart';
import 'package:unchained/widgets/notification.dart';
import 'package:unchained/widgets/terminal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController remoteAddrController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController localAddrController = TextEditingController();
  final TextEditingController terminalController = TextEditingController();
  final TextEditingController retryIntervalController = TextEditingController();
  bool terminalVisible = false;
  bool nodelay = false;
  String type = 'tcp';
  bool processing = false;
  Process? _process;

  void runCommand(String command) async {
    setState(() {
      terminalController.text = 'Running command: $command\nOutput:\n';
    });

    try {
      _process = await Process.start(
        'cmd',
        ['/c', command],
        workingDirectory: '${buildPath}', // TODO: 编译前修改
      );
      _process!.stdout.transform(utf8.decoder).listen((data) {
        setState(() {
          terminalController.text += data;
        });
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        setState(() {
          terminalController.text += data;
        });
      });
      await _process!.exitCode;
    } catch (e) {
      setState(() {
        terminalController.text += 'Error running command: $e';
      });
    }
  }

  void stopCommand() async {
    try {
      await Process.start('taskkill', ['/F', '/IM', 'rathole.exe']);
      setState(() {
        terminalController.text += '\nProcess terminated.';
      });
    } catch (e) {
      setState(() {
        terminalController.text += '\nError terminating process: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _readFile();
  }

  Future<void> _readFile() async {
    try {
      final file = File('${buildPath}client.toml'); // TODO: 编译前修改
      final content = await file.readAsString();
      final tomlDocument = TomlDocument.parse(content);
      final tomlMap = tomlDocument.toMap();
      final client = tomlMap['client'] as Map<String, dynamic>;
      final services = client['services'] as Map<String, dynamic>;
      final localServices = services['services'] as Map<String, dynamic>;

      setState(() {
        remoteAddrController.text = client['remote_addr'] ?? '';
        tokenController.text = localServices['token'] ?? '';
        localAddrController.text = localServices['local_addr'] ?? '';
        type = localServices['type'] ?? 'tcp';
        nodelay = localServices['nodelay'] ?? false;
        retryIntervalController.text =
            localServices['retry_interval']?.toString() ?? '0';
      });
    } catch (e) {
      setState(() {
        remoteAddrController.text = 'Error reading file: $e';
        tokenController.text = 'Error reading file: $e';
        localAddrController.text = 'Error reading file: $e';
        retryIntervalController.text = 'Error reading file: $e';
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    final userName = Platform.environment['USERNAME'] ?? '用户';
    if (hour < 11) {
      return '早上好, $userName！';
    } else if (hour < 14) {
      return '中午好, $userName！';
    } else if (hour < 18) {
      return '下午好，$userName！';
    } else {
      return '晚上好, $userName！';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
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
      children: [
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 100),
                child: Column(
                  children: [
                    InfoLabel(
                      label: '远程服务器地址：',
                      child: TextBox(
                        controller: remoteAddrController,
                      ),
                    ),
                    const SizedBox(height: 20),
                    InfoLabel(
                        label: '远程服务器Token：',
                        child: PasswordBox(
                          revealMode: PasswordRevealMode.peekAlways,
                          controller: tokenController,
                        )),
                    const SizedBox(height: 20),
                    InfoLabel(
                      label: '本地服务地址：',
                      child: TextBox(
                        controller: localAddrController,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Expander(
                header: const Text('可选选项'),
                content: Column(
                  children: [
                    Row(
                      children: [
                        InfoLabel(
                          label: '协议',
                          child: ComboBox<String>(
                            value: type,
                            items: ['tcp', 'udp']
                                .map((type) => ComboBoxItem<String>(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                type = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        InfoLabel(
                          label: '无延迟',
                          child: ToggleSwitch(
                            checked: nodelay,
                            onChanged: (value) {
                              setState(() {
                                nodelay = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InfoLabel(
                      label: '重试间隔s',
                      child: TextBox(
                        controller: retryIntervalController,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: processing
                  ? null
                  : () {
                      if (saveFile(
                        remoteAddrController.text,
                        tokenController.text,
                        localAddrController.text,
                        type,
                        nodelay,
                        int.tryParse(retryIntervalController.text) ?? 0,
                      )) {
                        setState(() {
                          terminalVisible = true;
                          processing = true;
                        });
                        runCommand('rathole.exe client.toml');
                        showContentDialog(context, "通知",
                            "请自行判断穿透是否成功（Control channel established代表成功），失败请停用后再重新穿透！");
                      } else {
                        showContentDialog(context, "错误", "配置保存失败，请重试！");
                      }
                    },
              child: const Text('开始穿透'),
            ),
            const SizedBox(
              width: 10,
            ),
            Button(
              onPressed: processing
                  ? () {
                      setState(() {
                        terminalVisible = false;
                        processing = false;
                      });
                      stopCommand();
                      showContentDialog(context, "通知", "已停止！");
                    }
                  : null,
              child: const Text('停止'),
            ),
            const SizedBox(height: 20),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(right: 25),
          child: Column(
            children: [
              Terminal(
                controller: terminalController,
                visible: terminalVisible,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
