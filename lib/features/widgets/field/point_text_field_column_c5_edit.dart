import 'package:flutter/material.dart';

class point_text_field_column_c5_edit extends StatefulWidget {
  final String name;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int? maxLines;
  final int minLines;

  const point_text_field_column_c5_edit({
    required this.name,
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    super.key,
  });

  @override
  State<point_text_field_column_c5_edit> createState() => _point_text_field_column_c5_editState();
}

class _point_text_field_column_c5_editState extends State<point_text_field_column_c5_edit> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF18181C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(width: 8),

            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoSansThai',
                color: Color(0xFF18181C),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          textInputAction: widget.maxLines == 1
              ? TextInputAction.done
              : TextInputAction.newline,

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
                borderRadius: BorderRadius.circular(5)
            ),
            // เมื่อถูกเลือก
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.6),
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(5)
            ),
            // เมื่อใส่ข้อความตรงเงื้อนไข
            border: OutlineInputBorder(
                borderSide: const BorderSide(
                    color: Color.fromARGB(255, 34, 34, 34),
                    width: 1.2
                ),
                borderRadius: BorderRadius.circular(5)
            ),
            // เมื่อใส่ข้อความไม่ตรงเงื้อนไข
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                    color: Colors.red,
                    width: 3.0
                ),
                borderRadius: BorderRadius.circular(5)
            ),
          ),
        ),

      ],
    );
  }
}
