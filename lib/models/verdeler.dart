class Verdeler {
  final String id;
  String naam;
  String? parentId; // null = hoofdverdeler (wortel)

  Verdeler({
    required this.id,
    required this.naam,
    this.parentId,
  });

  bool get isHoofdverdeler => parentId == null;

  Verdeler copyWith({String? naam, String? parentId, bool clearParent = false}) {
    return Verdeler(
      id: id,
      naam: naam ?? this.naam,
      parentId: clearParent ? null : (parentId ?? this.parentId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'naam': naam,
        'parentId': parentId,
      };

  factory Verdeler.fromJson(Map<String, dynamic> json) => Verdeler(
        id: json['id'] as String,
        naam: json['naam'] as String,
        parentId: json['parentId'] as String?,
      );
}
