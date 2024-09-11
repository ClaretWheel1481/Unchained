import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'dart:io';
import 'dart:convert';
import 'package:toml/toml.dart';
import 'package:unchained/utils/client.dart';
import 'package:unchained/widgets/notification.dart';
import 'package:unchained/widgets/terminal.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
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
        workingDirectory: '${Path}',
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

  @override
  void initState() {
    super.initState();
    _readFile();
  }

  Future<void> _readFile() async {
    try {
      final file = File('${Path}client.toml');
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
    return fluent.ScaffoldPage.scrollable(
      header: Padding(
        padding: const EdgeInsets.only(left: 25.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            getGreeting(),
            style: fluent.FluentTheme.of(context)
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
                    fluent.InfoLabel(
                      label: '服务端地址',
                      child: fluent.TextBox(
                        enabled: !processing,
                        controller: remoteAddrController,
                      ),
                    ),
                    const SizedBox(height: 20),
                    fluent.InfoLabel(
                        label: '服务端Token',
                        child: fluent.PasswordBox(
                          enabled: !processing,
                          revealMode: fluent.PasswordRevealMode.peekAlways,
                          controller: tokenController,
                        )),
                    const SizedBox(height: 20),
                    fluent.InfoLabel(
                      label: '需转发的服务地址',
                      child: fluent.TextBox(
                        enabled: !processing,
                        controller: localAddrController,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: fluent.Expander(
                initiallyExpanded: true,
                header: const Text('可选选项'),
                content: Column(
                  children: [
                    Row(
                      children: [
                        fluent.InfoLabel(
                          label: '协议',
                          child: fluent.ComboBox<String>(
                              value: type,
                              items: ['tcp', 'udp']
                                  .map((type) => fluent.ComboBoxItem<String>(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: !processing
                                  ? (value) {
                                      setState(() {
                                        type = value!;
                                      });
                                    }
                                  : null),
                        ),
                        const SizedBox(width: 15),
                        Row(
                          children: [
                            fluent.InfoLabel(
                              isHeader: true,
                              label: '无延迟',
                              child: fluent.ToggleSwitch(
                                  checked: nodelay,
                                  onChanged: !processing
                                      ? (value) {
                                          setState(() {
                                            nodelay = value;
                                          });
                                        }
                                      : null),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(
                                right: 20,
                                bottom: 25,
                              ),
                              child: fluent.Tooltip(
                                message: '通过降低一定带宽来减少延迟，关闭后带宽提高但延迟增加。',
                                child: Icon(Icons.help),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    fluent.InfoLabel(
                      label: '重试间隔s',
                      child: fluent.TextBox(
                        enabled: !processing,
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
        fluent.Align(
          alignment: fluent.Alignment.centerRight,
          child: processing
              ? fluent.Button(
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
                  child: const Text('停止穿透'),
                )
              : fluent.FilledButton(
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
