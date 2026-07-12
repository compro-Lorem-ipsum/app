import 'dart:io';

import 'package:get/get.dart';
import '../widgets/success_screen.dart';

class DocumentSlot {
  final String key;
  final String title;
  final String subtitle;
  bool uploaded;
  String? fileName;
  String? fileSize;
  String? filePath;

  DocumentSlot({
    required this.key,
    required this.title,
    required this.subtitle,
    this.uploaded = false,
    this.fileName,
    this.fileSize,
    this.filePath,
  });
}

class UnggahBerkasController extends GetxController {
  final slots = <DocumentSlot>[
    DocumentSlot(key: 'ktp', title: 'KTP', subtitle: 'KTP Yang Masih Berlaku'),
    DocumentSlot(key: 'bpjs', title: 'BPJS', subtitle: 'BPJS Kesehatan / Ketenagakerjaan'),
    DocumentSlot(key: 'npwp', title: 'NPWP', subtitle: 'Nomor Pokok Wajib Pajak'),
  ].obs;

  int get uploadedCount => slots.where((s) => s.uploaded).length;

  bool get isComplete => uploadedCount == slots.length;

  /// Navigates to the existing camera capture route (same one used by
  /// `lapor_kejadian_controller.dart`'s `goToCamera`) to take a real photo
  /// of the document, then stores its path, name and actual file size.
  Future<void> upload(DocumentSlot slot) async {
    final result = await Get.toNamed('/take-photo-patroli');

    if (result != null && result is String) {
      final file = File(result);
      int bytes = 0;
      try {
        bytes = file.lengthSync();
      } catch (_) {
        bytes = 0;
      }

      slot.uploaded = true;
      slot.filePath = result;
      slot.fileName = '${slot.title}_Scan.jpg';
      slot.fileSize = _formatFileSize(bytes);
      slots.refresh();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  void remove(DocumentSlot slot) {
    slot.uploaded = false;
    slot.fileName = null;
    slot.fileSize = null;
    slot.filePath = null;
    slots.refresh();
  }

  void submit() {
    if (!isComplete) return;
    Get.to(() => SuccessScreen(
          title: 'Behasil',
          subtitle: 'Berkas Anda berhasil di Simpan/Unggah',
          buttonLabel: 'Kembali ke Beranda',
          onButtonPressed: () => Get.offAllNamed('/'),
        ));
  }
}
