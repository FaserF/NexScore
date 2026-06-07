import 'package:flutter/material.dart';
import '../i18n/app_localizations.dart';
import '../services/apk_verification_service.dart';
import '../theme/widgets/glass_container.dart';

class ApkVerificationDialog extends StatefulWidget {
  final ApkVerificationResult initialResult;

  const ApkVerificationDialog({super.key, required this.initialResult});

  static void show(BuildContext context, ApkVerificationResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (context) => ApkVerificationDialog(initialResult: result),
    );
  }

  @override
  State<ApkVerificationDialog> createState() => _ApkVerificationDialogState();
}

class _ApkVerificationDialogState extends State<ApkVerificationDialog> {
  late ApkVerificationResult _result;
  bool _isLoading = false;
  bool _hasAcceptedRisks = false;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
  }

  Future<void> _retryVerification() async {
    setState(() {
      _isLoading = true;
    });

    final newResult = await ApkVerificationService.verifyApk();

    if (mounted) {
      setState(() {
        _result = newResult;
        _isLoading = false;
      });

      if (newResult == ApkVerificationResult.valid || newResult == ApkVerificationResult.notAndroid) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNetworkError = _result == ApkVerificationResult.networkError;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: GlassContainer(
          borderRadius: 28,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isNetworkError ? Colors.orange : Colors.red).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isNetworkError ? Icons.wifi_off : Icons.security_update_warning,
                      color: isNetworkError ? Colors.orange : Colors.red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.get('apk_verify_title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ] else ...[
                Text(
                  isNetworkError
                      ? l10n.get('apk_verify_network_desc')
                      : l10n.get('apk_verify_mismatch_desc'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 16),
                if (!isNetworkError) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('apk_verify_danger_headline'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.get('apk_verify_dangers'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _hasAcceptedRisks,
                          onChanged: (val) {
                            setState(() {
                              _hasAcceptedRisks = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _hasAcceptedRisks = !_hasAcceptedRisks;
                            });
                          },
                          child: Text(
                            l10n.get('apk_verify_checkbox'),
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isNetworkError) ...[
                      ElevatedButton.icon(
                        onPressed: _retryVerification,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.get('apk_verify_btn_retry')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: _retryVerification,
                        child: const Text('Re-Verify'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _hasAcceptedRisks
                            ? () => Navigator.of(context).pop()
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.get('apk_verify_btn_proceed')),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
