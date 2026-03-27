import 'enums.dart';

class VerdelerResultaat {
  final String verdederId;
  final String verdelerNaam;
  final bool isHoofdverdeler;
  final double lokaalVermogen;       // kVA: bronnen direct op deze verdeler
  final double beschikbaarVermogen;  // kVA: lokaal + upstream bronnen
  final double gevraagdVermogen;     // kVA: belastingvelden op deze verdeler
  final double kritischVermogen;     // kVA: alleen kritische belastingvelden
  final bool overbelast;
  final bool kritischGedekt;         // kritische belasting gedekt na N-1 uitval

  const VerdelerResultaat({
    required this.verdederId,
    required this.verdelerNaam,
    required this.isHoofdverdeler,
    required this.lokaalVermogen,
    required this.beschikbaarVermogen,
    required this.gevraagdVermogen,
    required this.kritischVermogen,
    required this.overbelast,
    required this.kritischGedekt,
  });

  bool get heeftBelasting => gevraagdVermogen > 0;
  bool get heeftKritischeBelasting => kritischVermogen > 0;
}

class BronResultaat {
  final String bronId;
  final String bronNaam;
  final double nominaleStroom; // A
  final double kortsluitStroom; // A
  final bool actief;

  const BronResultaat({
    required this.bronId,
    required this.bronNaam,
    required this.nominaleStroom,
    required this.kortsluitStroom,
    required this.actief,
  });
}

class BeveiligingResultaat {
  final String beveiligingId;
  final String beveiligingNaam;
  final String bronNaam;
  final SelectiviteitStatus selectiviteit;
  final bool spreektAanBijMinIk; // spreekt aan bij minimale foutstroom
  final bool overschrijdtIcu; // kortsluitstroom > Icu
  final String opmerking;

  const BeveiligingResultaat({
    required this.beveiligingId,
    required this.beveiligingNaam,
    required this.bronNaam,
    required this.selectiviteit,
    required this.spreektAanBijMinIk,
    required this.overschrijdtIcu,
    required this.opmerking,
  });
}

class BatterijAutonomie {
  final String bronId;
  final String bronNaam;
  final double capaciteitKwh;
  final double? autonomieZomerUur;  // null als capaciteit niet opgegeven
  final double? autonomieWinterUur;
  final double? oplaadtijdZomerUur; // null als geen PV in scenario
  final double? oplaadtijdWinterUur;

  const BatterijAutonomie({
    required this.bronId,
    required this.bronNaam,
    required this.capaciteitKwh,
    this.autonomieZomerUur,
    this.autonomieWinterUur,
    this.oplaadtijdZomerUur,
    this.oplaadtijdWinterUur,
  });
}

class FoutMelding {
  final String id;
  final FoutNiveau niveau;
  final String titel;
  final String beschrijving;
  final String? aanbeveling;

  const FoutMelding({
    required this.id,
    required this.niveau,
    required this.titel,
    required this.beschrijving,
    this.aanbeveling,
  });
}

class ScenarioResultaat {
  final BedrijfsModus modus;
  final double totaleIkMax; // kA
  final double totaleIkMin; // kA
  final double beschikbaarVermogen; // kVA
  final double gevraagdVermogen; // kVA
  final bool overbelast;
  final bool nMinEenOk; // N-1 redundantie
  final List<BronResultaat> bronResultaten;
  final List<BeveiligingResultaat> beveiligingResultaten;
  final List<VerdelerResultaat> verdelerResultaten;
  final List<FoutMelding> fouten;
  final List<BatterijAutonomie> batterijAutonomies;

  const ScenarioResultaat({
    required this.modus,
    required this.totaleIkMax,
    required this.totaleIkMin,
    required this.beschikbaarVermogen,
    required this.gevraagdVermogen,
    required this.overbelast,
    required this.nMinEenOk,
    required this.bronResultaten,
    required this.beveiligingResultaten,
    required this.verdelerResultaten,
    required this.fouten,
    this.batterijAutonomies = const [],
  });

  double get belastingsgraad =>
      gevraagdVermogen > 0 ? gevraagdVermogen / beschikbaarVermogen : 0;

  int get aantalKritiek =>
      fouten.where((f) => f.niveau == FoutNiveau.kritisch).length;
  int get aantalWaarschuwingen =>
      fouten.where((f) => f.niveau == FoutNiveau.waarschuwing).length;
}

class AnalyseResultaten {
  final ScenarioResultaat? huidigScenario;
  final Map<BedrijfsModus, ScenarioResultaat> alleScenarios;
  final DateTime berekendeOp;

  const AnalyseResultaten({
    required this.huidigScenario,
    required this.alleScenarios,
    required this.berekendeOp,
  });
}
