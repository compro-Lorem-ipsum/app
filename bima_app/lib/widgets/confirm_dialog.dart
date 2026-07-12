import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_theme.dart';

Future<bool?> showConfirmDialog({
  required String title,
  required String message,
  String cancelLabel = 'Batal',
  String confirmLabel = 'Kirim',
  int countdownSeconds = 0,
  Color accentColor = AppColors.primary,
}) {
  return Get.dialog<bool>(
    _ConfirmDialogContent(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      countdownSeconds: countdownSeconds,
      accentColor: accentColor,
    ),
    barrierDismissible: false,
  );
}

class _ConfirmDialogContent extends StatefulWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final int countdownSeconds;
  final Color accentColor;

  const _ConfirmDialogContent({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.countdownSeconds,
    required this.accentColor,
  });

  @override
  State<_ConfirmDialogContent> createState() => _ConfirmDialogContentState();
}

class _ConfirmDialogContentState extends State<_ConfirmDialogContent> {
  late int _secondsLeft = widget.countdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _secondsLeft <= 0;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, textAlign: TextAlign.center, style: AppText.bold.copyWith(fontSize: 16, color: widget.accentColor)),
            const SizedBox(height: 10),
            Text(widget.message, textAlign: TextAlign.center, style: AppText.regular.copyWith(fontSize: 13, color: AppColors.disabled)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.accentColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(widget.cancelLabel, style: TextStyle(fontFamily: 'Poppins', color: widget.accentColor)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canConfirm ? () => Get.back(result: true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      canConfirm ? widget.confirmLabel : '${widget.confirmLabel} ($_secondsLeft)',
                      style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
