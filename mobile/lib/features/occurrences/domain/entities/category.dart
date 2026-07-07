import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({required this.id, required this.name, this.icon, this.color});

  final String id;
  final String name;
  final String? icon;
  final String? color;

  @override
  List<Object?> get props => [id, name, icon, color];
}
