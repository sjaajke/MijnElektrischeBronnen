import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/enums.dart';
import '../models/resultaten.dart';
import 'bronnen_screen.dart';
import 'beveiligingen_screen.dart';
import 'belasting_screen.dart';
import 'netwerk_screen.dart';
import 'resultaten_screen.dart';
import 'fout_analyse_screen.dart';
import 'instellingen_screen.dart';
import 'info_screen.dart';
import 'netwerken_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    _DashboardTab(),
    NetwerkScreen(),
    BronnenScreen(),
    BeveiligingScreen(),
    BelastingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          if (i == 5) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NetwerkenScreen()),
            );
          } else {
            setState(() => _selectedIndex = i);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Netwerk',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Bronnen',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Beveiligingen',
          ),
          NavigationDestination(
            icon: Icon(Icons.electrical_services_outlined),
            selectedIcon: Icon(Icons.electrical_services),
            label: 'Belasting',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Netwerken',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallatieProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MijnElektrischeBronnen'),
            if (provider.huidigNetwerkNaam != null)
              Text(
                provider.huidigNetwerkNaam!,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Over deze app',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InfoScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InstellingenScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Scenario selector
          _ScenarioSelector(provider: provider),
          const SizedBox(height: 16),

          // Snelle statusoverzicht
          if (provider.bronnen.isEmpty)
            _LeegStatusCard()
          else ...[
            _StatusOverzicht(provider: provider),
            const SizedBox(height: 16),
            _BronnenToggleKaart(provider: provider),
          ],

          const SizedBox(height: 16),

          // Bereken knop
          FilledButton.icon(
            onPressed: provider.bronnen.isEmpty
                ? null
                : () {
                    provider.bereken();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ResultatenScreen()),
                    );
                  },
            icon: const Icon(Icons.calculate),
            label: const Text('Bereken & analyseer'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),

          if (provider.isBerekend && provider.resultaten != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoutAnalyseScreen()),
              ),
              icon: const Icon(Icons.warning_amber_outlined),
              label: Text(
                'Foutanalyse bekijken'
                '${_foutTeller(provider.resultaten!)}',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                foregroundColor: _foutKleur(provider.resultaten!, colorScheme),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _foutTeller(AnalyseResultaten resultaten) {
    final scenario = resultaten.huidigScenario;
    if (scenario == null) return '';
    final k = scenario.aantalKritiek;
    final w = scenario.aantalWaarschuwingen;
    if (k == 0 && w == 0) return ' ✓';
    return ' ($k kritisch, $w waarschuwingen)';
  }

  Color _foutKleur(AnalyseResultaten resultaten, ColorScheme cs) {
    final scenario = resultaten.huidigScenario;
    if (scenario == null) return cs.primary;
    if (scenario.aantalKritiek > 0) return cs.error;
    if (scenario.aantalWaarschuwingen > 0) return Colors.orange;
    return Colors.green;
  }
}

class _LeegStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.bolt_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Geen bronnen geconfigureerd',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg energiebronnen toe via het tabblad "Bronnen".',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioSelector extends StatelessWidget {
  final InstallatieProvider provider;
  const _ScenarioSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bedrijfsmodus',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<BedrijfsModus>(
              segments: BedrijfsModus.values
                  .map((m) => ButtonSegment(
                        value: m,
                        label: Text(
                          m == BedrijfsModus.netbedrijf
                              ? 'Net'
                              : m == BedrijfsModus.eilandbedrijf
                                  ? 'Eiland'
                                  : m == BedrijfsModus.eilandGeneratorBatterij
                                      ? 'Eil+Bat'
                                      : m == BedrijfsModus.hybride
                                          ? 'Hybride'
                                          : 'Nood',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ))
                  .toList(),
              selected: {provider.actiefScenario},
              onSelectionChanged: (s) => provider.setScenario(s.first),
              multiSelectionEnabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOverzicht extends StatelessWidget {
  final InstallatieProvider provider;
  const _StatusOverzicht({required this.provider});

  @override
  Widget build(BuildContext context) {
    final resultaat = provider.resultaten?.huidigScenario;
    final bronnenActief =
        provider.bronnen.where((b) => b.actief).length;
    final totaalVermogen =
        provider.bronnen.where((b) => b.actief).fold(0.0, (s, b) => s + b.nominaalVermogen);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Actieve bronnen',
            value: '$bronnenActief / ${provider.bronnen.length}',
            icon: Icons.bolt,
            color: bronnenActief > 0 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Vermogen',
            value: '${totaalVermogen.toStringAsFixed(0)} kVA',
            icon: Icons.power,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: resultaat != null ? 'Ik max' : 'Ik max',
            value: resultaat != null
                ? '${resultaat.totaleIkMax.toStringAsFixed(2)} kA'
                : '—',
            icon: Icons.flash_on,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BronnenToggleKaart extends StatelessWidget {
  final InstallatieProvider provider;
  const _BronnenToggleKaart({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Bronnen aan/uit',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          ...([...provider.bronnen]
                ..sort((a, b) {
                  final t = a.type.index.compareTo(b.type.index);
                  return t != 0 ? t : a.naam.compareTo(b.naam);
                }))
              .map((bron) => SwitchListTile(
                title: Text(bron.naam),
                subtitle: Text(
                    '${bron.type.label} • ${bron.nominaalVermogen.toStringAsFixed(0)} kVA'),
                value: bron.actief,
                onChanged: (_) => provider.toggleBronActief(bron.id),
                secondary: Icon(
                  _bronIcon(bron.type),
                  color: bron.actief
                      ? Colors.green
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )),
        ],
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
