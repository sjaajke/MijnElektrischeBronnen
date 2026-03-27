class OpgeslagenNetwerk {
  final String id;
  final String naam;
  final DateTime opgeslagenOp;
  final Map<String, dynamic> data;

  const OpgeslagenNetwerk({
    required this.id,
    required this.naam,
    required this.opgeslagenOp,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'naam': naam,
        'opgeslagenOp': opgeslagenOp.toIso8601String(),
        'data': data,
      };

  factory OpgeslagenNetwerk.fromJson(Map<String, dynamic> json) =>
      OpgeslagenNetwerk(
        id: json['id'] as String,
        naam: json['naam'] as String,
        opgeslagenOp: DateTime.parse(json['opgeslagenOp'] as String),
        data: json['data'] as Map<String, dynamic>,
      );
}
