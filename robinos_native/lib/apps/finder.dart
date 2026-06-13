import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/file_system.dart';
import '../system/platform_backend.dart';
import '../widgets/context_menu.dart';
import '../system/app_intents.dart';

// Finder — 가상 파일시스템 탐색 (폴더 이동·파일 미리보기·새 폴더)
class FinderApp extends StatefulWidget {
  const FinderApp({super.key});

  @override
  State<FinderApp> createState() => _FinderAppState();
}

class _FinderAppState extends State<FinderApp> {
  String _dir = '/';
  int _newCount = 0;
  Offset? _menuPos;
  FsEntry? _menuTarget;

  // 타일 우클릭 → Finder 내용 기준 좌표로 컨텍스트 메뉴 표시
  void _showMenu(FsEntry e, Offset globalPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    setState(() {
      _menuTarget = e;
      _menuPos = box.globalToLocal(globalPos);
    });
  }

  void _closeMenu() => setState(() {
        _menuPos = null;
        _menuTarget = null;
      });

  void _renameDialog(FsEntry e, SystemState sys) {
    final ctrl = TextEditingController(text: e.name);
    ctrl.selection = TextSelection(baseOffset: 0, extentOffset: e.name.length);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: sys.windowSurface,
        title: Text('이름 변경',
            style: TextStyle(color: sys.textPrimary, fontSize: 15)),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(color: sys.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: '새 이름',
              hintStyle: TextStyle(color: sys.textSec(0.35)),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: sys.chromeBorder)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: sys.accent)),
            ),
            onSubmitted: (_) => _doRename(e, ctrl.text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: sys.textSec(0.7))),
          ),
          TextButton(
            onPressed: () => _doRename(e, ctrl.text),
            child: Text('변경', style: TextStyle(color: sys.accent)),
          ),
        ],
      ),
    );
  }

  void _doRename(FsEntry e, String raw) {
    Navigator.pop(context);
    context.read<RobinFs>().rename(e.path, raw);
  }

  // .txt 파일을 메모 앱에서 열기 (Desktop이 듣고 메모 앱을 띄우고, NotesApp이 전환)
  void _openInNotes(FsEntry e) => notesOpenTarget.value = e.path;

  bool _isTxt(FsEntry e) => !e.isDir && e.name.toLowerCase().endsWith('.txt');

  void _open(FsEntry e, SystemState sys) {
    if (e.isDir) {
      setState(() => _dir = e.path);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: sys.windowSurface,
          title: Text(e.name, style: TextStyle(color: sys.textPrimary, fontSize: 15)),
          content: SizedBox(
            width: 360,
            child: Text(
              e.content.isEmpty ? '(빈 파일)' : e.content,
              style: TextStyle(color: sys.textSec(0.8), fontSize: 13, height: 1.5),
            ),
          ),
          actions: [
            if (e.name.toLowerCase().endsWith('.txt'))
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openInNotes(e);
                },
                child: Text('메모에서 열기', style: TextStyle(color: sys.accent)),
              ),
            TextButton(
              onPressed: () {
                context.read<RobinFs>().delete(e.path);
                Navigator.pop(context);
              },
              child: const Text('삭제', style: TextStyle(color: Color(0xFFFF5F57))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('닫기', style: TextStyle(color: sys.accent)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final fs = context.watch<RobinFs>();
    final items = fs.list(_dir);
    final menuTarget = _menuTarget;
    return Container(
      color: sys.windowSurface,
      child: Stack(
        children: [
          Column(
            children: [
          // 툴바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: sys.chromeBorder)),
            ),
            child: Row(
              children: [
                _toolBtn(sys, Icons.arrow_back_ios_new, _dir != '/', () {
                  setState(() => _dir = fs.get(_dir)?.parent ?? '/');
                }),
                const SizedBox(width: 10),
                // 실기기: 디스크 변경(터미널/외부)을 다시 읽어오는 새로고침.
                if (platformBackend.isReal) ...[
                  _toolBtn(sys, Icons.refresh, true,
                      () => context.read<RobinFs>().refresh()),
                  const SizedBox(width: 10),
                ],
                Flexible(child: _breadcrumb(sys)),
                const Spacer(),
                Text('${items.length}개',
                    style: TextStyle(fontSize: 12, color: sys.textSec(0.4))),
                const SizedBox(width: 12),
                _newFileBtn(sys, fs),
                const SizedBox(width: 8),
                _newFolderBtn(sys, fs),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('비어 있어요', style: TextStyle(color: sys.textSec(0.4))))
                : GridView.count(
                    crossAxisCount: 4,
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final e in items)
                        _tile(sys, e),
                    ],
                  ),
          ),
            ],
          ),
          if (_menuPos != null && menuTarget != null)
            ContextMenu(
              pos: _menuPos!,
              onClose: _closeMenu,
              items: [
                if (_isTxt(menuTarget))
                  CtxItem(
                    '메모에서 열기',
                    () => _openInNotes(menuTarget),
                    icon: Icons.sticky_note_2_outlined,
                  ),
                CtxItem(
                  menuTarget.isDir ? '열기' : '미리보기',
                  () => _open(menuTarget, sys),
                  icon: menuTarget.isDir
                      ? Icons.folder_open
                      : Icons.visibility_outlined,
                ),
                CtxItem(
                  '이름 변경',
                  () => _renameDialog(menuTarget, sys),
                  icon: Icons.drive_file_rename_outline,
                ),
                CtxItem(
                  '삭제',
                  () => context.read<RobinFs>().delete(menuTarget.path),
                  icon: Icons.delete_outline,
                  danger: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _toolBtn(SystemState sys, IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(icon, size: 16, color: sys.textSec(enabled ? 0.7 : 0.2)),
    );
  }

  // 경로 브레드크럼 (🏠 › 문서 …) — 조각 탭하면 그 폴더로 이동
  Widget _breadcrumb(SystemState sys) {
    final parts =
        _dir == '/' ? const <String>[] : _dir.split('/').where((s) => s.isNotEmpty).toList();
    final homeActive = _dir == '/';
    final crumbs = <Widget>[
      GestureDetector(
        onTap: () => setState(() => _dir = '/'),
        child: Icon(Icons.home_rounded,
            size: 16,
            color: homeActive ? sys.textPrimary : sys.textSec(0.6)),
      ),
    ];
    var acc = '';
    for (final p in parts) {
      acc = '$acc/$p';
      crumbs.add(Text('  ›  ', style: TextStyle(fontSize: 13, color: sys.textSec(0.3))));
      crumbs.add(_crumb(sys, p, acc));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: crumbs),
    );
  }

  Widget _crumb(SystemState sys, String label, String path) {
    final active = path == _dir;
    return GestureDetector(
      onTap: () => setState(() => _dir = path),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: active ? sys.textPrimary : sys.textSec(0.6),
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _newFolderBtn(SystemState sys, RobinFs fs) {
    return GestureDetector(
      onTap: () {
        _newCount++;
        fs.mkdir(_dir, '새 폴더${_newCount > 1 ? ' $_newCount' : ''}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sys.textSec(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('+ 새 폴더', style: TextStyle(fontSize: 12, color: sys.textSec(0.8))),
      ),
    );
  }

  Widget _newFileBtn(SystemState sys, RobinFs fs) {
    String pathOf(String nm) => _dir == '/' ? '/$nm' : '$_dir/$nm';
    return GestureDetector(
      onTap: () {
        var name = '새 메모.txt';
        var n = 2;
        while (fs.exists(pathOf(name))) {
          name = '새 메모 $n.txt';
          n++;
        }
        fs.write(pathOf(name), '');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sys.textSec(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('+ 새 파일', style: TextStyle(fontSize: 12, color: sys.textSec(0.8))),
      ),
    );
  }

  Widget _tile(SystemState sys, FsEntry e) {
    return GestureDetector(
      onTap: () => _open(e, sys),
      onSecondaryTapDown: (d) => _showMenu(e, d.globalPosition),
      onLongPressStart: (d) => _showMenu(e, d.globalPosition),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _itemIcon(sys, e),
          const SizedBox(height: 6),
          Text(
            e.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: sys.textSec(0.85)),
          ),
        ],
      ),
    );
  }

  // 파일/폴더 아이콘 — 이모지 대신 RobinOS 글리프 언어(폴더=블루, 타입별 색).
  Widget _itemIcon(SystemState sys, FsEntry e) {
    if (e.isDir) {
      return const Icon(Icons.folder_rounded, size: 46, color: Color(0xFF5AA6FF));
    }
    final (glyph, color) = _fileGlyph(e.name);
    return Icon(glyph, size: 44, color: color);
  }

  (IconData, Color) _fileGlyph(String name) {
    final n = name.toLowerCase();
    bool ext(List<String> xs) => xs.any(n.endsWith);
    if (ext(['.txt', '.md', '.log', '.rtf'])) {
      return (Icons.description_rounded, const Color(0xFF8FA0B8));
    }
    if (ext(['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.svg'])) {
      return (Icons.image_rounded, const Color(0xFFFF6FA5));
    }
    if (ext(['.mp3', '.flac', '.wav', '.ogg', '.m4a', '.aac', '.opus'])) {
      return (Icons.music_note_rounded, const Color(0xFFFF9F4A));
    }
    if (ext(['.mp4', '.mkv', '.webm', '.mov', '.avi'])) {
      return (Icons.movie_rounded, const Color(0xFFB57BFF));
    }
    if (ext(['.pdf'])) {
      return (Icons.picture_as_pdf_rounded, const Color(0xFFFF5A5F));
    }
    if (ext(['.zip', '.tar', '.gz', '.xz', '.7z', '.rar'])) {
      return (Icons.folder_zip_rounded, const Color(0xFFC8A24A));
    }
    if (ext(['.dart', '.py', '.c', '.h', '.js', '.ts', '.json', '.yaml', '.yml',
        '.sh', '.html', '.css', '.xml'])) {
      return (Icons.code_rounded, const Color(0xFF49D17A));
    }
    return (Icons.insert_drive_file_rounded, const Color(0xFF9AA3AE));
  }
}
