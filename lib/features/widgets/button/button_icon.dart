import 'package:offline_gnss69_new/export.dart';

class button_icon extends StatelessWidget {
  final String name;
  final double name_size;
  final IconData icon;
  final double icon_size;
  final VoidCallback? onPressed;

  const button_icon({
    required this.name,
    required this.name_size,
    required this.icon,
    required this.icon_size,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF18181C),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(icon, size: icon_size, color: Colors.white),

          const SizedBox(width: 8.0),

          Text(
            name,
            style: TextStyle(
                fontSize: name_size,
                fontFamily: 'InstrumentSans',
                fontWeight: FontWeight.w700,
                color: Colors.white
            ),
          ),
        ],
      ),
    );
  }
}