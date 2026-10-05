import 'package:flutter/material.dart';

class point_dropdown_field_column_c30 extends StatefulWidget {
  final String name;
  final String hintText;
  final String? value;
  final List<String> items;
  final void Function(String? p1) onChanged;
  final String? Function(String?)? validator;
  final double nameWidth;
  final String unit;
  final double unitWidth;

  const point_dropdown_field_column_c30({
    required this.name,
    this.hintText = "-",
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.nameWidth = 80.0,
    this.unit = "",
    this.unitWidth = 25.0,

    Key? key,
  }) : super(key: key);

  @override
  State<point_dropdown_field_column_c30> createState() => _point_dropdown_field_column_c30State();
}

class _point_dropdown_field_column_c30State extends State<point_dropdown_field_column_c30> {
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
              child: DropdownButtonFormField<String>(
                value: widget.value,
                validator: widget.validator,
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
                items: widget.items
                    .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis, // ถ้าข้อความยาวเกินให้ใส่ ...
                    maxLines: 1, // บังคับให้อยู่ในบรรทัดเดียว
                    softWrap: false,
                  ),
                )).toList(),
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 12,
                  ),
                  hintText: widget.hintText,
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
                  // ไม่ถูกแตะ/ไม่ focus
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 34, 34, 34),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  // focus
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.6),
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  // ใส่ข้อความตรงเงื้อนไข
                  border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 34, 34, 34),
                          width: 1.2
                      ),
                      borderRadius: BorderRadius.circular(30)
                  ),
                  // ใส่ข้อความไม่ตรงเงื้อนไข
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
