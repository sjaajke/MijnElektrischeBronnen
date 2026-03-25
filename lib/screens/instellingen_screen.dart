import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';

class InstellingenScreen extends StatefulWidget {
  const InstellingenScreen({super.key});

  @override
  State<InstellingenScreen> createState() => _InstellingenScreenState();
}

class _InstellingenScreenState extends State<InstellingenScreen> {
  late TextEditingController _spanningCtrl;
  late TextEditingController _frequentieCtrl;
  late TextEditingController _cosFiCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<InstallatieProvider>();
    _spanningCtrl =
        TextEditingController(text: p.netspanning.toStringAsFixed(0));
    _frequentieCtrl =
        TextEditingController(text: p.frequentie.toStringAsFixed(0));
    _cosFiCtrl = TextEditingController(text: p.cosFi.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _spanningCtrl.dispose();
    _frequentieCtrl.dispose();
    _cosFiCtrl.dispose();
    super.dispose();
  }

  void _sla() {
    context.read<InstallatieProvider>().updateAlgemeen(
          netspanning: double.tryParse(_spanningCtrl.text),
          frequentie: double.tryParse(_frequentieCtrl.text),
          cosFi: double.tryParse(_cosFiCtrl.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Netparameters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Netparameters',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _spanningCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Netspanning (V)',
                      border: OutlineInputBorder(),
                      suffixText: 'V',
                      helperText: 'Nominale spanning van het net (bijv. 400 V)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _sla(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _frequentieCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Frequentie (Hz)',
                      border: OutlineInputBorder(),
                      suffixText: 'Hz',
                      helperText: '50 Hz (Europa) of 60 Hz (Amerika)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _sla(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cosFiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'cos φ (vermogensfactor)',
                      border: OutlineInputBorder(),
                      helperText:
                          'Standaard vermogensfactor (0.0 – 1.0). Default = 0.85',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _sla(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reset
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gegevens',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _bevestigReset(context),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text('Alle gegevens wissen',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Over MijnBronnen',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Versie 1.0.0'),
                  const SizedBox(height: 4),
                  const Text(
                      'Rekentool voor elektrische installaties met meerdere energiebronnen.'),
                  const SizedBox(height: 8),
                  const Text('Berekeningen conform:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('• NEN 1010 – Laagspanningsinstallaties'),
                  const Text('• NEN 3140 – Bedrijfsvoering elektrische installaties'),
                  const Text('• IEC 60909 – Kortsluitstroomberekening'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bevestigReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alle gegevens wissen'),
        content: const Text(
            'Weet je zeker dat je alle bronnen, beveiligingen en belastingen wilt wissen? '
            'Dit kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              context.read<InstallatieProvider>().reset();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Wissen'),
          ),
        ],
      ),
    );
  }
}
