import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/energiebron.dart';
import '../models/verdeler.dart';
import '../models/enums.dart';

class BronnenScreen extends StatelessWidget {
  const BronnenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallatieProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Energiebronnen'),
        actions: [
          PopupMenuButton<BronType>(
            icon: const Icon(Icons.add),
            tooltip: 'Bron toevoegen',
            onSelected: (type) => provider.voegBronToe(type: type),
            itemBuilder: (_) => BronType.values
                .map((t) => PopupMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(_bronIcon(t), size: 20),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: provider.bronnen.isEmpty
          ? const _LeegScherm()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.bronnen.length,
              itemBuilder: (context, i) {
                final bron = provider.bronnen[i];
                return _BronKaart(bron: bron, provider: provider);
              },
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

class _LeegScherm extends StatelessWidget {
  const _LeegScherm();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Geen bronnen',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Druk op + om een energiebron toe te voegen.'),
        ],
      ),
    );
  }
}

class _BronKaart extends StatelessWidget {
  final EnergiBron bron;
  final InstallatieProvider provider;
  const _BronKaart({required this.bron, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Switch(
          value: bron.actief,
          onChanged: (_) => provider.toggleBronActief(bron.id),
        ),
        title: Text(bron.naam,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: bron.actief
                  ? null
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            )),
        subtitle: Text(
            '${bron.type.label} • ${bron.nominaalVermogen.toStringAsFixed(0)} kVA • '
            'In = ${bron.nominaleStroom.toStringAsFixed(1)} A • '
            'Ik = ${bron.kortsluitStroomKA.toStringAsFixed(2)} kA'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Verwijder bron',
              onPressed: () => _bevestigVerwijder(context),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _BronFormulier(bron: bron, provider: provider),
          ),
        ],
      ),
    );
  }

  void _bevestigVerwijder(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bron verwijderen'),
        content: Text('Weet je zeker dat je "${bron.naam}" wilt verwijderen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren')),
          FilledButton(
            onPressed: () {
              provider.verwijderBron(bron.id);
              Navigator.pop(context);
            },
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }
}

class _BronFormulier extends StatefulWidget {
  final EnergiBron bron;
  final InstallatieProvider provider;
  const _BronFormulier({required this.bron, required this.provider});

  @override
  State<_BronFormulier> createState() => _BronFormulierState();
}

class _BronFormulierState extends State<_BronFormulier> {
  late TextEditingController _naam;
  late TextEditingController _vermogen;
  late TextEditingController _spanning;
  late TextEditingController _uk;
  late TextEditingController _xd;
  late TextEditingController _ksFactor;

  @override
  void initState() {
    super.initState();
    final b = widget.bron;
    _naam = TextEditingController(text: b.naam);
    _vermogen = TextEditingController(text: b.nominaalVermogen.toStringAsFixed(0));
    _spanning = TextEditingController(text: b.nominaleSpanning.toStringAsFixed(0));
    _uk = TextEditingController(text: b.kortsluitspanning.toStringAsFixed(1));
    _xd = TextEditingController(text: b.subtransientReactantie.toStringAsFixed(1));
    _ksFactor = TextEditingController(text: b.kortsluitFactor.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _naam.dispose();
    _vermogen.dispose();
    _spanning.dispose();
    _uk.dispose();
    _xd.dispose();
    _ksFactor.dispose();
    super.dispose();
  }

  void _sla() {
    widget.provider.updateBron(widget.bron.copyWith(
      naam: _naam.text,
      nominaalVermogen: double.tryParse(_vermogen.text) ?? widget.bron.nominaalVermogen,
      nominaleSpanning: double.tryParse(_spanning.text) ?? widget.bron.nominaleSpanning,
      kortsluitspanning: double.tryParse(_uk.text) ?? widget.bron.kortsluitspanning,
      subtransientReactantie: double.tryParse(_xd.text) ?? widget.bron.subtransientReactantie,
      kortsluitFactor: double.tryParse(_ksFactor.text) ?? widget.bron.kortsluitFactor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bron = widget.bron;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _veld('Naam', _naam, onChanged: (_) => _sla()),
        const SizedBox(height: 8),

        // Type
        DropdownButtonFormField<BronType>(
          initialValue: bron.type,
          decoration: const InputDecoration(
            labelText: 'Type bron',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: BronType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (t) {
            if (t != null) {
              widget.provider.updateBron(bron.copyWith(type: t));
            }
          },
        ),
        const SizedBox(height: 8),

        // Verdeler koppeling
        if (widget.provider.verdelaars.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: widget.provider.verdelaars
                    .any((v) => v.id == bron.verdederId)
                ? bron.verdederId
                : widget.provider.verdelaars.first.id,
            decoration: const InputDecoration(
              labelText: 'Aangesloten op verdeler',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.account_tree_outlined, size: 18),
            ),
            items: widget.provider.verdelaars
                .map((Verdeler v) => DropdownMenuItem(
                      value: v.id,
                      child: Text(
                        v.naam + (v.isHoofdverdeler ? ' (HV)' : ' (OV)'),
                      ),
                    ))
                .toList(),
            onChanged: (id) {
              if (id != null) {
                widget.provider.updateBron(bron.copyWith(verdederId: id));
              }
            },
          ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(child: _veld('Vermogen (kVA)', _vermogen, onChanged: (_) => _sla(), isNum: true)),
            const SizedBox(width: 8),
            Expanded(child: _veld('Spanning (V)', _spanning, onChanged: (_) => _sla(), isNum: true)),
          ],
        ),
        const SizedBox(height: 8),

        // Typespecifieke velden
        if (bron.type == BronType.trafo)
          _veld('Kortsluitspanning uk (%)', _uk,
              onChanged: (_) => _sla(), isNum: true,
              hint: 'bijv. 4.0'),
        if (bron.type == BronType.generator)
          _veld("Subtransiënt reactantie X''d (%)", _xd,
              onChanged: (_) => _sla(), isNum: true,
              hint: 'bijv. 15.0'),
        if (bron.type == BronType.pv || bron.type == BronType.batterij)
          _veld('Kortsluitfactor (× In)', _ksFactor,
              onChanged: (_) => _sla(), isNum: true,
              hint: 'bijv. 1.2'),

        const SizedBox(height: 12),
        // Berekende waarden
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _InfoVeld('In (nominaal)',
                    '${bron.nominaleStroom.toStringAsFixed(1)} A'),
              ),
              Expanded(
                child: _InfoVeld('Ik (kortsluit)',
                    '${bron.kortsluitStroomKA.toStringAsFixed(3)} kA'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _veld(
    String label,
    TextEditingController ctrl, {
    void Function(String)? onChanged,
    bool isNum = false,
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: onChanged,
    );
  }
}

class _InfoVeld extends StatelessWidget {
  final String label;
  final String value;
  const _InfoVeld(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
