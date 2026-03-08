import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/volleyball_models.dart';

class VolleyballPdfService {
  static Future<void> generateAndPrintReport({
    required VolleyballGameState state,
    required Uint8List? signatureA,
    required Uint8List? signatureB,
    required Uint8List? signatureRef,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NexScore - Volleyball Match Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(DateTime.now().toString().split('.')[0]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildTeamInfo(
                    state.teamAName,
                    state.setsWonA,
                    state.teamAPlayers,
                  ),
                  pw.Text(
                    'VS',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  _buildTeamInfo(
                    state.teamBName,
                    state.setsWonB,
                    state.teamBPlayers,
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Set Results:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Set #'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(state.teamAName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(state.teamBName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Winner'),
                      ),
                    ],
                  ),
                  ...List.generate(state.sets.length, (index) {
                    final s = state.sets[index];
                    if (!s.isFinished &&
                        index > 0 &&
                        s.scoreA == 0 &&
                        s.scoreB == 0) {
                      return null;
                    }
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${index + 1}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${s.scoreA}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${s.scoreB}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            s.scoreA > s.scoreB
                                ? state.teamAName
                                : state.teamBName,
                          ),
                        ),
                      ],
                    );
                  }).whereType<pw.TableRow>(),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureSection(
                    'Captain ${state.teamAName}',
                    signatureA,
                  ),
                  _buildSignatureSection('Referee', signatureRef),
                  _buildSignatureSection(
                    'Captain ${state.teamBName}',
                    signatureB,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildTeamInfo(String name, int sets, List<String> players) {
    return pw.Column(
      children: [
        pw.Text(
          name,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Sets Won: $sets', style: const pw.TextStyle(fontSize: 16)),
        if (players.isNotEmpty)
          pw.Text(
            'Players: ${players.join(", ")}',
            style: const pw.TextStyle(fontSize: 10),
          ),
      ],
    );
  }

  static pw.Widget _buildSignatureSection(String label, Uint8List? data) {
    return pw.Column(
      children: [
        if (data != null)
          pw.Image(pw.MemoryImage(data), width: 100, height: 50)
        else
          pw.SizedBox(
            width: 100,
            height: 50,
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide()),
              ),
            ),
          ),
        pw.SizedBox(height: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}
