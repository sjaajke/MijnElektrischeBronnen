import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/energiebron.dart';
import '../models/beveiliging.dart';
import '../models/belasting.dart';
import '../models/verdeler.dart';
import '../models/enums.dart';
import '../models/resultaten.dart';
import '../berekeningen/elektro_berekeningen.dart';

class InstallatieProvider extends ChangeNotifier {
  static const _saveKey = 'installatie_data';
  final _uuid = const Uuid();

  // --- Invoergegevens ---
  double netspanning = 400.0; // V
  double frequentie = 50.0; // Hz
  double cosFi = 0.85;

  List<Verdeler> verdelaars = [];
  List<EnergiBron> bronnen = [];
  List<Beveiliging> beveiligingen = [];
  Belasting belasting = Belasting();
  BedrijfsModus actiefScenario = BedrijfsModus.netbedrijf;

  // --- Resultaten ---
  AnalyseResultaten? resultaten;
  bool isBerekend = false;

  InstallatieProvider() {
    _laadVanOpslag();
  }

  // -------- Verdelaars --------

  void voegVerdelerToe({required String naam, String? parentId}) {
    verdelaars = [
      ...verdelaars,
      Verdeler(id: _uuid.v4(), naam: naam, parentId: parentId),
    ];
    _markeerOnberekend();
  }

  void updateVerdeler(Verdeler verdeler) {
    verdelaars =
        verdelaars.map((v) => v.id == verdeler.id ? verdeler : v).toList();
    _markeerOnberekend();
  }

  void verwijderVerdeler(String id) {
    // Verzamel alle verdeler-IDs in de subboom (inclusief de verdeler zelf)
    final teVerwijderen = _getSubboomIds(id);

    // Verwijder bronnen die aan deze verdelaars hangen (inclusief beveiligingen)
    final bronIds = bronnen
        .where((b) => b.verdederId != null && teVerwijderen.contains(b.verdederId))
        .map((b) => b.id)
        .toSet();
    bronnen = bronnen.where((b) => !bronIds.contains(b.id)).toList();
    beveiligingen =
        beveiligingen.where((b) => !bronIds.contains(b.bronId)).toList();

    // Verwijder belastingvelden die aan deze verdelaars hangen
    belasting = Belasting(
      totaalVermogen: belasting.totaalVermogen,
      cosFi: belasting.cosFi,
      velden: belasting.velden
          .where((v) =>
              v.verdederId == null || !teVerwijderen.contains(v.verdederId))
          .toList(),
    );

    // Verwijder de verdelaars zelf
    verdelaars =
        verdelaars.where((v) => !teVerwijderen.contains(v.id)).toList();

    _markeerOnberekend();
  }

  Set<String> _getSubboomIds(String rootId) {
    final result = <String>{rootId};
    for (final v in verdelaars) {
      if (v.parentId == rootId) {
        result.addAll(_getSubboomIds(v.id));
      }
    }
    return result;
  }

  void _ensureHoofdverdeler() {
    if (verdelaars.isEmpty) {
      verdelaars = [Verdeler(id: _uuid.v4(), naam: 'Hoofdverdeler')];
    }
  }

  // -------- Bronnen --------

  void voegBronToe({BronType type = BronType.trafo, String? verdederId}) {
    _ensureHoofdverdeler();
    final targetVerdederId = verdederId ??
        (verdelaars.firstWhere(
          (v) => v.isHoofdverdeler,
          orElse: () => verdelaars.first,
        ).id);

    final id = _uuid.v4();
    final nummer = bronnen.length + 1;
    bronnen = [
      ...bronnen,
      EnergiBron(
        id: id,
        naam: '${type.label} $nummer',
        type: type,
        nominaleSpanning: netspanning,
        verdederId: targetVerdederId,
      ),
    ];
    // Voeg standaard beveiliging toe
    final bevId = _uuid.v4();
    beveiligingen = [
      ...beveiligingen,
      Beveiliging(
        id: bevId,
        bronId: id,
        naam: 'Q$nummer',
      ),
    ];
    _markeerOnberekend();
  }

  void verwijderBron(String bronId) {
    bronnen = bronnen.where((b) => b.id != bronId).toList();
    beveiligingen =
        beveiligingen.where((b) => b.bronId != bronId).toList();
    _markeerOnberekend();
  }

  void updateBron(EnergiBron bron) {
    bronnen = bronnen.map((b) => b.id == bron.id ? bron : b).toList();
    _markeerOnberekend();
  }

  void toggleBronActief(String bronId) {
    bronnen = bronnen.map((b) {
      if (b.id == bronId) return b.copyWith(actief: !b.actief);
      return b;
    }).toList();
    _markeerOnberekend();
  }

  // -------- Beveiligingen --------

  void updateBeveiliging(Beveiliging bev) {
    beveiligingen =
        beveiligingen.map((b) => b.id == bev.id ? bev : b).toList();
    _markeerOnberekend();
  }

  void voegBeveiligingToe(String bronId) {
    final bron = bronnen.firstWhere((b) => b.id == bronId);
    final id = _uuid.v4();
    final nummer = beveiligingen.where((b) => b.bronId == bronId).length + 1;
    beveiligingen = [
      ...beveiligingen,
      Beveiliging(
        id: id,
        bronId: bronId,
        naam: 'Q-${bron.naam}-$nummer',
        inNominaal: bron.nominaleStroom.roundToDouble(),
      ),
    ];
    _markeerOnberekend();
  }

  void verwijderBeveiliging(String bevId) {
    beveiligingen = beveiligingen.where((b) => b.id != bevId).toList();
    _markeerOnberekend();
  }

  // -------- Belasting --------

  void updateBelasting(Belasting nieuweBelasting) {
    belasting = nieuweBelasting;
    _markeerOnberekend();
  }

  void voegBelastingVeldToe({String? verdederId}) {
    final id = _uuid.v4();
    final nummer = belasting.velden.length + 1;
    belasting = Belasting(
      totaalVermogen: belasting.totaalVermogen,
      cosFi: belasting.cosFi,
      velden: [
        ...belasting.velden,
        BelastingVeld(
          id: id,
          naam: 'Veld $nummer',
          vermogen: 10.0,
          verdederId: verdederId,
        ),
      ],
    );
    _markeerOnberekend();
  }

  void verwijderBelastingVeld(String veldId) {
    belasting = Belasting(
      totaalVermogen: belasting.totaalVermogen,
      cosFi: belasting.cosFi,
      velden: belasting.velden.where((v) => v.id != veldId).toList(),
    );
    _markeerOnberekend();
  }

  void updateBelastingVeld(BelastingVeld veld) {
    belasting = Belasting(
      totaalVermogen: belasting.totaalVermogen,
      cosFi: belasting.cosFi,
      velden: belasting.velden.map((v) => v.id == veld.id ? veld : v).toList(),
    );
    _markeerOnberekend();
  }

  // -------- Scenario --------

  void setScenario(BedrijfsModus modus) {
    actiefScenario = modus;
    if (isBerekend) {
      bereken();
    } else {
      notifyListeners();
    }
  }

  // -------- Algemeen --------

  void updateAlgemeen({
    double? netspanning,
    double? frequentie,
    double? cosFi,
  }) {
    if (netspanning != null) this.netspanning = netspanning;
    if (frequentie != null) this.frequentie = frequentie;
    if (cosFi != null) this.cosFi = cosFi;
    _markeerOnberekend();
  }

  // -------- Berekenen --------

  void bereken() {
    resultaten = ElektroBerekeningen.bereken(
      bronnen: bronnen,
      beveiligingen: beveiligingen,
      belasting: belasting,
      actiefScenario: actiefScenario,
      verdelaars: verdelaars,
    );
    isBerekend = true;
    _slaOp();
    notifyListeners();
  }

  void _markeerOnberekend() {
    isBerekend = false;
    notifyListeners();
  }

  // -------- Persistentie --------

  Future<void> _slaOp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'netspanning': netspanning,
        'frequentie': frequentie,
        'cosFi': cosFi,
        'actiefScenario': actiefScenario.index,
        'verdelaars': verdelaars.map((v) => v.toJson()).toList(),
        'bronnen': bronnen.map((b) => b.toJson()).toList(),
        'beveiligingen': beveiligingen.map((b) => b.toJson()).toList(),
        'belasting': belasting.toJson(),
      });
      await prefs.setString(_saveKey, data);
    } catch (_) {}
  }

  Future<void> _laadVanOpslag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_saveKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      netspanning = (data['netspanning'] as num?)?.toDouble() ?? 400;
      frequentie = (data['frequentie'] as num?)?.toDouble() ?? 50;
      cosFi = (data['cosFi'] as num?)?.toDouble() ?? 0.85;
      actiefScenario =
          BedrijfsModus.values[data['actiefScenario'] as int? ?? 0];
      verdelaars = (data['verdelaars'] as List<dynamic>?)
              ?.map((v) => Verdeler.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [];
      bronnen = (data['bronnen'] as List<dynamic>?)
              ?.map((b) => EnergiBron.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [];
      beveiligingen = (data['beveiligingen'] as List<dynamic>?)
              ?.map((b) => Beveiliging.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [];
      belasting = data['belasting'] != null
          ? Belasting.fromJson(data['belasting'] as Map<String, dynamic>)
          : Belasting();

      // Migratie: als er bronnen zijn zonder verdederId (oudere data),
      // maak dan een standaard hoofdverdeler aan en koppel ze daaraan.
      _migreerBronnenZonderVerdeler();

      notifyListeners();
    } catch (_) {}
  }

  void _migreerBronnenZonderVerdeler() {
    final heeftOngekoppeldeBronnen = bronnen.any((b) => b.verdederId == null);
    if (!heeftOngekoppeldeBronnen) return;

    _ensureHoofdverdeler();
    final defaultId = verdelaars.first.id;
    bronnen = bronnen.map((b) {
      if (b.verdederId == null) return b.copyWith(verdederId: defaultId);
      return b;
    }).toList();
  }

  void reset() {
    bronnen = [];
    beveiligingen = [];
    belasting = Belasting();
    verdelaars = [];
    resultaten = null;
    isBerekend = false;
    _slaOp();
    notifyListeners();
  }

  // -------- Helpers voor UI --------

  List<Beveiliging> getBeveiligingVoorBron(String bronId) =>
      beveiligingen.where((b) => b.bronId == bronId).toList();

  EnergiBron? getBronById(String bronId) =>
      bronnen.cast<EnergiBron?>().firstWhere((b) => b?.id == bronId,
          orElse: () => null);

  List<EnergiBron> getBronnenVanVerdeler(String verdederId) =>
      bronnen.where((b) => b.verdederId == verdederId).toList();

  List<BelastingVeld> getBelastingenVanVerdeler(String verdederId) =>
      belasting.velden.where((v) => v.verdederId == verdederId).toList();

  List<Verdeler> getKinderenVanVerdeler(String? parentId) =>
      verdelaars.where((v) => v.parentId == parentId).toList();

  Verdeler? getVerdelerById(String id) =>
      verdelaars.cast<Verdeler?>().firstWhere((v) => v?.id == id,
          orElse: () => null);
}
