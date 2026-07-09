import 'package:flutter/material.dart';
import 'package:unchained/app_constant.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:unchained/classes/log_formatter.dart';
import 'package:unchained/classes/service_config.dart';
import 'package:unchained/pages/home/rathole_home/widgets/action_buttons.dart';
import 'package:unchained/pages/home/rathole_home/widgets/rathole_service_tile.dart';
import 'package:unchained/classes/rathole_config_manager.dart';
import 'package:unchained/widgets/notification.dart';
import 'package:unchained/widgets/terminal.dart';

class RatholeHomePage extends StatefulWidget {
  final String configFileName;

  const RatholeHomePage({super.key, required this.configFileName});

  @override
  RatholeHomePageState createState() => RatholeHomePageState();
}

class RatholeHomePageState extends State<RatholeHomePage>
    with AutomaticKeepAliveClientMixin<RatholeHomePage> {
  final TextEditingController remoteAddrController = TextEditingController();
  final TextEditingController defaultTokenController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _terminalScrollController = ScrollController();

  List<String> formattedLines = [];
  List<RatholeServiceConfig> services = [];
  bool terminalVisible = false;
  bool processing = false;
  Process? _process;

  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  void _initializeConfig() {
    final fullPath =
        '${AppConstant.assetsPath}rathole/${widget.configFileName}';
    RatholeConfigManager.readRatholeConfigFrom(fullPath).then((config) {
      if (!mounted) return;
      remoteAddrController.text = config['remoteAddr'];
      defaultTokenController.text = config['defaultToken'] ?? '';
      if (config['services'].isNotEmpty) {
        services = config['services'];
        for (int i = 0; i < services.length; i++) {
          _listKey.currentState?.insertItem(
            i,
            duration: const Duration(milliseconds: 100),
          );
        }
      }
      if (mounted) setState(() {});
    }).catchError((error) {
      if (mounted) {
        showBottomNotification('配置文件读取失败: $error', NotificationType.error);
      }
    });
  }

  @override
  void dispose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _process?.kill();
    remoteAddrController.dispose();
    defaultTokenController.dispose();
    _terminalScrollController.dispose();
    super.dispose();
  }

  void runCommand(String command) async {
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();

    if (!mounted) return;
    setState(() => formattedLines.clear());

    try {
      _process = await Process.start(
          'cmd',
          [
            '/c',
            command,
          ],
          workingDirectory: "${AppConstant.assetsPath}rathole/");

      Null onData(String data) {
        if (!mounted) return;
        for (var line in data.split('\n')) {
          if (line.trim().isEmpty) continue;
          final f = LogFormatter.formatLine(line);
          if (mounted) {
            setState(() => formattedLines.add(f));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_terminalScrollController.hasClients) {
                _terminalScrollController.animateTo(
                  _terminalScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      }

      void onError(error) {
        if (mounted) {
          showBottomNotification('$error', NotificationType.error);
        }
      }

      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .listen(onData, onError: onError);
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .listen(onData, onError: onError);
    } catch (error) {
      if (mounted) {
        showBottomNotification('启动进程失败: $error', NotificationType.error);
      }
    }
  }

  void addService() {
    if (!mounted) return;
    final newIndex = services.length;
    setState(() {
      services.add(RatholeServiceConfig());
      _listKey.currentState?.insertItem(newIndex);
    });
  }

  void _removeService(int index) {
    if (!mounted) return;
    final removed = services.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => RatholeServiceTile(
        service: removed,
        index: index,
        animation: animation,
        processing: processing,
        onDelete: () {},
        onUpdate: () {},
      ),
      duration: const Duration(milliseconds: 300),
    );
    setState(() {});
  }

  void toggleProcess() {
    processing ? _stopProcess() : _startProcess();
  }

  void _stopProcess() async {
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _process?.kill();
    _process = null;

    if (mounted) {
      setState(() {
        processing = false;
        terminalVisible = false;
      });
      showBottomNotification('已停止转发服务。', NotificationType.warning);
    }
  }

  void _startProcess() async {
    if (!mounted) return;

    if (remoteAddrController.text.isEmpty) {
      showBottomNotification('请输入中继服务器地址。', NotificationType.error);
      return;
    }
    if (services.isEmpty) {
      showBottomNotification('请添加服务。', NotificationType.error);
      return;
    }

    final fullPath =
        '${AppConstant.assetsPath}rathole/${widget.configFileName}';
    final success = await RatholeConfigManager.saveRatholeConfigTo(
      fullPath,
      remoteAddrController.text.trim(),
      defaultTokenController.text.trim(),
      services,
    );

    if (!success) {
      if (mounted) {
        showBottomNotification('请检查所有服务的必填项是否完整。', NotificationType.error);
      }
      return;
    }

    if (mounted) {
      setState(() {
        processing = true;
        terminalVisible = true;
      });
      runCommand('rathole.exe --client ${widget.configFileName}');
      showBottomNotification('已启动，请查看日志。', NotificationType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    enabled: !processing,
                    controller: remoteAddrController,
                    decoration: const InputDecoration(
                      labelText: '中继服务器地址',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !processing,
                    controller: defaultTokenController,
                    decoration: const InputDecoration(
                      labelText: '全局 Token（可选）',
                      hintText: '所有服务共用此 Token，无需逐服务填写',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Expanded(
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: services.length,
                      padding: const EdgeInsets.only(top: 4, bottom: 80),
                      itemBuilder: (context, index, animation) {
                        final hasDefaultToken =
                            defaultTokenController.text.trim().isNotEmpty;
                        return RatholeServiceTile(
                          service: services[index],
                          index: index,
                          animation: animation,
                          processing: processing,
                          hasDefaultToken: hasDefaultToken,
                          onDelete: () => _removeService(index),
                          onUpdate: () {
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // 右侧终端区域
            terminalVisible
                ? Expanded(
                    flex: 4,
                    child: Terminal(
                      lines: formattedLines,
                      scrollController: _terminalScrollController,
                    ),
                  )
                : Expanded(flex: 4, child: Container()),
          ],
        ),
      ),
      floatingActionButton: ActionButtons(
        processing: processing,
        onAddService: addService,
        onToggleProcess: toggleProcess,
      ),
    );
  }
}
