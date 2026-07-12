import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class RekanKerjaItem {
  final String name;
  final String nip;
  final String role;
  final Color roleColor;
  final String phone;

  RekanKerjaItem({
    required this.name,
    required this.nip,
    required this.role,
    required this.roleColor,
    required this.phone,
  });
}

class RekanKerjaController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  final rekan = <RekanKerjaItem>[
    RekanKerjaItem(name: 'Nama Rekan', nip: 'NIP 123xxx', role: 'Chief', roleColor: const Color(0xFFB90023), phone: '081x - xxxx - xxxx'),
    RekanKerjaItem(name: 'Nama Rekan', nip: 'NIP 123xxx', role: 'Danru', roleColor: const Color(0xFF894B00), phone: '081x - xxxx - xxxx'),
    RekanKerjaItem(name: 'Nama Satpam', nip: 'NIP 123xxx', role: 'Anggota', roleColor: primaryColor, phone: '081x - xxxx - xxxx'),
    RekanKerjaItem(name: 'Nama Satpam', nip: 'NIP 123xxx', role: 'Anggota', roleColor: primaryColor, phone: '081x - xxxx - xxxx'),
  ].obs;

  void confirmWhatsapp(RekanKerjaItem item) {
    Get.dialog(
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(15)),
                    child: SvgPicture.asset('assets/icons/whatsapp.svg', width: 30, height: 30),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                      const SizedBox(height: 4),
                      Text(item.phone, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF6B6B6B))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02A758),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Buka WhatsApp', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF8D8787))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
