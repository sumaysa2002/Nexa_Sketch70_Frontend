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
    final img = point.pointZoominImg;
    // หมุดที่ยังไม่ sync >> รูปอยู่ในเครื่อง (local://...)
    final isLocalImg = img != null && img.startsWith('local://');

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

                  // ชื่อหมุด (1 บรรทัด ยาวเกินตัดเป็น)
                  Expanded(
                    child: Tooltip(
                      message: _orDash(point.pointName),
                      triggerMode: TooltipTriggerMode.longPress,
                      child: Text(
                        _orDash(point.pointName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NotoSansThai',
                          color: Color(0xFF24252A),
                        ),
                      ),
                    ),
                  ),

                  // ป้ายสถานะ sync
                  if (point.isPendingSync) ...[
                    const SizedBox(width: 8),
                    // จำกัดความกว้างป้าย
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: _SyncBadge(status: point.syncStatus, error: point.syncError),
                    ),
                  ],
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
                        child: img == null
                            ? _placeholder()
                            : isLocalImg
                            ? Image.file(
                          File(img.replaceFirst('local://', '')),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                            : Image.network(
                          SecureImage.pointUrl(point.projectId, point.id, img),
                          headers: SecureImage.headers(context),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
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


/// ── ป้ายสถานะ sync บน card หมุด ─────────────────────────────────────
/// แตะที่ป้าย (ถ้ามี error) >> แสดงสาเหตุที่ sync ไม่ผ่าน
class _SyncBadge extends StatelessWidget {
  final PointSyncStatus status;
  final String? error;

  const _SyncBadge({required this.status, this.error});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      PointSyncStatus.pendingCreate => ('รอ sync',        Icons.cloud_upload_outlined, const Color(0xFF448AFF)),
      PointSyncStatus.pendingUpdate => ('แก้ไขรอ sync',    Icons.sync,                  const Color(0xFF448AFF)),
      PointSyncStatus.failed        => ('sync ไม่สำเร็จ',    Icons.error_outline,         const Color(0xFFE53935)),
      PointSyncStatus.synced        => ('',               Icons.check,                 Colors.green),
    };

    final hasError = error != null && error!.trim().isNotEmpty;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoSansThai',
                color: color,
              ),
            ),
          ),

          // เคย sync ไม่ผ่าน >> มีจุดบอกว่าแตะดูสาเหตุได้
          if (hasError && status != PointSyncStatus.failed) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );

    if (!hasError) return badge;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              status == PointSyncStatus.failed
                  ? 'sync ข้อมูลไม่สำเร็จ: $error\nแก้ไขข้อมูลหมุดรังวัด หรือออกจากระบบเพื่อ sync ข้อมูลอีกครั้ง'
                  : 'sync ข้อมูลครั้งล่าสุดไม่สำเร็จ: $error\nระบบจะลองส่งข้อมูลใหม่อีกครั้ง',
            ),
          ),
        );
      },
      child: badge,
    );
  }
}