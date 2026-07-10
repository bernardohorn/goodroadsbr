import 'package:equatable/equatable.dart';

/// Visao de uma conta de cidadao (mobile) sob a otica do painel
/// administrativo — somente leitura, exceto pelo campo `active` (ver
/// UpdateCitizenStatusUseCase). A conta continua sendo criada e editada
/// exclusivamente pelo proprio cidadao no app mobile.
class Citizen extends Equatable {
  const Citizen({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.cpf,
    this.avatarUrl,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? cpf;
  final String? avatarUrl;
  final bool active;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, email, phone, cpf, avatarUrl, active, createdAt];
}
