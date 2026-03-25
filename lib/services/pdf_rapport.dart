import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/resultaten.dart';
import '../models/enums.dart';
import '../state/installatie_provider.dart';

class PdfRapport {
  static Future<void> drukAf(
    BuildContext context,
    InstallatieProvider provider,
    AnalyseResultaten resultaten,
  ) async {
    final fontBase = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final fontItalic = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontBase,
        bold: fontBold,
        italic: fontItalic,
      ),
      title: 'MijnBronnen Rapport',
    );

    // --- Pagina 1: Samenvatting ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        header: (_) => _paginaHeader(),
        footer: (ctx) => _paginaFooter(ctx, resultaten),
        build: (ctx) => [
          _installatieInfoBlok(provider, resultaten.berekendeOp),
          pw.SizedBox(height: 16),
          _overzichtSamenvattingBlok(resultaten),
          pw.SizedBox(height: 16),
          _scenarioVergelijkingBlok(resultaten),
          pw.SizedBox(height: 16),
          _globaleBevindingenBlok(resultaten),
        ],
      ),
    );

    // --- Per scenario: detail pagina's ---
    for (final modus in BedrijfsModus.values) {
      final s = resultaten.alleScenarios[modus];
      if (s == null) continue;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          header: (_) => _paginaHeader(),
          footer: (ctx) => _paginaFooter(ctx, resultaten),
          build: (ctx) => [
            _scenarioTitelBlok(s),
            pw.SizedBox(height: 12),
            _scenarioSamenvattingBlok(s),
            pw.SizedBox(height: 16),
            if (s.verdelerResultaten.isNotEmpty) ...[
              _verdelerBlok(s),
              pw.SizedBox(height: 16),
            ],
            _bronnenBlok(s),
            pw.SizedBox(height: 16),
            if (s.beveiligingResultaten.isNotEmpty) ...[
              _selectiviteitBlok(s),
              pw.SizedBox(height: 16),
            ],
            _foutenBlok(s),
          ],
        ),
      );
    }

    final bytes = await pdf.save();
    final now = DateTime.now();
    final bestandsnaam = 'mijnbronnen_rapport_${_datumString(now)}.pdf';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Rapport opslaan',
      fileName: bestandsnaam,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (savePath != null) {
      await File(savePath).writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport opgeslagen: $savePath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ======== Header / Footer ========

  static pw.Widget _paginaHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MijnBronnen - Elektrische Installatie Rapport',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.Text(
              'NEN 1010 / NEN 3140 / IEC 60909',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400),
            ),
          ],
        ),
        pw.Divider(color: PdfColors.blueGrey300, thickness: 0.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _paginaFooter(pw.Context ctx, AnalyseResultaten resultaten) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.blueGrey200, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Gegenereerd op ${_datumTijdString(resultaten.berekendeOp)}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey400),
            ),
            pw.Text(
              'Pagina ${ctx.pageNumber} van ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey400),
            ),
          ],
        ),
      ],
    );
  }

  // ======== Pagina 1: Samenvatting ========

  static pw.Widget _installatieInfoBlok(
    InstallatieProvider provider,
    DateTime berekendeOp,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Installatie overzicht',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _metaItem('Netspanning', '${provider.netspanning.toStringAsFixed(0)} V'),
              _metaItem('Frequentie', '${provider.frequentie.toStringAsFixed(0)} Hz'),
              _metaItem('cos fi', provider.cosFi.toStringAsFixed(2)),
              _metaItem('Berekend op', _datumTijdString(berekendeOp)),
              _metaItem(
                'Scenario\'s',
                '${BedrijfsModus.values.length} doorgerekend',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _overzichtSamenvattingBlok(AnalyseResultaten resultaten) {
    final scenarios = resultaten.alleScenarios;

    // Bepaal globale status
    final alleOverbelast = scenarios.values.any((s) => s.overbelast);
    final alleNMinEenFout = scenarios.values.any((s) => !s.nMinEenOk);
    final totaalKritisch = scenarios.values.fold<int>(0, (som, s) => som + s.aantalKritiek);
    final totaalWaarschuwingen =
        scenarios.values.fold<int>(0, (som, s) => som + s.aantalWaarschuwingen);

    final statusKleur = alleOverbelast || totaalKritisch > 0
        ? PdfColors.red700
        : alleNMinEenFout || totaalWaarschuwingen > 0
            ? PdfColors.orange700
            : PdfColors.green700;
    final statusTekst = alleOverbelast
        ? 'Kritisch - overbelasting geconstateerd'
        : totaalKritisch > 0
            ? 'Kritisch - bevindingen aanwezig'
            : alleNMinEenFout
                ? 'Waarschuwing - N-1 niet gewaarborgd'
                : totaalWaarschuwingen > 0
                    ? 'Waarschuwing - aandachtspunten aanwezig'
                    : 'Goed - alle controles geslaagd';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectieHeader('Samenvatting', PdfColors.blueGrey800),
        pw.SizedBox(height: 8),
        // Globale statusbanner
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: statusKleur,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            statusTekst,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        // Statistieken
        pw.Row(
          children: [
            _statKaart(
              'Kritische meldingen',
              '$totaalKritisch',
              totaalKritisch > 0 ? PdfColors.red700 : PdfColors.green700,
            ),
            pw.SizedBox(width: 8),
            _statKaart(
              'Waarschuwingen',
              '$totaalWaarschuwingen',
              totaalWaarschuwingen > 0 ? PdfColors.orange700 : PdfColors.green700,
            ),
            pw.SizedBox(width: 8),
            _statKaart(
              'Overbelaste scenario\'s',
              '${scenarios.values.where((s) => s.overbelast).length} / ${scenarios.length}',
              alleOverbelast ? PdfColors.red700 : PdfColors.green700,
            ),
            pw.SizedBox(width: 8),
            _statKaart(
              'N-1 gewaarborgd',
              '${scenarios.values.where((s) => s.nMinEenOk).length} / ${scenarios.length}',
              alleNMinEenFout ? PdfColors.orange700 : PdfColors.green700,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _statKaart(String label, String waarde, PdfColor kleur) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: kleur, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          color: kleur.shade(0.92),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey600)),
            pw.SizedBox(height: 4),
            pw.Text(waarde,
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold, color: kleur)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _scenarioVergelijkingBlok(AnalyseResultaten resultaten) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectieHeader('Scenario vergelijking', PdfColors.blueGrey700),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.2),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.4),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1),
            6: const pw.FlexColumnWidth(1),
            7: const pw.FlexColumnWidth(1),
          },
          children: [
            _tabelHeader([
              'Scenario',
              'Beschikbaar (kVA)',
              'Belasting (kVA)',
              'Belastingsgraad',
              'Ik max (kA)',
              'Overbelast',
              'N-1',
              'Kritisch',
            ]),
            ...BedrijfsModus.values.map((modus) {
              final s = resultaten.alleScenarios[modus];
              if (s == null) {
                return pw.TableRow(children: List.filled(8, _cel('-')));
              }
              final graad = s.beschikbaarVermogen > 0
                  ? s.gevraagdVermogen / s.beschikbaarVermogen * 100
                  : 0.0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: s.overbelast ? PdfColors.red50 : null,
                ),
                children: [
                  _cel(_scenarioLabel(modus),
                      bold: s == resultaten.huidigScenario),
                  _cel(s.beschikbaarVermogen.toStringAsFixed(0),
                      align: pw.Alignment.centerRight),
                  _cel(s.gevraagdVermogen.toStringAsFixed(0),
                      align: pw.Alignment.centerRight),
                  _cel('${graad.toStringAsFixed(1)}%',
                      align: pw.Alignment.centerRight,
                      kleur: graad > 100
                          ? PdfColors.red700
                          : graad > 80
                              ? PdfColors.orange700
                              : null),
                  _cel(s.totaleIkMax.toStringAsFixed(3),
                      align: pw.Alignment.centerRight),
                  _cel(s.overbelast ? 'Ja' : 'Nee',
                      kleur: s.overbelast ? PdfColors.red700 : PdfColors.green700,
                      bold: s.overbelast),
                  _cel(s.nMinEenOk ? 'OK' : 'Nee',
                      kleur:
                          s.nMinEenOk ? PdfColors.green700 : PdfColors.orange700),
                  _cel(s.aantalKritiek > 0 ? '${s.aantalKritiek}' : '-',
                      kleur: s.aantalKritiek > 0 ? PdfColors.red700 : null,
                      bold: s.aantalKritiek > 0),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _globaleBevindingenBlok(AnalyseResultaten resultaten) {
    // Verzamel unieke kritische meldingen over alle scenario's
    final kritisch = <String>{};
    final waarschuwingen = <String>{};

    for (final s in resultaten.alleScenarios.values) {
      for (final f in s.fouten) {
        if (f.niveau == FoutNiveau.kritisch) kritisch.add(f.titel);
        if (f.niveau == FoutNiveau.waarschuwing) waarschuwingen.add(f.titel);
      }
    }

    if (kritisch.isEmpty && waarschuwingen.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          border: pw.Border.all(color: PdfColors.green300, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          'Geen kritische bevindingen over alle scenario\'s - alle controles geslaagd.',
          style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.green800,
              fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectieHeader('Globale bevindingen (alle scenario\'s)', PdfColors.red700),
        pw.SizedBox(height: 6),
        if (kritisch.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              border: pw.Border.all(color: PdfColors.red300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Kritisch',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700)),
                pw.SizedBox(height: 4),
                ...kritisch.map((t) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text('- $t',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.red900)),
                    )),
              ],
            ),
          ),
        if (kritisch.isNotEmpty && waarschuwingen.isNotEmpty) pw.SizedBox(height: 6),
        if (waarschuwingen.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Waarschuwingen',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange700)),
                pw.SizedBox(height: 4),
                ...waarschuwingen.map((t) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text('- $t',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.orange900)),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  // ======== Per-scenario pagina's ========

  static pw.Widget _scenarioTitelBlok(ScenarioResultaat s) {
    final statusKleur = s.overbelast
        ? PdfColors.red700
        : s.aantalKritiek > 0
            ? PdfColors.red700
            : s.aantalWaarschuwingen > 0
                ? PdfColors.orange700
                : PdfColors.green700;
    final statusTekst = s.overbelast
        ? 'OVERBELAST'
        : s.aantalKritiek > 0
            ? '${s.aantalKritiek} kritische melding(en)'
            : s.aantalWaarschuwingen > 0
                ? '${s.aantalWaarschuwingen} waarschuwing(en)'
                : 'Geen bevindingen';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey700,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Scenario: ${_scenarioLabel(s.modus)}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: statusKleur,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              statusTekst,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _scenarioSamenvattingBlok(ScenarioResultaat s) {
    final graad = s.beschikbaarVermogen > 0
        ? s.gevraagdVermogen / s.beschikbaarVermogen * 100
        : 0.0;

    return pw.Row(
      children: [
        _waardeKaart('Ik max',
            '${s.totaleIkMax.toStringAsFixed(3)} kA', 'Maximale kortsluitstroom',
            PdfColors.red700),
        pw.SizedBox(width: 8),
        _waardeKaart('Ik min',
            '${s.totaleIkMin.toStringAsFixed(3)} kA', 'Minimale kortsluitstroom',
            PdfColors.orange700),
        pw.SizedBox(width: 8),
        _waardeKaart('Beschikbaar',
            '${s.beschikbaarVermogen.toStringAsFixed(0)} kVA', 'Actieve bronnen',
            PdfColors.blue700),
        pw.SizedBox(width: 8),
        _waardeKaart('Belasting',
            '${s.gevraagdVermogen.toStringAsFixed(0)} kVA',
            'Belastingsgraad ${graad.toStringAsFixed(1)}%',
            s.overbelast ? PdfColors.red700 : PdfColors.green700),
        pw.SizedBox(width: 8),
        _waardeKaart('N-1',
            s.nMinEenOk ? 'Gedekt' : 'Ongedekt', 'Redundantie kritische last',
            s.nMinEenOk ? PdfColors.green700 : PdfColors.orange700),
      ],
    );
  }

  // ======== Blokken (hergebruikt per scenario) ========

  static pw.Widget _verdelerBlok(ScenarioResultaat scenario) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectieHeader('Netwerktopologie', PdfColors.teal700),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1.2),
          },
          children: [
            _tabelHeader([
              'Verdeler',
              'Lokaal (kVA)',
              'Beschikbaar (kVA)',
              'Belasting (kVA)',
              'Kritisch (kVA)',
              'Status',
            ]),
            ...scenario.verdelerResultaten.map((vr) {
              final status = vr.overbelast
                  ? 'Overbelast'
                  : vr.heeftKritischeBelasting && !vr.kritischGedekt
                      ? 'Kritisch ongedekt'
                      : vr.beschikbaarVermogen == 0 && vr.heeftBelasting
                          ? 'Geen voeding'
                          : 'OK';
              final statusKleur = vr.overbelast
                  ? PdfColors.red700
                  : vr.heeftKritischeBelasting && !vr.kritischGedekt
                      ? PdfColors.orange700
                      : PdfColors.green700;

              return pw.TableRow(children: [
                _cel('${vr.isHoofdverdeler ? "HV" : "OV"}  ${vr.verdelerNaam}'),
                _cel(vr.lokaalVermogen.toStringAsFixed(0),
                    align: pw.Alignment.centerRight),
                _cel(vr.beschikbaarVermogen.toStringAsFixed(0),
                    align: pw.Alignment.centerRight),
                _cel(
                  vr.heeftBelasting ? vr.gevraagdVermogen.toStringAsFixed(0) : '-',
                  align: pw.Alignment.centerRight,
                ),
                _cel(
                  vr.heeftKritischeBelasting
                      ? vr.kritischVermogen.toStringAsFixed(0)
                      : '-',
                  align: pw.Alignment.centerRight,
                  kleur: vr.heeftKritischeBelasting && !vr.kritischGedekt
                      ? PdfColors.orange700
                      : null,
                ),
                _cel(status, kleur: statusKleur, bold: true),
              ]);
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _bronnenBlok(ScenarioResultaat scenario) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectieHeader('Energiebronnen', PdfColors.blue700),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            _tabelHeader(['Bron', 'In (A)', 'Ik (kA)', 'Status']),
            ...scenario.bronResultaten.map((b) => pw.TableRow(children: [
                  _cel(b.bronNaam),
                  _cel(b.nominaleStroom.toStringAsFixed(1),
                      align: pw.Alignment.centerRight),
                  _cel((b.kortsluitStroom / 1000).toStringAsFixed(3),
                      align: pw.Alignment.centerRight),
                  _cel(
                    b.actief ? 'Actief' : 'Inactief',
                    kleur: b.actief ? PdfColors.green700 : PdfColors.grey500,
                    bold: true,
                  ),
                ])),
          ],
        ),
      ],
    );
  }

  static pw.Widget _selectiviteitBlok(ScenarioResultaat scenario) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectieHeader('Selectiviteitscontrole', PdfColors.purple700),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            _tabelHeader(['Beveiliging', 'Bron', 'Opmerking', 'Status']),
            ...scenario.beveiligingResultaten.map((bev) {
              final ok = bev.selectiviteit == SelectiviteitStatus.ok &&
                  !bev.overschrijdtIcu;
              return pw.TableRow(children: [
                _cel(bev.beveiligingNaam),
                _cel(bev.bronNaam),
                _cel(bev.opmerking),
                _cel(
                  ok ? 'OK' : bev.overschrijdtIcu ? 'Icu!' : 'Fout',
                  kleur: ok ? PdfColors.green700 : PdfColors.red700,
                  bold: true,
                ),
              ]);
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _foutenBlok(ScenarioResultaat scenario) {
    if (scenario.fouten.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          border: pw.Border.all(color: PdfColors.green300, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          'Geen bevindingen voor dit scenario - alle controles geslaagd.',
          style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.green800,
              fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    final kritisch =
        scenario.fouten.where((f) => f.niveau == FoutNiveau.kritisch).toList();
    final waarschuwingen =
        scenario.fouten.where((f) => f.niveau == FoutNiveau.waarschuwing).toList();
    final info =
        scenario.fouten.where((f) => f.niveau == FoutNiveau.informatief).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectieHeader('Bevindingen', PdfColors.red700),
        pw.SizedBox(height: 6),
        if (kritisch.isNotEmpty) ...[
          _foutGroep('Kritisch', kritisch, PdfColors.red700, PdfColors.red50),
          pw.SizedBox(height: 6),
        ],
        if (waarschuwingen.isNotEmpty) ...[
          _foutGroep('Waarschuwingen', waarschuwingen, PdfColors.orange700,
              PdfColors.orange50),
          pw.SizedBox(height: 6),
        ],
        if (info.isNotEmpty)
          _foutGroep('Informatief', info, PdfColors.blue700, PdfColors.blue50),
      ],
    );
  }

  static pw.Widget _foutGroep(
    String titel,
    List<FoutMelding> fouten,
    PdfColor kleur,
    PdfColor achtergrond,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: kleur, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: kleur,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(3),
                topRight: pw.Radius.circular(3),
              ),
            ),
            child: pw.Text(
              '$titel (${fouten.length})',
              style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold),
            ),
          ),
          ...fouten.map((f) => pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: achtergrond,
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: kleur.shade(0.3), width: 0.3)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(f.titel,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: kleur)),
                    pw.SizedBox(height: 2),
                    pw.Text(f.beschrijving,
                        style: const pw.TextStyle(fontSize: 8)),
                    if (f.aanbeveling != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text('> ${f.aanbeveling}',
                          style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.blueGrey600,
                              fontStyle: pw.FontStyle.italic)),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ======== Hulp widgets ========

  static pw.Widget _sectieHeader(String titel, PdfColor kleur) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 14,
          decoration: pw.BoxDecoration(
            color: kleur,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(titel,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: kleur)),
      ],
    );
  }

  static pw.Widget _metaItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.blueGrey500)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _waardeKaart(
      String label, String waarde, String sublabel, PdfColor kleur) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: kleur.shade(0.5), width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          color: kleur.shade(0.9),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 8,
                    color: kleur,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(waarde,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: kleur)),
            pw.Text(sublabel,
                style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _tabelHeader(List<String> kolommen) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      children: kolommen
          .map((k) => pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Text(k,
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  static pw.Widget _cel(
    String tekst, {
    pw.Alignment align = pw.Alignment.centerLeft,
    PdfColor? kleur,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          tekst,
          style: pw.TextStyle(
            fontSize: 9,
            color: kleur,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ======== Datum helpers ========

  static String _datumString(DateTime dt) =>
      '${dt.year}${_pad(dt.month)}${_pad(dt.day)}_${_pad(dt.hour)}${_pad(dt.minute)}';

  static String _datumTijdString(DateTime dt) =>
      '${_pad(dt.day)}-${_pad(dt.month)}-${dt.year}  '
      '${_pad(dt.hour)}:${_pad(dt.minute)}';

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _scenarioLabel(BedrijfsModus modus) {
    switch (modus) {
      case BedrijfsModus.netbedrijf:
        return 'Netbedrijf';
      case BedrijfsModus.eilandbedrijf:
        return 'Eilandbedrijf';
      case BedrijfsModus.hybride:
        return 'Hybride';
      case BedrijfsModus.noodbedrijf:
        return 'Noodbedrijf';
    }
  }
}
