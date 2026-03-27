import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/installatie_provider.dart';
import '../models/opgeslagen_netwerk.dart';

class NetwerkenScreen extends StatefulWidget {
  const NetwerkenScreen({super.key});

  @override
  State<NetwerkenScreen> createState() => _NetwerkenScreenState();
}

class _NetwerkenScreenState extends State<NetwerkenScreen> {
  late Future<List<OpgeslagenNetwerk>> _netwerkenFuture;

  @override
  void initState() {
    super.initState();
    _herlaad();
  }

  void _herlaad() {
    final provider = context.read<InstallatieProvider>();
    setState(() {
      _netwerkenFuture = provider.getOpgeslagenNetwerken();
    });
  }

  Future<void> _slaOp(InstallatieProvider provider) async {
    final controller = TextEditingController(
        text: provider.huidigNetwerkNaam ?? '');
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
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Opslaan')),
        ],
      ),
    );
    if (naam == null || naam.isEmpty) return;
    await provider.slaNetwerkOp(naam,
        bestaandId: provider.huidigNetwerkId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$naam" opgeslagen')),
      );
      _herlaad();
    }
  }

  Future<void> _hernoem(
      InstallatieProvider provider, OpgeslagenNetwerk netwerk) async {
    final controller = TextEditingController(text: netwerk.naam);
    final naam = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naam wijzigen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Naam'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Opslaan')),
        ],
      ),
    );
    if (naam == null || naam.isEmpty) return;
    await provider.hernoemNetwerk(netwerk.id, naam);
    if (mounted) _herlaad();
  }

  Future<void> _verwijder(
      InstallatieProvider provider, OpgeslagenNetwerk netwerk) async {
    final bevestigd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"${netwerk.naam}" verwijderen?'),
        content:
            const Text('Dit kan niet ongedaan gemaakt worden.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
    if (bevestigd != true) return;
    await provider.verwijderOpgeslagenNetwerk(netwerk.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${netwerk.naam}" verwijderd')),
      );
      _herlaad();
    }
  }

  Future<void> _laad(
      InstallatieProvider provider, OpgeslagenNetwerk netwerk) async {
    final bevestigd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"${netwerk.naam}" laden?'),
        content: const Text(
            'De huidige configuratie wordt vervangen. Sla eerst op als je die wilt bewaren.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Laden')),
        ],
      ),
    );
    if (bevestigd != true) return;
    await provider.laadNetwerk(netwerk);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${netwerk.naam}" geladen')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallatieProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opgeslagen netwerken'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Huidig netwerk opslaan',
            onPressed: () => _slaOp(provider),
          ),
        ],
      ),
      body: FutureBuilder<List<OpgeslagenNetwerk>>(
        future: _netwerkenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final netwerken = snapshot.data ?? [];
          if (netwerken.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Geen opgeslagen netwerken',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Gebruik de knop rechtsboven om op te slaan.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: netwerken.length,
            itemBuilder: (context, index) {
              final netwerk = netwerken[index];
              final isHuidig = netwerk.id == provider.huidigNetwerkId;
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.account_tree_outlined,
                    color: isHuidig
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    netwerk.naam,
                    style: isHuidig
                        ? TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  subtitle: Text(
                    _formatDatum(netwerk.opgeslagenOp) +
                        (isHuidig ? ' • huidig' : ''),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.drive_file_rename_outline),
                        tooltip: 'Naam wijzigen',
                        onPressed: () =>
                            _hernoem(provider, netwerk),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Verwijderen',
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () =>
                            _verwijder(provider, netwerk),
                      ),
                    ],
                  ),
                  onTap: () => _laad(provider, netwerk),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _slaOp(provider),
        icon: const Icon(Icons.save),
        label: const Text('Opslaan als...'),
      ),
    );
  }

  String _formatDatum(DateTime dt) {
    final nu = DateTime.now();
    final verschil = nu.difference(dt);
    if (verschil.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Vandaag $h:$m';
    } else if (verschil.inDays == 1) {
      return 'Gisteren';
    } else if (verschil.inDays < 7) {
      return '${verschil.inDays} dagen geleden';
    } else {
      return '${dt.day}-${dt.month}-${dt.year}';
    }
  }
}
