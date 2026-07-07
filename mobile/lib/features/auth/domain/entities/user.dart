import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.cpf,
    this.birthDate,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? cpf;
  final DateTime? birthDate;
  final String? phone;
  final String? avatarUrl;

  User copyWith({String? name, String? phone, String? avatarUrl}) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      cpf: cpf,
      birthDate: birthDate,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, email, cpf, birthDate, phone, avatarUrl];
}
