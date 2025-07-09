import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'dart:io';

void main() async {
  print('Starting user creation script...');
  
  final apiService = ApiService(StorageService());
  
  print('Attempting to create new user: Vitali Mack');
  final result = await apiService.createUser(
    name: 'Vitali Mack',
    email: 'vitali.mack@gmx.de',
    tariff: 'full-de',
    id: '125',
    password: '18101973',
    accountNumber: '125'
  );
  
  print('User creation result: $result');
  
  exit(0);
}
