import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/resultaten.dart';
import '../models/enums.dart';
import '../services/pdf_rapport.dart';
import 'fout_analyse_screen.dart';

// ─── Batterij autonomie kaart ─────────────────────────────────────────────────

class _BatterijAutonomieKaart extends StatelessWidget {
  final List<BatterijAutonomie> autonomies;
  const _BatterijAutonomieKaart({required this.autonomies});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.battery_charging_full, size: 18),
              const SizedBox(width: 8),
              Text('Batterij autonomie',
                  style: Theme.of(context).textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            ...autonomies.map((a) => _AutonomieRij(autonomie: a)),
            const SizedBox(height: 8),
            Text(
              'Autonomie = capaciteit (kWh) ÷ kritische belasting (kW). '
              'Winter = zomer × seizoensfactor.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutonomieRij extends StatelessWidget {
  final BatterijAutonomie autonomie;
  const _AutonomieRij({required this.autonomie});

  @override
  Widget build(BuildContext context) {
    final a = autonomie;
    final heeftCapaciteit = a.capaciteitKwh > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.bronNaam,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (!heeftCapaciteit)
            Text('Geen capaciteit opgegeven',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  children: [
                    _Cel('Capaciteit', '${a.capaciteitKwh.toStringAsFixed(0)} kWh'),
                    _Cel('Autonomie zomer', _uurTekst(a.autonomieZomerUur),
                        kleur: _autonomieKleur(context, a.autonomieZomerUur)),
                    _Cel('Autonomie winter', _uurTekst(a.autonomieWinterUur),
                        kleur: _autonomieKleur(context, a.autonomieWinterUur)),
                  ],
                ),
                if (a.oplaadtijdZomerUur != null)
                  TableRow(children: [
                    const _Cel('', ''),
                    _Cel('Oplaadtijd zomer', _uurTekst(a.oplaadtijdZomerUur)),
                    _Cel('Oplaadtijd winter', _uurTekst(a.oplaadtijdWinterUur)),
                  ]),
              ],
            ),
        ],
      ),
    );
  }

  String _uurTekst(double? uren) {
    if (uren == null) return '—';
    if (uren < 1) return '${(uren * 60).toStringAsFixed(0)} min';
    if (uren >= 100) return '> 99 uur';
    return '${uren.toStringAsFixed(1)} uur';
  }

  Color? _autonomieKleur(BuildContext context, double? uren) {
    if (uren == null) return null;
    if (uren < 1) return Theme.of(context).colorScheme.error;
    if (uren < 4) return Colors.orange;
    return Colors.green;
  }
}

class _Cel extends StatelessWidget {
  final String label;
  final String waarde;
  final Color? kleur;
  const _Cel(this.label, this.waarde, {this.kleur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(waarde,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: kleur, fontSize: 14)),
        ],
      ),
    );
  }
}

class ResultatenScreen extends StatelessWidget {
  const ResultatenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallatieProvider>();

    if (!provider.isBerekend || provider.resultaten == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultaten')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calculate_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('Nog geen berekening uitgevoerd.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  provider.bereken();
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Nu berekenen'),
              ),
            ],
          ),
        ),
      );
    }

    final resultaten = provider.resultaten!;
    final huidig = resultaten.huidigScenario!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultaten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exporteren als PDF',
            onPressed: () => PdfRapport.drukAf(context, provider, resultaten),
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined),
            tooltip: 'Foutanalyse',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoutAnalyseScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ScenarioTabs(resultaten: resultaten, provider: provider),
          const SizedBox(height: 16),
          _KortsluitKaart(scenario: huidig),
          const SizedBox(height: 12),
          _VermogenKaart(scenario: huidig),
          const SizedBox(height: 12),
          if (huidig.verdelerResultaten.isNotEmpty) ...[
            _VerdelerAnalyseKaart(scenario: huidig),
            const SizedBox(height: 12),
          ],
          _BronnenTabel(scenario: huidig),
          const SizedBox(height: 12),
          if (huidig.batterijAutonomies.isNotEmpty) ...[
            _BatterijAutonomieKaart(autonomies: huidig.batterijAutonomies),
            const SizedBox(height: 12),
          ],
          _SelectiviteitTabel(scenario: huidig),
          const SizedBox(height: 12),
          _FoutSamenvatting(scenario: huidig),
        ],
      ),
    );
  }
}

class _ScenarioTabs extends StatelessWidget {
  final AnalyseResultaten resultaten;
  final InstallatieProvider provider;
  const _ScenarioTabs(
      {required this.resultaten, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scenario vergelijking',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: BedrijfsModus.values.map((modus) {
                  final scenario = resultaten.alleScenarios[modus];
                  if (scenario == null) return const SizedBox();
                  final isActief = modus == provider.actiefScenario;
                  final k = scenario.aantalKritiek;
                  final w = scenario.aantalWaarschuwingen;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ScenarioChip(
                      label: modus.label,
                      isActief: isActief,
                      kritisch: k,
                      waarschuwingen: w,
                      ikMax: scenario.totaleIkMax,
                      vermogen: scenario.beschikbaarVermogen,
                      onTap: () => provider.setScenario(modus),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioChip extends StatelessWidget {
  final String label;
  final bool isActief;
  final int kritisch;
  final int waarschuwingen;
  final double ikMax;
  final double vermogen;
  final VoidCallback onTap;

  const _ScenarioChip({
    required this.label,
    required this.isActief,
    required this.kritisch,
    required this.waarschuwingen,
    required this.ikMax,
    required this.vermogen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color statusKleur = Colors.green;
    if (kritisch > 0) {
      statusKleur = cs.error;
    } else if (waarschuwingen > 0) {
      statusKleur = Colors.orange;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
              color: isActief ? cs.primary : cs.outline, width: isActief ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          color: isActief ? cs.primaryContainer : cs.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isActief ? cs.onPrimaryContainer : null)),
            const SizedBox(height: 4),
            Text('${ikMax.toStringAsFixed(2)} kA',
                style: const TextStyle(fontSize: 12)),
            Text('${vermogen.toStringAsFixed(0)} kVA',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, color: statusKleur, size: 8),
                const SizedBox(width: 4),
                Text(
                  kritisch > 0
                      ? '$kritisch kritisch'
                      : waarschuwingen > 0
                          ? '$waarschuwingen waarsch.'
                          : 'OK',
                  style: TextStyle(color: statusKleur, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KortsluitKaart extends StatelessWidget {
  final ScenarioResultaat scenario;
  const _KortsluitKaart({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Kortsluitstromen',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _WaardeKaart(
                    label: 'Ik max (alle bronnen)',
                    value: '${scenario.totaleIkMax.toStringAsFixed(3)} kA',
                    sublabel: 'Maximale kortsluitstroom',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WaardeKaart(
                    label: 'Ik min (zwakste bron)',
                    value: '${scenario.totaleIkMin.toStringAsFixed(3)} kA',
                    sublabel: 'Minimale kortsluitstroom',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VermogenKaart extends StatelessWidget {
  final ScenarioResultaat scenario;
  const _VermogenKaart({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final graad = scenario.belastingsgraad;
    final kleur = scenario.overbelast
        ? Colors.red
        : graad > 0.8
            ? Colors.orange
            : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.power, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Vermogenbalans',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (scenario.nMinEenOk)
                  const Chip(
                    label: Text('N-1 OK', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )
                else
                  const Chip(
                    label: Text('Geen N-1', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _WaardeKaart(
                    label: 'Beschikbaar',
                    value:
                        '${scenario.beschikbaarVermogen.toStringAsFixed(0)} kVA',
                    sublabel: 'Totaal actieve bronnen',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WaardeKaart(
                    label: 'Gevraagd',
                    value:
                        '${scenario.gevraagdVermogen.toStringAsFixed(0)} kVA',
                    sublabel: 'Totale belasting',
                    color: kleur,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: graad.clamp(0.0, 1.0),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                color: kleur,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Belastingsgraad: ${(graad * 100).toStringAsFixed(1)}%'
              '${scenario.overbelast ? ' ⚠ OVERBELAST' : ''}',
              style: TextStyle(
                  color: kleur, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdelerAnalyseKaart extends StatelessWidget {
  final ScenarioResultaat scenario;
  const _VerdelerAnalyseKaart({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree, color: Colors.teal),
                const SizedBox(width: 8),
                Text('Netwerktopologie',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...scenario.verdelerResultaten.map((vr) {
              final statusKleur = vr.overbelast
                  ? cs.error
                  : vr.heeftKritischeBelasting && !vr.kritischGedekt
                      ? Colors.orange
                      : Colors.green;
              final statusIcon = vr.overbelast
                  ? Icons.error
                  : vr.heeftKritischeBelasting && !vr.kritischGedekt
                      ? Icons.warning_amber
                      : Icons.check_circle;
              final statusTekst = vr.overbelast
                  ? 'Overbelast'
                  : vr.heeftKritischeBelasting && !vr.kritischGedekt
                      ? 'Kritisch ongedekt'
                      : vr.beschikbaarVermogen == 0 && vr.heeftBelasting
                          ? 'Geen voeding'
                          : 'OK';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: statusKleur.withValues(alpha: 0.4), width: 1),
                  borderRadius: BorderRadius.circular(8),
                  color: statusKleur.withValues(alpha: 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: vr.isHoofdverdeler
                              ? cs.primary
                              : cs.secondary,
                          child: Text(
                            vr.isHoofdverdeler ? 'HV' : 'OV',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: vr.isHoofdverdeler
                                  ? cs.onPrimary
                                  : cs.onSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(vr.verdelerNaam,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Icon(statusIcon, color: statusKleur, size: 18),
                        const SizedBox(width: 4),
                        Text(statusTekst,
                            style: TextStyle(
                                color: statusKleur,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniStat(
                          label: 'Lokaal',
                          value:
                              '${vr.lokaalVermogen.toStringAsFixed(0)} kVA',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _MiniStat(
                          label: 'Beschikbaar',
                          value:
                              '${vr.beschikbaarVermogen.toStringAsFixed(0)} kVA',
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        _MiniStat(
                          label: 'Belasting',
                          value: vr.heeftBelasting
                              ? '${vr.gevraagdVermogen.toStringAsFixed(0)} kVA'
                              : '—',
                          color: vr.overbelast ? cs.error : Colors.grey,
                        ),
                        if (vr.heeftKritischeBelasting) ...[
                          const SizedBox(width: 8),
                          _MiniStat(
                            label: 'Kritisch',
                            value:
                                '${vr.kritischVermogen.toStringAsFixed(0)} kVA',
                            color: vr.kritischGedekt
                                ? Colors.green
                                : Colors.orange,
                            icon: vr.kritischGedekt
                                ? Icons.shield
                                : Icons.shield_outlined,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 10, color: color),
                  const SizedBox(width: 2),
                ],
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _BronnenTabel extends StatelessWidget {
  final ScenarioResultaat scenario;
  const _BronnenTabel({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bronnen overzicht',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 36,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                columns: const [
                  DataColumn(label: Text('Bron')),
                  DataColumn(label: Text('In (A)')),
                  DataColumn(label: Text('Ik (kA)')),
                  DataColumn(label: Text('Status')),
                ],
                rows: scenario.bronResultaten
                    .map((b) => DataRow(cells: [
                          DataCell(Text(b.bronNaam)),
                          DataCell(Text(b.nominaleStroom.toStringAsFixed(1))),
                          DataCell(
                              Text((b.kortsluitStroom / 1000).toStringAsFixed(3))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: b.actief
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                b.actief ? 'Actief' : 'Inactief',
                                style: TextStyle(
                                  color: b.actief
                                      ? Colors.green.shade800
                                      : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ]))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectiviteitTabel extends StatelessWidget {
  final ScenarioResultaat scenario;
  const _SelectiviteitTabel({required this.scenario});

  @override
  Widget build(BuildContext context) {
    if (scenario.beveiligingResultaten.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selectiviteitscontrole',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...scenario.beveiligingResultaten.map((bev) {
              final ok = bev.selectiviteit == SelectiviteitStatus.ok &&
                  !bev.overschrijdtIcu;
              return ListTile(
                dense: true,
                leading: Icon(
                  ok ? Icons.check_circle : Icons.cancel,
                  color: ok ? Colors.green : Colors.red,
                ),
                title: Text(bev.beveiligingNaam),
                subtitle: Text(bev.opmerking),
                trailing: bev.overschrijdtIcu
                    ? const Chip(
                        label: Text('Icu!',
                            style: TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.red,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FoutSamenvatting extends StatelessWidget {
  final ScenarioResultaat scenario;
  const _FoutSamenvatting({required this.scenario});

  @override
  Widget build(BuildContext context) {
    if (scenario.fouten.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        child: const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('Geen kritische bevindingen'),
          subtitle: Text('Alle controles geslaagd voor dit scenario.'),
        ),
      );
    }

    final kritisch =
        scenario.fouten.where((f) => f.niveau == FoutNiveau.kritisch).toList();
    final waarschuwingen = scenario.fouten
        .where((f) => f.niveau == FoutNiveau.waarschuwing)
        .toList();
    final info =
        scenario.fouten.where((f) => f.niveau == FoutNiveau.informatief).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bevindingen samenvatting',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (kritisch.isNotEmpty)
              _FoutGroep(
                  titel: '${kritisch.length} Kritisch',
                  kleur: Colors.red,
                  icon: Icons.error,
                  fouten: kritisch.take(3).toList()),
            if (waarschuwingen.isNotEmpty)
              _FoutGroep(
                  titel: '${waarschuwingen.length} Waarschuwingen',
                  kleur: Colors.orange,
                  icon: Icons.warning,
                  fouten: waarschuwingen.take(3).toList()),
            if (info.isNotEmpty)
              _FoutGroep(
                  titel: '${info.length} Informatief',
                  kleur: Colors.blue,
                  icon: Icons.info,
                  fouten: info.take(2).toList()),
          ],
        ),
      ),
    );
  }
}

class _FoutGroep extends StatelessWidget {
  final String titel;
  final Color kleur;
  final IconData icon;
  final List<FoutMelding> fouten;

  const _FoutGroep({
    required this.titel,
    required this.kleur,
    required this.icon,
    required this.fouten,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: kleur, size: 16),
              const SizedBox(width: 6),
              Text(titel,
                  style: TextStyle(
                      color: kleur, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        ...fouten.map((f) => Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 4),
              child: Text('• ${f.titel}',
                  style: TextStyle(color: kleur, fontSize: 12)),
            )),
      ],
    );
  }
}

class _WaardeKaart extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color color;

  const _WaardeKaart({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(sublabel,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
