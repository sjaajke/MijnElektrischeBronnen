import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Over MijnElektrischeBronnen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _IntroKaart(),
          SizedBox(height: 12),
          _InfoSectie(
            icon: Icons.apps_outlined,
            titel: 'Wat doet de app?',
            kleur: Colors.blue,
            items: [
              _InfoItem(
                titel: 'Elektrische installatieanalyse',
                tekst:
                    'MijnElektrischeBronnen is een rekentool voor elektrotechnici en installatieontwerpers. '
                    'De app analyseert elektrische installaties met meerdere energiebronnen zoals '
                    'nettrafo\'s, generatoren, PV-omvormers en batterijtechnologie (BESS).',
              ),
              _InfoItem(
                titel: 'Netwerktopologie',
                tekst:
                    'Bronnen en belastingen worden gekoppeld aan een hiërarchisch netwerk van '
                    'hoofd- en onderverdelers. De app berekent de vermogensstroom per verdeler '
                    'en signaleert knelpunten in de topologie.',
              ),
              _InfoItem(
                titel: 'Scenario\'s',
                tekst:
                    'De app doorrekent automatisch vier bedrijfsmodi:\n'
                    '• Netbedrijf — alleen nettrafo\'s actief\n'
                    '• Eilandbedrijf — alleen generatoren actief\n'
                    '• Hybride — alle actieve bronnen gecombineerd\n'
                    '• Noodbedrijf — generatoren en batterijen actief',
              ),
              _InfoItem(
                titel: 'PDF-rapport',
                tekst:
                    'Alle resultaten, scenario\'s en bevindingen worden samengevat in een '
                    'professioneel PDF-rapport dat direct opgeslagen kan worden.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _InfoSectie(
            icon: Icons.calculate_outlined,
            titel: 'Hoe wordt er berekend?',
            kleur: Colors.teal,
            items: [
              _InfoItem(
                titel: 'Kortsluitstroom — maximaal (Ik max)',
                tekst:
                    'De maximale kortsluitstroom is de optelsom van de individuele '
                    'kortsluitbijdragen van alle actieve bronnen in het betreffende scenario:\n\n'
                    'Ik max = Σ Ik_bron  [kA]\n\n'
                    'Dit is de worst-case stroom die een beveiliging moet kunnen uitschakelen. '
                    'Per bron wordt de kortsluitbijdrage ingesteld op basis van het brontype '
                    'en de kortsluitfactor (standaard 10× In voor trafo\'s, instelbaar per bron).',
              ),
              _InfoItem(
                titel: 'Kortsluitstroom — minimaal (Ik min)',
                tekst:
                    'De minimale kortsluitstroom is de laagste individuele kortsluitbijdrage '
                    'van de bronnen in het actieve scenario:\n\n'
                    'Ik min = min(Ik_bron)  [kA]\n\n'
                    'Deze waarde wordt gebruikt om te toetsen of beveiligingen aanspreken '
                    'bij de meest ongunstige foutconditie (enkelfasige fout op het einde '
                    'van een kabel).',
              ),
              _InfoItem(
                titel: 'Vermogenbalans',
                tekst:
                    'Het beschikbare vermogen is de som van het nominale vermogen van alle '
                    'actieve bronnen in het scenario:\n\n'
                    'P_beschikbaar = Σ P_nominaal  [kVA]\n\n'
                    'De installatie wordt als overbelast aangemerkt wanneer de gevraagde '
                    'belasting meer dan 110% van het beschikbare vermogen bedraagt. '
                    'De 10% marge houdt rekening met meetonzekerheid en aanloopstromen.',
              ),
              _InfoItem(
                titel: 'Gelijktijdigheid',
                tekst:
                    'Per belastingveld kan een gelijktijdigheidsfactor (0–100%) per tijdperiode '
                    'worden ingevoerd. Het effectieve vermogen van een veld is:\n\n'
                    'P_effectief = P_geïnstalleerd × g_max  [kVA]\n\n'
                    'waarbij g_max de hoogste gelijktijdigheid over alle ingestelde perioden is. '
                    'Dit effectieve vermogen wordt gebruikt in de vermogenbalans en de '
                    'topologie-analyse.',
              ),
              _InfoItem(
                titel: 'N-1 redundantie',
                tekst:
                    'De N-1 controle toetst of de kritische belasting gedekt blijft wanneer '
                    'de grootste bron uitvalt:\n\n'
                    'P_rest = Σ P_bron − P_grootsteBron\n'
                    'N-1 OK → P_rest ≥ P_kritisch\n\n'
                    'De analyse wordt zowel globaal als per verdeler uitgevoerd. Een installatie '
                    'met slechts één actieve bron slaagt per definitie niet voor N-1.',
              ),
              _InfoItem(
                titel: 'Netwerktopologie per verdeler',
                tekst:
                    'Het beschikbare vermogen voor een onderverdeler is recursief:\n\n'
                    'P_beschikbaar(OV) = P_eigen_bronnen(OV) + P_beschikbaar(parent)\n\n'
                    'Een verdeler wordt als overbelast aangemerkt wanneer de aangesloten '
                    'belasting groter is dan 110% van het beschikbare vermogen. '
                    'Kritische belasting op een verdeler is gedekt als er na uitval van '
                    'de grootste bron nog voldoende vermogen resteert.',
              ),
              _InfoItem(
                titel: 'Selectiviteitscontrole',
                tekst:
                    'Per beveiliging wordt getoetst of deze aanschakelt bij de minimale '
                    'kortsluitstroom:\n\n'
                    '• Instantaan (Ii): Ik min > Ii_werkelijk → directe uitschakeling\n'
                    '• Vertraagd (Isd): Ik min > Isd_werkelijk → thermische uitschakeling\n'
                    '• Icu-toets: Ik_bron > Icu → beveiliging is ondermaat\n\n'
                    'Ik_werkelijk = instelling × In (rekening houdend met tolerantie).',
              ),
            ],
          ),
          SizedBox(height: 12),
          _InfoSectie(
            icon: Icons.warning_amber_outlined,
            titel: 'Overwegingen & beperkingen',
            kleur: Colors.orange,
            items: [
              _InfoItem(
                titel: 'Kabels en impedanties',
                tekst:
                    'De app houdt geen rekening met kabellengte, kabelimpedantie of '
                    'transformatorimpedantie langs de weg. De kortsluitstroom wordt '
                    'direct per bron ingevoerd. Voor nauwkeurige berekeningen conform '
                    'IEC 60909 dient een gedetailleerd netberekeningsprogramma te worden gebruikt.',
              ),
              _InfoItem(
                titel: 'Driehoek- en sterverdeling',
                tekst:
                    'De app rekent uitsluitend met driefasige symmetrische kortsluitstromen. '
                    'Enkelfasige en tweefasige fouten, alsmede aardfouten, worden niet '
                    'afzonderlijk doorgerekend. De ingevoerde Ik min dient door de gebruiker '
                    'te worden bepaald voor de meest ongunstige foutconfiguratie.',
              ),
              _InfoItem(
                titel: 'PV en batterij kortsluitbijdrage',
                tekst:
                    'PV-omvormers en batterijsystemen leveren een beperkte kortsluitbijdrage '
                    '(typisch 1,0–1,5× In) afhankelijk van de omvormer. '
                    'De app waarschuwt wanneer de ingestelde kortsluitfactor ≤ 1,0× In is, '
                    'omdat beveiligingen dan mogelijk niet aanspreken.',
              ),
              _InfoItem(
                titel: 'Asynchrone koppeling',
                tekst:
                    'Wanneer een generator en een nettrafo gelijktijdig actief zijn, '
                    'waarschuwt de app voor asynchroon koppelingsrisico. '
                    'De app berekent geen synchronisatiehoek of faseverschil; '
                    'dit vereist aanvullende meetapparatuur in de installatie.',
              ),
              _InfoItem(
                titel: 'Overbelastingmarge',
                tekst:
                    'Overbelasting wordt gesignaleerd bij > 110% belasting. '
                    'Deze marge is instelbaar noch afwijkend per scenario; '
                    'het is een vaste ontwerpkeuze voor de meldingendrempel.',
              ),
              _InfoItem(
                titel: 'Gegevensopslag',
                tekst:
                    'Alle invoergegevens worden lokaal opgeslagen via shared_preferences. '
                    'Er vindt geen synchronisatie naar een externe server plaats. '
                    'Bij het verwijderen van de app gaan de opgeslagen gegevens verloren.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _InfoSectie(
            icon: Icons.menu_book_outlined,
            titel: 'Normen & richtlijnen',
            kleur: Colors.purple,
            items: [
              _InfoItem(
                titel: 'NEN 1010',
                tekst:
                    'Veiligheidsbepalingen voor laagspanningsinstallaties. '
                    'De app toetst de vermogenbalans, beveiliging en selectiviteit '
                    'op basis van de uitgangspunten van NEN 1010.',
              ),
              _InfoItem(
                titel: 'NEN 3140',
                tekst:
                    'Bedrijfsvoering van elektrische installaties — laagspanning. '
                    'De N-1 aanbeveling en de eis voor redundantie bij kritische '
                    'installaties sluiten aan bij de NEN 3140 bedrijfsvoeringsrichtlijnen.',
              ),
              _InfoItem(
                titel: 'IEC 60909',
                tekst:
                    'Internationale norm voor kortsluitstroomberekeningen in '
                    'driepolige wisselstroomstelsels. De app gebruikt de superpositionemethode '
                    '(sommatie van bronbijdragen) als vereenvoudiging. '
                    'Voor netwerk-impedantieberekeningen conform IEC 60909 is aanvullende '
                    'netberekeningssoftware nodig.',
              ),
              _InfoItem(
                titel: 'IEC 61439',
                tekst:
                    'Norm voor schakel- en besturingsinstallaties. '
                    'De instelwaarden voor beveiligingen (In, Ii, Isd, Icu) '
                    'sluiten aan bij de parameters zoals gedefinieerd in IEC 61439.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _InfoSectie(
            icon: Icons.lightbulb_outline,
            titel: 'Aanbevolen werkwijze',
            kleur: Colors.green,
            items: [
              _InfoItem(
                titel: 'Stap 1 — Netwerk opbouwen',
                tekst:
                    'Begin met het aanmaken van de verdeelstructuur (hoofd- en '
                    'onderverdelers) via het tabblad "Netwerk". '
                    'Zo kan elke bron en belasting worden gekoppeld aan de juiste verdeler.',
              ),
              _InfoItem(
                titel: 'Stap 2 — Bronnen invoeren',
                tekst:
                    'Voer alle energiebronnen in via "Bronnen". '
                    'Geef per bron het nominale vermogen, de kortsluitstroom en '
                    'de kortsluitfactor op. Koppel elke bron aan de bijbehorende verdeler.',
              ),
              _InfoItem(
                titel: 'Stap 3 — Beveiligingen invoeren',
                tekst:
                    'Voer de hoofdbeveiligingen per bron in via "Beveiligingen". '
                    'Geef de instellingswaarden voor In, Ii, Isd en Icu op.',
              ),
              _InfoItem(
                titel: 'Stap 4 — Belasting invoeren',
                tekst:
                    'Voer het totale gevraagde vermogen in en verdeel dit optioneel '
                    'over belastingvelden per verbruiksgroep. '
                    'Stel gelijktijdigheid en tijdperiode per veld in voor realistische analyse. '
                    'Markeer kritische verbruikers (UPS, verlichting vluchtwegen, etc.) '
                    'als "Kritisch".',
              ),
              _InfoItem(
                titel: 'Stap 5 — Berekenen & analyseren',
                tekst:
                    'Druk op "Bereken & analyseer" op het dashboard. '
                    'Alle vier scenario\'s worden doorgerekend. '
                    'Controleer de bevindingen en verhelp eventuele kritische meldingen '
                    'voordat het rapport wordt opgesteld.',
              ),
              _InfoItem(
                titel: 'Stap 6 — PDF exporteren',
                tekst:
                    'Exporteer het rapport via de knop op de resultatenspagina. '
                    'Het PDF-rapport bevat een samenvatting, scenario-vergelijking, '
                    'topologie-overzicht en alle bevindingen per scenario.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _VersieKaart(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Intro kaart ──────────────────────────────────────────────────────────────

class _IntroKaart extends StatelessWidget {
  const _IntroKaart();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.bolt, size: 48, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MijnElektrischeBronnen',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rekentool voor elektrische installaties met meerdere energiebronnen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info sectie ──────────────────────────────────────────────────────────────

class _InfoSectie extends StatefulWidget {
  final IconData icon;
  final String titel;
  final Color kleur;
  final List<_InfoItem> items;

  const _InfoSectie({
    required this.icon,
    required this.titel,
    required this.kleur,
    required this.items,
  });

  @override
  State<_InfoSectie> createState() => _InfoSectieState();
}

class _InfoSectieState extends State<_InfoSectie> {
  bool _uitgevouwen = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _uitgevouwen = !_uitgevouwen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.kleur, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.titel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Icon(
                    _uitgevouwen ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_uitgevouwen) ...[
            const Divider(height: 1),
            ...widget.items.map((item) => _InfoItemWidget(
                  item: item,
                  accentKleur: widget.kleur,
                  isLaatste: item == widget.items.last,
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Info item ────────────────────────────────────────────────────────────────

class _InfoItem {
  final String titel;
  final String tekst;
  const _InfoItem({required this.titel, required this.tekst});
}

class _InfoItemWidget extends StatelessWidget {
  final _InfoItem item;
  final Color accentKleur;
  final bool isLaatste;

  const _InfoItemWidget({
    required this.item,
    required this.accentKleur,
    required this.isLaatste,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(top: 2, right: 10),
                decoration: BoxDecoration(
                  color: accentKleur,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.tekst,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLaatste)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
      ],
    );
  }
}

// ─── Versie kaart ─────────────────────────────────────────────────────────────

class _VersieKaart extends StatelessWidget {
  const _VersieKaart();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Versie-informatie',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _VersieRij('Versie', '1.0.0'),
            _VersieRij('Platform', 'Flutter (iOS / macOS / Windows)'),
            _VersieRij('Normen', 'NEN 1010 · NEN 3140 · IEC 60909 · IEC 61439'),
            _VersieRij('Opslag', 'Lokaal (shared_preferences)'),
            const SizedBox(height: 10),
            Text(
              'Deze app is uitsluitend bedoeld als rekenhulpmiddel. '
              'De gebruiker blijft verantwoordelijk voor de juistheid van '
              'de invoergegevens en de toepassing van de resultaten conform '
              'geldende normen en richtlijnen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersieRij extends StatelessWidget {
  final String label;
  final String waarde;
  const _VersieRij(this.label, this.waarde);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            waarde,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
