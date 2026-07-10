import '../../domain/entities/citizen.dart';

class CitizenModel extends Citizen {
  const CitizenModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.cpf,
    super.avatarUrl,
    required super.active,
    required super.createdAt,
  });

  factory CitizenModel.fromJson(Map<String, dynamic> json) {
    return CitizenModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      cpf: json['cpf'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
