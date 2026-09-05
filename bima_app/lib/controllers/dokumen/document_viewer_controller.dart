// Controller untuk viewer dokumen in-app (PDF/gambar) — dipakai dari
// Dokumen Repositori (rep_doks_controller.dart), sebelumnya cuma
// launchUrl ke browser eksternal.
//
// PDF dirender lewat pdfx (MIT, tanpa lisensi berbayar) — package ini
// tidak bisa langsung stream dari URL, jadi file diunduh penuh dulu ke
// memori (http.get) baru dibuka lewat PdfDocument.openData(). Untuk
// dokumen berukuran wajar (shared-documents dibatasi lewat GCS) ini
// cukup cepat; kalau gagal (jaringan/format tak terduga), tetap ada
// tombol "Buka di Aplikasi Lain" sebagai jalan keluar (url_launcher).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

enum DocumentViewerType { pdf, image, unknown }

class DocumentViewerController extends GetxController {
  late final String url;
  late final String nama;
  late final DocumentViewerType type;

  final isLoading = true.obs;
  final hasError = false.obs;
  PdfController? pdfController;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final data = args is Map ? args : const <String, dynamic>{};
    url = (data['url'] as String?) ?? '';
    nama = (data['nama'] as String?) ?? 'Dokumen';
    type = _detectType(nama, url);

    if (type == DocumentViewerType.pdf) {
      _loadPdf();
    } else {
      isLoading.value = false;
    }
  }

  DocumentViewerType _detectType(String nama, String url) {
    final lower = '$nama $url'.toLowerCase();
    if (lower.contains('.pdf')) return DocumentViewerType.pdf;
    if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png') || lower.contains('.webp')) {
      return DocumentViewerType.image;
    }
    return DocumentViewerType.unknown;
  }

  Future<void> _loadPdf() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('status ${response.statusCode}');
      }
      pdfController = PdfController(document: PdfDocument.openData(response.bodyBytes));
    } catch (e) {
      debugPrint('DocumentViewerController: gagal memuat PDF: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openExternally() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('DocumentViewerController: gagal buka eksternal: $e');
    }
  }

  @override
  void onClose() {
    pdfController?.dispose();
    super.onClose();
  }
}
