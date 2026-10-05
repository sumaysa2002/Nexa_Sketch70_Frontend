import 'package:offline_gnss69_new/export.dart';

class List_Project_Card extends StatelessWidget {
  final String? userRole; // 'Editor' | 'Viewer'
  final String projectName;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> provinces;
  final VoidCallback? onTap;

  const List_Project_Card({
    required this.userRole,
    required this.projectName,
    required this.startDate,
    required this.endDate,
    required this.provinces,
    this.onTap,

    Key? key,
  }) : super(key: key);

  // แปลงวันที่เป็น String
  String _formatDate(DateTime date) {
    return date.toString().split(' ')[0]; // yyyy-MM-dd
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(1.5), // ความหนาของขอบ
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF18181C),
                Color(0xFFCFCFCF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF18181C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ไอคอน
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ชื่อโครงการ
                      Expanded(
                        child: Text(
                          projectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NotoSansThai',
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Role Editor / Viewer
                      if (userRole != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: userRole == 'Editor'
                                ? Colors.white.withOpacity(0.20)  // Editor
                                : Colors.white.withOpacity(0.08), // Viewer
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                userRole == 'Editor'
                                    ? Icons.edit_rounded
                                    : Icons.visibility_rounded,
                                size: 12,
                                color: userRole == 'Editor'
                                    ? Colors.white
                                    : Colors.white60,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                userRole!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'NotoSansThai',
                                  color: userRole == 'Editor'
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                    ],
                  ),
                ),

                /// Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // พื้นที่โครงการ
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        color: Colors.grey,
                        label: 'พื้นที่โครงการ',
                        value: provinces.isEmpty
                            ? '-'
                            : provinces.join(', '),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 15),

                      // ช่วงการสำรวจ
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        color: Colors.grey,
                        label: 'ช่วงการสำรวจ',
                        value: '${_formatDate(startDate)}  -  ${_formatDate(endDate)}',
                      ),

                    ],
                  ),
                ),

              ],
            ),     // ← เนื้อหาเดิมทั้งหมด
          ),
        )
    );
  }
}


// แสดงข้อมูลแต่ละบรรทัด
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // ไอคอน
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.black54,
            size: 18
          ),
        ),

        const SizedBox(width: 12),

        // label + value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF707078),
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF24252A),
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

      ],
    );
  }
}