import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/device_id_service.dart';

class DeviceIdTestScreen extends StatefulWidget {
  const DeviceIdTestScreen({super.key});

  @override
  State<DeviceIdTestScreen> createState() => _DeviceIdTestScreenState();
}

class _DeviceIdTestScreenState extends State<DeviceIdTestScreen> {
  String _deviceId = 'Lade...';
  String _macAddress = 'Lade...';
  Map<String, dynamic> _deviceInfo = {};
  Map<String, String> _persistenceTest = {};
  bool _isLoading = true;
  bool _isTestingPersistence = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deviceId = await DeviceIdService.getDeviceId();
      final macAddress = await DeviceIdService.getMacAddress();
      final deviceInfo = await DeviceIdService.getDeviceInfo();

      setState(() {
        _deviceId = deviceId;
        _macAddress = macAddress;
        _deviceInfo = deviceInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _deviceId = 'Fehler: $e';
        _macAddress = 'Fehler: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetDeviceId() async {
    await DeviceIdService.resetDeviceId();
    await _loadDeviceInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geräte-ID wurde zurückgesetzt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testPersistence() async {
    setState(() {
      _isTestingPersistence = true;
    });

    try {
      final persistenceResult = await DeviceIdService.testPersistence();
      setState(() {
        _persistenceTest = persistenceResult;
        _isTestingPersistence = false;
      });
      
      // Aktualisiere auch die anderen Informationen
      await _loadDeviceInfo();
      
      if (mounted) {
        final isSuccess = persistenceResult['testResult'] == 'ERFOLGREICH';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess 
                ? 'Persistenz-Test erfolgreich! IDs bleiben nach App-Deinstallation gleich.'
                : 'Persistenz-Test fehlgeschlagen. IDs ändern sich nach App-Deinstallation.',
            ),
            backgroundColor: isSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _persistenceTest = {'error': e.toString()};
        _isTestingPersistence = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label in Zwischenablage kopiert'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geräte-ID Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeviceInfo,
            tooltip: 'Neu laden',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Geräte-ID Sektion
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.fingerprint, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Geräte-ID',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SelectableText(
                              _deviceId,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _copyToClipboard(_deviceId, 'Geräte-ID'),
                            icon: const Icon(Icons.copy),
                            label: const Text('Kopieren'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // MAC-Adresse Sektion
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.network_check, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'MAC-Adresse',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SelectableText(
                              _macAddress,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _copyToClipboard(_macAddress, 'MAC-Adresse'),
                            icon: const Icon(Icons.copy),
                            label: const Text('Kopieren'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Geräteinformationen Sektion
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text(
                                'Geräteinformationen',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._deviceInfo.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '${entry.key}:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SelectableText(
                                      entry.value?.toString() ?? 'null',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Persistenz-Test Sektion
                  if (_persistenceTest.isNotEmpty)
                    Card(
                      color: _persistenceTest['testResult'] == 'ERFOLGREICH' 
                          ? Colors.green[50] 
                          : Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _persistenceTest['testResult'] == 'ERFOLGREICH'
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: _persistenceTest['testResult'] == 'ERFOLGREICH'
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Persistenz-Test Ergebnis',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _persistenceTest['testResult'] == 'ERFOLGREICH'
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._persistenceTest.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        '${entry.key}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SelectableText(
                                        entry.value,
                                        style: TextStyle(
                                          fontFamily: entry.key.contains('Address') ? 'monospace' : null,
                                          fontSize: 12,
                                          fontWeight: entry.key == 'testResult' 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                          color: entry.key == 'testResult'
                                              ? (entry.value == 'ERFOLGREICH' ? Colors.green[700] : Colors.orange[700])
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isTestingPersistence ? null : _testPersistence,
                        icon: _isTestingPersistence 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.science),
                        label: Text(_isTestingPersistence ? 'Teste...' : 'Persistenz testen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _resetDeviceId,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Informationstext
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Hinweise',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Die Geräte-ID wird sicher im Keychain/Keystore gespeichert\n'
                            '• Sie bleibt über App-Neustarts hinweg konsistent\n'
                            '• Die MAC-Adresse wird aus der Geräte-ID generiert\n'
                            '• Bei App-Deinstallation gehen die IDs verloren\n'
                            '• "Reset" löscht die gespeicherten IDs und generiert neue',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
