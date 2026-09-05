// Tampilan viewer dokumen in-app (PDF/gambar).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';

import '../../controllers/dokumen/document_viewer_controller.dart';

class DocumentViewerView extends GetView<DocumentViewerController> {
  const DocumentViewerView({super.key});

  static const primaryColor = Color(0xFF122C93);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(controller.nama, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Buka di aplikasi lain',
            onPressed: controller.openExternally,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (controller.hasError.value) {
          return _buildFallback(
            icon: Icons.error_outline,
            message: 'Gagal memuat dokumen.',
          );
        }

        switch (controller.type) {
          case DocumentViewerType.pdf:
            return PdfView(controller: controller.pdfController!);
          case DocumentViewerType.image:
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  controller.url,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Gagal memuat gambar.', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            );
          case DocumentViewerType.unknown:
            return _buildFallback(
              icon: Icons.insert_drive_file,
              message: 'Format file ini tidak didukung untuk dilihat di app.',
            );
        }
      }),
    );
  }

  Widget _buildFallback({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
              onPressed: controller.openExternally,
              child: const Text('Buka di Aplikasi Lain', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
