import 'package:nexa_sketch/export.dart';

class Deleted_Points_Page extends StatelessWidget {
  final ProjectModel project;

  const Deleted_Points_Page({super.key, required this.project});

  static MaterialPageRoute route(ProjectModel project) => MaterialPageRoute(
    builder: (_) => Deleted_Points_Page(project: project),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrashCubit(),
      child: _DeletedPointsView(project: project),
    );
  }
}

class _DeletedPointsView extends StatefulWidget {
  final ProjectModel project;
  const _DeletedPointsView({required this.project});

  @override
  State<_DeletedPointsView> createState() => _DeletedPointsViewState();
}

class _DeletedPointsViewState extends State<_DeletedPointsView> {
  List<DeletedPoint>? _items;
  String? _error;
  bool _offline = false;
  bool _loading = true;
  int? _busyId;          // id หมุดที่กำลังกู้คืน / ลบถาวร
  bool _purgingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load({bool silent = false}) {
    final token = trashToken(context);
    if (token == null) return;
    context.read<TrashCubit>().loadDeletedPoints(
      token: token,
      projectId: widget.project.id,
      silent: silent,
    );
  }

  /// ปุ่มกู้คืนที่การ์ด >> ถามยืนยันก่อน แล้วค่อยกู้คืน
  Future<void> _onRestore(DeletedPoint item) async {
    final ok = await confirmTrashRestore(
      context,
      text: 'ยืนยันกู้คืนหมุดรังวัด',
    );
    if (!ok || !mounted) return;
    _restore(item);
  }

  /// กู้คืนทันที (ไม่ถามยืนยันซ้ำ) — ใช้ทั้งจากการ์ดหลังยืนยันแล้ว และจากหน้ารายละเอียดที่ยืนยันมาแล้ว
  void _restore(DeletedPoint item) {
    final token = trashToken(context);
    if (token == null) return;

    setState(() => _busyId = item.point.id);
    context.read<TrashCubit>().restorePoint(
      token: token,
      projectId: widget.project.id,
      pointId: item.point.id,
    );
  }

  /// ลบถาวรหมุดเดียว (ก่อนครบ 30 วัน)
  Future<void> _onPurge(DeletedPoint item) async {
    final ok = await confirmTrashPurge(
      context,
      text: 'ยืนยันลบหมุดรังวัดแบบถาวร\nโดยจะไม่สามารถกู้คืนได้อีก',
    );
    if (!ok || !mounted) return;

    final token = trashToken(context);
    if (token == null) return;

    setState(() => _busyId = item.point.id);
    context.read<TrashCubit>().purgePoint(
      token: token,
      projectId: widget.project.id,
      pointId: item.point.id,
    );
  }

  /// ลบถาวรทุกหมุดในประวัติการลบของโครงการ
  Future<void> _onPurgeAll() async {
    final count = _items?.length ?? 0;
    final ok = await confirmTrashPurge(
      context,
      text: 'ยืนยันลบหมุดรังวัดทั้งหมด $count หมุดแบบถาวร\nโดยจะไม่สามารถกู้คืนได้อีก',
    );
    if (!ok || !mounted) return;

    final token = trashToken(context);
    if (token == null) return;

    setState(() => _purgingAll = true);
    context.read<TrashCubit>().purgeAllPoints(token: token, projectId: widget.project.id);
  }

  /// กดเข้าไปดูข้อมูลหมุด >> ถ้ากดปุ่ม "กู้คืน" และยืนยันในหน้านั้นแล้ว จะกลับมาพร้อมค่า true
  Future<void> _openDetail(DeletedPoint item) async {
    final wantRestore = await Navigator.of(context).push<bool>(
      Deleted_Point_Detail_Page.route(
        point: item.point,
        deletedAt: item.deletedAt,
        deletedByName: item.deletedByName,
        daysLeft: item.daysLeft,
        restoreLabel: 'กู้คืนหมุดรังวัด',
      ),
    );
    if (!mounted) return;
    if (wantRestore == true) _restore(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      /// ปุ่มลบทั้งหมด
      bottomNavigationBar: (_items != null && _items!.isNotEmpty)
          ? TrashPurgeAllButton(
        onPressed: _busyId == null ? _onPurgeAll : null,
        busy: _purgingAll,
      )
          : Container(
        width: double.infinity,
        height: 80,
        color: const Color(0xFFFAFAFA),
      ),
      body: BlocListener<TrashCubit, TrashState>(
        listener: (context, state) {
          if (state is TrashLoading) {
            setState(() {
              _loading = true;
              _error = null;
            });
          } else if (state is DeletedPointsLoaded) {
            setState(() {
              _items = state.items;
              _loading = false;
              _error = null;
              _busyId = null;
              _purgingAll = false;
            });
          } else if (state is TrashLoadFailed) {
            setState(() {
              _loading = false;
              _error = state.message;
              _offline = state.offline;
              _busyId = null;
              _purgingAll = false;
            });
          } else if (state is RestorePointSuccess) {
            showTrashSnack(context, 'กู้คืนหมุดรังวัดสำเร็จ');
          } else if (state is RestoreFailed) {
            setState(() => _busyId = null);
            showTrashSnack(context, state.message, error: true);
          } else if (state is PurgeSuccess) {
            showTrashSnack(
              context,
              state.count > 1 ? 'ลบหมุดรังวัดทั้งหมด ${state.count} หมุดสำเร็จ' : 'ลบหมุดรังวัดแบบถาวรสำเร็จ',
            );
          } else if (state is PurgeFailed) {
            setState(() {
              _busyId = null;
              _purgingAll = false;
            });
            showTrashSnack(context, state.message, error: true);
          }
        },
        child: Column(
          children: [

            TrashHeader(
              title: 'ประวัติการลบหมุดรังวัด',
              subtitle: widget.project.projectName,
            ),

            const SizedBox(height: 8),

            const TrashInfoBanner(
                text: 'หมุดรังวัดที่ลบจะถูกจัดเก็บไว้เป็นเวลา 30 วัน หลังจากครบกำหนด ระบบจะลบข้อมูลหมุดรังวัดทั้งหมดอย่างถาวร'
            ),


            Expanded(child: _buildBody()),


          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items == null) {
      return TrashMessage(
        icon: _offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
        text: _error!,
        onRetry: _load,
      );
    }

    final items = _items ?? const <DeletedPoint>[];
    if (items.isEmpty) {
      return const TrashMessage(
        icon: Icons.delete_outline_rounded,
        text: 'ไม่มีหมุดรังวัดที่ถูกลบ',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _load(silent: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          mainAxisExtent: 630,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: List_Point_Card(
              point: item.point,
              fromTrash: true,
              onTap: () => _openDetail(item),

              /// แถบกู้คืนหมุด
              footer: TrashRestoreStrip(
                embedded: true,
                margin: EdgeInsets.zero,
                deletedAt: item.deletedAt,
                deletedByName: item.deletedByName,
                daysLeft: item.daysLeft,
                restoreLabel: 'กู้คืน',
                busy: _busyId == item.point.id || _purgingAll,
                onRestore: () => _onRestore(item),
                onPurge: () => _onPurge(item),
              ),
            ),
          );
        },
      ),
    );
  }
}