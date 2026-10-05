import 'package:flutter/material.dart';

class dropdown_field_c5 extends StatelessWidget {
  final String name;
  final String hintText;
  final String? value;
  final List<String> items;
  final void Function(String? p1) onChanged;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const dropdown_field_c5({
    required this.name,
    this.hintText = "-",
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),

        SizedBox(height: 10.0),

        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(15),
          menuMaxHeight: 300,
          icon: const Icon(Icons.keyboard_arrow_down),
          // ข้อความในช่อง
          style: const TextStyle(
            fontFamily: 'NotoSansThai',
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
            color: Colors.black,
          ),
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis, // ถ้าข้อความยาวเกินให้ใส่ ...
              maxLines: 1, // บังคับให้อยู่ในบรรทัดเดียว
              softWrap: false,
            ),
          )).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            errorMaxLines: 1,
            helperText: ' ',
            helperStyle: const TextStyle(height: 1),
            errorStyle: const TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.red,
              height: 1.2,
            ),

            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey)
                : null,
            hintStyle: const TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              //color: Colors.grey,
            ),
            // ไม่ถูกแตะ/ไม่ focus
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 34, 34, 34),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            // focus
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.6),
                width: 3.0,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            // ใส่ข้อความตรงเงื้อนไข
            border: OutlineInputBorder(
                borderSide: const BorderSide(
                    color: Color.fromARGB(255, 34, 34, 34),
                    width: 1.2
                ),
                borderRadius: BorderRadius.circular(5)
            ),
            // ใส่ข้อความไม่ตรงเงื้อนไข
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