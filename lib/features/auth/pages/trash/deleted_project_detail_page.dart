import 'package:nexa_sketch/export.dart';

class Deleted_Project_Detail_Page extends StatelessWidget {
  final DeletedProject item;

  const Deleted_Project_Detail_Page({super.key, required this.item});

  static MaterialPageRoute<bool> route(DeletedProject item) => MaterialPageRoute<bool>(
    builder: (_) => Deleted_Project_Detail_Page(item: item),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrashCubit(),
      child: _DeletedProjectDetailView(item: item),
    );
  }
}

class _DeletedProjectDetailView extends StatefulWidget {
  final DeletedProject item;
  const _DeletedProjectDetailView({required this.item});

  @override
  State<_DeletedProjectDetailView> createState() => _DeletedProjectDetailViewState();
}

class _DeletedProjectDetailViewState extends State<_DeletedProjectDetailView> {
  List<PointModel>? _points;
  String? _error;
  bool _offline = false;
  bool _loading = true;
  bool _restoring = false;

  ProjectModel get _project => widget.item.project;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final token = trashToken(context);
    if (token == null) return;
    context.read<TrashCubit>().loadPointsOfDeletedProject(token: token, projectId: _project.id);
  }

  Future<void> _onRestore() async {
    final ok = await confirmTrashRestore(
      context,
      text: 'ยืนยันกู้คืนโครงการ',
    );
    if (!ok || !mounted) return;

    final token = trashToken(context);
    if (token == null) return;

    setState(() => _restoring = true);
    context.read<TrashCubit>().restoreProject(
      token: token,
      projectId: _project.id,
      reloadList: false,
    );
  }

  String _dateText(String? iso) {
    return displayDate(iso);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final pj = _project;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _restoring ? null : _onRestore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _restoring
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white
                  ))
                  : const Icon(Icons.refresh),
              label: const Text(
                  'กู้คืนโครงการ',
                  style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 15
                  )
              ),
            ),
          ),
        ),
      ),
      body: BlocListener<TrashCubit, TrashState>(
        listener: (context, state) {
          if (state is TrashLoading) {
            setState(() {
              _loading = true;
              _error = null;
            });
          } else if (state is DeletedProjectPointsLoaded) {
            setState(() {
              _points = state.points;
              _loading = false;
              _error = null;
            });
          } else if (state is TrashLoadFailed) {
            setState(() {
              _loading = false;
              _error = state.message;
              _offline = state.offline;
            });
          } else if (state is RestoreProjectSuccess) {
            Navigator.of(context).pop(true);
          } else if (state is RestoreFailed) {
            setState(() => _restoring = false);
            showTrashSnack(context, state.message, error: true);
          }
        },
        child: Column(
          children: [
            TrashHeader(
              title: pj.projectName,
              subtitle: 'รายละเอียดโครงการที่ถูกลบ',
              textOffsetY: -20,
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const SizedBox(height: 8),

                        TrashInfoBanner(
                          text: '${trashDaysLeftText(it.daysLeft)}\n'
                              'ลบเมื่อ ${formatTrashDate(it.deletedAt)}'
                              '${it.deletedByName != null ? '         โดย ${it.deletedByName}' : ''}',
                        ),

                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TrashInfoLine(label: 'ชื่อโครงการ', value: pj.projectName),
                              TrashInfoLine(label: 'ID โครงการ', value: pj.nameProjectId),
                              TrashInfoLine(label: 'รายละเอียดโครงการ', value: pj.projectDetails),
                              TrashInfoLine(label: 'จังหวัด', value: pj.province),
                              TrashInfoLine(label: 'Sensor', value: pj.sensor),
                              TrashInfoLine(
                                label: 'Ground Sample Distance\n(GSD)',
                                value: pj.gsdNum == null ? null : '${pj.gsdNum} ${pj.gsdUnit ?? ''}'.trim(),
                              ),
                              TrashInfoLine(label: 'วิธีการรังวัดหลัก', value: pj.surveyMain),
                              TrashInfoLine(label: 'วิธีการรังวัดย่อย', value: pj.surveySub),
                              TrashInfoLine(label: 'วันเริ่มต้นการสำรวจ', value: _dateText(pj.projectStartDate)),
                              TrashInfoLine(label: 'วันสิ้นสุดการสำรวจ', value: _dateText(pj.projectEndDate)),
                              TrashInfoLine(label: 'หมายเหตุ', value: pj.projectNote),
                              TrashInfoLine(label: 'จำนวนสมาชิกในโครงการ', value: '${pj.memberIds.length} คน'),
                              TrashInfoLine(label: 'จำนวนหมุดรังวัด', value: '${it.pointCount} หมุด'),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(30, 12, 30, 4),
                          child: Text(
                            'หมุดรังวัดในโครงการ',
                            style: TextStyle(
                              fontFamily: 'NotoSansThai',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18181C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._buildPointSlivers(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPointSlivers() {
    if (_loading && _points == null) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    if (_error != null && _points == null) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: TrashMessage(
              icon: _offline
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              text: _error!,
              onRetry: _load,
            ),
          ),
        ),
      ];
    }

    final points = _points ?? const <PointModel>[];
    if (points.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: TrashMessage(
              icon: Icons.location_off,
              text: 'ไม่มีหมุดรังวัดในโครงการ'
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            mainAxisExtent: 475,
          ),
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final p = points[index];
              return List_Point_Card(
                point: p,
                fromTrash: true,
                onTap: () => Navigator.of(context).push(
                  Deleted_Point_Detail_Page.route(point: p),
                ),
              );
            },
            childCount: points.length,
          ),
        ),
      ),
    ];
  }
}