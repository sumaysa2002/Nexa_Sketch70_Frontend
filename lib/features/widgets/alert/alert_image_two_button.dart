import 'package:offline_gnss69_new/export.dart';

class alert_image_two_button extends StatelessWidget {
  final String text;
  final String assets_image;
  final double height;
  final String one_text_button;
  final FontWeight one_fontWeight;
  final VoidCallback? one_onPressed;
  final String two_text_button;
  final VoidCallback? two_onPressed;

  const alert_image_two_button({
    required this.text,
    required this.assets_image,
    this.height = 120,
    required this.one_text_button,
    this.one_fontWeight = FontWeight.w500,
    required this.one_onPressed,
    required this.two_text_button,
    required this.two_onPressed,

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
                    fontWeight: one_fontWeight,
                    fontFamily: 'NotoSansThai',
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [

                    // Button 1
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: TextButton(
                          onPressed: one_onPressed,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF18181C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                //bottomRight: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              ),
                            ),
                          ),
                          child: Text(
                            one_text_button,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NotoSansThai',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Button 2
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: TextButton(
                          onPressed: two_onPressed,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF18181C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(30),
                                //bottomLeft: Radius.circular(30),
                              ),
                            ),
                          ),
                          child: Text(
                            two_text_button,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NotoSansThai',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}