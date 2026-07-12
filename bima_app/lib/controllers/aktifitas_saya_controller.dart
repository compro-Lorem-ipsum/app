import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ActivityType { checkIn, checkOut, patroli }

class ActivityEntry {
  final ActivityType type;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final Color? badgeColor;
  final Color? badgeBg;
  final String? trailing;

  ActivityEntry({
    required this.type,
    required this.title,
    required this.subtitle,
    this.badgeLabel,
    this.badgeColor,
    this.badgeBg,
    this.trailing,
  });
}

class ActivityGroup {
  final String date;
  final List<ActivityEntry> entries;

  ActivityGroup({required this.date, required this.entries});
}

class AktifitasSayaController extends GetxController {
  static const green = Color(0xFF008236);
  static const greenBg = Color(0xFFDCFCE7);
  static const yellow = Color(0xFF894B00);
  static const yellowBg = Color(0xFFFEF9C2);
  static const red = Color(0xFFC10007);
  static const redBg = Color(0xFFFFE2E2);

  final selectedFilter = 'Semua'.obs;

  final _absensi = [
    ActivityGroup(date: 'Kamis, 26 Jun 2026', entries: [
      ActivityEntry(type: ActivityType.checkOut, title: 'Check - out', subtitle: 'Pos Utama · 17:05', trailing: '8j 24m'),
      ActivityEntry(type: ActivityType.checkIn, title: 'Check - in', subtitle: 'Pos Utama · 08:48', badgeLabel: 'Tepat Waktu', badgeColor: green, badgeBg: greenBg),
    ]),
    ActivityGroup(date: 'Rabu, 25 Jun 2026', entries: [
      ActivityEntry(type: ActivityType.checkOut, title: 'Check - out', subtitle: 'Pos Utama · 17:05', trailing: '7j 54m'),
      ActivityEntry(type: ActivityType.checkIn, title: 'Check - in', subtitle: 'Pos Utama · 09:22', badgeLabel: 'Terlambat', badgeColor: yellow, badgeBg: yellowBg),
    ]),
  ];

  final _patroli = [
    ActivityGroup(date: 'Kamis, 26 Jun 2026', entries: [
      ActivityEntry(type: ActivityType.patroli, title: 'Laporan Patroli', subtitle: 'Nama Pos Patroli · 16:45', badgeLabel: 'Berhasil', badgeColor: green, badgeBg: greenBg),
      ActivityEntry(type: ActivityType.patroli, title: 'Laporan Patroli', subtitle: 'Nama Pos Patroli · 16:45', badgeLabel: 'Berhasil', badgeColor: green, badgeBg: greenBg),
      ActivityEntry(type: ActivityType.patroli, title: 'Laporan Patroli', subtitle: 'Nama Pos Patroli · 16:45', badgeLabel: 'Berhasil', badgeColor: green, badgeBg: greenBg),
    ]),
    ActivityGroup(date: 'Rabu, 25 Jun 2026', entries: [
      ActivityEntry(type: ActivityType.patroli, title: 'Laporan Patroli', subtitle: 'Nama Pos Patroli · 16:45', badgeLabel: 'Berhasil', badgeColor: green, badgeBg: greenBg),
      ActivityEntry(type: ActivityType.patroli, title: 'Laporan Patroli', subtitle: 'Nama Pos Patroli · 16:45', badgeLabel: 'Gagal', badgeColor: red, badgeBg: redBg),
      ActivityEntry(type: ActivityType.patroli, title: 'Laporan Patroli', subtitle: 'Nama Pos Patroli · 16:45', badgeLabel: 'Berhasil', badgeColor: green, badgeBg: greenBg),
    ]),
  ];

  late final List<ActivityGroup> _semua = [
    ActivityGroup(date: 'Kamis, 26 Jun 2026', entries: [
      ..._absensi[0].entries.where((e) => e.type == ActivityType.checkOut),
      ..._patroli[0].entries,
      ..._absensi[0].entries.where((e) => e.type == ActivityType.checkIn),
    ]),
    ActivityGroup(date: 'Rabu, 25 Jun 2026', entries: [
      ..._absensi[1].entries.where((e) => e.type == ActivityType.checkOut),
      ..._patroli[1].entries,
      ..._absensi[1].entries.where((e) => e.type == ActivityType.checkIn),
    ]),
  ];

  List<ActivityGroup> get currentGroups {
    switch (selectedFilter.value) {
      case 'Absensi':
        return _absensi;
      case 'Patroli':
        return _patroli;
      default:
        return _semua;
    }
  }

  void selectFilter(String filter) {
    selectedFilter.value = filter;
  }
}
