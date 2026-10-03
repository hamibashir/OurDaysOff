import 'user_model.dart';

class AuthResponse {
  final String message;
  final UserModel user;
  final String token;

  const AuthResponse({
    required this.message,
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final userMap = data['user'] as Map<String, dynamic>? ?? {};

    return AuthResponse(
      message: json['message'] as String? ?? 'Success',
      user: UserModel.fromJson(userMap),
      token: data['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': {
        'user': user.toJson(),
        'token': token,
      },
    };
  }
}
