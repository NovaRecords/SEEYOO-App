class AuthResponse {
  final bool isSuccess;
  final String? accessToken;
  final String? tokenType;
  final int? expiresIn;
  final String? refreshToken;
  final int? userId;
  final String? errorMessage;

  AuthResponse({
    this.isSuccess = true,
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.refreshToken,
    this.userId,
    this.errorMessage,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      isSuccess: !json.containsKey('error'),
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
      refreshToken: json['refresh_token'],
      userId: json['user_id'],
      errorMessage: json['error'],
    );
  }

  // Konvertiert die Response zu einem speicherbaren JSON-Format
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_token': refreshToken,
      'user_id': userId,
      'expiry_date': DateTime.now().add(Duration(seconds: expiresIn ?? 0)).millisecondsSinceEpoch,
    };
  }

  // Hilft zu überprüfen, ob der Token abgelaufen ist
  bool get isExpired {
    final expiryDate = toJson()['expiry_date'] as int?;
    if (expiryDate == null) return true;
    
    return DateTime.now().millisecondsSinceEpoch > expiryDate;
  }
}
