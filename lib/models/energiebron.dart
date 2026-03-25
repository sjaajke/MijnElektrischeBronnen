import 'dart:math';
import 'enums.dart';

class EnergiBron {
  final String id;
  String naam;
  bool actief;
  BronType type;

  // Algemeen
  double nominaalVermogen; // kVA
  double nominaleSpanning; // V

  // Trafo specifiek
  double kortsluitspanning; // uk %  (b.v. 4.0 = 4%)

  // Generator specifiek
  double subtransientReactantie; // X''d %  (b.v. 15.0 = 15%)

  // PV / Batterij specifiek
  double kortsluitFactor; // bijv. 1.1 – 1.25

  // Netwerktopologie
  String? verdederId; // verwijst naar Verdeler.id

  EnergiBron({
    required this.id,
    required this.naam,
    this.actief = true,
    this.type = BronType.trafo,
    this.nominaalVermogen = 100.0,
    this.nominaleSpanning = 400.0,
    this.kortsluitspanning = 4.0,
    this.subtransientReactantie = 15.0,
    this.kortsluitFactor = 1.2,
    this.verdederId,
  });

  /// Nominale stroom I = S / (√3 × U)  in Ampere
  double get nominaleStroom =>
      (nominaalVermogen * 1000) / (sqrt(3) * nominaleSpanning);

  /// Kortsluitstroom per type
  double get kortsluitStroom {
    switch (type) {
      case BronType.trafo:
        if (kortsluitspanning <= 0) return 0;
        return nominaleStroom / (kortsluitspanning / 100);
      case BronType.generator:
        if (subtransientReactantie <= 0) return 0;
        return nominaleStroom / (subtransientReactantie / 100);
      case BronType.pv:
      case BronType.batterij:
        return kortsluitFactor * nominaleStroom;
    }
  }

  /// Bijdrage in kA
  double get kortsluitStroomKA => kortsluitStroom / 1000;

  EnergiBron copyWith({
    String? naam,
    bool? actief,
    BronType? type,
    double? nominaalVermogen,
    double? nominaleSpanning,
    double? kortsluitspanning,
    double? subtransientReactantie,
    double? kortsluitFactor,
    String? verdederId,
  }) {
    return EnergiBron(
      id: id,
      naam: naam ?? this.naam,
      actief: actief ?? this.actief,
      type: type ?? this.type,
      nominaalVermogen: nominaalVermogen ?? this.nominaalVermogen,
      nominaleSpanning: nominaleSpanning ?? this.nominaleSpanning,
      kortsluitspanning: kortsluitspanning ?? this.kortsluitspanning,
      subtransientReactantie:
          subtransientReactantie ?? this.subtransientReactantie,
      kortsluitFactor: kortsluitFactor ?? this.kortsluitFactor,
      verdederId: verdederId ?? this.verdederId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'naam': naam,
        'actief': actief,
        'type': type.index,
        'nominaalVermogen': nominaalVermogen,
        'nominaleSpanning': nominaleSpanning,
        'kortsluitspanning': kortsluitspanning,
        'subtransientReactantie': subtransientReactantie,
        'kortsluitFactor': kortsluitFactor,
        'verdederId': verdederId,
      };

  factory EnergiBron.fromJson(Map<String, dynamic> json) => EnergiBron(
        id: json['id'] as String,
        naam: json['naam'] as String,
        actief: json['actief'] as bool? ?? true,
        type: BronType.values[json['type'] as int? ?? 0],
        nominaalVermogen: (json['nominaalVermogen'] as num?)?.toDouble() ?? 100,
        nominaleSpanning: (json['nominaleSpanning'] as num?)?.toDouble() ?? 400,
        kortsluitspanning:
            (json['kortsluitspanning'] as num?)?.toDouble() ?? 4.0,
        subtransientReactantie:
            (json['subtransientReactantie'] as num?)?.toDouble() ?? 15.0,
        kortsluitFactor:
            (json['kortsluitFactor'] as num?)?.toDouble() ?? 1.2,
        verdederId: json['verdederId'] as String?,
      );
}
