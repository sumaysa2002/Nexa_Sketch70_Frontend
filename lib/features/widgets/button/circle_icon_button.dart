import 'package:offline_gnss69_new/export.dart';

class circle_icon_button extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  circle_icon_button({
    required this.icon,
    this.color = const Color(0xFFBDBDBD),
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}