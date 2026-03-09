import 'dart:typed_data';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../models/volleyball_models.dart';

class VolleyballPdfService {
  static Future<void> generateAndPrintReport({
    required BuildContext context,
    required VolleyballGameState state,
    required Uint8List? signatureA,
    required Uint8List? signatureB,
    required Uint8List? signatureRef,
  }) async {
    final l10n = AppLocalizations.of(context);
    final pdf = pw.Document();
    final (lpA, lpB) = state.leaguePoints;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NexScore',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      l10n.get('game_volleyball').toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      DateTime.now().toString().split(' ')[0],
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'MATCH REPORT #${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 20),

            // Match Summary Card
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildTeamSummary(
                        state.teamAName,
                        state.setsWonA,
                        lpA,
                        PdfColors.blue800,
                        l10n,
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'VS',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey400,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                            ),
                            child: pw.Text(
                              state.type == VolleyballType.indoor
                                  ? l10n.get('vb_indoor')
                                  : l10n.get('vb_beach'),
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildTeamSummary(
                        state.teamBName,
                        state.setsWonB,
                        lpB,
                        PdfColors.red800,
                        l10n,
                      ),
                    ],
                  ),
                  if (state.earlyFinished) ...[
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange100,
                        borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Text(
                        'EARLY FINISH - OFFICIAL LEAGUE RESULT',
                        style: pw.TextStyle(
                          color: PdfColors.orange900,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Sets Detail Table
            pw.Text(
              '${l10n.get('vb_sets').toUpperCase()} DETAILS',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(),
                2: const pw.FlexColumnWidth(),
                3: const pw.FixedColumnWidth(100),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableHeader('#'),
                    _tableHeader(state.teamAName),
                    _tableHeader(state.teamBName),
                    _tableHeader('WINNER'),
                  ],
                ),
                ...List.generate(state.sets.length, (index) {
                  final s = state.sets[index];
                  // Hide unplayed sets unless it's the current one that just ended
                  if (!s.isFinished &&
                      index > 0 &&
                      s.scoreA == 0 &&
                      s.scoreB == 0)
                    return null;

                  return pw.TableRow(
                    children: [
                      _tableCell('${index + 1}'),
                      _tableCell('${s.scoreA}', bold: s.scoreA > s.scoreB),
                      _tableCell('${s.scoreB}', bold: s.scoreB > s.scoreA),
                      _tableCell(
                        s.scoreA > s.scoreB ? state.teamAName : state.teamBName,
                        bold: true,
                        color: s.scoreA > s.scoreB
                            ? PdfColors.blue
                            : PdfColors.red,
                      ),
                    ],
                  );
                }).whereType<pw.TableRow>(),
              ],
            ),

            pw.SizedBox(height: 60),

            // Signatures Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildProfessionalSignature(
                  'CAPTAIN ${state.teamAName}',
                  signatureA,
                  PdfColors.blue900,
                ),
                _buildProfessionalSignature(
                  'OFFICIAL REFEREE',
                  signatureRef,
                  PdfColors.grey900,
                ),
                _buildProfessionalSignature(
                  'CAPTAIN ${state.teamBName}',
                  signatureB,
                  PdfColors.red900,
                ),
              ],
            ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by NexScore - nexscore.app',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                ),
                pw.Text(
                  'Page 1 of 1',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'NexScore_Volleyball_${state.teamAName}_vs_${state.teamBName}.pdf',
    );
  }

  static pw.Widget _buildTeamSummary(
    String name,
    int sets,
    int leaguePoints,
    PdfColor color,
    AppLocalizations l10n,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          name.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Text(
              '${l10n.get('vb_sets')}: ',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              '$sets',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Row(
          children: [
            pw.Text(
              '${l10n.get('vb_points_ab')}: ',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              '$leaguePoints',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildProfessionalSignature(
    String label,
    Uint8List? data,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Container(
          width: 120,
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey200),
            color: PdfColors.white,
          ),
          child: data != null
              ? pw.Center(
                  child: pw.Image(pw.MemoryImage(data), fit: pw.BoxFit.contain),
                )
              : pw.SizedBox(),
        ),
        pw.SizedBox(height: 6),
        pw.Container(width: 120, height: 1.5, color: color),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
