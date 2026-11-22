// Halaman Splash / Intro aplikasi yang menampilkan logo dan nama
// perusahaan "PT Bima Global Security" dengan animasi sebelum masuk ke
// halaman Login (atau Beranda jika sesi login "Ingat Saya" masih aktif).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../services/panic_alert_notification_service.dart';
import '../../widgets/app_theme.dart';

class SplashIntroView extends StatefulWidget {
  final String nextRoute;
  final String? pendingNotificationPayload;

  const SplashIntroView({
    super.key,
    required this.nextRoute,
    this.pendingNotificationPayload,
  });

  @override
  State<SplashIntroView> createState() => _SplashIntroViewState();
}

class _SplashIntroViewState extends State<SplashIntroView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.06).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65)),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    );

    _ringScale = Tween<double>(begin: 0.75, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic)),
    );

    _ringFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.35), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 0.35, end: 0.0), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.90)),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic)),
    );

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.80, curve: Curves.easeIn),
    );

    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    _navTimer = Timer(const Duration(milliseconds: 2500), _proceed);
  }

  void _proceed() {
    if (!mounted) return;
    Get.offAllNamed(widget.nextRoute);
    final payload = widget.pendingNotificationPayload;
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PanicAlertNotificationService.navigateFromPayload(payload);
      });
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -105,
            right: -85,
            child: SvgPicture.asset('assets/images/success/ellipse3_blob.svg', width: 329, height: 329),
          ),
          Positioned(
            bottom: -105,
            left: -55,
            child: SvgPicture.asset('assets/images/success/ellipse7_blob.svg', width: 329, height: 329),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _ringScale.value,
                              child: Opacity(
                                opacity: _ringFade.value,
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        children: [
                          Text(
                            'PT Bima Global Security',
                            textAlign: TextAlign.center,
                            style: AppText.bold.copyWith(
                              fontSize: 22,
                              color: AppColors.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 48,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Sistem Manajemen Operasional & Kehadiran Personel',
                      textAlign: TextAlign.center,
                      style: AppText.regular.copyWith(
                        fontSize: 12,
                        color: AppColors.greyText,
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'BIMA GLOBAL SECURITY · v2.0.0',
                          style: AppText.semiBold.copyWith(
                            fontSize: 10,
                            color: AppColors.disabled,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
