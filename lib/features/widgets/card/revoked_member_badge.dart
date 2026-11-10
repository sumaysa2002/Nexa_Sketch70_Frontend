import 'package:flutter/material.dart';
import 'package:nexa_sketch/models/user_model.dart';

/// ── ตรวจว่าเป็น สมาชิกโครงการที่ถูกถอนการอนุมัติจาก admin หรือไม่ ──────────────────────
bool isFormerProjectMember(UserModel user, int? creatorAdminId) {
  if (creatorAdminId == null) {
    return user.status != 'user' && user.status != 'admin';
  }
  if (user.status == 'admin') return user.id != creatorAdminId;
  if (user.status == 'user') return user.admin != creatorAdminId.toString();
  return true;
}

/// ── เรียงสมาชิก: สมาชิกปัจจุบันก่อน แล้วตามด้วยสมาชิกโครงการที่ถูกถอนการอนุมัติ ──────────
List<UserModel> sortCurrentMembersFirst(List<UserModel> members, int? creatorAdminId) {
  final current = members.where((m) => !isFormerProjectMember(m, creatorAdminId));
  final former  = members.where((m) => isFormerProjectMember(m, creatorAdminId));
  return [...current, ...former];
}

/// ── ป้าย "ถูกถอนการอนุมัติ" ──────────────────────
class RevokedMemberBadge extends StatelessWidget {
  const RevokedMemberBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(Icons.person_off_outlined, size: 14, color: Color(0xFFC62828)),

          SizedBox(width: 4),

          Text(
            'ถูกถอนการอนุมัติ',
            style: TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}
