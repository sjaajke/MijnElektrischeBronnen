import 'enums.dart';

class Beveiliging {
  final String id;
  final String bronId; // koppeling aan EnergiBron
  String naam;
  BeveiligingType type;

  double inNominaal; // In – nominale stroom (A)
  double irThermisch; // Ir – thermische afstelling (× In)
  double isdKortsluit; // Isd – kortsluit vertraagd (× In)
  double iiInstantaan; // Ii – instantaan (× In)

  double tIr; // tijdvertraging thermisch (s)
  double tIsd; // tijdvertraging kortsluit vertraagd (s)
  double tIi; // tijdvertraging instantaan (s)

  double icu; // Uitschakelcapaciteit kA

  Beveiliging({
    required this.id,
    required this.bronId,
    required this.naam,
    this.type = BeveiligingType.automatLsig,
    this.inNominaal = 100.0,
    this.irThermisch = 1.0,
    this.isdKortsluit = 5.0,
    this.iiInstantaan = 10.0,
    this.tIr = 0.0,
    this.tIsd = 0.3,
    this.tIi = 0.0,
    this.icu = 25.0,
  });

  /// Werkelijke thermische uitschakelstroom (A)
  double get iThermischWerkelijk => inNominaal * irThermisch;

  /// Werkelijke kortsluit vertraagde stroom (A)
  double get iSdWerkelijk => inNominaal * isdKortsluit;

  /// Werkelijke instantane stroom (A)
  double get iIWerkelijk => inNominaal * iiInstantaan;

  Beveiliging copyWith({
    String? naam,
    BeveiligingType? type,
    double? inNominaal,
    double? irThermisch,
    double? isdKortsluit,
    double? iiInstantaan,
    double? tIr,
    double? tIsd,
    double? tIi,
    double? icu,
  }) {
    return Beveiliging(
      id: id,
      bronId: bronId,
      naam: naam ?? this.naam,
      type: type ?? this.type,
      inNominaal: inNominaal ?? this.inNominaal,
      irThermisch: irThermisch ?? this.irThermisch,
      isdKortsluit: isdKortsluit ?? this.isdKortsluit,
      iiInstantaan: iiInstantaan ?? this.iiInstantaan,
      tIr: tIr ?? this.tIr,
      tIsd: tIsd ?? this.tIsd,
      tIi: tIi ?? this.tIi,
      icu: icu ?? this.icu,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bronId': bronId,
        'naam': naam,
        'type': type.index,
        'inNominaal': inNominaal,
        'irThermisch': irThermisch,
        'isdKortsluit': isdKortsluit,
        'iiInstantaan': iiInstantaan,
        'tIr': tIr,
        'tIsd': tIsd,
        'tIi': tIi,
        'icu': icu,
      };

  factory Beveiliging.fromJson(Map<String, dynamic> json) => Beveiliging(
        id: json['id'] as String,
        bronId: json['bronId'] as String,
        naam: json['naam'] as String,
        type: BeveiligingType.values[json['type'] as int? ?? 0],
        inNominaal: (json['inNominaal'] as num?)?.toDouble() ?? 100,
        irThermisch: (json['irThermisch'] as num?)?.toDouble() ?? 1.0,
        isdKortsluit: (json['isdKortsluit'] as num?)?.toDouble() ?? 5.0,
        iiInstantaan: (json['iiInstantaan'] as num?)?.toDouble() ?? 10.0,
        tIr: (json['tIr'] as num?)?.toDouble() ?? 0.0,
        tIsd: (json['tIsd'] as num?)?.toDouble() ?? 0.3,
        tIi: (json['tIi'] as num?)?.toDouble() ?? 0.0,
        icu: (json['icu'] as num?)?.toDouble() ?? 25.0,
      );
}
