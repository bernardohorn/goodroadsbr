class TeamModel {
  const TeamModel({required this.id, required this.name});
  final String id;
  final String name;

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(id: json['id'] as String, name: json['name'] as String);
  }
}
