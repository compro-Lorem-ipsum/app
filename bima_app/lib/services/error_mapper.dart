// Pemetaan `error.code` dari backend ke pesan bahasa Indonesia untuk
// pengguna. Backend HANYA mengirim kode (mis. `{"error": {"code":
// "OUTSIDE_POS_RADIUS"}}`); teks yang tampil di layar sepenuhnya diatur di
// sini. Semua controller sebaiknya memakai [ErrorMapper.parse] /
// [ErrorMapper.messageFor] ketimbang membaca `error['message']` langsung.

class ApiError {
  final int? statusCode;
  final String? code;

  /// Pesan siap tampil ke pengguna (tidak pernah null).
  final String message;

  const ApiError({this.statusCode, this.code, required this.message});

  bool get isUnauthorized => statusCode == 401 || code == 'UNAUTHORIZED' || code == 'TOKEN_EXPIRED' || code == 'TOKEN_REUSED';

  bool hasCode(String value) => code == value;

  @override
  String toString() => 'ApiError(status: $statusCode, code: $code, message: $message)';
}

class ErrorMapper {
  ErrorMapper._();

  static const String defaultMessage = 'Terjadi kesalahan, silakan coba lagi.';
  static const String networkMessage = 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.';

  static const Map<String, String> codeMessages = {
    'ACCOUNT_INACTIVE': 'Akun Anda tidak aktif. Silakan hubungi administrator untuk bantuan.',
    'ACCOUNT_PENDING': 'Akun Anda masih menunggu persetujuan admin. Mohon tunggu konfirmasi.',
    'ACCOUNT_REJECTED': 'Pendaftaran akun Anda ditolak.',
    'ALREADY_CHECKED_IN': 'Anda sudah melakukan absen masuk untuk shift ini.',
    'ASSIGNMENT_OVERLAP': 'Satpam ini sudah memiliki jadwal pada pola dan rentang tanggal tersebut.',
    'AVATAR_NOT_VALIDATED': 'Foto profil masih diverifikasi. Mohon tunggu sebentar lalu coba lagi.',
    'CHECK_OUT_WITHOUT_CHECK_IN': 'Absen pulang tidak dapat disimpan tanpa absen masuk.',
    'CHECK_VIOLATION': 'Nilai yang dimasukkan tidak diizinkan.',
    'CLIENT_NOT_FOUND': 'Klien tidak ditemukan.',
    'CONFLICT': 'Data serupa sudah terdaftar.',
    'CONTACT_LIMIT_REACHED': 'Kontak darurat maksimal 2. Hapus salah satu terlebih dahulu.',
    'EMAIL_TAKEN': 'Email ini sudah terdaftar.',
    'EMPTY_POLYLINE': 'Data rute kosong.',
    'EXCEPTION_EXISTS': 'Pengecualian untuk jadwal ini sudah ada. Hapus dahulu sebelum membuat yang baru.',
    'FACE_BAD_REQUEST': 'Permintaan ke layanan pengenalan wajah tidak valid.',
    'FACE_COLLECTION_UNAVAILABLE': 'Data wajah sedang tidak tersedia. Hubungi administrator.',
    'FACE_DECODE_FAILED': 'Foto tidak dapat dibaca. Silakan unggah ulang.',
    'FACE_IMAGE_TOO_LARGE': 'Ukuran foto terlalu besar.',
    'FACE_MULTIPLE_FACES': 'Terdeteksi lebih dari satu wajah. Gunakan foto dengan satu wajah saja.',
    'FACE_NOT_ENROLLED': 'Data wajah belum terdaftar untuk akun ini. Hubungi administrator.',
    'FACE_NOT_FOUND': 'Data wajah untuk akun ini tidak ditemukan.',
    'FACE_NOT_MATCHED': 'Wajah tidak cocok dengan data yang terdaftar.',
    'FACE_NO_FACE': 'Tidak ada wajah yang terdeteksi pada foto.',
    'FACE_TIMEOUT': 'Layanan pengenalan wajah tidak merespons. Silakan coba lagi.',
    'FACE_UNAVAILABLE': 'Layanan pengenalan wajah sedang tidak tersedia. Coba lagi nanti.',
    'FACE_UPSTREAM_ERROR': 'Terjadi kesalahan pada layanan pengenalan wajah.',
    'FORBIDDEN': 'Anda tidak memiliki akses ke fitur ini.',
    'FOREIGN_KEY_VIOLATION': 'Data yang dirujuk tidak ditemukan atau masih digunakan.',
    'INTERNAL_ERROR': 'Terjadi kesalahan pada sistem. Silakan coba lagi nanti.',
    'INVALID_ALERT_TRANSITION': 'Status panic alert tidak dapat diubah dari kondisi saat ini.',
    'INVALID_CREDENTIALS': 'Email atau NIP dan kata sandi tidak cocok.',
    'INVALID_CURSOR': 'Halaman tidak valid. Muat ulang daftar dari awal.',
    'INVALID_EVENT_TRANSITION': 'Status laporan tidak dapat diubah dari kondisi saat ini.',
    'INVALID_TIME_RANGE': 'Waktu pulang harus setelah waktu masuk.',
    'MEMBER_NOT_ACTIVE': 'Satpam belum berstatus aktif, sehingga belum dapat ditugaskan ke klien.',
    'NIP_TAKEN': 'NIP ini sudah terdaftar.',
    'NOT_CHECKED_IN': 'Anda belum melakukan absen masuk.',
    'NOT_FOUND': 'Data tidak ditemukan.',
    'NOT_ON_DUTY': 'Anda harus sedang bertugas untuk melakukan tindakan ini.',
    'NOT_PENDING': 'Pendaftaran ini sudah diproses sebelumnya.',
    'NO_ACTIVE_SESSION': 'Tidak ada sesi absen yang sedang berjalan.',
    'NO_CLIENT_SCOPE': 'Anda belum ditugaskan ke klien mana pun.',
    'NO_OPEN_SHIFT': 'Tidak ada shift yang dapat diabsen saat ini. Absen dibuka satu jam sebelum shift dimulai.',
    'NO_UTAMA_POS': 'Klien Anda belum memiliki pos utama.',
    'OBJECT_INVALID': 'Jenis berkas tidak sesuai dengan ekstensinya. Silakan unggah ulang.',
    'OBJECT_IN_USE': 'Berkas ini sudah dipakai pada data lain. Silakan unggah berkas baru.',
    'OTP_INVALID': 'Kode verifikasi salah atau sudah kedaluwarsa.',
    'OTP_MAX_ATTEMPTS': 'Kode verifikasi salah sebanyak 3 kali. Silakan minta kode baru.',
    'OUTSIDE_CHECK_IN_WINDOW': 'Belum waktunya absen untuk shift ini.',
    'OUTSIDE_POS_RADIUS': 'Anda berada di luar radius pos.',
    'PATTERN_IN_USE': 'Pola shift masih dipakai oleh jadwal aktif. Hapus jadwalnya terlebih dahulu.',
    'POS_NOT_JAGA': 'Patroli hanya dapat dilaporkan pada pos jaga.',
    'POS_NOT_UTAMA': 'Shift hanya dapat dipasang pada pos utama.',
    'RATE_LIMITED': 'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.',
    'READ_ONLY_ROLE': 'Akun Anda hanya dapat melihat data dan tidak dapat mengubahnya.',
    'REQUEST_NOT_PENDING': 'Pengajuan ini sudah diproses sebelumnya.',
    'REQUEST_OVERLAP': 'Tanggal yang diajukan bertabrakan dengan pengajuan lain yang masih berlaku.',
    'ROLE_NOT_ASSIGNABLE': 'Akun ini tidak dapat ditugaskan ke klien.',
    'ROLE_NOT_SEEDED': 'Konfigurasi peran pengguna belum lengkap. Hubungi administrator.',
    'SATPAM_NOT_ASSIGNED': 'Satpam belum ditugaskan ke klien, sehingga teguran tidak dapat diterbitkan.',
    'SATPAM_NOT_CHECKED_IN': 'Satpam belum absen hari ini, sehingga pesan belum dapat dikirim.',
    'SELF_ACTION_FORBIDDEN': 'Anda tidak dapat menghapus atau menonaktifkan akun Anda sendiri.',
    'SHIFT_OVERLAP': 'Satpam ini sudah memiliki shift pada rentang waktu tersebut.',
    'TOKEN_EXPIRED': 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    'TOKEN_REUSED': 'Sesi Anda dinonaktifkan karena terdeteksi digunakan ulang. Silakan masuk kembali.',
    'UNAUTHORIZED': 'Anda belum masuk. Silakan masuk terlebih dahulu.',
    'VALIDATION_ERROR': 'Data yang dikirim tidak valid. Periksa kembali isian Anda.',
    'VALUE_TOO_LONG': 'Teks yang dimasukkan terlalu panjang.',
    'VIOLATION_STEP_SKIPPED': 'Tahapan teguran tidak boleh dilewati. Terbitkan tahap sebelumnya terlebih dahulu.',
    'VIOLATION_TYPE_EXISTS': 'Satpam ini sudah memiliki teguran aktif dengan jenis yang sama.',
  };

  /// Pesan fallback berdasarkan HTTP status, dipakai kalau `error.code`
  /// tidak ada atau belum dikenal.
  static const Map<int, String> _statusMessages = {
    400: 'Permintaan tidak valid. Periksa kembali data Anda.',
    401: 'Anda belum masuk. Silakan masuk terlebih dahulu.',
    403: 'Anda tidak memiliki akses ke fitur ini.',
    404: 'Data tidak ditemukan.',
    409: 'Data serupa sudah terdaftar.',
    422: 'Data yang dikirim tidak valid. Periksa kembali isian Anda.',
    429: 'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.',
    500: 'Terjadi kesalahan pada sistem. Silakan coba lagi nanti.',
  };

  /// Ambil `error.code` dari body respons (`{"error": {"code": ...}}`).
  static String? extractCode(dynamic body) {
    if (body is! Map) return null;
    final error = body['error'];
    final code = error is Map ? error['code'] : body['code'];
    final text = code?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Pesan untuk satu [code]; null kalau kode tidak dikenal.
  static String? messageForCode(String? code) => code == null ? null : codeMessages[code];

  /// Pesan siap tampil untuk respons [body] / [statusCode]. Urutan:
  /// 1. pemetaan `error.code`, 2. fallback per HTTP status, 3. [fallback].
  static String messageFor(dynamic body, {int? statusCode, String? fallback}) {
    final mapped = messageForCode(extractCode(body));
    if (mapped != null) return mapped;
    if (statusCode != null && _statusMessages.containsKey(statusCode)) return _statusMessages[statusCode]!;
    if (statusCode != null && statusCode >= 500) return _statusMessages[500]!;
    return fallback ?? defaultMessage;
  }

  /// Bungkus code + pesan sekaligus supaya controller bisa `switch` pada
  /// `code` untuk perilaku khusus (mis. tipe dialog) dan tetap memakai
  /// `message` untuk teksnya.
  static ApiError parse(dynamic body, {int? statusCode, String? fallback}) {
    return ApiError(
      statusCode: statusCode,
      code: extractCode(body),
      message: messageFor(body, statusCode: statusCode, fallback: fallback),
    );
  }
}
