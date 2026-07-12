import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Fullscreen overlay representing what OTHER users see when a panic alert
/// is broadcast (e.g. invoked from a push-notification handler). This is
/// intentionally NOT a routed `GetPage` — there is no "other user" context
/// reachable via normal in-app navigation.
Future<void> showPanicAlertReceivedOverlay() {
  return Get.dialog(
    const PopScope(
      canPop: false,
      child: _PanicAlertReceivedOverlay(),
    ),
    barrierDismissible: false,
    barrierColor: Colors.transparent,
  );
}

class _PanicAlertReceivedOverlay extends StatefulWidget {
  const _PanicAlertReceivedOverlay();

  static const panicRed = Color(0xFFFF746C);
  static const iconCircleColor = Color(0xFFFFB6B2);
  static const _countdownStart = 10;

  @override
  State<_PanicAlertReceivedOverlay> createState() => _PanicAlertReceivedOverlayState();
}

class _PanicAlertReceivedOverlayState extends State<_PanicAlertReceivedOverlay> {
  late int _secondsLeft = _PanicAlertReceivedOverlay._countdownStart;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) Get.back();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTutup() {
    _timer?.cancel();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PanicAlertReceivedOverlay.panicRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              SizedBox(
                width: 157,
                height: 157,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 157,
                      height: 157,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    Container(
                      width: 129,
                      height: 129,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    Container(
                      width: 95,
                      height: 95,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _PanicAlertReceivedOverlay.iconCircleColor),
                    ),
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 46),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Panic Alert',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 30, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Segera berikan bantuan atau hubungi pihak terkait untuk menindaklanjuti situasi darurat ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  onPressed: _handleTutup,
                  child: Text(
                    'Tutup ($_secondsLeft)',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Color(0xFFA80808),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
