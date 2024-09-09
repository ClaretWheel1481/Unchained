import 'dart:io';

void initClientToml() async {
  try {
    final file = File('assets/client.toml');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('''
# client.toml
[client]
remote_addr = ""
[client.services.my_nas_ssh]
token = ""
local_addr = ""
''');
    } else {
      // TODO: 弹出错误提醒
    }
  } catch (e) {
    print('创建 client.toml 文件时出错: $e');
    // TODO: 弹出错误提醒
  }
}

bool saveFile(String remoteAddr, token, localAddr) {
  try {
    final file = File('assets/client.toml');
    final content = '''
[client]
remote_addr = "$remoteAddr"
[client.services.my_nas_ssh]
token = "$token"
local_addr = "$localAddr"
''';
    file.writeAsString(content);
    return true;
  } catch (e) {
    return false;
  }
}
