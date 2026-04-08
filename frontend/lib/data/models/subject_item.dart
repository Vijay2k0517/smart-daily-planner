class SubjectItem {
  SubjectItem({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
