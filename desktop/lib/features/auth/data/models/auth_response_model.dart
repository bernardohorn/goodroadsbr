import 'staff_user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({required this.user, required this.accessToken, required this.refreshToken});

  final StaffUserModel user;
  final String accessToken;
  final String refreshToken;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: StaffUserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
