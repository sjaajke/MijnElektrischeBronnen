import '../models/energiebron.dart';
import '../models/beveiliging.dart';
import '../models/belasting.dart';
import '../models/verdeler.dart';
import '../models/enums.dart';
import '../models/resultaten.dart';

class ElektroBerekeningen {
  static AnalyseResultaten bereken({
    required List<EnergiBron> bronnen,
    required List<Beveiliging> beveiligingen,
    required Belasting belasting,
    required BedrijfsModus actiefScenario,
    List<Verdeler> verdelaars = const [],
  }) {
    final alleScenarios = <BedrijfsModus, ScenarioResultaat>{};

    for (final modus in BedrijfsModus.values) {
      final activeBronnen = _getBronnenVoorModus(bronnen, modus);
      alleScenarios[modus] = _berekenScenario(
        modus: modus,
        bronnen: activeBronnen,
        alleBronnen: bronnen,
        beveiligingen: beveiligingen,
        belasting: belasting,
        verdelaars: verdelaars,
      );
    }

    return AnalyseResultaten(
      huidigScenario: alleScenarios[actiefScenario],
      alleScenarios: alleScenarios,
      berekendeOp: DateTime.now(),
    );
  }

  static List<EnergiBron> _getBronnenVoorModus(
      List<EnergiBron> bronnen, BedrijfsModus modus) {
    switch (modus) {
      case BedrijfsModus.netbedrijf:
        return bronnen
            .where((b) => b.actief && b.type == BronType.trafo)
            .toList();
      case BedrijfsModus.eilandbedrijf:
        return bronnen
            .where((b) => b.actief && b.type == BronType.generator)
            .toList();
      case BedrijfsModus.hybride:
        return bronnen.where((b) => b.actief).toList();
      case BedrijfsModus.noodbedrijf:
        return bronnen
            .where((b) =>
                b.actief &&
                (b.type == BronType.generator || b.type == BronType.batterij))
            .toList();
    }
  }

  static ScenarioResultaat _berekenScenario({
    required BedrijfsModus modus,
    required List<EnergiBron> bronnen,
    required List<EnergiBron> alleBronnen,
    required List<Beveiliging> beveiligingen,
    required Belasting belasting,
    required List<Verdeler> verdelaars,
  }) {
    // Kortsluitstromen
    final ikMax =
        _berekenTotaleIkMax(alleBronnen.where((b) => b.actief).toList());
    final ikMin = _berekenTotaleIkMin(bronnen);

    // Vermogen
    final beschikbaarVermogen =
        bronnen.fold(0.0, (sum, b) => sum + b.nominaalVermogen);
    final gevraagdVermogen = belasting.totaalVermogen;
    final overbelast = gevraagdVermogen > beschikbaarVermogen * 1.1;

    // N-1 analyse
    final nMinEenOk = _berekenNMinEen(bronnen, gevraagdVermogen);

    // Bron resultaten
    final bronResultaten = alleBronnen
        .map((b) => BronResultaat(
              bronId: b.id,
              bronNaam: b.naam,
              nominaleStroom: b.nominaleStroom,
              kortsluitStroom: b.kortsluitStroom,
              actief: bronnen.contains(b),
            ))
        .toList();

    // Beveiliging resultaten
    final beveiligingResultaten = _berekenSelectiviteit(
      beveiligingen: beveiligingen,
      bronnen: bronnen,
      alleBronnen: alleBronnen,
      ikMin: ikMin * 1000,
    );

    // Verdeler resultaten (topologie-analyse)
    final verdelerResultaten = _berekenVerdelerResultaten(
      verdelaars: verdelaars,
      activeBronnen: bronnen,
      belasting: belasting,
    );

    // Fout analyse
    final fouten = _genereerFouten(
      modus: modus,
      bronnen: bronnen,
      beveiligingen: beveiligingen,
      beveiligingResultaten: beveiligingResultaten,
      belasting: belasting,
      verdelerResultaten: verdelerResultaten,
      ikMin: ikMin,
      ikMax: ikMax,
      beschikbaarVermogen: beschikbaarVermogen,
    );

    return ScenarioResultaat(
      modus: modus,
      totaleIkMax: ikMax,
      totaleIkMin: ikMin,
      beschikbaarVermogen: beschikbaarVermogen,
      gevraagdVermogen: gevraagdVermogen,
      overbelast: overbelast,
      nMinEenOk: nMinEenOk,
      bronResultaten: bronResultaten,
      beveiligingResultaten: beveiligingResultaten,
      verdelerResultaten: verdelerResultaten,
      fouten: fouten,
    );
  }

  // -------- Verdeler topologie --------

  static List<VerdelerResultaat> _berekenVerdelerResultaten({
    required List<Verdeler> verdelaars,
    required List<EnergiBron> activeBronnen,
    required Belasting belasting,
  }) {
    if (verdelaars.isEmpty) return [];

    return verdelaars.map((verdeler) {
      // Lokaal: bronnen direct op deze verdeler
      final lokaalVermogen = activeBronnen
          .where((b) => b.verdederId == verdeler.id)
          .fold(0.0, (sum, b) => sum + b.nominaalVermogen);

      // Beschikbaar: lokaal + alle bronnen stroomopwaarts (parent-keten)
      final beschikbaarVermogen = _beschikbaarVermogenVoorVerdeler(
          verdeler.id, verdelaars, activeBronnen);

      // Belasting op deze verdeler
      final veldenHier = belasting.velden
          .where((v) => v.verdederId == verdeler.id)
          .toList();
      final gevraagdVermogen =
          veldenHier.fold(0.0, (sum, v) => sum + v.vermogen);
      final kritischVermogen = veldenHier
          .where((v) => v.prioriteit == BelastingPrioriteit.kritisch)
          .fold(0.0, (sum, v) => sum + v.vermogen);

      final overbelast =
          gevraagdVermogen > 0 && gevraagdVermogen > beschikbaarVermogen * 1.1;

      // N-1 check voor kritische belasting
      final bereikbareBronnen = _bereikbareBronnen(
          verdeler.id, verdelaars, activeBronnen);
      final kritischGedekt =
          _isKritischGedekt(kritischVermogen, bereikbareBronnen);

      return VerdelerResultaat(
        verdederId: verdeler.id,
        verdelerNaam: verdeler.naam,
        isHoofdverdeler: verdeler.isHoofdverdeler,
        lokaalVermogen: lokaalVermogen,
        beschikbaarVermogen: beschikbaarVermogen,
        gevraagdVermogen: gevraagdVermogen,
        kritischVermogen: kritischVermogen,
        overbelast: overbelast,
        kritischGedekt: kritischGedekt,
      );
    }).toList();
  }

  /// Vermogen beschikbaar voor verdeler: eigen bronnen + die van alle ancestors
  static double _beschikbaarVermogenVoorVerdeler(
    String verdederId,
    List<Verdeler> verdelaars,
    List<EnergiBron> activeBronnen,
  ) {
    double vermogen = activeBronnen
        .where((b) => b.verdederId == verdederId)
        .fold(0.0, (sum, b) => sum + b.nominaalVermogen);

    final verdeler = verdelaars.cast<Verdeler?>().firstWhere(
        (v) => v?.id == verdederId,
        orElse: () => null);
    if (verdeler?.parentId != null) {
      vermogen += _beschikbaarVermogenVoorVerdeler(
          verdeler!.parentId!, verdelaars, activeBronnen);
    }
    return vermogen;
  }

  /// Alle bronnen bereikbaar vanuit verdeler (eigen + ancestors)
  static List<EnergiBron> _bereikbareBronnen(
    String verdederId,
    List<Verdeler> verdelaars,
    List<EnergiBron> activeBronnen,
  ) {
    final bronnen = activeBronnen
        .where((b) => b.verdederId == verdederId)
        .toList();

    final verdeler = verdelaars.cast<Verdeler?>().firstWhere(
        (v) => v?.id == verdederId,
        orElse: () => null);
    if (verdeler?.parentId != null) {
      bronnen.addAll(_bereikbareBronnen(
          verdeler!.parentId!, verdelaars, activeBronnen));
    }
    return bronnen;
  }

  /// N-1: zijn kritische lasten gedekt als de grootste bron uitvalt?
  static bool _isKritischGedekt(
      double kritischVermogen, List<EnergiBron> bronnen) {
    if (kritischVermogen == 0) return true;
    if (bronnen.isEmpty) return false;
    if (bronnen.length == 1) return false; // geen redundantie
    final gesorteerd = List<EnergiBron>.from(bronnen)
      ..sort((a, b) => b.nominaalVermogen.compareTo(a.nominaalVermogen));
    final zonderGrootste = gesorteerd.skip(1).toList();
    final restVermogen =
        zonderGrootste.fold(0.0, (sum, b) => sum + b.nominaalVermogen);
    return restVermogen >= kritischVermogen;
  }

  // -------- Kortsluit --------

  static double _berekenTotaleIkMax(List<EnergiBron> activeBronnen) {
    final totaal =
        activeBronnen.fold(0.0, (sum, b) => sum + b.kortsluitStroom);
    return totaal / 1000;
  }

  static double _berekenTotaleIkMin(List<EnergiBron> bronnen) {
    if (bronnen.isEmpty) return 0;
    final minIk =
        bronnen.map((b) => b.kortsluitStroom).reduce((a, b) => a < b ? a : b);
    return minIk / 1000;
  }

  static bool _berekenNMinEen(
      List<EnergiBron> bronnen, double gevraagdVermogen) {
    if (bronnen.length <= 1) return false;
    final sortedByVermogen = List<EnergiBron>.from(bronnen)
      ..sort((a, b) => b.nominaalVermogen.compareTo(a.nominaalVermogen));
    final zonderGrootste = sortedByVermogen.skip(1).toList();
    final beschikbaarZonderGrootste =
        zonderGrootste.fold(0.0, (sum, b) => sum + b.nominaalVermogen);
    return beschikbaarZonderGrootste >= gevraagdVermogen;
  }

  // -------- Selectiviteit --------

  static List<BeveiligingResultaat> _berekenSelectiviteit({
    required List<Beveiliging> beveiligingen,
    required List<EnergiBron> bronnen,
    required List<EnergiBron> alleBronnen,
    required double ikMin,
  }) {
    final resultaten = <BeveiligingResultaat>[];

    for (final bev in beveiligingen) {
      final bron = alleBronnen.cast<EnergiBron?>().firstWhere(
            (b) => b?.id == bev.bronId,
            orElse: () => null,
          );
      final bronActief = bronnen.any((b) => b.id == bev.bronId);
      final bronNaam = bron?.naam ?? 'Onbekend';

      final spreektAanInstantaan = ikMin > bev.iIWerkelijk;
      final spreektAanKsd = ikMin > bev.iSdWerkelijk;
      final spreektAan = spreektAanInstantaan || spreektAanKsd;

      final bvIkMax =
          bron != null && bronActief ? bron.kortsluitStroom : 0.0;
      final overschrijdtIcu = bvIkMax / 1000 > bev.icu;

      SelectiviteitStatus selectiviteit = SelectiviteitStatus.ok;
      if (!spreektAan && bronActief) {
        selectiviteit = SelectiviteitStatus.nietSelectief;
      }

      String opmerking = '';
      if (!bronActief) {
        opmerking = 'Bron niet actief in dit scenario';
      } else if (overschrijdtIcu) {
        opmerking = 'Kortsluitstroom overschrijdt Icu ${bev.icu} kA!';
      } else if (!spreektAanInstantaan && !spreektAanKsd) {
        opmerking = 'Spreekt niet aan bij minimale foutstroom';
      } else if (!spreektAanInstantaan && spreektAanKsd) {
        opmerking =
            'Alleen thermisch/vertraagd actief (geen instantane uitschakeling)';
      } else {
        opmerking = 'Beveiliging OK';
      }

      resultaten.add(BeveiligingResultaat(
        beveiligingId: bev.id,
        beveiligingNaam: bev.naam,
        bronNaam: bronNaam,
        selectiviteit: selectiviteit,
        spreektAanBijMinIk: spreektAan,
        overschrijdtIcu: overschrijdtIcu,
        opmerking: opmerking,
      ));
    }

    return resultaten;
  }

  // -------- Foutanalyse --------

  static List<FoutMelding> _genereerFouten({
    required BedrijfsModus modus,
    required List<EnergiBron> bronnen,
    required List<Beveiliging> beveiligingen,
    required List<BeveiligingResultaat> beveiligingResultaten,
    required Belasting belasting,
    required List<VerdelerResultaat> verdelerResultaten,
    required double ikMin,
    required double ikMax,
    required double beschikbaarVermogen,
  }) {
    final fouten = <FoutMelding>[];
    int idCounter = 0;
    String nextId() => 'f${++idCounter}';

    // --- Globale vermogenbalans ---
    if (bronnen.isEmpty) {
      fouten.add(FoutMelding(
        id: nextId(),
        niveau: FoutNiveau.kritisch,
        titel: 'Geen actieve bronnen',
        beschrijving:
            'Er zijn geen actieve energiebronnen in het huidige scenario (${modus.label}).',
        aanbeveling: 'Activeer minimaal één energiebron.',
      ));
    } else if (beschikbaarVermogen < belasting.totaalVermogen) {
      final tekort = belasting.totaalVermogen - beschikbaarVermogen;
      fouten.add(FoutMelding(
        id: nextId(),
        niveau: FoutNiveau.kritisch,
        titel: 'Onvoldoende vermogen',
        beschrijving:
            'Beschikbaar vermogen (${beschikbaarVermogen.toStringAsFixed(0)} kVA) is onvoldoende voor belasting (${belasting.totaalVermogen.toStringAsFixed(0)} kVA). Tekort: ${tekort.toStringAsFixed(0)} kVA.',
        aanbeveling: 'Voeg extra bronnen toe of verminder de belasting.',
      ));
    } else if (beschikbaarVermogen > belasting.totaalVermogen * 2 &&
        belasting.totaalVermogen > 0) {
      fouten.add(FoutMelding(
        id: nextId(),
        niveau: FoutNiveau.informatief,
        titel: 'Onderbenutting',
        beschrijving:
            'Geïnstalleerd vermogen is meer dan 2× de belasting. Overweeg optimalisatie.',
        aanbeveling: null,
      ));
    }

    // --- Topologie: per verdeler ---
    for (final vr in verdelerResultaten) {
      // Overbelaste verdeler
      if (vr.overbelast) {
        fouten.add(FoutMelding(
          id: nextId(),
          niveau: FoutNiveau.kritisch,
          titel: 'Verdeler overbelast: ${vr.verdelerNaam}',
          beschrijving:
              'Gevraagd vermogen (${vr.gevraagdVermogen.toStringAsFixed(0)} kVA) '
              'overschrijdt beschikbaar vermogen (${vr.beschikbaarVermogen.toStringAsFixed(0)} kVA) '
              'op verdeler "${vr.verdelerNaam}".',
          aanbeveling:
              'Voeg een bron toe aan deze verdeler of verplaats belasting naar een andere verdeler.',
        ));
      }

      // Kritische belasting zonder N-1 dekking
      if (vr.heeftKritischeBelasting && !vr.kritischGedekt) {
        final reden = vr.beschikbaarVermogen == 0
            ? 'Er zijn geen actieve bronnen bereikbaar vanuit deze verdeler.'
            : 'Er is slechts één bron beschikbaar — bij uitval is de kritische belasting (${vr.kritischVermogen.toStringAsFixed(0)} kVA) niet gedekt.';

        fouten.add(FoutMelding(
          id: nextId(),
          niveau: FoutNiveau.kritisch,
          titel: 'Kritische belasting zonder backup: ${vr.verdelerNaam}',
          beschrijving:
              'Verdeler "${vr.verdelerNaam}" heeft ${vr.kritischVermogen.toStringAsFixed(0)} kVA '
              'kritische belasting. $reden',
          aanbeveling:
              'Voeg een reservebron toe (UPS, generator of netvoeding) of sluit kritische '
              'belasting aan op een verdeler met N-1 redundantie.',
        ));
      }

      // Verdeler met belasting maar zonder eigen én zonder upstream bronnen
      if (vr.heeftBelasting &&
          vr.beschikbaarVermogen == 0 &&
          bronnen.isNotEmpty) {
        fouten.add(FoutMelding(
          id: nextId(),
          niveau: FoutNiveau.waarschuwing,
          titel: 'Geen voeding naar verdeler: ${vr.verdelerNaam}',
          beschrijving:
              'Verdeler "${vr.verdelerNaam}" heeft belasting maar ontvangt geen vermogen '
              'van actieve bronnen in dit scenario (${modus.label}).',
          aanbeveling:
              'Koppel een bron aan deze verdeler of aan een bovenliggende verdeler.',
        ));
      }
    }

    // --- Ongekoppelde belastingvelden ---
    final ongekoppeld =
        belasting.velden.where((v) => v.verdederId == null).toList();
    if (ongekoppeld.isNotEmpty && verdelerResultaten.isNotEmpty) {
      final kritischOngekoppeld = ongekoppeld
          .where((v) => v.prioriteit == BelastingPrioriteit.kritisch)
          .length;
      fouten.add(FoutMelding(
        id: nextId(),
        niveau: kritischOngekoppeld > 0
            ? FoutNiveau.waarschuwing
            : FoutNiveau.informatief,
        titel: '${ongekoppeld.length} belastingveld(en) niet gekoppeld',
        beschrijving:
            '${ongekoppeld.length} belastingveld(en) zijn niet aan een verdeler gekoppeld '
            'en worden niet meegenomen in de topologie-analyse.'
            '${kritischOngekoppeld > 0 ? ' Waarvan $kritischOngekoppeld kritisch.' : ''}',
        aanbeveling:
            'Koppel alle belastingvelden aan een verdeler via het tabblad "Belasting".',
      ));
    }

    // --- Generator eilandbedrijf ---
    if (modus == BedrijfsModus.eilandbedrijf) {
      final generatoren =
          bronnen.where((b) => b.type == BronType.generator).toList();
      if (generatoren.isEmpty) {
        fouten.add(FoutMelding(
          id: nextId(),
          niveau: FoutNiveau.kritisch,
          titel: 'Geen generator in eilandbedrijf',
          beschrijving:
              'Eilandbedrijf vereist een actieve generator, maar er zijn er geen.',
          aanbeveling: 'Activeer een generator voor eilandbedrijf.',
        ));
      }
      final genVermogen =
          generatoren.fold(0.0, (s, b) => s + b.nominaalVermogen);
      if (genVermogen > 0 && genVermogen < belasting.totaalVermogen) {
        fouten.add(FoutMelding(
          id: nextId(),
          niveau: FoutNiveau.waarschuwing,
          titel: 'Generator onvoldoende voor volledige belasting',
          beschrijving:
              'Generator vermogen (${genVermogen.toStringAsFixed(0)} kVA) < belasting '
              '(${belasting.totaalVermogen.toStringAsFixed(0)} kVA) → load shedding vereist.',
          aanbeveling:
              'Implementeer load shedding voor niet-kritische verbruikers.',
        ));
      }
    }

    // --- PV/Batterij kortsluitbijdrage ---
    final pvBatterijBronnen = bronnen
        .where((b) => b.type == BronType.pv || b.type == BronType.batterij)
        .toList();
    for (final bron in pvBatterijBronnen) {
      if (bron.kortsluitFactor <= 1.0) {
        fouten.add(FoutMelding(
          id: nextId(),
          niveau: FoutNiveau.waarschuwing,
          titel: 'PV/Batterij lage kortsluitfactor: ${bron.naam}',
          beschrijving:
              '${bron.naam} heeft een kortsluitfactor ≤ 1.0× In.',
          aanbeveling:
              'Controleer of beveiliging kan aanspreken bij lage kortsluitbijdrage.',
        ));
      }
      if (bron.type == BronType.pv) {
        fouten.add(FoutMelding(
          id: nextId(),
          niveau: FoutNiveau.informatief,
          titel: 'PV beperkte kortsluitbijdrage: ${bron.naam}',
          beschrijving:
              'PV-omvormers leveren beperkte foutstroom (${bron.kortsluitFactor.toStringAsFixed(2)}× In).',
          aanbeveling: null,
        ));
      }
    }

    // --- Kortsluitniveaus & beveiliging ---
    if (ikMin > 0 && ikMax > 0) {
      for (final br in beveiligingResultaten) {
        if (br.overschrijdtIcu) {
          fouten.add(FoutMelding(
            id: nextId(),
            niveau: FoutNiveau.kritisch,
            titel: 'Icu overschreden: ${br.beveiligingNaam}',
            beschrijving:
                'Kortsluitstroom overschrijdt de uitschakelcapaciteit (Icu) van ${br.beveiligingNaam}.',
            aanbeveling:
                'Vervang beveiliging door hogere Icu klasse of beperk kortsluitstroom.',
          ));
        }
        if (!br.spreektAanBijMinIk &&
            br.selectiviteit == SelectiviteitStatus.nietSelectief) {
          fouten.add(FoutMelding(
            id: nextId(),
            niveau: FoutNiveau.kritisch,
            titel: 'Beveiliging spreekt niet aan: ${br.beveiligingNaam}',
            beschrijving:
                'Beveiliging ${br.beveiligingNaam} schakelt niet af bij de minimale foutstroom '
                '(${(ikMin * 1000).toStringAsFixed(0)} A).',
            aanbeveling:
                'Verlaag de Ii/Isd instelling of pas netwerk aan voor hogere minimale foutstroom.',
          ));
        }
      }
    }

    for (final bev in beveiligingen) {
      final bron = bronnen.cast<EnergiBron?>().firstWhere(
            (b) => b?.id == bev.bronId,
            orElse: () => null,
          );
      if (bron != null) {
        final ikBron = bron.kortsluitStroom;
        if (ikBron > 0 && ikBron < 2 * bev.inNominaal) {
          fouten.add(FoutMelding(
            id: nextId(),
            niveau: FoutNiveau.waarschuwing,
            titel: 'Lage kortsluitstroom: ${bev.naam}',
            beschrijving:
                'Kortsluitstroom (${ikBron.toStringAsFixed(0)} A) < 2× In '
                '(${(2 * bev.inNominaal).toStringAsFixed(0)} A) bij ${bev.naam}.',
            aanbeveling:
                'Controleer kabellengte en bronimpedantie.',
          ));
        }
      }
    }

    // --- Asynchrone koppeling ---
    final hasGenerator = bronnen.any((b) => b.type == BronType.generator);
    final hasTrafo = bronnen.any((b) => b.type == BronType.trafo);
    if (hasGenerator &&
        hasTrafo &&
        (modus == BedrijfsModus.hybride ||
            modus == BedrijfsModus.netbedrijf)) {
      fouten.add(FoutMelding(
        id: nextId(),
        niveau: FoutNiveau.waarschuwing,
        titel: 'Asynchrone koppelingsrisico',
        beschrijving:
            'Generator en nettrafo zijn beide actief. Asynchrone koppeling kan gevaarlijk zijn.',
        aanbeveling:
            'Zorg voor synchronisatieapparatuur of anti-islanddetectie conform NEN 1010.',
      ));
    }

    // --- Terugvoeding ---
    if (hasTrafo && pvBatterijBronnen.isNotEmpty) {
      fouten.add(FoutMelding(
        id: nextId(),
        niveau: FoutNiveau.informatief,
        titel: 'Terugvoeding mogelijk',
        beschrijving:
            'PV/Batterij aanwezig naast nettrafo. Ongewenste terugvoeding naar het net is mogelijk.',
        aanbeveling:
            'Controleer anti-terugvoedingsbeveiliging en net-aansluiteisen.',
      ));
    }

    // --- Globale N-1 ---
    if (bronnen.length == 1 && belasting.totaalVermogen > 0) {
      fouten.add(FoutMelding(
        id: nextId(),
        niveau: FoutNiveau.waarschuwing,
        titel: 'Geen N-1 redundantie',
        beschrijving:
            'Slechts één actieve bron aanwezig. Uitval betekent volledige stroomonderbreking.',
        aanbeveling:
            'Voeg reservebron toe voor kritische installaties (NEN 3140).',
      ));
    }

    // --- Eilandbedrijf beveiliging ---
    for (final bev in beveiligingen) {
      final bron = bronnen.cast<EnergiBron?>().firstWhere(
            (b) => b?.id == bev.bronId,
            orElse: () => null,
          );
      if (bron != null &&
          bron.type == BronType.generator &&
          modus == BedrijfsModus.eilandbedrijf) {
        final genIk = bron.kortsluitStroom;
        if (genIk < bev.iIWerkelijk) {
          fouten.add(FoutMelding(
            id: nextId(),
            niveau: FoutNiveau.kritisch,
            titel: 'Beveiliging schakelt niet af bij eilandbedrijf: ${bev.naam}',
            beschrijving:
                'Generator kortsluitstroom (${genIk.toStringAsFixed(0)} A) is lager dan '
                'Ii (${bev.iIWerkelijk.toStringAsFixed(0)} A) van ${bev.naam}.',
            aanbeveling:
                'Verlaag Ii instelling of gebruik een beveiliging voor eilandbedrijf.',
          ));
        }
      }
    }

    return fouten;
  }
}
