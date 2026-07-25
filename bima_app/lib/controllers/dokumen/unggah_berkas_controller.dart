// Controller untuk halaman Unggah Berkas (KTP, BPJS, NPWP).
// Setiap dokumen diunggah dari file (JPG/PDF) memakai file_picker,
// bukan dari kamera, lalu diringkas di kartu progres sebelum disimpan.

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../../widgets/success_screen.dart';

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

  bool get isPdf => fileName?.toLowerCase().endsWith('.pdf') ?? false;
}

class UnggahBerkasController extends GetxController {
  final slots = <DocumentSlot>[
    DocumentSlot(key: 'ktp', title: 'KTP', subtitle: 'KTP Yang Masih Berlaku'),
    DocumentSlot(key: 'bpjs', title: 'BPJS', subtitle: 'BPJS Kesehatan / Ketenagakerjaan'),
    DocumentSlot(key: 'npwp', title: 'NPWP', subtitle: 'Nomor Pokok Wajib Pajak'),
  ].obs;

  int get uploadedCount => slots.where((s) => s.uploaded).length;

  bool get isComplete => uploadedCount == slots.length;

  Future<void> upload(DocumentSlot slot) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'pdf'],
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    if (picked.path == null) return;

    slot.uploaded = true;
    slot.filePath = picked.path;
    slot.fileName = picked.name;
    slot.fileSize = _formatFileSize(picked.size);
    slots.refresh();
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
          subtitle: 'Berkas Anda berhasil di Unggah',
          buttonLabel: 'Kembali ke Beranda',
          buttonWidth: 316,
          buttonHeight: 60,
          buttonBorderRadius: 40,
          buttonFontSize: 20,
          onButtonPressed: () => Get.offAllNamed('/'),
        ));
  }
}
