import 'package:equatable/equatable.dart';

/// Usuario autenticado no painel — sempre `FUNCIONARIO` ou `ADMIN` (o
/// backend rejeita login de `CIDADAO` nas rotas do desktop atraves do
/// RBAC de cada endpoint, ver docs/ARQUITETURA_GOODROADS.md, secao 4.1).
class StaffUser extends Equatable {
  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String role; // 'FUNCIONARIO' | 'ADMIN'
  final String? phone;
  final String? avatarUrl;

  bool get isAdmin => role == 'ADMIN';

  StaffUser copyWith({String? name, String? phone, String? avatarUrl}) {
    return StaffUser(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, phone, avatarUrl];
}
