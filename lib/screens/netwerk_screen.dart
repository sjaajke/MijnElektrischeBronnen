import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/verdeler.dart';
import '../models/energiebron.dart';
import '../models/belasting.dart';
import '../models/enums.dart';
import '../widgets/periode_section.dart';

class NetwerkScreen extends StatelessWidget {
  const NetwerkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallatieProvider>();
    final roots = provider.getKinderenVanVerdeler(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Netwerk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Netwerk opslaan',
            onPressed: () => _slaNetwerkOp(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Hoofdverdeler toevoegen',
            onPressed: () =>
                _toonVerdelerDialoog(context, provider, parentId: null),
          ),
        ],
      ),
      body: roots.isEmpty
          ? _LeegScherm(
              onAdd: () =>
                  _toonVerdelerDialoog(context, provider, parentId: null))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _ScenarioKnoppen(provider: provider),
                const SizedBox(height: 8),
                _BelastingOverzicht(provider: provider),
                const SizedBox(height: 8),
                ...roots.map((v) =>
                    _VerdelerNode(verdeler: v, provider: provider, depth: 0)),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  static Future<void> _slaNetwerkOp(
      BuildContext context, InstallatieProvider provider) async {
    final controller =
        TextEditingController(text: provider.huidigNetwerkNaam ?? '');
    final naam = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Netwerk opslaan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Naam',
            hintText: 'bijv. Kantoor begane grond',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Opslaan')),
        ],
      ),
    );
    if (naam == null || naam.isEmpty) return;
    await provider.slaNetwerkOp(naam, bestaandId: provider.huidigNetwerkId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$naam" opgeslagen')),
      );
    }
  }

  static void _toonVerdelerDialoog(
    BuildContext context,
    InstallatieProvider provider, {
    required String? parentId,
    Verdeler? bewerken,
  }) {
    final ctrl = TextEditingController(text: bewerken?.naam ?? '');
    final isBewerken = bewerken != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isBewerken
            ? 'Verdeler bewerken'
            : parentId == null
                ? 'Hoofdverdeler toevoegen'
                : 'Onderverdeler toevoegen'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Naam',
            hintText:
                parentId == null ? 'bijv. Hoofdverdeler' : 'bijv. OV-Kantine',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              _opslaanVerdeler(context, provider, ctrl.text, parentId, bewerken),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () =>
                _opslaanVerdeler(context, provider, ctrl.text, parentId, bewerken),
            child: Text(isBewerken ? 'Opslaan' : 'Toevoegen'),
          ),
        ],
      ),
    );
  }

  static void _opslaanVerdeler(
    BuildContext context,
    InstallatieProvider provider,
    String naam,
    String? parentId,
    Verdeler? bewerken,
  ) {
    final trimmed = naam.trim();
    if (trimmed.isEmpty) return;
    if (bewerken != null) {
      provider.updateVerdeler(bewerken.copyWith(naam: trimmed));
    } else {
      provider.voegVerdelerToe(naam: trimmed, parentId: parentId);
    }
    Navigator.pop(context);
  }
}

// ─── Scenario knoppen ────────────────────────────────────────────────────────

class _ScenarioKnoppen extends StatelessWidget {
  final InstallatieProvider provider;
  const _ScenarioKnoppen({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bedrijfsmodus',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: BedrijfsModus.values.map((modus) {
                final actief = provider.actiefScenario == modus;
                return ChoiceChip(
                  label: Text(_kortLabel(modus),
                      style: const TextStyle(fontSize: 12)),
                  selected: actief,
                  onSelected: (_) => provider.setScenario(modus),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _kortLabel(BedrijfsModus m) {
    switch (m) {
      case BedrijfsModus.netbedrijf:
        return 'Netbedrijf';
      case BedrijfsModus.eilandbedrijf:
        return 'Eiland (Gen)';
      case BedrijfsModus.eilandGeneratorBatterij:
        return 'Eiland (Gen+Bat)';
      case BedrijfsModus.hybride:
        return 'Hybride';
      case BedrijfsModus.noodbedrijf:
        return 'Noodbedrijf';
    }
  }
}

// ─── Belasting overzicht (visualisatie) ──────────────────────────────────────

class _BelastingOverzicht extends StatelessWidget {
  final InstallatieProvider provider;
  const _BelastingOverzicht({required this.provider});

  static List<EnergiBron> _bronnenVoorScenario(
      List<EnergiBron> bronnen, BedrijfsModus modus) {
    switch (modus) {
      case BedrijfsModus.netbedrijf:
        return bronnen.where((b) => b.actief && b.type == BronType.trafo).toList();
      case BedrijfsModus.eilandbedrijf:
        return bronnen.where((b) => b.actief && b.type == BronType.generator).toList();
      case BedrijfsModus.eilandGeneratorBatterij:
        return bronnen
            .where((b) =>
                b.actief &&
                (b.type == BronType.generator || b.type == BronType.batterij))
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

  @override
  Widget build(BuildContext context) {
    final velden = provider.belasting.velden;
    if (velden.isEmpty) return const SizedBox.shrink();

    final beschikbaar = _bronnenVoorScenario(
            provider.bronnen, provider.actiefScenario)
        .fold(0.0, (s, b) => s + b.nominaalVermogen);

    // Verzamel alle gebruikte presets
    final gebruiktePresets = velden
        .expand((v) => v.perioden.map((p) => p.preset))
        .toSet()
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    // Bereken totaal kritisch + totaal effectief (zonder perioden = 100%)
    final totaalKritisch = velden
        .where((v) => v.prioriteit == BelastingPrioriteit.kritisch)
        .fold(0.0, (s, v) => s + v.effectiefVermogen);
    final totaalEffectief =
        velden.fold(0.0, (s, v) => s + v.effectiefVermogen);

    final maxWaarde =
        beschikbaar > 0 ? beschikbaar : (totaalEffectief > 0 ? totaalEffectief : 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Belasting overzicht',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (beschikbaar > 0)
                  Text(
                    'Beschikbaar: ${beschikbaar.toStringAsFixed(0)} kVA',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Totaalregel (max effectief)
            _PerioderBalk(
              label: 'Totaal (max)',
              kritisch: totaalKritisch,
              normaal: velden
                  .where((v) => v.prioriteit == BelastingPrioriteit.normaal)
                  .fold(0.0, (s, v) => s + v.effectiefVermogen),
              nietKritisch: velden
                  .where(
                      (v) => v.prioriteit == BelastingPrioriteit.nietKritisch)
                  .fold(0.0, (s, v) => s + v.effectiefVermogen),
              maxWaarde: maxWaarde,
              beschikbaar: beschikbaar,
              vetgedrukt: true,
            ),

            if (gebruiktePresets.isNotEmpty) ...[
              const Divider(height: 16),
              ...gebruiktePresets.map((preset) {
                double kritisch = 0, normaal = 0, nietKritisch = 0;
                for (final v in velden) {
                  final periode = v.perioden
                      .where((p) => p.preset == preset)
                      .firstOrNull;
                  final factor = periode?.gelijktijdigheid ?? 1.0;
                  final eff = v.vermogen * factor;
                  switch (v.prioriteit) {
                    case BelastingPrioriteit.kritisch:
                      kritisch += eff;
                    case BelastingPrioriteit.normaal:
                      normaal += eff;
                    case BelastingPrioriteit.nietKritisch:
                      nietKritisch += eff;
                  }
                }
                return _PerioderBalk(
                  label: preset.label.split(' ').first,
                  kritisch: kritisch,
                  normaal: normaal,
                  nietKritisch: nietKritisch,
                  maxWaarde: maxWaarde,
                  beschikbaar: beschikbaar,
                );
              }),
            ],

            const SizedBox(height: 8),
            // Legenda
            Row(
              children: [
                _LegendaItem(kleur: Colors.red.shade600, label: 'Kritisch'),
                const SizedBox(width: 12),
                _LegendaItem(kleur: Colors.blue.shade400, label: 'Normaal'),
                const SizedBox(width: 12),
                _LegendaItem(kleur: Colors.grey.shade400, label: 'Niet-kritisch'),
                if (beschikbaar > 0) ...[
                  const SizedBox(width: 12),
                  _LegendaItem(
                      kleur: Colors.green.shade300,
                      label: 'Beschikbaar',
                      streepje: true),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PerioderBalk extends StatelessWidget {
  final String label;
  final double kritisch;
  final double normaal;
  final double nietKritisch;
  final double maxWaarde;
  final double beschikbaar;
  final bool vetgedrukt;

  const _PerioderBalk({
    required this.label,
    required this.kritisch,
    required this.normaal,
    required this.nietKritisch,
    required this.maxWaarde,
    required this.beschikbaar,
    this.vetgedrukt = false,
  });

  @override
  Widget build(BuildContext context) {
    final totaal = kritisch + normaal + nietKritisch;
    final overbelast = beschikbaar > 0 && totaal > beschikbaar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    vetgedrukt ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gestapelde balk
                LayoutBuilder(builder: (ctx, constraints) {
                  final breedte = constraints.maxWidth;
                  final kBreedte =
                      (kritisch / maxWaarde * breedte).clamp(0.0, breedte);
                  final nBreedte =
                      (normaal / maxWaarde * breedte).clamp(0.0, breedte - kBreedte);
                  final nkBreedte = (nietKritisch / maxWaarde * breedte)
                      .clamp(0.0, breedte - kBreedte - nBreedte);
                  final beschikbaarX = beschikbaar > 0
                      ? (beschikbaar / maxWaarde * breedte).clamp(0.0, breedte)
                      : 0.0;

                  return Stack(
                    children: [
                      // Achtergrond
                      Container(
                        height: 14,
                        width: breedte,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // Niet-kritisch
                      if (nkBreedte > 0)
                        Positioned(
                          left: kBreedte + nBreedte,
                          child: Container(
                            height: 14,
                            width: nkBreedte,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      // Normaal
                      if (nBreedte > 0)
                        Positioned(
                          left: kBreedte,
                          child: Container(
                            height: 14,
                            width: nBreedte,
                            color: Colors.blue.shade400,
                          ),
                        ),
                      // Kritisch
                      if (kBreedte > 0)
                        Container(
                          height: 14,
                          width: kBreedte,
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              bottomLeft: Radius.circular(3),
                            ),
                          ),
                        ),
                      // Beschikbaar streepje
                      if (beschikbaarX > 0)
                        Positioned(
                          left: beschikbaarX - 1.5,
                          child: Container(
                            height: 14,
                            width: 2.5,
                            color: Colors.green.shade600,
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            child: Text(
              '${totaal.toStringAsFixed(1)} kVA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: vetgedrukt ? FontWeight.bold : FontWeight.normal,
                color: overbelast ? Colors.red : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color kleur;
  final String label;
  final bool streepje;
  const _LegendaItem(
      {required this.kleur, required this.label, this.streepje = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: streepje ? 3 : 12,
          height: 12,
          color: kleur,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

// ─── Leeg scherm ─────────────────────────────────────────────────────────────

class _LeegScherm extends StatelessWidget {
  final VoidCallback onAdd;
  const _LeegScherm({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Geen verdelaars',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Voeg een hoofdverdeler toe om de netwerktopologie op te bouwen.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Hoofdverdeler toevoegen'),
          ),
        ],
      ),
    );
  }
}

// ─── Verdeler node ────────────────────────────────────────────────────────────

class _VerdelerNode extends StatelessWidget {
  final Verdeler verdeler;
  final InstallatieProvider provider;
  final int depth;

  const _VerdelerNode({
    required this.verdeler,
    required this.provider,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final bronnen = provider.getBronnenVanVerdeler(verdeler.id);
    final belastingen = provider.getBelastingenVanVerdeler(verdeler.id);
    final kinderen = provider.getKinderenVanVerdeler(verdeler.id);
    final colorScheme = Theme.of(context).colorScheme;
    final isHV = verdeler.isHoofdverdeler;

    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: depth == 0,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor:
                isHV ? colorScheme.primary : colorScheme.secondary,
            child: Text(
              isHV ? 'HV' : 'OV',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isHV ? colorScheme.onPrimary : colorScheme.onSecondary,
              ),
            ),
          ),
          title: Text(verdeler.naam,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            _subtitel(bronnen.length, belastingen.length, kinderen.length),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Onderverdeler toevoegen',
                onPressed: () => NetwerkScreen._toonVerdelerDialoog(
                  context, provider,
                  parentId: verdeler.id,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Naam bewerken',
                onPressed: () => NetwerkScreen._toonVerdelerDialoog(
                  context, provider,
                  parentId: verdeler.parentId,
                  bewerken: verdeler,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Verwijder verdeler',
                onPressed: () => _bevestigVerwijder(context),
              ),
            ],
          ),
          children: [
            // --- Bronnen ---
            _SectieHeader(
              icon: Icons.bolt,
              label: 'Energiebronnen',
              count: bronnen.length,
              onAdd: () => _toonBronDialoog(context, provider,
                  verdederId: verdeler.id),
            ),
            ...bronnen.map((b) => _BronTegel(bron: b, provider: provider)),

            // --- Belasting ---
            _SectieHeader(
              icon: Icons.electrical_services,
              label: 'Belasting',
              count: belastingen.length,
              onAdd: () => _toonBelastingDialoog(context, provider,
                  verdederId: verdeler.id),
            ),
            ...belastingen
                .map((v) => _BelastingTegel(veld: v, provider: provider)),

            if (bronnen.isEmpty && belastingen.isEmpty && kinderen.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Gebruik de + knoppen hierboven om bronnen en belastingen toe te voegen.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic),
                ),
              ),

            // --- Kinderen (recursief) ---
            if (kinderen.isNotEmpty) ...[
              _SectieHeader(
                icon: Icons.account_tree,
                label: 'Onderverdelers',
                count: kinderen.length,
              ),
              ...kinderen.map((k) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _VerdelerNode(
                        verdeler: k, provider: provider, depth: 0),
                  )),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String _subtitel(int bronnen, int belastingen, int kinderen) {
    final delen = <String>[];
    if (bronnen > 0) delen.add('$bronnen ${bronnen == 1 ? "bron" : "bronnen"}');
    if (belastingen > 0) {
      delen.add('$belastingen belasting${belastingen == 1 ? "" : "en"}');
    }
    if (kinderen > 0) {
      delen.add('$kinderen onderverdeler${kinderen == 1 ? "" : "s"}');
    }
    return delen.isEmpty ? 'Leeg' : delen.join(' • ');
  }

  void _bevestigVerwijder(BuildContext context) {
    final kinderen = provider.getKinderenVanVerdeler(verdeler.id);
    final totaalBronnen = _telBronnenInSubboom(verdeler.id);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('"${verdeler.naam}" verwijderen?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dit verwijdert ook:'),
            const SizedBox(height: 8),
            if (totaalBronnen > 0)
              Text(
                  '• $totaalBronnen energiebron${totaalBronnen == 1 ? "" : "nen"} (en beveiligingen)'),
            if (kinderen.isNotEmpty)
              Text(
                  '• ${kinderen.length} onderverdeler${kinderen.length == 1 ? "" : "s"} (en hun inhoud)'),
            if (totaalBronnen == 0 && kinderen.isEmpty)
              const Text('• Niets (verdeler is leeg)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              provider.verwijderVerdeler(verdeler.id);
              Navigator.pop(context);
            },
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  int _telBronnenInSubboom(String verdederId) {
    final directe = provider.getBronnenVanVerdeler(verdederId).length;
    final kinderen = provider.getKinderenVanVerdeler(verdederId);
    return directe +
        kinderen.fold(0, (sum, k) => sum + _telBronnenInSubboom(k.id));
  }

  static void _toonBronDialoog(
    BuildContext context,
    InstallatieProvider provider, {
    EnergiBron? bewerken,
    String? verdederId,
  }) {
    showDialog(
      context: context,
      builder: (_) => _BronDialoog(
        provider: provider,
        bewerken: bewerken,
        verdederId: verdederId,
      ),
    );
  }

  static void _toonBelastingDialoog(
    BuildContext context,
    InstallatieProvider provider, {
    BelastingVeld? bewerken,
    String? verdederId,
  }) {
    showDialog(
      context: context,
      builder: (_) => _BelastingDialoog(
        provider: provider,
        bewerken: bewerken,
        verdederId: verdederId,
      ),
    );
  }
}

// ─── Sectie header ────────────────────────────────────────────────────────────

class _SectieHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback? onAdd;

  const _SectieHeader({
    required this.icon,
    required this.label,
    required this.count,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 2),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 14,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 2),
                    Text('Toevoegen',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Bron tegel ───────────────────────────────────────────────────────────────

class _BronTegel extends StatelessWidget {
  final EnergiBron bron;
  final InstallatieProvider provider;
  const _BronTegel({required this.bron, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(_bronIcon(bron.type),
          size: 20,
          color: bron.actief
              ? Colors.green
              : Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(bron.naam,
          style: TextStyle(
            fontSize: 14,
            color: bron.actief
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
          )),
      subtitle: Text(
        '${bron.type.label} • ${bron.nominaalVermogen.toStringAsFixed(0)} kVA'
        ' • Ik = ${bron.kortsluitStroomKA.toStringAsFixed(2)} kA',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!bron.actief)
            const Chip(
              label: Text('Uit', style: TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Bewerken',
            onPressed: () => _toonBewerken(context),
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move_outlined, size: 18),
            tooltip: 'Verplaats naar andere verdeler',
            onPressed: () => _toonVerplaatsen(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Verwijderen',
            onPressed: () => provider.verwijderBron(bron.id),
          ),
        ],
      ),
    );
  }

  void _toonBewerken(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _BronDialoog(provider: provider, bewerken: bron),
    );
  }

  void _toonVerplaatsen(BuildContext context) {
    String? geselecteerdeId = bron.verdederId;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('"${bron.naam}" verplaatsen'),
          content: DropdownButtonFormField<String>(
            initialValue: geselecteerdeId,
            decoration: const InputDecoration(
              labelText: 'Naar verdeler',
              border: OutlineInputBorder(),
            ),
            items: provider.verdelaars
                .map((v) => DropdownMenuItem(
                      value: v.id,
                      child: Text(
                          v.naam + (v.isHoofdverdeler ? ' (HV)' : ' (OV)')),
                    ))
                .toList(),
            onChanged: (id) => setState(() => geselecteerdeId = id),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: geselecteerdeId == null ||
                      geselecteerdeId == bron.verdederId
                  ? null
                  : () {
                      provider.updateBron(
                          bron.copyWith(verdederId: geselecteerdeId));
                      Navigator.pop(ctx);
                    },
              child: const Text('Verplaatsen'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _bronIcon(BronType type) {
    switch (type) {
      case BronType.trafo:
        return Icons.transform;
      case BronType.generator:
        return Icons.settings_input_antenna;
      case BronType.pv:
        return Icons.solar_power;
      case BronType.batterij:
        return Icons.battery_charging_full;
    }
  }
}

// ─── Belasting tegel ──────────────────────────────────────────────────────────

class _BelastingTegel extends StatelessWidget {
  final BelastingVeld veld;
  final InstallatieProvider provider;
  const _BelastingTegel({required this.veld, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 4,
        height: 32,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _prioriteitKleur(veld.prioriteit),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(veld.naam, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        '${veld.effectiefVermogen.toStringAsFixed(1)} kVA'
        '${veld.perioden.isNotEmpty ? " (${(veld.maxGelijktijdigheid * 100).toStringAsFixed(0)}%)" : ""}'
        ' • ${_prioriteitLabel(veld.prioriteit)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Bewerken',
            onPressed: () => _toonBewerken(context),
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move_outlined, size: 18),
            tooltip: 'Verplaats naar andere verdeler',
            onPressed: () => _toonVerplaatsen(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Verwijderen',
            onPressed: () => provider.verwijderBelastingVeld(veld.id),
          ),
        ],
      ),
    );
  }

  void _toonBewerken(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _BelastingDialoog(provider: provider, bewerken: veld),
    );
  }

  void _toonVerplaatsen(BuildContext context) {
    String? geselecteerdeId = veld.verdederId;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('"${veld.naam}" verplaatsen'),
          content: DropdownButtonFormField<String>(
            initialValue: geselecteerdeId,
            decoration: const InputDecoration(
              labelText: 'Naar verdeler',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('— Niet gekoppeld —'),
              ),
              ...provider.verdelaars.map((v) => DropdownMenuItem(
                    value: v.id,
                    child: Text(
                        v.naam + (v.isHoofdverdeler ? ' (HV)' : ' (OV)')),
                  )),
            ],
            onChanged: (id) => setState(() => geselecteerdeId = id),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: geselecteerdeId == veld.verdederId
                  ? null
                  : () {
                      provider.updateBelastingVeld(
                        geselecteerdeId == null || geselecteerdeId!.isEmpty
                            ? veld.copyWith(clearVerdeler: true)
                            : veld.copyWith(verdederId: geselecteerdeId),
                      );
                      Navigator.pop(ctx);
                    },
              child: const Text('Verplaatsen'),
            ),
          ],
        ),
      ),
    );
  }

  Color _prioriteitKleur(BelastingPrioriteit p) {
    switch (p) {
      case BelastingPrioriteit.kritisch:
        return Colors.red;
      case BelastingPrioriteit.normaal:
        return Colors.blue;
      case BelastingPrioriteit.nietKritisch:
        return Colors.grey;
    }
  }

  String _prioriteitLabel(BelastingPrioriteit p) {
    switch (p) {
      case BelastingPrioriteit.kritisch:
        return 'Kritisch';
      case BelastingPrioriteit.normaal:
        return 'Normaal';
      case BelastingPrioriteit.nietKritisch:
        return 'Niet-kritisch';
    }
  }
}

// ─── Bron dialoog (toevoegen / bewerken) ─────────────────────────────────────

class _BronDialoog extends StatefulWidget {
  final InstallatieProvider provider;
  final EnergiBron? bewerken;
  final String? verdederId;

  const _BronDialoog({
    required this.provider,
    this.bewerken,
    this.verdederId,
  });

  @override
  State<_BronDialoog> createState() => _BronDialoogState();
}

class _BronDialoogState extends State<_BronDialoog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _naam;
  late TextEditingController _vermogen;
  late TextEditingController _spanning;
  late TextEditingController _param; // uk% / X''d% / kortsluitFactor
  late TextEditingController _capaciteit;
  late TextEditingController _pvWinter;
  late double _seizoensfactorWinter;
  late BronType _type;
  late bool _actief;

  @override
  void initState() {
    super.initState();
    final b = widget.bewerken;
    _type = b?.type ?? BronType.trafo;
    _actief = b?.actief ?? true;
    _naam = TextEditingController(text: b?.naam ?? '');
    _vermogen = TextEditingController(
        text: (b?.nominaalVermogen ?? 100.0).toStringAsFixed(0));
    _spanning = TextEditingController(
        text: (b?.nominaleSpanning ?? 400.0).toStringAsFixed(0));
    _param = TextEditingController(text: _paramWaarde(b));
    _capaciteit = TextEditingController(
        text: (b?.capaciteitKwh ?? 0) > 0
            ? (b!.capaciteitKwh).toStringAsFixed(0)
            : '');
    _pvWinter = TextEditingController(
        text: ((b?.pvWinterFactor ?? 0.25) * 100).toStringAsFixed(0));
    _seizoensfactorWinter = b?.seizoensfactorWinter ?? 0.85;
  }

  String _paramWaarde(EnergiBron? b) {
    if (b == null) return _defaultParam(BronType.trafo);
    switch (b.type) {
      case BronType.trafo:
        return b.kortsluitspanning.toStringAsFixed(1);
      case BronType.generator:
        return b.subtransientReactantie.toStringAsFixed(1);
      case BronType.pv:
      case BronType.batterij:
        return b.kortsluitFactor.toStringAsFixed(2);
    }
  }

  String _defaultParam(BronType type) {
    switch (type) {
      case BronType.trafo:
        return '4.0';
      case BronType.generator:
        return '15.0';
      case BronType.pv:
      case BronType.batterij:
        return '1.2';
    }
  }

  String _paramLabel(BronType type) {
    switch (type) {
      case BronType.trafo:
        return 'Kortsluitspanning uk (%)';
      case BronType.generator:
        return 'Subtrans. reactantie X\'\'d (%)';
      case BronType.pv:
      case BronType.batterij:
        return 'Kortsluitfactor (× In)';
    }
  }

  @override
  void dispose() {
    _naam.dispose();
    _vermogen.dispose();
    _spanning.dispose();
    _param.dispose();
    _capaciteit.dispose();
    _pvWinter.dispose();
    super.dispose();
  }

  void _opslaan() {
    if (!_formKey.currentState!.validate()) return;
    final param = double.tryParse(_param.text) ?? 0;
    final capaciteit = double.tryParse(_capaciteit.text) ?? 0.0;
    final pvWinter = (double.tryParse(_pvWinter.text) ?? 25.0) / 100.0;

    EnergiBron bron;
    if (widget.bewerken != null) {
      bron = widget.bewerken!.copyWith(
        naam: _naam.text.trim(),
        actief: _actief,
        type: _type,
        nominaalVermogen: double.tryParse(_vermogen.text) ?? 100,
        nominaleSpanning: double.tryParse(_spanning.text) ?? 400,
        kortsluitspanning: _type == BronType.trafo ? param : null,
        subtransientReactantie: _type == BronType.generator ? param : null,
        kortsluitFactor:
            (_type == BronType.pv || _type == BronType.batterij) ? param : null,
        capaciteitKwh: _type == BronType.batterij ? capaciteit : null,
        seizoensfactorWinter:
            _type == BronType.batterij ? _seizoensfactorWinter : null,
        pvWinterFactor: _type == BronType.pv ? pvWinter : null,
      );
      widget.provider.updateBron(bron);
    } else {
      widget.provider.voegBronToe(type: _type, verdederId: widget.verdederId);
      final nieuw = widget.provider.bronnen.last;
      widget.provider.updateBron(nieuw.copyWith(
        naam: _naam.text.trim().isNotEmpty ? _naam.text.trim() : null,
        actief: _actief,
        nominaalVermogen: double.tryParse(_vermogen.text) ?? 100,
        nominaleSpanning: double.tryParse(_spanning.text) ?? 400,
        kortsluitspanning: _type == BronType.trafo ? param : null,
        subtransientReactantie: _type == BronType.generator ? param : null,
        kortsluitFactor:
            (_type == BronType.pv || _type == BronType.batterij) ? param : null,
        capaciteitKwh: _type == BronType.batterij ? capaciteit : null,
        seizoensfactorWinter:
            _type == BronType.batterij ? _seizoensfactorWinter : null,
        pvWinterFactor: _type == BronType.pv ? pvWinter : null,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isBewerken = widget.bewerken != null;
    return AlertDialog(
      title: Text(isBewerken ? 'Bron bewerken' : 'Bron toevoegen'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Naam
              TextFormField(
                controller: _naam,
                decoration: const InputDecoration(
                  labelText: 'Naam',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vereist' : null,
              ),
              const SizedBox(height: 12),
              // Type
              DropdownButtonFormField<BronType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: BronType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (t) {
                  if (t != null) {
                    setState(() {
                      _type = t;
                      _param.text = _defaultParam(t);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              // Actief
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Actief'),
                value: _actief,
                onChanged: (v) => setState(() => _actief = v),
              ),
              const SizedBox(height: 4),
              // Vermogen + spanning
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vermogen,
                      decoration: const InputDecoration(
                        labelText: 'Vermogen (kVA)',
                        border: OutlineInputBorder(),
                        suffixText: 'kVA',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) =>
                          double.tryParse(v ?? '') == null ? 'Getal' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _spanning,
                      decoration: const InputDecoration(
                        labelText: 'Spanning (V)',
                        border: OutlineInputBorder(),
                        suffixText: 'V',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) =>
                          double.tryParse(v ?? '') == null ? 'Getal' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Type-specifieke parameter
              TextFormField(
                controller: _param,
                decoration: InputDecoration(
                  labelText: _paramLabel(_type),
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Getal' : null,
              ),
              // Batterij: capaciteit + seizoensfactor
              if (_type == BronType.batterij) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capaciteit,
                  decoration: const InputDecoration(
                    labelText: 'Capaciteit (kWh)',
                    border: OutlineInputBorder(),
                    suffixText: 'kWh',
                    hintText: 'leeg = niet opgegeven',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (_, ss) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Winterfactor capaciteit',
                              style: TextStyle(fontSize: 13)),
                          Text(
                            '${(_seizoensfactorWinter * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: _seizoensfactorWinter,
                        min: 0.5,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (v) =>
                            ss(() => _seizoensfactorWinter = v),
                      ),
                      Text(
                        'Lithium: typisch 80–90% bij lage temp.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
              // PV: winterfactor productie
              if (_type == BronType.pv) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pvWinter,
                  decoration: const InputDecoration(
                    labelText: 'Winterproductie (% van zomer)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                    hintText: 'bijv. 25',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                ),
                const SizedBox(height: 4),
                Text(
                  'In NL produceert PV in winter ~20–30% van de zomerproductie.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        FilledButton(
          onPressed: _opslaan,
          child: Text(isBewerken ? 'Opslaan' : 'Toevoegen'),
        ),
      ],
    );
  }
}

// ─── Belasting dialoog (toevoegen / bewerken) ─────────────────────────────────

class _BelastingDialoog extends StatefulWidget {
  final InstallatieProvider provider;
  final BelastingVeld? bewerken;
  final String? verdederId;

  const _BelastingDialoog({
    required this.provider,
    this.bewerken,
    this.verdederId,
  });

  @override
  State<_BelastingDialoog> createState() => _BelastingDialoogState();
}

class _BelastingDialoogState extends State<_BelastingDialoog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _naam;
  late TextEditingController _vermogen;
  late BelastingPrioriteit _prioriteit;
  late BelastingVeld _veld;

  @override
  void initState() {
    super.initState();
    final v = widget.bewerken;
    _naam = TextEditingController(text: v?.naam ?? '');
    _vermogen =
        TextEditingController(text: (v?.vermogen ?? 10.0).toStringAsFixed(1));
    _prioriteit = v?.prioriteit ?? BelastingPrioriteit.normaal;
    _veld = v ??
        BelastingVeld(
          id: '',
          naam: '',
          vermogen: 10.0,
          verdederId: widget.verdederId,
        );
  }

  @override
  void dispose() {
    _naam.dispose();
    _vermogen.dispose();
    super.dispose();
  }

  void _opslaan() {
    if (!_formKey.currentState!.validate()) return;
    final bijgewerkt = _veld.copyWith(
      naam: _naam.text.trim(),
      vermogen: double.tryParse(_vermogen.text) ?? _veld.vermogen,
      prioriteit: _prioriteit,
    );
    if (widget.bewerken != null) {
      widget.provider.updateBelastingVeld(bijgewerkt);
    } else {
      widget.provider.voegBelastingVeldToe(verdederId: widget.verdederId);
      final nieuw = widget.provider.belasting.velden.last;
      widget.provider.updateBelastingVeld(nieuw.copyWith(
        naam: bijgewerkt.naam,
        vermogen: bijgewerkt.vermogen,
        prioriteit: bijgewerkt.prioriteit,
        perioden: bijgewerkt.perioden,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isBewerken = widget.bewerken != null;
    return AlertDialog(
      title: Text(isBewerken ? 'Belasting bewerken' : 'Belasting toevoegen'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _naam,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Naam',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vereist' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vermogen,
                  decoration: const InputDecoration(
                    labelText: 'Vermogen (kVA)',
                    border: OutlineInputBorder(),
                    suffixText: 'kVA',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {
                    _veld = _veld.copyWith(
                        vermogen:
                            double.tryParse(_vermogen.text) ?? _veld.vermogen);
                  }),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Getal' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BelastingPrioriteit>(
                  initialValue: _prioriteit,
                  decoration: const InputDecoration(
                    labelText: 'Prioriteit',
                    border: OutlineInputBorder(),
                  ),
                  items: BelastingPrioriteit.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(_prioriteitLabel(p)),
                          ))
                      .toList(),
                  onChanged: (p) {
                    if (p != null) setState(() => _prioriteit = p);
                  },
                ),
                const SizedBox(height: 8),
                PeriodeSection(
                  veld: _veld,
                  onChanged: (v) => setState(() => _veld = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        FilledButton(
          onPressed: _opslaan,
          child: Text(isBewerken ? 'Opslaan' : 'Toevoegen'),
        ),
      ],
    );
  }

  String _prioriteitLabel(BelastingPrioriteit p) {
    switch (p) {
      case BelastingPrioriteit.kritisch:
        return 'Kritisch';
      case BelastingPrioriteit.normaal:
        return 'Normaal';
      case BelastingPrioriteit.nietKritisch:
        return 'Niet-kritisch';
    }
  }
}
