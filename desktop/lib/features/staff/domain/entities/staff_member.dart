import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.active = true,
  });

  final String id;
  final String name;
  final String email;
  final String role; // 'FUNCIONARIO' | 'ADMIN'
  final String? phone;
  final String? avatarUrl;
  final bool active;

  @override
  List<Object?> get props => [id, name, email, role, phone, avatarUrl, active];
}
