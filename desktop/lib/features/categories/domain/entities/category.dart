import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({required this.id, required this.name, this.icon, this.color, this.active = true});

  final String id;
  final String name;
  final String? icon;
  final String? color;
  final bool active;

  @override
  List<Object?> get props => [id, name, icon, color, active];
}
