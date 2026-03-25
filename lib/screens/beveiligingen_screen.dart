import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/beveiliging.dart';
import '../models/enums.dart';

class BeveiligingScreen extends StatelessWidget {
  const BeveiligingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallatieProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Beveiligingen')),
      body: provider.bronnen.isEmpty
          ? const Center(
              child: Text('Voeg eerst energiebronnen toe.'),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: provider.bronnen.map((bron) {
                final beveiligingen = provider.getBeveiligingVoorBron(bron.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(
                          _bronIcon(bron.type),
                          color: bron.actief ? Colors.green : Colors.grey,
                        ),
                        title: Text(bron.naam,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${bron.type.label} • Ik = ${bron.kortsluitStroomKA.toStringAsFixed(2)} kA'),
                        trailing: TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Beveiliging'),
                          onPressed: () =>
                              provider.voegBeveiligingToe(bron.id),
                        ),
                      ),
                      if (beveiligingen.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            'Geen beveiligingen geconfigureerd voor deze bron.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ...beveiligingen.map((bev) => _BeveiligingTegel(
                            bev: bev,
                            provider: provider,
                          )),
                    ],
                  ),
                );
              }).toList(),
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

class _BeveiligingTegel extends StatelessWidget {
  final Beveiliging bev;
  final InstallatieProvider provider;
  const _BeveiligingTegel({required this.bev, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.shield_outlined),
      title: Text(bev.naam),
      subtitle: Text(
          '${bev.type.label} • In = ${bev.inNominaal.toStringAsFixed(0)} A'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => provider.verwijderBeveiliging(bev.id),
          ),
          const Icon(Icons.expand_more),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _BeveiligingFormulier(bev: bev, provider: provider),
        ),
      ],
    );
  }
}

class _BeveiligingFormulier extends StatefulWidget {
  final Beveiliging bev;
  final InstallatieProvider provider;
  const _BeveiligingFormulier({required this.bev, required this.provider});

  @override
  State<_BeveiligingFormulier> createState() => _BeveiligingFormulierState();
}

class _BeveiligingFormulierState extends State<_BeveiligingFormulier> {
  late TextEditingController _naam;
  late TextEditingController _inNominaal;
  late TextEditingController _irThermisch;
  late TextEditingController _isdKortsluit;
  late TextEditingController _iiInstantaan;
  late TextEditingController _tIr;
  late TextEditingController _tIsd;
  late TextEditingController _tIi;
  late TextEditingController _icu;

  @override
  void initState() {
    super.initState();
    final b = widget.bev;
    _naam = TextEditingController(text: b.naam);
    _inNominaal = TextEditingController(text: b.inNominaal.toStringAsFixed(0));
    _irThermisch = TextEditingController(text: b.irThermisch.toStringAsFixed(2));
    _isdKortsluit = TextEditingController(text: b.isdKortsluit.toStringAsFixed(1));
    _iiInstantaan = TextEditingController(text: b.iiInstantaan.toStringAsFixed(1));
    _tIr = TextEditingController(text: b.tIr.toStringAsFixed(2));
    _tIsd = TextEditingController(text: b.tIsd.toStringAsFixed(2));
    _tIi = TextEditingController(text: b.tIi.toStringAsFixed(2));
    _icu = TextEditingController(text: b.icu.toStringAsFixed(1));
  }

  @override
  void dispose() {
    for (final c in [_naam, _inNominaal, _irThermisch, _isdKortsluit,
        _iiInstantaan, _tIr, _tIsd, _tIi, _icu]) {
      c.dispose();
    }
    super.dispose();
  }

  void _sla() {
    widget.provider.updateBeveiliging(widget.bev.copyWith(
      naam: _naam.text,
      inNominaal: double.tryParse(_inNominaal.text) ?? widget.bev.inNominaal,
      irThermisch: double.tryParse(_irThermisch.text) ?? widget.bev.irThermisch,
      isdKortsluit: double.tryParse(_isdKortsluit.text) ?? widget.bev.isdKortsluit,
      iiInstantaan: double.tryParse(_iiInstantaan.text) ?? widget.bev.iiInstantaan,
      tIr: double.tryParse(_tIr.text) ?? widget.bev.tIr,
      tIsd: double.tryParse(_tIsd.text) ?? widget.bev.tIsd,
      tIi: double.tryParse(_tIi.text) ?? widget.bev.tIi,
      icu: double.tryParse(_icu.text) ?? widget.bev.icu,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bev = widget.bev;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _veld('Naam', _naam),
        const SizedBox(height: 8),
        DropdownButtonFormField<BeveiligingType>(
          initialValue: bev.type,
          decoration: const InputDecoration(
            labelText: 'Type beveiliging',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: BeveiligingType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (t) {
            if (t != null) {
              widget.provider.updateBeveiliging(bev.copyWith(type: t));
            }
          },
        ),
        const SizedBox(height: 12),
        Text('Instellingen',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _veld('In (A)', _inNominaal, isNum: true)),
          const SizedBox(width: 8),
          Expanded(child: _veld('Icu (kA)', _icu, isNum: true)),
        ]),
        const SizedBox(height: 8),
        _sectieLabel(context, 'L – Thermisch (Ir × In)'),
        Row(children: [
          Expanded(child: _veld('Ir (× In)', _irThermisch, isNum: true)),
          const SizedBox(width: 8),
          Expanded(child: _veld('t Ir (s)', _tIr, isNum: true)),
        ]),
        const SizedBox(height: 8),
        _sectieLabel(context, 'S – Kortsluit vertraagd (Isd × In)'),
        Row(children: [
          Expanded(child: _veld('Isd (× In)', _isdKortsluit, isNum: true)),
          const SizedBox(width: 8),
          Expanded(child: _veld('t Isd (s)', _tIsd, isNum: true)),
        ]),
        const SizedBox(height: 8),
        _sectieLabel(context, 'I – Instantaan (Ii × In)'),
        Row(children: [
          Expanded(child: _veld('Ii (× In)', _iiInstantaan, isNum: true)),
          const SizedBox(width: 8),
          Expanded(child: _veld('t Ii (s)', _tIi, isNum: true)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Berekende uitschakelstromen',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _InfoRij('Ir werkelijk',
                      '${bev.iThermischWerkelijk.toStringAsFixed(0)} A')),
                  Expanded(child: _InfoRij('Isd werkelijk',
                      '${bev.iSdWerkelijk.toStringAsFixed(0)} A')),
                  Expanded(child: _InfoRij('Ii werkelijk',
                      '${bev.iIWerkelijk.toStringAsFixed(0)} A')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectieLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
    );
  }

  Widget _veld(String label, TextEditingController ctrl,
      {bool isNum = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType:
          isNum ? const TextInputType.numberWithOptions(decimal: true) : null,
      onChanged: (_) => _sla(),
    );
  }
}

class _InfoRij extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRij(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
