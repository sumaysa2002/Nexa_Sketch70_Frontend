import 'package:offline_gnss69_new/export.dart';

class Calendar extends StatelessWidget {
  final DateTime Date_name;
  final void Function(DateTime, DateTime) Date_Selected;
  final Color color;

  const Calendar({
    required this.Date_name,
    required this.Date_Selected,
    this.color = const Color(0xFF515155),

    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // สไตล์ฟอนต์ส่วนกลาง
    const TextStyle commonTextStyle = TextStyle(
      fontFamily: 'NotoSansThai',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    );

    return Container(
      // ทำเส้นกรอบไล่สี
      padding: const EdgeInsets.all(1.5), // ความหนาของเส้นขอบ
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFCFCFCF),
            Color(0xFF515155),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Container(
        // พื้นหลังด้านใน
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(29),
        ),
        padding: const EdgeInsets.all(10),
        child: TableCalendar(
          locale: "en_US",
          rowHeight: 45,
          availableGestures: AvailableGestures.all,
          focusedDay: Date_name,
          firstDay: DateTime.utc(2000),
          lastDay: DateTime.utc(2100),
          selectedDayPredicate: (day) => isSameDay(day, Date_name),
          onDaySelected: Date_Selected,

          // Header (เดือน/ปี)
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey),
          ),

          // ปรับแต่งชื่อวัน (Mo, Tu, ...)
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            weekendStyle: TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),

          // ปรับแต่งสไตล์วันที่
          calendarStyle: CalendarStyle(
            defaultTextStyle: commonTextStyle,
            weekendTextStyle: commonTextStyle,
            outsideTextStyle: commonTextStyle.copyWith(color: Colors.grey[400]),

            // วันนอกเดือน
            outsideDecoration: const BoxDecoration(
              shape: BoxShape.rectangle,
            ),

            // วันที่ถูกล็อค (ถ้ามี)
            disabledDecoration: const BoxDecoration(
              shape: BoxShape.rectangle,
            ),

            // วันที่เลือก
            selectedDecoration: BoxDecoration(
              color: color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
            ),
            selectedTextStyle: commonTextStyle.copyWith(color: Colors.white),

            // วันนี้
            todayDecoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            todayTextStyle: commonTextStyle.copyWith(color: color),

            // ปรับส่วนของวันอื่นๆ
            defaultDecoration: const BoxDecoration(
              shape: BoxShape.rectangle,
            ),
            weekendDecoration: const BoxDecoration(
              shape: BoxShape.rectangle,
            ),
            holidayDecoration: const BoxDecoration(
              shape: BoxShape.rectangle,
            ),
          ),
        ),
      ),
    );
  }
}