import 'package:nexa_sketch/export.dart';

/// token ของผู้ใช้ที่ login อยู่
String? trashToken(BuildContext context) {
  final s = context.read<AuthCubit>().state;
  return s is AuthLoggedIn ? s.userModel.token : null;
}

/// dd/MM/yyyy HH:mm
String formatTrashDate(DateTime? d) {
  if (d == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// เหลือ <= 3 วัน >> สีแดง
Color trashDaysLeftColor(int days) =>
    days <= 3
        ? const Color(0xFFD32F2F)
        : const Color(0xFF707078);

String trashDaysLeftText(int days) =>
    days <= 0
        ? 'เหลือเวลาน้อยกว่า 1 วัน ก่อนลบถาวร'
        : 'เหลืออีก $days วัน ก่อนลบถาวร';

void showTrashSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: error
          ? const Color(0xFF18181C)
          : const Color(0xFF18181C),
      content: Text(
        message,
        style: const TextStyle(
            fontFamily: 'NotoSansThai',
            color: Colors.white
        ),
      ),
    ));
}

/// ── dialog ยืนยันการกู้คืน ──
Future<bool> confirmTrashRestore(
    BuildContext context, {
      required String text,
    }) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => alert_image_two_button(
      text: text,
      one_fontWeight: FontWeight.w700,
      assets_image: 'assets/images/question.png',
      one_text_button: 'ยกเลิก',
      one_onPressed: () => Navigator.of(ctx).pop(false),
      two_text_button: 'ยืนยัน',
      two_onPressed: () => Navigator.of(ctx).pop(true),
    ),
  );
  return ok == true;
}

/// ── dialog ยืนยันการลบถาวร ──
Future<bool> confirmTrashPurge(
    BuildContext context, {
      required String text,
    }) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => alert_image_two_button(
      text: text,
      one_fontWeight: FontWeight.w700,
      assets_image: 'assets/images/icon_bin.png',
      one_text_button: 'ยกเลิก',
      one_onPressed: () => Navigator.of(ctx).pop(false),
      two_text_button: 'ลบถาวร',
      two_onPressed: () => Navigator.of(ctx).pop(true),
    ),
  );
  return ok == true;
}

/// ── Header หน้าจอ ──
class TrashHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double textOffsetY; // ใช้ปรับตำแหน่งข้อความเฉพาะหน้า

  const TrashHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.textOffsetY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F0F10),
            Color(0xFF0F0F10)
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.elliptical(2000, 120),
          bottomRight: Radius.elliptical(2000, 120),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, textOffsetY),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const SizedBox(height: 10),

                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'NotoSansThai',
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 3),

                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'NotoSansThai',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── แถบข้อความอธิบาย (เก็บไว้ 30 วัน) ──
class TrashInfoBanner extends StatelessWidget {
  final String text;
  const TrashInfoBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(30, 4, 30, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Color(0xFFB26A00)
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontFamily: 'NotoSansThai',
                  fontSize: 12.5,
                  color: Color(0xFF7A4A00)
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── แถบใต้การ์ด: ลบเมื่อ / โดย / เหลืออีกกี่วัน + ปุ่มกู้คืน ──
class TrashRestoreStrip extends StatelessWidget {
  final DateTime? deletedAt;
  final String? deletedByName;
  final int daysLeft;
  final String restoreLabel;
  final bool busy;
  final VoidCallback? onRestore;
  final VoidCallback? onPurge;
  final String purgeLabel;
  final EdgeInsetsGeometry margin;
  final bool embedded;

  const TrashRestoreStrip({
    super.key,
    required this.deletedAt,
    required this.deletedByName,
    required this.daysLeft,
    required this.restoreLabel,
    required this.onRestore,
    this.onPurge,
    this.purgeLabel = 'ลบถาวร',
    this.busy = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = trashDaysLeftColor(daysLeft);
    return Container(
      margin: margin,
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(12),
      decoration: embedded
          ? null
          : BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: color
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  trashDaysLeftText(daysLeft),
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'ลบเมื่อ ${formatTrashDate(deletedAt)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
              fontFamily: 'NotoSansThai',
              color: Color(0xFF707078),
            ),
          ),

          const SizedBox(height: 2),

          if (deletedByName != null)
            Text(
              'โดย $deletedByName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                fontFamily: 'NotoSansThai',
                color: Color(0xFF707078),
              ),
            ),

          const SizedBox(height: 10),

          // ปุ่มกู้คืน + ปุ่มลบถาวร
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 240;

              Widget content(String text, {Widget? leading, Color? color}) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[leading, const SizedBox(width: 6)],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        fontFamily: 'NotoSansThai',
                        color: color,
                      ),
                    ),
                  ],
                ),
              );

              final restoreButton = SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: busy ? null : onRestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                      ),
                    ),
                  ),
                  child: content(
                    restoreLabel,
                    color: Colors.white,
                    leading: busy
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                        : (compact
                        ? null
                        : const Icon(
                        Icons.refresh,
                        size: 18)),
                  ),
                ),
              );

              if (onPurge == null) {
                return SizedBox(width: double.infinity, child: restoreButton);
              }

              final purgeButton = SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: busy ? null : onPurge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                  ),
                  child: content(
                    purgeLabel,
                    color: Colors.white,
                    leading: compact
                        ? null
                        : const Icon(Icons.delete_forever_rounded, size: 18),
                  ),
                ),
              );

              return Row(
                children: [
                  Expanded(child: restoreButton),
                  const SizedBox(width: 4),
                  Expanded(child: purgeButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ── ปุ่ม ลบทั้งหมด ──
class TrashPurgeAllButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool busy;
  final String label;

  const TrashPurgeAllButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.label = 'ลบทั้งหมด',
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: disabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: busy
                ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.delete_forever_rounded),
            label: Text(
              label,
              style: const TextStyle(fontFamily: 'NotoSansThai', fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

/// ── ข้อความกลางจอ (ว่าง / error / offline) + ปุ่มลองอีกครั้ง ──
class TrashMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const TrashMessage({super.key, required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Icon(
                icon,
                size: 56,
                color: Colors.grey.shade400
            ),

            const SizedBox(height: 15),

            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'NotoSansThai',
                  fontSize: 16,
                  color: Colors.grey
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.grey
                ),

                label: const Text(
                    'ลองอีกครั้ง',
                    style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 16,
                        color: Colors.grey
                    )
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ── แถวข้อมูล (label : value) ──
class TrashInfoLine extends StatelessWidget {
  final String label;
  final String? value;
  const TrashInfoLine({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final v = (value == null || value!.trim().isEmpty) ? '-' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'NotoSansThai',
                fontWeight: FontWeight.w500,
                color: Color(0xFF515155),
              ),
            ),
          ),

          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'NotoSansThai',
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}