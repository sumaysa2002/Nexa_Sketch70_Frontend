import 'package:offline_gnss69_new/export.dart';

class List_Point_Card extends StatelessWidget {
  final PointModel point;
  final VoidCallback? onTap;

  const List_Point_Card({
    required this.point,
    this.onTap,
    Key? key,
  }) : super(key: key);

  String _orDash(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;

  @override
  Widget build(BuildContext context) {
    final picUrl = point.pointZoominImg != null
        ? '${Constants.backendUri}/uploads/point/${point.projectId}/${point.id}/${point.pointZoominImg}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        /// Card ขาวด้านใน
        child: Container(
          margin: const EdgeInsets.all(1.5), // ขอบ gradient
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                children: [

                  // ไอคอน
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        Icons.my_location_sharp,
                        color: Colors.blueAccent,
                        size: 18
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _orDash(point.pointName),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansThai',
                        color: Color(0xFF24252A),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              const Divider(),

              const SizedBox(height: 5),

              const SizedBox(height: 8),

              /// COORDINATE
              _InfoRow(label: 'N :', value: _orDash(point.northing)),
              _InfoRow(label: 'E :', value: _orDash(point.easting)),

              const SizedBox(height: 8),

              /// LOCATION
              _InfoRow(label: 'ตำบล :', value: _orDash(point.tambon)),
              _InfoRow(label: 'อำเภอ :', value: _orDash(point.amphoe)),
              _InfoRow(label: 'จังหวัด :', value: _orDash(point.province)),

              const SizedBox(height: 5),

              const Divider(),

              const SizedBox(height: 5),

              /// IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: picUrl != null
                            ? Image.network(
                          picUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                            : _placeholder(),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.photo_outlined, size: 40, color: Colors.grey),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF707078),
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansThai',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansThai',
                color: Color(0xFF24252A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}