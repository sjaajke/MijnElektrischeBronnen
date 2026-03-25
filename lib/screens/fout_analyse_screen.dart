import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/resultaten.dart';
import '../models/enums.dart';

class FoutAnalyseScreen extends StatefulWidget {
  const FoutAnalyseScreen({super.key});

  @override
  State<FoutAnalyseScreen> createState() => _FoutAnalyseScreenState();
}

class _FoutAnalyseScreenState extends State<FoutAnalyseScreen> {
  FoutNiveau? _filter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallatieProvider>();

    if (!provider.isBerekend || provider.resultaten == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Foutanalyse')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('Voer eerst een berekening uit.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  provider.bereken();
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Bereken'),
              ),
            ],
          ),
        ),
      );
    }

    final scenario = provider.resultaten!.huidigScenario!;
    final alleFouten = scenario.fouten;
    final gefilterd = _filter == null
        ? alleFouten
        : alleFouten.where((f) => f.niveau == _filter).toList();

    final aantalKritisch =
        alleFouten.where((f) => f.niveau == FoutNiveau.kritisch).length;
    final aantalWaarschuwingen =
        alleFouten.where((f) => f.niveau == FoutNiveau.waarschuwing).length;
    final aantalInfo =
        alleFouten.where((f) => f.niveau == FoutNiveau.informatief).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fout- & risicoanalyse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Herbereken',
            onPressed: provider.bereken,
          ),
        ],
      ),
      body: Column(
        children: [
          // Samenvatting balk
          _SamenvattingBalk(
            kritisch: aantalKritisch,
            waarschuwingen: aantalWaarschuwingen,
            info: aantalInfo,
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Alle'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Kritisch ($aantalKritisch)'),
                    selected: _filter == FoutNiveau.kritisch,
                    selectedColor: Colors.red.shade100,
                    onSelected: (_) => setState(() => _filter =
                        _filter == FoutNiveau.kritisch
                            ? null
                            : FoutNiveau.kritisch),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Waarschuwingen ($aantalWaarschuwingen)'),
                    selected: _filter == FoutNiveau.waarschuwing,
                    selectedColor: Colors.orange.shade100,
                    onSelected: (_) => setState(() => _filter =
                        _filter == FoutNiveau.waarschuwing
                            ? null
                            : FoutNiveau.waarschuwing),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Info ($aantalInfo)'),
                    selected: _filter == FoutNiveau.informatief,
                    selectedColor: Colors.blue.shade100,
                    onSelected: (_) => setState(() => _filter =
                        _filter == FoutNiveau.informatief
                            ? null
                            : FoutNiveau.informatief),
                  ),
                ],
              ),
            ),
          ),

          // Foutlijst
          Expanded(
            child: gefilterd.isEmpty
                ? _GeenFouten(filter: _filter)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: gefilterd.length,
                    itemBuilder: (context, i) =>
                        _FoutKaart(fout: gefilterd[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SamenvattingBalk extends StatelessWidget {
  final int kritisch;
  final int waarschuwingen;
  final int info;

  const _SamenvattingBalk({
    required this.kritisch,
    required this.waarschuwingen,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final Color achtergrond;
    final String statusText;
    final IconData statusIcon;

    if (kritisch > 0) {
      achtergrond = Colors.red.shade700;
      statusText = '$kritisch kritisch probleem${kritisch > 1 ? "en" : ""} gevonden';
      statusIcon = Icons.error;
    } else if (waarschuwingen > 0) {
      achtergrond = Colors.orange.shade700;
      statusText = '$waarschuwingen waarschuwing${waarschuwingen > 1 ? "en" : ""} gevonden';
      statusIcon = Icons.warning;
    } else {
      achtergrond = Colors.green.shade700;
      statusText = 'Geen kritische bevindingen';
      statusIcon = Icons.check_circle;
    }

    return Container(
      width: double.infinity,
      color: achtergrond,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(statusIcon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(statusText,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          if (waarschuwingen > 0 && kritisch == 0) ...[
            const SizedBox(width: 8),
            Text('$waarschuwingen waarsch.',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
          if (info > 0) ...[
            const SizedBox(width: 8),
            Text('$info info',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _FoutKaart extends StatelessWidget {
  final FoutMelding fout;
  const _FoutKaart({required this.fout});

  @override
  Widget build(BuildContext context) {
    final (kleur, icon, achtergrond) = switch (fout.niveau) {
      FoutNiveau.kritisch => (
          Colors.red.shade700,
          Icons.error,
          Colors.red.shade50,
        ),
      FoutNiveau.waarschuwing => (
          Colors.orange.shade700,
          Icons.warning,
          Colors.orange.shade50,
        ),
      FoutNiveau.informatief => (
          Colors.blue.shade700,
          Icons.info,
          Colors.blue.shade50,
        ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: achtergrond,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: kleur, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(fout.titel,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kleur,
                          fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kleur,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    switch (fout.niveau) {
                      FoutNiveau.kritisch => 'KRITISCH',
                      FoutNiveau.waarschuwing => 'WAARSCHUWING',
                      FoutNiveau.informatief => 'INFO',
                    },
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fout.beschrijving,
                    style: Theme.of(context).textTheme.bodyMedium),
                if (fout.aanbeveling != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fout.aanbeveling!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeenFouten extends StatelessWidget {
  final FoutNiveau? filter;
  const _GeenFouten({this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filter == null ? Icons.check_circle_outline : Icons.filter_alt,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            filter == null
                ? 'Geen bevindingen'
                : 'Geen ${_filterLabel(filter!)} gevonden',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (filter == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Alles ziet er goed uit voor dit scenario!'),
            ),
        ],
      ),
    );
  }

  String _filterLabel(FoutNiveau niveau) {
    switch (niveau) {
      case FoutNiveau.kritisch:
        return 'kritische meldingen';
      case FoutNiveau.waarschuwing:
        return 'waarschuwingen';
      case FoutNiveau.informatief:
        return 'informatieve meldingen';
    }
  }
}
