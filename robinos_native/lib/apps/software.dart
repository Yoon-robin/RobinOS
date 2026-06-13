import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/platform_backend.dart';
import '../widgets/anim.dart';

// 소프트웨어 센터 — apt 패키지 검색·설치 (리눅스). 칼리/우분투 소프트웨어 센터 대응.
// 검색은 apt-cache, 설치는 pkexec(polkit 암호). 웹/개발 모드는 안내만.
class SoftwareApp extends StatefulWidget {
  const SoftwareApp({super.key});

  @override
  State<SoftwareApp> createState() => _SoftwareAppState();
}

class _SoftwareAppState extends State<SoftwareApp> {
  final _ctrl = TextEditingController();
  bool _searching = false;
  bool _did = false;
  List<PackageInfo> _results = const [];
  final _installing = <String>{};
  String? _status;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _did = true;
      _status = null;
    });
    final r = await platformBackend.searchPackages(q);
    if (!mounted) return;
    setState(() {
      _results = r;
      _searching = false;
    });
  }

  Future<void> _install(PackageInfo p) async {
    setState(() {
      _installing.add(p.name);
      _status = null;
    });
    await platformBackend.installPackage(p.name);
    if (!mounted) return;
    setState(() {
      _installing.remove(p.name);
      _status = '${p.name} 설치를 요청했어요(암호 창에서 진행). 끝나면 다시 검색해 보세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Container(
      color: sys.windowSurface,
      child: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    onSubmitted: (_) => _search(),
                    style: TextStyle(fontSize: 14, color: sys.textPrimary),
                    decoration: InputDecoration(
                      hintText: '패키지 검색 (예: firefox, gimp, vlc)',
                      hintStyle: TextStyle(color: sys.textSec(0.4), fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search, size: 20, color: sys.textSec(0.5)),
                      isDense: true,
                      filled: true,
                      fillColor: sys.textSec(0.06),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _searching ? null : _search,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: sys.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('검색',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body(sys)),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(_status!,
                  style: TextStyle(fontSize: 11.5, color: sys.textSec(0.6))),
            ),
        ],
      ),
    );
  }

  Widget _body(SystemState sys) {
    if (!platformBackend.isReal) {
      return _center(sys,
          '소프트웨어 검색·설치는 리눅스 실기기(apt)에서 돼요.\n지금은 웹/개발 모드예요.');
    }
    if (_searching) {
      return Center(
          child: SizedBox(
              width: 26,
              height: 26,
              child:
                  CircularProgressIndicator(strokeWidth: 2.5, color: sys.accent)));
    }
    if (!_did) {
      return _center(sys, '설치할 앱을 검색해 보세요.\nfirefox · gimp · vlc · libreoffice …');
    }
    if (_results.isEmpty) {
      return _center(sys, '검색 결과가 없어요. 다른 이름으로 찾아보세요.');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: _results.length,
      itemBuilder: (_, i) =>
          StaggerIn(index: i, child: _row(sys, _results[i])),
    );
  }

  Widget _row(SystemState sys, PackageInfo p) {
    final installing = _installing.contains(p.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: sys.textSec(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: sys.accent.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.inventory_2_outlined,
                size: 18, color: sys.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: sys.textPrimary)),
                const SizedBox(height: 1),
                Text(p.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: sys.textSec(0.55))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (p.installed)
            Text('설치됨',
                style: TextStyle(
                    fontSize: 12,
                    color: sys.textSec(0.5),
                    fontWeight: FontWeight.w600))
          else
            GestureDetector(
              onTap: installing ? null : () => _install(p),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sys.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: sys.accent.withValues(alpha: 0.5)),
                ),
                child: installing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: sys.accent))
                    : Text('설치',
                        style: TextStyle(
                            fontSize: 12,
                            color: sys.accent,
                            fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _center(SystemState sys, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(text,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: sys.textSec(0.5), height: 1.5)),
        ),
      );
}
