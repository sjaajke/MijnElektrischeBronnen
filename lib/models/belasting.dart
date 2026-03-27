import 'enums.dart';

class BelastingPeriode {
  final String id;
  BelastingPeriodePreset preset;
  double gelijktijdigheid; // 0.0 – 1.0

  BelastingPeriode({
    required this.id,
    this.preset = BelastingPeriodePreset.altijd,
    this.gelijktijdigheid = 1.0,
  });

  double get effectiefVermogenFactor => gelijktijdigheid;

  Map<String, dynamic> toJson() => {
        'id': id,
        'preset': preset.index,
        'gelijktijdigheid': gelijktijdigheid,
      };

  factory BelastingPeriode.fromJson(Map<String, dynamic> json) =>
      BelastingPeriode(
        id: json['id'] as String,
        preset: BelastingPeriodePreset
            .values[json['preset'] as int? ?? 0],
        gelijktijdigheid:
            (json['gelijktijdigheid'] as num?)?.toDouble() ?? 1.0,
      );
}

class BelastingVeld {
  final String id;
  String naam;
  double vermogen; // kVA (geïnstalleerd vermogen)
  BelastingPrioriteit prioriteit;
  String? verdederId;
  List<BelastingPeriode> perioden;

  BelastingVeld({
    required this.id,
    required this.naam,
    this.vermogen = 10.0,
    this.prioriteit = BelastingPrioriteit.normaal,
    this.verdederId,
    List<BelastingPeriode>? perioden,
  }) : perioden = perioden ?? [];

  /// Maximale gelijktijdigheid over alle perioden (of 1.0 als geen perioden).
  double get maxGelijktijdigheid => perioden.isEmpty
      ? 1.0
      : perioden
          .map((p) => p.gelijktijdigheid)
          .reduce((a, b) => a > b ? a : b);

  /// Effectief gevraagd vermogen (max periode).
  double get effectiefVermogen => vermogen * maxGelijktijdigheid;

  BelastingVeld copyWith({
    String? naam,
    double? vermogen,
    BelastingPrioriteit? prioriteit,
    String? verdederId,
    bool clearVerdeler = false,
    List<BelastingPeriode>? perioden,
  }) {
    return BelastingVeld(
      id: id,
      naam: naam ?? this.naam,
      vermogen: vermogen ?? this.vermogen,
      prioriteit: prioriteit ?? this.prioriteit,
      verdederId: clearVerdeler ? null : (verdederId ?? this.verdederId),
      perioden: perioden ?? List.from(this.perioden),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'naam': naam,
        'vermogen': vermogen,
        'prioriteit': prioriteit.index,
        'verdederId': verdederId,
        'perioden': perioden.map((p) => p.toJson()).toList(),
      };

  factory BelastingVeld.fromJson(Map<String, dynamic> json) => BelastingVeld(
        id: json['id'] as String,
        naam: json['naam'] as String,
        vermogen: (json['vermogen'] as num?)?.toDouble() ?? 10.0,
        prioriteit:
            BelastingPrioriteit.values[json['prioriteit'] as int? ?? 1],
        verdederId: json['verdederId'] as String?,
        perioden: (json['perioden'] as List<dynamic>?)
                ?.map((p) =>
                    BelastingPeriode.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class Belasting {
  double totaalVermogen; // kVA
  double cosFi;
  List<BelastingVeld> velden;

  Belasting({
    this.totaalVermogen = 100.0,
    this.cosFi = 0.85,
    List<BelastingVeld>? velden,
  }) : velden = velden ?? [];

  double get kritischVermogen => velden
      .where((v) => v.prioriteit == BelastingPrioriteit.kritisch)
      .fold(0.0, (sum, v) => sum + v.effectiefVermogen);

  double get totaalVeldenVermogen =>
      velden.fold(0.0, (sum, v) => sum + v.effectiefVermogen);

  Map<String, dynamic> toJson() => {
        'totaalVermogen': totaalVermogen,
        'cosFi': cosFi,
        'velden': velden.map((v) => v.toJson()).toList(),
      };

  factory Belasting.fromJson(Map<String, dynamic> json) => Belasting(
        totaalVermogen:
            (json['totaalVermogen'] as num?)?.toDouble() ?? 100.0,
        cosFi: (json['cosFi'] as num?)?.toDouble() ?? 0.85,
        velden: (json['velden'] as List<dynamic>?)
                ?.map((v) =>
                    BelastingVeld.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
