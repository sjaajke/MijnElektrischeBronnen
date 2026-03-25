import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/verdeler.dart';
import '../models/energiebron.dart';
import '../models/belasting.dart';
import '../models/enums.dart';

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
            icon: const Icon(Icons.add),
            tooltip: 'Hoofdverdeler toevoegen',
            onPressed: () =>
                _toonVerdelerDialoog(context, provider, parentId: null),
          ),
        ],
      ),
      body: roots.isEmpty
          ? _LeegScherm(onAdd: () =>
              _toonVerdelerDialoog(context, provider, parentId: null))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ...roots.map((v) =>
                    _VerdelerNode(verdeler: v, provider: provider, depth: 0)),
                const SizedBox(height: 80),
              ],
            ),
    );
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
            hintText: parentId == null ? 'bijv. Hoofdverdeler' : 'bijv. OV-Kantine',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _opslaan(context, provider, ctrl.text, parentId, bewerken),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () =>
                _opslaan(context, provider, ctrl.text, parentId, bewerken),
            child: Text(isBewerken ? 'Opslaan' : 'Toevoegen'),
          ),
        ],
      ),
    );
  }

  static void _opslaan(
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
                color: isHV
                    ? colorScheme.onPrimary
                    : colorScheme.onSecondary,
              ),
            ),
          ),
          title: Text(
            verdeler.naam,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  context,
                  provider,
                  parentId: verdeler.id,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Naam bewerken',
                onPressed: () => NetwerkScreen._toonVerdelerDialoog(
                  context,
                  provider,
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
            if (bronnen.isNotEmpty) ...[
              _SectieHeader(
                  icon: Icons.bolt, label: 'Energiebronnen', count: bronnen.length),
              ...bronnen.map((b) => _BronTegel(bron: b, provider: provider)),
            ],

            // --- Belasting ---
            if (belastingen.isNotEmpty) ...[
              _SectieHeader(
                  icon: Icons.electrical_services,
                  label: 'Belasting',
                  count: belastingen.length),
              ...belastingen.map((v) => _BelastingTegel(veld: v, provider: provider)),
            ],

            if (bronnen.isEmpty && belastingen.isEmpty && kinderen.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Geen bronnen of belastingen gekoppeld.\n'
                  'Koppel via de tabbladen "Bronnen" en "Belasting".',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant),
                ),
              ),

            // --- Kinderen (recursief) ---
            if (kinderen.isNotEmpty) ...[
              _SectieHeader(
                  icon: Icons.account_tree,
                  label: 'Onderverdelers',
                  count: kinderen.length),
              ...kinderen.map((k) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _VerdelerNode(
                        verdeler: k,
                        provider: provider,
                        depth: 0),
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
    if (belastingen > 0) delen.add('$belastingen belasting${belastingen == 1 ? "" : "en"}');
    if (kinderen > 0) delen.add('$kinderen onderverdeler${kinderen == 1 ? "" : "s"}');
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
              Text('• $totaalBronnen energiebron${totaalBronnen == 1 ? "" : "nen"} (en beveiligingen)'),
            if (kinderen.isNotEmpty)
              Text('• ${kinderen.length} onderverdeler${kinderen.length == 1 ? "" : "s"} (en hun inhoud)'),
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
}

class _SectieHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _SectieHeader(
      {required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
        ],
      ),
    );
  }
}

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
            icon: const Icon(Icons.drive_file_move_outlined, size: 18),
            tooltip: 'Verplaats naar andere verdeler',
            onPressed: () => _toonVerplaatsDialoog(context),
          ),
        ],
      ),
    );
  }

  void _toonVerplaatsDialoog(BuildContext context) {
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
        '${veld.vermogen.toStringAsFixed(1)} kVA • ${_prioriteitLabel(veld.prioriteit)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.drive_file_move_outlined, size: 18),
        tooltip: 'Verplaats naar andere verdeler',
        onPressed: () => _toonVerplaatsDialoog(context),
      ),
    );
  }

  void _toonVerplaatsDialoog(BuildContext context) {
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
