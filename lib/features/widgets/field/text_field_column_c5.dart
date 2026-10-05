import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class text_field_column_c5 extends StatefulWidget {
  final String name;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;

  final TextInputType keyboardType;
  final bool isPassword;
  final List<TextInputFormatter>? inputFormatters;

  const text_field_column_c5({
    required this.name,
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.inputFormatters,
    super.key,
  });

  @override
  State<text_field_column_c5> createState() => _text_field_column_c5State();
}

class _text_field_column_c5State extends State<text_field_column_c5> {

  bool _obscureText = true; //ปุ่มเปิดปิด password

  @override
  Widget build(BuildContext context) {
    return Column(
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

        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          obscureText: widget.isPassword ? _obscureText : false,

          style: const TextStyle(
            fontFamily: 'NotoSansThai',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),

          decoration: InputDecoration(
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

            // 👁 ปุ่มเปิด/ปิดรหัสผ่าน
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
                : null,

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