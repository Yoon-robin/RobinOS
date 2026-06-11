import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/file_system.dart';

// Finder — 가상 파일시스템 탐색 (폴더 이동·파일 미리보기·새 폴더)
class FinderApp extends StatefulWidget {
  const FinderApp({super.key});

  @override
  State<FinderApp> createState() => _FinderAppState();
}

class _FinderAppState extends State<FinderApp> {
  String _dir = '/';
  int _newCount = 0;

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
    return Container(
      color: sys.windowSurface,
      child: Column(
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
                Text(_dir, style: TextStyle(fontSize: 13, color: sys.textPrimary, fontWeight: FontWeight.w600)),
                const Spacer(),
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
    );
  }

  Widget _toolBtn(SystemState sys, IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(icon, size: 16, color: sys.textSec(enabled ? 0.7 : 0.2)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.isDir ? '📁' : '📄', style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 4),
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
}
