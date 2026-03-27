import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/belasting.dart';
import '../models/verdeler.dart';
import '../models/enums.dart';
import '../widgets/periode_section.dart';

class BelastingScreen extends StatelessWidget {
  const BelastingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallatieProvider>();
    final belasting = provider.belasting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belasting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Veld toevoegen',
            onPressed: provider.voegBelastingVeldToe,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TotaalVermogenKaart(belasting: belasting, provider: provider),
          const SizedBox(height: 16),
          if (belasting.velden.isNotEmpty) ...[
            Text('Verdeling per veld',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...belasting.velden.map((veld) => _VeldKaart(
                  veld: veld,
                  provider: provider,
                )),
            const SizedBox(height: 8),
            _VeldenSamenvattingKaart(belasting: belasting),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Optioneel: voeg velden toe voor gedetailleerde verdeling per verbruiksgroep.',
                      ),
                    ),
                    TextButton(
                      onPressed: provider.voegBelastingVeldToe,
                      child: const Text('Toevoegen'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Totaal vermogen kaart ────────────────────────────────────────────────────

class _TotaalVermogenKaart extends StatefulWidget {
  final Belasting belasting;
  final InstallatieProvider provider;
  const _TotaalVermogenKaart(
      {required this.belasting, required this.provider});

  @override
  State<_TotaalVermogenKaart> createState() => _TotaalVermogenKaartState();
}

class _TotaalVermogenKaartState extends State<_TotaalVermogenKaart> {
  late TextEditingController _vermogenCtrl;
  late TextEditingController _cosFiCtrl;

  @override
  void initState() {
    super.initState();
    _vermogenCtrl = TextEditingController(
        text: widget.belasting.totaalVermogen.toStringAsFixed(0));
    _cosFiCtrl =
        TextEditingController(text: widget.belasting.cosFi.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _vermogenCtrl.dispose();
    _cosFiCtrl.dispose();
    super.dispose();
  }

  void _sla() {
    widget.provider.updateBelasting(Belasting(
      totaalVermogen: double.tryParse(_vermogenCtrl.text) ??
          widget.belasting.totaalVermogen,
      cosFi: double.tryParse(_cosFiCtrl.text) ?? widget.belasting.cosFi,
      velden: widget.belasting.velden,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final beschikbaar = context
        .watch<InstallatieProvider>()
        .bronnen
        .where((b) => b.actief)
        .fold(0.0, (s, b) => s + b.nominaalVermogen);

    final belasting = double.tryParse(_vermogenCtrl.text) ?? 0;
    final overbelast = belasting > beschikbaar * 1.1 && beschikbaar > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Totale belasting',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vermogenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Totaal vermogen (kVA)',
                      border: OutlineInputBorder(),
                      suffixText: 'kVA',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _sla(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cosFiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'cos φ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _sla(),
                  ),
                ),
              ],
            ),
            if (beschikbaar > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (belasting / beschikbaar).clamp(0.0, 1.5),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                color: overbelast ? Colors.red : Colors.green,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Belastingsgraad: ${(belasting / beschikbaar * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: overbelast ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold)),
                  Text('Beschikbaar: ${beschikbaar.toStringAsFixed(0)} kVA',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              if (overbelast)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text('Overbelasting!',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Veld kaart ───────────────────────────────────────────────────────────────

class _VeldKaart extends StatefulWidget {
  final BelastingVeld veld;
  final InstallatieProvider provider;
  const _VeldKaart({required this.veld, required this.provider});

  @override
  State<_VeldKaart> createState() => _VeldKaartState();
}

class _VeldKaartState extends State<_VeldKaart> {
  late TextEditingController _naam;
  late TextEditingController _vermogen;

  @override
  void initState() {
    super.initState();
    _naam = TextEditingController(text: widget.veld.naam);
    _vermogen =
        TextEditingController(text: widget.veld.vermogen.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _naam.dispose();
    _vermogen.dispose();
    super.dispose();
  }

  void _sla() {
    widget.provider.updateBelastingVeld(widget.veld.copyWith(
      naam: _naam.text,
      vermogen: double.tryParse(_vermogen.text) ?? widget.veld.vermogen,
    ));
  }


  @override
  Widget build(BuildContext context) {
    final veld = widget.veld;
    final prioriteitKleur = _prioriteitKleur(veld.prioriteit);
    final verdelaars = widget.provider.verdelaars;

    final huidigVerdederId = verdelaars.any((v) => v.id == veld.verdederId)
        ? veld.verdederId
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hoofdrij ──
            Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: prioriteitKleur,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _naam,
                    decoration: const InputDecoration(
                      labelText: 'Naam veld',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _sla(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _vermogen,
                    decoration: const InputDecoration(
                      labelText: 'kVA',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _sla(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<BelastingPrioriteit>(
                  value: veld.prioriteit,
                  isDense: true,
                  underline: const SizedBox(),
                  items: BelastingPrioriteit.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(_prioriteitLabel(p),
                                style: TextStyle(
                                    color: _prioriteitKleur(p),
                                    fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (p) {
                    if (p != null) {
                      widget.provider.updateBelastingVeld(
                          veld.copyWith(prioriteit: p));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () =>
                      widget.provider.verwijderBelastingVeld(veld.id),
                ),
              ],
            ),

            // ── Verdeler koppeling ──
            if (verdelaars.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: huidigVerdederId,
                decoration: const InputDecoration(
                  labelText: 'Verdeler',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon:
                      Icon(Icons.account_tree_outlined, size: 18),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Niet gekoppeld —'),
                  ),
                  ...verdelaars.map((Verdeler v) =>
                      DropdownMenuItem<String?>(
                        value: v.id,
                        child: Text(v.naam +
                            (v.isHoofdverdeler ? ' (HV)' : ' (OV)')),
                      )),
                ],
                onChanged: (id) {
                  widget.provider.updateBelastingVeld(
                    id == null
                        ? veld.copyWith(clearVerdeler: true)
                        : veld.copyWith(verdederId: id),
                  );
                },
              ),
            ],

            // ── Gelijktijdigheid per periode ──
            const SizedBox(height: 4),
            PeriodeSection(
              veld: veld,
              onChanged: widget.provider.updateBelastingVeld,
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

// ─── Velden samenvatting ──────────────────────────────────────────────────────

class _VeldenSamenvattingKaart extends StatelessWidget {
  final Belasting belasting;
  const _VeldenSamenvattingKaart({required this.belasting});

  @override
  Widget build(BuildContext context) {
    final kritisch = belasting.kritischVermogen;
    final totaalVelden = belasting.totaalVeldenVermogen;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SomVeld('Kritisch (eff.)',
                '${kritisch.toStringAsFixed(0)} kVA', Colors.red),
            _SomVeld('Totaal velden (eff.)',
                '${totaalVelden.toStringAsFixed(0)} kVA', Colors.blue),
            _SomVeld('Opgegeven totaal',
                '${belasting.totaalVermogen.toStringAsFixed(0)} kVA',
                Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SomVeld extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SomVeld(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
