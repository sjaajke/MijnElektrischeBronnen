import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/belasting.dart';
import '../models/enums.dart';

class PeriodeSection extends StatefulWidget {
  final BelastingVeld veld;
  final ValueChanged<BelastingVeld> onChanged;

  const PeriodeSection({
    super.key,
    required this.veld,
    required this.onChanged,
  });

  @override
  State<PeriodeSection> createState() => _PeriodeSectionState();
}

class _PeriodeSectionState extends State<PeriodeSection> {
  bool _uitgevouwen = false;

  @override
  void didUpdateWidget(PeriodeSection old) {
    super.didUpdateWidget(old);
    if (old.veld.perioden.isEmpty && widget.veld.perioden.isNotEmpty) {
      _uitgevouwen = true;
    }
  }

  void _voegToe() {
    final nieuw = BelastingPeriode(id: const Uuid().v4());
    widget.onChanged(
        widget.veld.copyWith(perioden: [...widget.veld.perioden, nieuw]));
  }

  void _update(BelastingPeriode periode) {
    widget.onChanged(widget.veld.copyWith(
        perioden: widget.veld.perioden
            .map((p) => p.id == periode.id ? periode : p)
            .toList()));
  }

  void _verwijder(String id) {
    widget.onChanged(widget.veld.copyWith(
        perioden: widget.veld.perioden.where((p) => p.id != id).toList()));
  }

  @override
  Widget build(BuildContext context) {
    final perioden = widget.veld.perioden;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _uitgevouwen = !_uitgevouwen),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _uitgevouwen ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Gelijktijdigheid per periode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (perioden.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${perioden.length}',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                const Spacer(),
                if (perioden.isNotEmpty)
                  Text(
                    'max ${widget.veld.effectiefVermogen.toStringAsFixed(1)} kVA'
                    ' (${(widget.veld.maxGelijktijdigheid * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                  ),
              ],
            ),
          ),
        ),
        if (_uitgevouwen) ...[
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (perioden.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Geen perioden — volledig vermogen (${widget.veld.vermogen.toStringAsFixed(1)} kVA) wordt meegenomen.',
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ...perioden.map((p) => _PeriodeRij(
                periode: p,
                veld: widget.veld,
                onUpdate: _update,
                onVerwijder: _verwijder,
              )),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _voegToe,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Periode toevoegen'),
            style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _PeriodeRij extends StatefulWidget {
  final BelastingPeriode periode;
  final BelastingVeld veld;
  final ValueChanged<BelastingPeriode> onUpdate;
  final ValueChanged<String> onVerwijder;

  const _PeriodeRij({
    required this.periode,
    required this.veld,
    required this.onUpdate,
    required this.onVerwijder,
  });

  @override
  State<_PeriodeRij> createState() => _PeriodeRijState();
}

class _PeriodeRijState extends State<_PeriodeRij> {
  late BelastingPeriodePreset _preset;
  late double _gelijktijdigheid;

  @override
  void initState() {
    super.initState();
    _preset = widget.periode.preset;
    _gelijktijdigheid = widget.periode.gelijktijdigheid;
  }

  void _opslaan() {
    widget.onUpdate(BelastingPeriode(
      id: widget.periode.id,
      preset: _preset,
      gelijktijdigheid: _gelijktijdigheid,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final effectief = widget.veld.vermogen * _gelijktijdigheid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<BelastingPeriodePreset>(
              initialValue: _preset,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Periode',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: BelastingPeriodePreset.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.label,
                            style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (p) {
                if (p != null) {
                  setState(() => _preset = p);
                  _opslaan();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_gelijktijdigheid * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${effectief.toStringAsFixed(1)} kVA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _gelijktijdigheid,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (v) => setState(() => _gelijktijdigheid = v),
                    onChangeEnd: (_) => _opslaan(),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            onPressed: () => widget.onVerwijder(widget.periode.id),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
