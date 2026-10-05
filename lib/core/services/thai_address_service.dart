import 'dart:convert';
import 'package:flutter/services.dart';

class ThaiAddressService {
  static List<Map<String, dynamic>> _amphures = [];
  static List<Map<String, dynamic>> _tambons  = [];
  static bool _loaded = false;

  /// โหลดข้อมูลอำเภอ จังหวัด
  static Future<void> load() async {
    if (_loaded) return;

    final amphureJson = await rootBundle.loadString('assets/data/thai_amphure.json');
    final tambonJson  = await rootBundle.loadString('assets/data/thai_tambon.json');

    _amphures = List<Map<String, dynamic>>.from(jsonDecode(amphureJson));
    _tambons  = List<Map<String, dynamic>>.from(jsonDecode(tambonJson));
    _loaded   = true;
  }

  /// ดึงชื่ออำเภอตาม province_id
  static List<String> getAmphures(int provinceId) {
    return _amphures
        .where((a) => a['province_id'] == provinceId)
        .map<String>((a) => a['name_th'] as String)
        .toList();
  }

  /// ดึงชื่อตำบลตาม amphure_id
  static List<String> getTambons(int amphureId) {
    return _tambons
        .where((t) => t['district_id'] == amphureId)
        .map<String>((t) => t['name_th'] as String)
        .toList();
  }

  /// ดึง province_id จากชื่อจังหวัด
  static int? getProvinceId(String provinceName) {
    // ข้อมูล province_id ของแต่ละจังหวัด (ตรงกับ thai-province-data)
    const provinceMap = {
      'กรุงเทพมหานคร': 1,
      'สมุทรปราการ': 2,
      'นนทบุรี': 3,
      'ปทุมธานี': 4,
      'พระนครศรีอยุธยา': 5,
      'อ่างทอง': 6,
      'ลพบุรี': 7,
      'สิงห์บุรี': 8,
      'ชัยนาท': 9,
      'สระบุรี': 10,
      'ชลบุรี': 11,
      'ระยอง': 12,
      'จันทบุรี': 13,
      'ตราด': 14,
      'ฉะเชิงเทรา': 15,
      'ปราจีนบุรี': 16,
      'นครนายก': 17,
      'สระแก้ว': 18,
      'นครราชสีมา': 19,
      'บุรีรัมย์': 20,
      'สุรินทร์': 21,
      'ศรีสะเกษ': 22,
      'อุบลราชธานี': 23,
      'ยโสธร': 24,
      'ชัยภูมิ': 25,
      'อำนาจเจริญ': 26,

      'บึงกาฬ': 77,

      'หนองบัวลำภู': 27,
      'ขอนแก่น': 28,
      'อุดรธานี': 29,
      'เลย': 30,
      'หนองคาย': 31,
      'มหาสารคาม': 32,
      'ร้อยเอ็ด': 33,
      'กาฬสินธุ์': 34,
      'สกลนคร': 35,
      'นครพนม': 36,
      'มุกดาหาร': 37,
      'เชียงใหม่': 38,
      'ลำพูน': 39,
      'ลำปาง': 40,
      'อุตรดิตถ์': 41,
      'แพร่': 42,
      'น่าน': 43,
      'พะเยา': 44,
      'เชียงราย': 45,
      'แม่ฮ่องสอน': 46,
      'นครสวรรค์': 47,
      'อุทัยธานี': 48,
      'กำแพงเพชร': 49,
      'ตาก': 50,
      'สุโขทัย': 51,
      'พิษณุโลก': 52,
      'พิจิตร': 53,
      'เพชรบูรณ์': 54,
      'ราชบุรี': 55,
      'กาญจนบุรี': 56,
      'สุพรรณบุรี': 57,
      'นครปฐม': 58,
      'สมุทรสาคร': 59,
      'สมุทรสงคราม': 60,
      'เพชรบุรี': 61,
      'ประจวบคีรีขันธ์': 62,
      'นครศรีธรรมราช': 63,
      'กระบี่': 64,
      'พังงา': 65,
      'ภูเก็ต': 66,
      'สุราษฎร์ธานี': 67,
      'ระนอง': 68,
      'ชุมพร': 69,
      'สงขลา': 70,
      'สตูล': 71,
      'ตรัง': 72,
      'พัทลุง': 73,
      'ปัตตานี': 74,
      'ยะลา': 75,
      'นราธิวาส': 76,
    };
    return provinceMap[provinceName];
  }

  /// ดึง amphure_id จากชื่ออำเภอและ province_id
  static int? getAmphureId(String amphueName, int provinceId) {
    final found = _amphures.firstWhere(
          (a) => a['name_th'] == amphueName && a['province_id'] == provinceId,
      orElse: () => {},
    );
    return found.isEmpty ? null : found['id'] as int?;
  }
}