import 'package:flutter/foundation.dart';

class User {
  final int id;
  final int? account;
  final int? status;
  final String? mac;
  final String? fname;
  final String? phone;
  final String? email;
  final String? tariffPlan;
  final String? endDate;
  final double? accountBalance;
  final String? logo;
  final String? background;

  const User({
    required this.id,
    this.account,
    this.status,
    this.mac,
    this.fname,
    this.phone,
    this.email,
    this.tariffPlan,
    this.endDate,
    this.accountBalance,
    this.logo,
    this.background,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      account: json['account'] != null ? int.tryParse(json['account'].toString()) : null,
      status: json['status'] != null ? int.tryParse(json['status'].toString()) : null,
      mac: json['mac']?.toString(),
      fname: json['fname']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      tariffPlan: json['tariff_plan']?.toString(),
      endDate: json['end_date']?.toString(),
      accountBalance: json['account_balance'] != null ? 
        double.tryParse(json['account_balance'].toString()) : null,
      logo: json['logo']?.toString(),
      background: json['background']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account': account,
      'email': email,
      'status': status,
      'mac': mac,
      'fname': fname,
      'phone': phone,
      'tariff_plan': tariffPlan,
      'end_date': endDate,
      'account_balance': accountBalance,
      'logo': logo,
      'background': background,
    };
  }

  User copyWith({
    int? id,
    int? account,
    int? status,
    String? mac,
    String? fname,
    String? phone,
    String? tariffPlan,
    String? endDate,
    double? accountBalance,
    String? logo,
    String? background,
  }) {
    return User(
      id: id ?? this.id,
      account: account ?? this.account,
      status: status ?? this.status,
      mac: mac ?? this.mac,
      fname: fname ?? this.fname,
      phone: phone ?? this.phone,
      tariffPlan: tariffPlan ?? this.tariffPlan,
      endDate: endDate ?? this.endDate,
      accountBalance: accountBalance ?? this.accountBalance,
      logo: logo ?? this.logo,
      background: background ?? this.background,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.account == account &&
        other.status == status &&
        other.mac == mac &&
        other.fname == fname &&
        other.phone == phone &&
        other.tariffPlan == tariffPlan &&
        other.endDate == endDate &&
        other.accountBalance == accountBalance &&
        other.logo == logo &&
        other.background == background;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      account,
      status,
      mac,
      fname,
      phone,
      tariffPlan,
      endDate,
      accountBalance,
      logo,
      background,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, account: $account, status: $status, mac: $mac, name: $fname)';
  }
}
