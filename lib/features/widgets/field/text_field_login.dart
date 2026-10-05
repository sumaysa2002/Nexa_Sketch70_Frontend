import 'package:flutter/material.dart';

class text_field_login extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final bool isPassword;

  const text_field_login({
    required this.controller,
    required this.hintText,
    required this.validator,
    this.isPassword = false,
    super.key,
  });

  @override
  State<text_field_login> createState() =>
      _text_field_loginState();
}

class _text_field_loginState
    extends State<text_field_login> {

  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: widget.isPassword ? _obscureText : false,

      style: const TextStyle(
        fontFamily: 'InstrumentSans',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),

      decoration: InputDecoration(
        hintText: widget.hintText,
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
    );
  }
}