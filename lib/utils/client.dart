import 'dart:io';

// final Path = "data/flutter_assets/assets/";
final Path = "assets/";

// TODO: 编译时记得修改
Future<void> initClientToml() async {
  final file = File('${Path}client.toml');
  if (!await file.exists()) {
    await file.create(recursive: true);
    await file.writeAsString('''
# client.toml
[client]
remote_addr = ""

[client.services.services]
token = ""
local_addr = ""
type = "tcp"
nodelay = true
retry_interval = 1
''');
  }
}

// TODO: 编译时记得修改
bool saveFile(String remoteAddr, token, localAddr, type, bool nodelay,
    int retryInterval) {
  try {
    final file = File('${Path}client.toml');
    final content = '''
# client.toml
[client]
remote_addr = "$remoteAddr"

[client.services.services]
token = "$token"
local_addr = "$localAddr"
type = "$type"
nodelay = $nodelay
retry_interval = $retryInterval
''';
    file.writeAsString(content);
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> stopCommand() async {
  await Process.start('taskkill', ['/F', '/IM', 'rathole.exe']);
}
