import 'enums.dart';

class BelastingVeld {
  final String id;
  String naam;
  double vermogen; // kVA
  BelastingPrioriteit prioriteit;

  // Netwerktopologie
  String? verdederId; // verwijst naar Verdeler.id

  BelastingVeld({
    required this.id,
    required this.naam,
    this.vermogen = 10.0,
    this.prioriteit = BelastingPrioriteit.normaal,
    this.verdederId,
  });

  BelastingVeld copyWith({
    String? naam,
    double? vermogen,
    BelastingPrioriteit? prioriteit,
    String? verdederId,
    bool clearVerdeler = false,
  }) {
    return BelastingVeld(
      id: id,
      naam: naam ?? this.naam,
      vermogen: vermogen ?? this.vermogen,
      prioriteit: prioriteit ?? this.prioriteit,
      verdederId: clearVerdeler ? null : (verdederId ?? this.verdederId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'naam': naam,
        'vermogen': vermogen,
        'prioriteit': prioriteit.index,
        'verdederId': verdederId,
      };

  factory BelastingVeld.fromJson(Map<String, dynamic> json) => BelastingVeld(
        id: json['id'] as String,
        naam: json['naam'] as String,
        vermogen: (json['vermogen'] as num?)?.toDouble() ?? 10.0,
        prioriteit:
            BelastingPrioriteit.values[json['prioriteit'] as int? ?? 1],
        verdederId: json['verdederId'] as String?,
      );
}

class Belasting {
  double totaalVermogen; // kVA
  double cosFi; // power factor
  List<BelastingVeld> velden;

  Belasting({
    this.totaalVermogen = 100.0,
    this.cosFi = 0.85,
    List<BelastingVeld>? velden,
  }) : velden = velden ?? [];

  double get kritischVermogen => velden
      .where((v) => v.prioriteit == BelastingPrioriteit.kritisch)
      .fold(0.0, (sum, v) => sum + v.vermogen);

  double get totaalVeldenVermogen =>
      velden.fold(0.0, (sum, v) => sum + v.vermogen);

  Map<String, dynamic> toJson() => {
        'totaalVermogen': totaalVermogen,
        'cosFi': cosFi,
        'velden': velden.map((v) => v.toJson()).toList(),
      };

  factory Belasting.fromJson(Map<String, dynamic> json) => Belasting(
        totaalVermogen: (json['totaalVermogen'] as num?)?.toDouble() ?? 100.0,
        cosFi: (json['cosFi'] as num?)?.toDouble() ?? 0.85,
        velden: (json['velden'] as List<dynamic>?)
                ?.map((v) => BelastingVeld.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
