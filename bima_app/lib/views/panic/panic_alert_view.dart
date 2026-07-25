// Tampilan halaman Panic Alert: kartu identitas & lokasi/GPS, serta
// tombol geser-untuk-konfirmasi yang teksnya ikut bergerak & memudar
// mengikuti posisi geser (bukan sekadar tombol biasa).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/panic/panic_alert_controller.dart';
import '../../widgets/map_preview.dart';

class PanicAlertView extends GetView<PanicAlertController> {
  const PanicAlertView({super.key});

  static const primaryRed = Color(0xFFA80808);
  static const bannerRed = Color(0xFFFF746C);
  static const disabledColor = Color(0xFF8D8787);
  static const abuColor = Color(0xFF6B6B6B);
  static const cardBorderColor = Color(0x33A70202);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDEDE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 23, 22, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: controller.handleBack,
                    child: SvgPicture.asset('assets/icons/panic_back_arrow.svg', width: 26, height: 26),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Panic Alert',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 25, color: primaryRed),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(25, 24, 25, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: bannerRed, borderRadius: BorderRadius.circular(15)),
                      child: const Text(
                        'Gunakan hanya saat situasi darurat. Admin akan menerima notifikasi seketika beserta lokasi Anda berada.',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildIdentitasCard(),
                    const SizedBox(height: 16),
                    _buildLokasiCard(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 12, 21, 24),
              child: Obx(
                () => _SlideToConfirm(
                  enabled: controller.isGpsActive.value && !controller.isSending.value,
                  onConfirmed: controller.confirmAndSend,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitasCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'IDENTITAS',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black),
                ),
                TextSpan(
                  text: ' · OTOMATIS DARI AKUN',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12, color: abuColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SvgPicture.asset('assets/icons/panic_avatar_icon.svg', width: 45, height: 45),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.namaSatpam,
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.nip,
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 10, color: abuColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLokasiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'LOKASI',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black),
                    ),
                    const TextSpan(
                      text: ' · OTOMATIS DARI GPS',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12, color: abuColor),
                    ),
                  ],
                ),
              ),
              Obx(() => _buildGpsBadge(controller.isGpsActive.value)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            controller.lokasiPos,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Obx(() => MapPreview(
                latitude: double.tryParse(controller.latitude.value),
                longitude: double.tryParse(controller.longitude.value),
              )),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              controller.koordinatText,
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 12, color: abuColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsBadge(bool active) {
    final bgColor = active ? const Color(0xFFDCFCE7) : const Color(0xFFFFE2E2);
    final fgColor = active ? const Color(0xFF008236) : const Color(0xFFC10007);
    return Container(
      height: 15,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(
        active ? 'GPS Aktif' : 'GPS Mati',
        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 9, color: fgColor),
      ),
    );
  }
}

class _SlideToConfirm extends StatefulWidget {
  final bool enabled;
  final Future<bool> Function() onConfirmed;

  const _SlideToConfirm({required this.enabled, required this.onConfirmed});

  @override
  State<_SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<_SlideToConfirm> with SingleTickerProviderStateMixin {
  static const double _height = 55;
  static const double _thumbSize = 45;
  static const double _thumbInset = 5;
  static const Duration _snapDuration = Duration(milliseconds: 280);

  late final AnimationController _snapController;
  Tween<double> _snapTween = Tween<double>(begin: 0, end: 0);

  double _dragX = 0;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: _snapDuration)
      ..addListener(() {
        setState(() {
          _dragX = _snapTween.transform(Curves.easeOutCubic.transform(_snapController.value));
        });
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  /// Eases `_dragX` from its current value to [target] over [_snapDuration].
  /// Used both for the "release before threshold" snap-back and the
  /// "release past threshold" snap-forward, so the thumb never jumps.
  Future<void> _animateTo(double target) {
    _snapTween = Tween<double>(begin: _dragX, end: target);
    return _snapController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _SlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _snapController.stop();
      setState(() {
        _dragX = 0;
        _confirmed = false;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled || _confirmed) return;
    // Let the user re-grab the thumb mid snap-back/forward instead of
    // fighting the animation.
    _snapController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (!widget.enabled || _confirmed) return;
    setState(() {
      _dragX = (_dragX + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  Future<void> _handleDragEnd(double maxDrag) async {
    if (!widget.enabled || _confirmed) return;
    if (_dragX >= maxDrag * 0.8) {
      await _animateTo(maxDrag);
      if (!mounted) return;
      setState(() => _confirmed = true);
      final sent = await widget.onConfirmed();
      if (!sent && mounted) {
        await _animateTo(0);
        if (mounted) setState(() => _confirmed = false);
      }
    } else {
      await _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - (_thumbInset * 2);
        final textOpacity = widget.enabled ? 1.0 : 0.7;
        final dragProgress = maxDrag > 0 ? (_dragX / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: double.infinity,
              height: _height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFFF746C),
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(_dragX, 0),
                child: Opacity(
                  opacity: ((1 - dragProgress * 1.4) * textOpacity).clamp(0.0, 1.0),
                  child: const Text(
                    'Geser untuk mengirim Panic Alert',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: _thumbInset + _dragX,
              child: GestureDetector(
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: (details) => _handleDragUpdate(details, maxDrag),
                onHorizontalDragEnd: (_) => _handleDragEnd(maxDrag),
                child: SizedBox(
                  width: _thumbSize,
                  height: _thumbSize,
                  child: SvgPicture.asset('assets/icons/panic_slide_icon.svg', fit: BoxFit.contain),
                ),
              ),
            ),
            if (!widget.enabled)
              Container(
                width: double.infinity,
                height: _height,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
          ],
        );
      },
    );
  }
}
