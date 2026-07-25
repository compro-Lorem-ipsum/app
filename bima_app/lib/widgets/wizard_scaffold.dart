// Scaffold bersama untuk halaman-halaman wizard: menggabungkan
// WizardHeader, area konten, dan tombol aksi di bawah.

import 'package:flutter/material.dart';
import 'primary_button.dart';

class WizardScaffold extends StatelessWidget {
  final Widget header;
  final Widget content;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;

  const WizardScaffold({
    super.key,
    required this.header,
    required this.content,
    required this.buttonLabel,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 20),
                      content,
                      const Spacer(flex: 2),
                      PrimaryButton(label: buttonLabel, onPressed: onButtonPressed),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
