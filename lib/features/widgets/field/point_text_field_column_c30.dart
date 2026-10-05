import 'package:flutter/material.dart';

class point_text_field_column_c30 extends StatefulWidget {
  final String name;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final String unit;
  final double unitWidth;

  const point_text_field_column_c30({
    required this.name,
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.unit = "m.",
    this.unitWidth = 25.0,

    super.key,
  });

  @override
  State<point_text_field_column_c30> createState() => _point_text_field_column_c30State();
}

class _point_text_field_column_c30State extends State<point_text_field_column_c30> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          widget.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                validator: widget.validator,
                keyboardType: widget.keyboardType,

                style: const TextStyle(
                  fontFamily: 'NotoSansThai',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),

                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 12,
                  ),
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    //color: Colors.grey,
                  ),

                  helperText: ' ',
                  errorStyle: const TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                    height: 1.2,
                  ),

                  // เมื่อไม่ถูกเลือก
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 34, 34, 34),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(30)
                  ),
                  // เมื่อถูกเลือก
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.6),
                        width: 3.0,
                      ),
                      borderRadius: BorderRadius.circular(30)
                  ),
                  // เมื่อใส่ข้อความตรงเงื้อนไข
                  border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 34, 34, 34),
                          width: 1.2
                      ),
                      borderRadius: BorderRadius.circular(30)
                  ),
                  // เมื่อใส่ข้อความไม่ตรงเงื้อนไข
                  errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.red,
                          width: 3.0
                      ),
                      borderRadius: BorderRadius.circular(30)
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10.0),

            Container(
              width: widget.unitWidth,
              height: 48,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.unit,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSansThai',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
