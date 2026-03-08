import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../core/i18n/app_localizations.dart';

class VolleyballSignatureDialog extends StatefulWidget {
  final String title;
  const VolleyballSignatureDialog({super.key, required this.title});

  @override
  State<VolleyballSignatureDialog> createState() =>
      _VolleyballSignatureDialogState();
}

class _VolleyballSignatureDialogState extends State<VolleyballSignatureDialog> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Signature(
              controller: _controller,
              height: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _controller.clear(),
                icon: const Icon(Icons.clear),
                label: Text(l10n.get('clear')),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('cancel')),
        ),
        FilledButton(
          onPressed: () async {
            if (_controller.isEmpty) return;
            final Uint8List? data = await _controller.toPngBytes();
            if (mounted) Navigator.pop(context, data);
          },
          child: Text(l10n.get('ok')),
        ),
      ],
    );
  }
}
