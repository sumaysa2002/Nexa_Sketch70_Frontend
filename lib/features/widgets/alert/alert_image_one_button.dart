import 'package:offline_gnss69_new/export.dart';

class alert_image_one_button extends StatelessWidget {
  final String text;
  final String assets_image;
  final double height;
  final VoidCallback? onPressed;
  final String text_button;

  const alert_image_one_button({
    required this.text,
    required this.assets_image,
    this.height = 120,
    required this.onPressed,
    required this.text_button,

    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 10),
      title: Center(
        child: Image.asset(
          assets_image,
          height: height,
        ),
      ),

      content: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.5, // 50% ของความกว้างหน้าจอ
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const SizedBox(height: 10),

                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NotoSansThai',
                  ),
                ),

                const SizedBox(height: 20),

                // ปุ่ม ตกลง
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: TextButton(
                    onPressed: onPressed,
                    child: Text(
                      text_button,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansThai',
                        color: Colors.white,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
                            return Colors.grey;
                          }
                          return Color(0xFF18181C);
                        },
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                        ),
                      ),
                      fixedSize: MaterialStateProperty.all(Size(350, 45)),
                    ),
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}