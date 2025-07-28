import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔒 Sichere Konfiguration wird injiziert...');
  
  // Lade config.json
  final configFile = File('config.json');
  if (!configFile.existsSync()) {
    print('❌ config.json nicht gefunden!');
    exit(1);
  }
  
  final configContent = await configFile.readAsString();
  final config = jsonDecode(configContent);
  
  // Injiziere Android strings.xml
  await injectAndroidConfig(config);
  
  // Injiziere iOS Info.plist
  await injectIOSConfig(config);
  
  print('✅ Android strings.xml aktualisiert');
  print('✅ iOS Info.plist aktualisiert');
  print('✅ Konfiguration erfolgreich injiziert!');
}

Future<void> injectAndroidConfig(Map<String, dynamic> config) async {
  final stringsFile = File('android/app/src/main/res/values/strings.xml');
  
  final content = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">${config['app']['name']}</string>
    
    <!-- Facebook App ID - INJECTED FROM CONFIG -->
    <string name="facebook_app_id">${config['oauth']['facebook']['app_id']}</string>
    <string name="fb_login_protocol_scheme">fb${config['oauth']['facebook']['app_id']}</string>
    <string name="facebook_client_token">${config['oauth']['facebook']['client_token']}</string>
</resources>
''';
  
  await stringsFile.writeAsString(content);
}

Future<void> injectIOSConfig(Map<String, dynamic> config) async {
  final infoFile = File('ios/Runner/Info.plist');
  
  if (!infoFile.existsSync()) {
    print('⚠️ iOS Info.plist nicht gefunden - überspringe iOS Konfiguration');
    return;
  }
  
  var content = await infoFile.readAsString();
  
  // Ersetze Facebook App ID
  content = content.replaceAll(
    RegExp(r'<key>FacebookAppID</key>\s*<string>.*?</string>'),
    '<key>FacebookAppID</key>\n\t<string>${config['oauth']['facebook']['app_id']}</string>'
  );
  
  // Ersetze Facebook URL Scheme
  content = content.replaceAll(
    RegExp(r'<string>fb\d+</string>'),
    '<string>fb${config['oauth']['facebook']['app_id']}</string>'
  );
  
  await infoFile.writeAsString(content);
}
