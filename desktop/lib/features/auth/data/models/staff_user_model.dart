import '../../domain/entities/staff_user.dart';

class StaffUserModel extends StaffUser {
  const StaffUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.avatarUrl,
  });

  factory StaffUserModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;
    return StaffUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: role?['name'] as String? ?? 'FUNCIONARIO',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
