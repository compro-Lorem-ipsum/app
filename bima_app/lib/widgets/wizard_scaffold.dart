// Scaffold bersama untuk halaman-halaman wizard: menggabungkan
// WizardHeader, area konten, dan tombol aksi di bawah.
//
// Tombol bawah default-nya solid biru (PrimaryButton). Halaman yang perlu
// menampilkan aksi bergaya lain di posisi yang sama — mis. "Upload Ulang"
// outline merah saat foto ditolak backend (Figma node 44:1055) — bisa
// mengatur [buttonOutlined], [buttonColor], dan [buttonTextColor].

import 'package:flutter/material.dart';
import 'primary_button.dart';

class WizardScaffold extends StatelessWidget {
  final Widget header;
  final Widget content;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;
  final bool buttonOutlined;
  final Color? buttonColor;
  final Color? buttonTextColor;

  const WizardScaffold({
    super.key,
    required this.header,
    required this.content,
    required this.buttonLabel,
    required this.onButtonPressed,
    this.buttonOutlined = false,
    this.buttonColor,
    this.buttonTextColor,
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
                      PrimaryButton(
                        label: buttonLabel,
                        onPressed: onButtonPressed,
                        outlined: buttonOutlined,
                        color: buttonColor,
                        textColor: buttonTextColor,
                      ),
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
