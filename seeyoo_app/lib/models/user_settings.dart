import 'package:flutter/foundation.dart';

class UserSettings {
  final String? parentPassword;
  final Map<String, dynamic>? customSettings;

  const UserSettings({
    this.parentPassword,
    this.customSettings,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      parentPassword: json['parent_password'] as String?,
      customSettings: json,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (parentPassword != null) {
      data['parent_password'] = parentPassword;
    }
    
    if (customSettings != null) {
      data.addAll(customSettings!);
    }
    
    return data;
  }

  UserSettings copyWith({
    String? parentPassword,
    Map<String, dynamic>? customSettings,
  }) {
    return UserSettings(
      parentPassword: parentPassword ?? this.parentPassword,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.parentPassword == parentPassword &&
        mapEquals(other.customSettings, customSettings);
  }

  @override
  int get hashCode => parentPassword.hashCode ^ customSettings.hashCode;
}
