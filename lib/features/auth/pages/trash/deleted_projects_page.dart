import 'package:nexa_sketch/export.dart';

class Deleted_Projects_Page extends StatelessWidget {
  const Deleted_Projects_Page({super.key});

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (_) => const Deleted_Projects_Page(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrashCubit(),
      child: const _DeletedProjectsView(),
    );
  }
}

class _DeletedProjectsView extends StatefulWidget {
  const _DeletedProjectsView();

  @override
  State<_DeletedProjectsView> createState() => _DeletedProjectsViewState();
}

class _DeletedProjectsViewState extends State<_DeletedProjectsView> {
  List<DeletedProject>? _items;
  String? _error;
  bool _offline = false;
  bool _loading = true;
  int? _busyId;          // id โครงการที่กำลังกู้คืน / ลบถาวร
  bool _purgingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load({bool silent = false}) {
    final token = trashToken(context);
    if (token == null) return;
    context.read<TrashCubit>().loadDeletedProjects(token: token, silent: silent);
  }

  Future<void> _onRestore(DeletedProject item) async {
    final ok = await confirmTrashRestore(
      context,
      text: 'ยืนยันกู้คืนโครงการ',
    );
    if (!ok || !mounted) return;

    final token = trashToken(context);
    if (token == null) return;

    setState(() => _busyId = item.project.id);
    context.read<TrashCubit>().restoreProject(
        token: token,
        projectId: item.project.id
    );
  }

  /// ลบถาวรโครงการเดียว (ก่อนครบ 30 วัน)
  Future<void> _onPurge(DeletedProject item) async {
    final ok = await confirmTrashPurge(
      context,
      text: 'ยืนยันลบโครงการแบบถาวร\nโดยจะไม่สามารถกู้คืนได้อีก',
    );
    if (!ok || !mounted) return;

    final token = trashToken(context);
    if (token == null) return;

    setState(() => _busyId = item.project.id);
    context.read<TrashCubit>().purgeProject(token: token, projectId: item.project.id);
  }

  /// ลบถาวรทุกโครงการ
  Future<void> _onPurgeAll() async {
    final count = _items?.length ?? 0;
    final ok = await confirmTrashPurge(
      context,
      text: 'ยืนยันลบโครงการทั้งหมด $count โครงการแบบถาวร\nโดยจะไม่สามารถกู้คืนได้อีก',
    );
    if (!ok || !mounted) return;

    final token = trashToken(context);
    if (token == null) return;

    setState(() => _purgingAll = true);
    context.read<TrashCubit>().purgeAllProjects(token: token);
  }

  Future<void> _openDetail(DeletedProject item) async {
    final restored = await Navigator.of(context).push<bool>(
      Deleted_Project_Detail_Page.route(item),
    );
    if (!mounted) return;
    if (restored == true) showTrashSnack(context, 'กู้คืนโครงการสำเร็จ');
    _load(silent: true);
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
          } else if (state is DeletedProjectsLoaded) {
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
          } else if (state is RestoreProjectSuccess) {
            showTrashSnack(context, 'กู้คืนโครงการสำเร็จ');
          } else if (state is RestoreFailed) {
            setState(() => _busyId = null);
            showTrashSnack(context, state.message, error: true);
          } else if (state is PurgeSuccess) {
            showTrashSnack(
              context,
              state.count > 1 ? 'ลบโครงการทั้งหมด ${state.count} โครงการสำเร็จ' : 'ลบโครงการแบบถาวรสำเร็จ',
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

            const TrashHeader(title: 'ประวัติการลบโครงการ'),

            const SizedBox(height: 8),

            const TrashInfoBanner(
                text: 'โครงการที่ถูกลบจะถูกจัดเก็บไว้เป็นเวลา 30 วัน หลังจากครบกำหนด ระบบจะลบโครงการและข้อมูลหมุดรังวัดทั้งหมดอย่างถาวร'
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
        icon: _offline
            ? Icons.wifi_off_rounded
            : Icons.error_outline_rounded,
        text: _error!,
        onRetry: _load,
      );
    }

    final items = _items ?? const <DeletedProject>[];
    if (items.isEmpty) {
      return const TrashMessage(
        icon: Icons.delete_outline_rounded,
        text: 'ไม่มีโครงการที่ถูกลบ',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _load(silent: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final pj = item.project;
          return List_Project_Card(
            userRole: null,
            projectName: pj.projectName,
            startDate: pj.projectStartDate != null
                ? (DateTime.tryParse(pj.projectStartDate!) ?? DateTime.now())
                : DateTime.now(),
            endDate: pj.projectEndDate != null
                ? (DateTime.tryParse(pj.projectEndDate!) ?? DateTime.now())
                : DateTime.now(),
            provinces: pj.province != null ? pj.province!.split(', ') : [],
            onTap: () => _openDetail(item),

            /// แถบกู้คืนโครงการ
            footer: TrashRestoreStrip(
              embedded: true,
              margin: EdgeInsets.zero,
              deletedAt: item.deletedAt,
              deletedByName: item.deletedByName,
              daysLeft: item.daysLeft,
              restoreLabel: 'กู้คืนโครงการ',
              busy: _busyId == pj.id || _purgingAll,
              onRestore: () => _onRestore(item),
              onPurge: () => _onPurge(item),
            ),
          );
        },
      ),
    );
  }
}