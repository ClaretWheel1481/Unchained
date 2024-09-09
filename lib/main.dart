import 'package:fluent_ui/fluent_ui.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:unchained/utils/client.dart';
import 'package:unchained/widgets/navigation.dart';

void main() {
  runApp(const MyApp());

  //启动时设置窗口大小
  doWhenWindowReady(() {
    appWindow.minSize = const Size(1080, 620);
    appWindow.maxSize = const Size(1080, 620);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });

  // 检查Toml文件是否存在，没有则初始化
  initClientToml();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const FluentApp(
      home: NavigationWidget(),
    );
  }
}
