import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_theme.dart';

class BubbleSuccessScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  const BubbleSuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onButtonPressed,
  });

  @override
  State<BubbleSuccessScreen> createState() => _BubbleSuccessScreenState();
}

class _BubbleSuccessScreenState extends State<BubbleSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
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
            right: -70,
            child: SvgPicture.asset('assets/images/success/ellipse3_blob.svg', width: 329, height: 329),
          ),
          Positioned(
            bottom: -105,
            left: -45,
            child: SvgPicture.asset('assets/images/success/ellipse7_blob.svg', width: 329, height: 329),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: const Alignment(0, 0.4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _scale,
                          child: FadeTransition(
                            opacity: _fade,
                            child: _buildCheckBubble(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: AppText.bold.copyWith(fontSize: 30, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: AppText.regular.copyWith(fontSize: 14, color: AppColors.greyText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 316,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      ),
                      onPressed: widget.onButtonPressed,
                      child: Text(widget.buttonLabel, style: AppText.bold.copyWith(fontSize: 20)),
                    ),
                  ),
                ),
                const Expanded(flex: 3, child: SizedBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBubble() {
    return SizedBox(
      width: 157,
      height: 157,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset('assets/images/success/ellipse6.svg', width: 157, height: 157),
          SvgPicture.asset('assets/images/success/ellipse5.svg', width: 129, height: 129),
          SvgPicture.asset('assets/images/success/ellipse4.svg', width: 95, height: 95),
          SvgPicture.asset('assets/images/success/check_bold.svg', width: 52, height: 52),
        ],
      ),
    );
  }
}
