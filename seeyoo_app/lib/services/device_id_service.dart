import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class DeviceIdService {
  static const String _deviceIdKey = 'unique_device_id';
  static const String _macAddressKey = 'device_mac_address';
  
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Ruft die eindeutige Geräte-ID ab oder erstellt eine neue
  static Future<String> getDeviceId() async {
    try {
      // Prüfe zuerst, ob bereits eine ID gespeichert ist
      String? storedId = await _secureStorage.read(key: _deviceIdKey);
      if (storedId != null && storedId.isNotEmpty) {
        return storedId;
      }

      // Generiere neue Geräte-ID basierend auf Geräteinformationen
      String deviceId = await _generateDeviceId();
      
      // Speichere die ID sicher
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      
      return deviceId;
    } catch (e) {
      print('Fehler beim Abrufen der Geräte-ID: $e');
      // Fallback: Generiere zufällige ID
      String fallbackId = _generateFallbackId();
      await _secureStorage.write(key: _deviceIdKey, value: fallbackId);
      return fallbackId;
    }
  }

  /// Ruft die MAC-Adresse ab oder generiert eine neue basierend auf der Geräte-ID
  static Future<String> getMacAddress() async {
    try {
      // Prüfe zuerst, ob bereits eine MAC-Adresse gespeichert ist
      String? storedMac = await _secureStorage.read(key: _macAddressKey);
      if (storedMac != null && storedMac.isNotEmpty) {
        return storedMac;
      }

      // Generiere MAC-Adresse basierend auf Geräte-ID
      String deviceId = await getDeviceId();
      String macAddress = _generateMacFromDeviceId(deviceId);
      
      // Speichere die MAC-Adresse
      await _secureStorage.write(key: _macAddressKey, value: macAddress);
      
      return macAddress;
    } catch (e) {
      print('Fehler beim Abrufen der MAC-Adresse: $e');
      // Fallback MAC-Adresse
      String fallbackMac = _generateFallbackMac();
      await _secureStorage.write(key: _macAddressKey, value: fallbackMac);
      return fallbackMac;
    }
  }

  /// Generiert eine eindeutige Geräte-ID basierend auf Geräteinformationen
  /// Diese ID ist darauf ausgelegt, auch nach App-Deinstallation konsistent zu bleiben
  static Future<String> _generateDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String identifier = '';

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        
        // Android ID ist die beste Option für Persistenz über App-Deinstallationen
        identifier = androidInfo.id ?? '';
        
        // Zusätzliche Fallback-Strategie mit Hardware-spezifischen Daten
        if (identifier.isEmpty) {
          // Kombiniere Hardware-spezifische Eigenschaften die sich nicht ändern
          List<String> hardwareProps = [
            androidInfo.brand ?? '',
            androidInfo.model ?? '',
            androidInfo.device ?? '',
            androidInfo.hardware ?? '',
            androidInfo.board ?? '',
            androidInfo.bootloader ?? '',
            androidInfo.fingerprint?.split('/').first ?? '', // Erste Teil des Fingerprints
          ].where((prop) => prop.isNotEmpty).toList();
          
          identifier = hardwareProps.join('_');
        }
        
        print('Android Geräte-ID Quelle: ${identifier.isNotEmpty ? "Android ID oder Hardware-Kombination" : "Fallback"}');
        
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        
        // identifierForVendor ist die beste verfügbare Option für iOS
        // Bleibt konsistent solange mindestens eine App des Vendors installiert ist
        identifier = iosInfo.identifierForVendor ?? '';
        
        // Fallback mit Hardware-spezifischen Eigenschaften
        if (identifier.isEmpty) {
          List<String> hardwareProps = [
            iosInfo.model ?? '',
            iosInfo.localizedModel ?? '',
            iosInfo.systemName ?? '',
            iosInfo.utsname.machine ?? '', // Hardware-Modell (z.B. "iPhone14,2")
          ].where((prop) => prop.isNotEmpty).toList();
          
          identifier = hardwareProps.join('_');
        }
        
        print('iOS Geräte-ID Quelle: ${identifier.isNotEmpty ? "identifierForVendor oder Hardware-Kombination" : "Fallback"}');
      }
    } catch (e) {
      print('Fehler beim Abrufen der Geräteinformationen: $e');
    }

    // Wenn immer noch leer, generiere deterministischen Fallback
    if (identifier.isEmpty) {
      identifier = _generateFallbackId();
      print('Geräte-ID Quelle: Sicherer Fallback');
    }

    // Hash die Identifier für Konsistenz und Datenschutz
    var bytes = utf8.encode(identifier);
    var digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Generiert eine MAC-Adresse aus der Geräte-ID
  static String _generateMacFromDeviceId(String deviceId) {
    // Verwende die ersten 12 Zeichen des Hashes für die MAC-Adresse
    String macBase = deviceId.substring(0, 12).toUpperCase();
    
    // Formatiere als MAC-Adresse (XX:XX:XX:XX:XX:XX)
    String macAddress = '';
    for (int i = 0; i < macBase.length; i += 2) {
      if (i > 0) macAddress += ':';
      macAddress += macBase.substring(i, i + 2);
    }
    
    // Stelle sicher, dass es eine gültige MAC-Adresse ist
    // Setze das zweite Bit des ersten Oktetts auf 1 für lokal administrierte Adresse
    List<String> parts = macAddress.split(':');
    int firstOctet = int.parse(parts[0], radix: 16);
    firstOctet |= 0x02; // Setze das "locally administered" Bit
    firstOctet &= 0xFE; // Stelle sicher, dass es keine Multicast-Adresse ist
    parts[0] = firstOctet.toRadixString(16).toUpperCase().padLeft(2, '0');
    
    return parts.join(':');
  }

  /// Generiert eine Fallback-ID wenn Geräteinformationen nicht verfügbar sind
  static String _generateFallbackId() {
    var random = Random.secure();
    var bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Generiert eine Fallback-MAC-Adresse
  static String _generateFallbackMac() {
    var random = Random.secure();
    List<String> macParts = [];
    
    for (int i = 0; i < 6; i++) {
      int octet = random.nextInt(256);
      if (i == 0) {
        // Erste Oktett: Setze locally administered bit, clear multicast bit
        octet |= 0x02;
        octet &= 0xFE;
      }
      macParts.add(octet.toRadixString(16).toUpperCase().padLeft(2, '0'));
    }
    
    return macParts.join(':');
  }

  /// Löscht die gespeicherten IDs (für Debugging/Reset)
  static Future<void> resetDeviceId() async {
    await _secureStorage.delete(key: _deviceIdKey);
    await _secureStorage.delete(key: _macAddressKey);
  }

  /// Testet die Persistenz der Geräte-ID durch Simulation einer App-Neuinstallation
  static Future<Map<String, String>> testPersistence() async {
    Map<String, String> result = {};
    
    try {
      // 1. Aktuelle IDs abrufen
      String currentDeviceId = await getDeviceId();
      String currentMacAddress = await getMacAddress();
      
      // 2. Secure Storage löschen (simuliert App-Deinstallation)
      await _secureStorage.delete(key: _deviceIdKey);
      await _secureStorage.delete(key: _macAddressKey);
      
      // 3. Neue IDs generieren (simuliert App-Neuinstallation)
      String newDeviceId = await getDeviceId();
      String newMacAddress = await getMacAddress();
      
      // 4. Vergleichen
      bool deviceIdPersistent = currentDeviceId == newDeviceId;
      bool macAddressPersistent = currentMacAddress == newMacAddress;
      
      result = {
        'currentDeviceId': currentDeviceId.substring(0, 16) + '...',
        'newDeviceId': newDeviceId.substring(0, 16) + '...',
        'currentMacAddress': currentMacAddress,
        'newMacAddress': newMacAddress,
        'deviceIdPersistent': deviceIdPersistent.toString(),
        'macAddressPersistent': macAddressPersistent.toString(),
        'testResult': (deviceIdPersistent && macAddressPersistent) ? 'ERFOLGREICH' : 'FEHLGESCHLAGEN',
      };
      
    } catch (e) {
      result['error'] = e.toString();
    }
    
    return result;
  }

  /// Gibt Debug-Informationen über das Gerät zurück
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> info = {};

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        info = {
          'platform': 'Android',
          'id': androidInfo.id,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'device': androidInfo.device,
          'hardware': androidInfo.hardware,
          'board': androidInfo.board,
          'bootloader': androidInfo.bootloader,
          'fingerprint': androidInfo.fingerprint,
          'androidId': androidInfo.id,
          'persistenceNote': 'Android ID überlebt App-Deinstallation (außer Factory Reset)',
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        info = {
          'platform': 'iOS',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'localizedModel': iosInfo.localizedModel,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
          'utsname_machine': iosInfo.utsname.machine,
          'persistenceNote': 'identifierForVendor überlebt App-Deinstallation (solange eine Vendor-App installiert bleibt)',
        };
      }
    } catch (e) {
      info['error'] = e.toString();
    }

    // Füge unsere generierten IDs hinzu
    try {
      info['generatedDeviceId'] = await getDeviceId();
      info['generatedMacAddress'] = await getMacAddress();
      
      // Prüfe ob IDs aus Secure Storage oder neu generiert wurden
      String? storedId = await _secureStorage.read(key: _deviceIdKey);
      info['idSource'] = storedId != null ? 'Secure Storage (bereits vorhanden)' : 'Neu generiert';
    } catch (e) {
      info['generationError'] = e.toString();
    }

    return info;
  }
}
