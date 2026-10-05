import 'package:offline_gnss69_new/export.dart';

class DrawToolButton extends StatelessWidget {
  final IconData? icon;
  final String? assetIcon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;
  final GlobalKey? iconKey;
  final Color highlightColor;
  final Color? iconColor;
  final double boxSize;

  const DrawToolButton({
    super.key,
    this.icon,
    this.assetIcon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.enabled = true,
    this.iconKey,
    this.highlightColor = const Color(0xFFE3E3E3),
    this.iconColor,
    this.boxSize = 38,
  }) : assert(icon != null || assetIcon != null,
  'ต้องระบุ icon หรือ assetIcon');

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor =
    !enabled
        ? Colors.grey.shade400
        : (iconColor ?? Colors.black);
    final Color effectiveTextColor =
    !enabled
        ? Colors.grey.shade400
        : Colors.black;

    return InkWell(
      onTap: enabled
          ? onPressed
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: iconKey,
              width: boxSize,
              height: boxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (selected && enabled)
                    ? highlightColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: assetIcon != null
                  ? Image.asset(
                assetIcon!,
                width: 22,
                height: 22,
                color: iconColor == null && !enabled ? Colors.grey.shade400 : null,
              )
                  : Icon(icon, size: 22, color: effectiveIconColor),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: effectiveTextColor,
                fontFamily: 'NotoSansThai',
              ),
            ),
          ],
        ),
      ),
    );
  }
}