import 'dart:io';
import 'package:toml/toml.dart';
import 'package:unchained/classes/service_config.dart';

class RatholeConfigManager {
  static Future<Map<String, dynamic>> readRatholeConfigFrom(
      String fullPath) async {
    final file = File(fullPath);

    if (!await file.exists()) {
      await createEmptyTemplate(file);
      return {
        'remoteAddr': '',
        'services': <RatholeServiceConfig>[],
      };
    }

    final content = await file.readAsString();
    TomlDocument tomlDoc;
    try {
      tomlDoc = TomlDocument.parse(content);
    } catch (e) {
      return {
        'remoteAddr': '',
        'services': <RatholeServiceConfig>[],
      };
    }
    final tomlMap = tomlDoc.toMap();

    final clientSection = (tomlMap['client'] ?? {}) as Map<String, dynamic>;

    final remoteAddr = clientSection['remote_addr']?.toString() ?? '';
    final rawServices = clientSection['services'];
    final List<RatholeServiceConfig> services = [];

    if (rawServices is Map<String, dynamic>) {
      rawServices.forEach((serviceName, value) {
        if (value is Map<String, dynamic>) {
          services.add(RatholeServiceConfig(
            name: serviceName,
            token: value['token']?.toString() ?? '',
            localAddr: value['local_addr']?.toString() ?? '',
            type: value['type']?.toString() ?? 'tcp',
            nodelay:
                value['nodelay'] is bool ? (value['nodelay'] as bool) : false,
            retryInterval: value['retry_interval']?.toString() ?? '1',
          ));
        }
      });
    }

    return {
      'remoteAddr': remoteAddr,
      'defaultToken': clientSection['default_token']?.toString() ?? '',
      'services': services,
    };
  }

  static Future<bool> saveRatholeConfigTo(String fullPath, String remoteAddr,
      String defaultToken, List<RatholeServiceConfig> services) async {
    for (var s in services) {
      if (s.nameController.text.trim().isEmpty ||
          s.localAddrController.text.trim().isEmpty ||
          s.retryIntervalController.text.trim().isEmpty) {
        return false;
      }
      if (defaultToken.isEmpty && s.tokenController.text.trim().isEmpty) {
        return false;
      }
    }

    final file = File(fullPath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final sb = StringBuffer();
    sb.writeln('[client]');
    sb.writeln('remote_addr = "${_escapeLiteral(remoteAddr)}"');
    if (defaultToken.isNotEmpty) {
      sb.writeln('default_token = "${_escapeLiteral(defaultToken)}"');
    }

    for (var s in services) {
      final name = s.nameController.text.trim();
      final m = s.toMap();
      sb.writeln('\n[client.services.$name]');
      final token = m['token']!.toString();
      if (token != defaultToken) {
        sb.writeln('token = "${_escapeLiteral(token)}"');
      }
      sb.writeln('local_addr = "${_escapeLiteral(m['local_addr']!)}"');
      sb.writeln('type = "${_escapeLiteral(m['type']!)}"');
      sb.writeln('nodelay = ${m['nodelay']!}');
      sb.writeln('retry_interval = ${m['retry_interval']!}');
    }

    try {
      await file.writeAsString(sb.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> createEmptyTemplate(File file) async {
    const defaultContent = '''
[client]
remote_addr = ""

''';

    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    await file.writeAsString(defaultContent);
  }

  static String _escapeLiteral(String raw) {
    return raw.replaceAll(r'"', r'\"');
  }

  static Future<void> stopRathole() async {
    await Process.start('taskkill', ['/F', '/IM', 'rathole.exe']);
  }
}
