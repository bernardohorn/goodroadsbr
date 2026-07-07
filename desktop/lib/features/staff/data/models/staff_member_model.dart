import '../../domain/entities/staff_member.dart';

class StaffMemberModel extends StaffMember {
  const StaffMemberModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.avatarUrl,
    super.active,
  });

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;
    return StaffMemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: role?['name'] as String? ?? 'FUNCIONARIO',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}
