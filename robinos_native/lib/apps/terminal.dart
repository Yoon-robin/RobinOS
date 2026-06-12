import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/file_system.dart';
import '../system/platform_backend.dart';
import '../widgets/clock.dart';

// 터미널 — 리눅스 실기기면 진짜 bash, 그 외엔 RobinFs 가상 셸
class TerminalApp extends StatefulWidget {
  const TerminalApp({super.key});

  @override
  State<TerminalApp> createState() => _TerminalAppState();
}

class _TerminalAppState extends State<TerminalApp> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final List<String> _lines = [
    'RobinOS 터미널 — "help" 입력',
  ];
  String _dir = '/'; // RobinFs 가상 셸용 현재 폴더
  String _realCwd = ''; // 진짜 bash용 현재 디렉터리(빈 값=홈)

  bool get _isReal => platformBackend.isReal;
  String get _promptDir => _isReal ? (_realCwd.isEmpty ? '~' : _realCwd) : _dir;

  // 진짜 bash 실행 (리눅스). cd는 cwd 추적, 나머지는 bash -c.
  Future<void> _runReal(String cmd) async {
    setState(() => _ctrl.clear());
    if (cmd.isEmpty) {
      _scrollDown();
      _focus.requestFocus();
      return;
    }
    if (cmd == 'clear') {
      setState(() => _lines.clear());
      _focus.requestFocus();
      return;
    }
    if (cmd == 'cd' || cmd.startsWith('cd ')) {
      final target = cmd == 'cd' ? r'$HOME' : cmd.substring(3).trim();
      final out = await platformBackend.runShell('cd $target && pwd', _realCwd);
      if (!mounted) return;
      final p = (out ?? '').trim();
      setState(() {
        if (p.startsWith('/') && !p.contains('\n')) {
          _realCwd = p;
        } else if (p.isNotEmpty) {
          _lines.add(p);
        }
      });
      _scrollDown();
      _focus.requestFocus();
      return;
    }
    final out = await platformBackend.runShell(cmd, _realCwd);
    if (!mounted) return;
    setState(() {
      final text = (out ?? '').trimRight();
      if (text.isNotEmpty) _lines.add(text);
    });
    _scrollDown();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _run(String raw) {
    final cmd = raw.trim();
    _lines.add('robin@robinos:$_promptDir\$ $cmd');
    if (_isReal) {
      _runReal(cmd);
      return;
    }
    final fs = context.read<RobinFs>();
    final parts = cmd.split(RegExp(r'\s+'));
    final name = parts.isEmpty ? '' : parts.first;
    final arg = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    switch (name) {
      case '':
        break;
      case 'help':
        _lines.add('명령어: help, ls, cd <폴더>, pwd, cat <파일>, echo <텍스트>,');
        _lines.add('        mkdir <폴더>, touch <파일>, write <파일> <내용>,');
        _lines.add('        rm <대상>, mv <원래> <새이름>, date, whoami, robinos, clear');
        break;
      case 'ls':
        final items = fs.list(_dir);
        _lines.add(items.isEmpty
            ? '(비어 있음)'
            : items.map((e) => e.isDir ? '${e.name}/' : e.name).join('   '));
        break;
      case 'pwd':
        _lines.add(_dir);
        break;
      case 'cd':
        if (arg == '..' || arg == '../') {
          _dir = fs.get(_dir)?.parent ?? '/';
        } else if (arg == '/' || arg.isEmpty) {
          _dir = '/';
        } else {
          final target = _dir == '/' ? '/$arg' : '$_dir/$arg';
          final e = fs.get(target);
          if (e != null && e.isDir) {
            _dir = target;
          } else {
            _lines.add('cd: $arg: 그런 폴더가 없어요');
          }
        }
        break;
      case 'cat':
        final target = arg.startsWith('/')
            ? arg
            : (_dir == '/' ? '/$arg' : '$_dir/$arg');
        final e = fs.get(target);
        _lines.add(e == null
            ? 'cat: $arg: 그런 파일이 없어요'
            : (e.isDir ? 'cat: $arg: 폴더예요' : e.content));
        break;
      case 'echo':
        _lines.add(arg);
        break;
      case 'mkdir':
        if (arg.isEmpty) {
          _lines.add('mkdir: 폴더 이름을 입력하세요');
        } else {
          fs.mkdir(_dir, arg);
          _lines.add('폴더 만듦: $arg');
        }
        break;
      case 'touch':
        if (arg.isEmpty) {
          _lines.add('touch: 파일 이름을 입력하세요');
        } else {
          final p = _dir == '/' ? '/$arg' : '$_dir/$arg';
          if (!fs.exists(p)) fs.write(p, '');
          _lines.add('파일 만듦: $arg');
        }
        break;
      case 'write':
        final sp = arg.indexOf(' ');
        if (sp < 1) {
          _lines.add('사용법: write <파일> <내용>');
        } else {
          final fname = arg.substring(0, sp);
          final content = arg.substring(sp + 1);
          final p = fname.startsWith('/')
              ? fname
              : (_dir == '/' ? '/$fname' : '$_dir/$fname');
          fs.write(p, content);
          _lines.add('저장: $fname (${content.length}자)');
        }
        break;
      case 'rm':
        if (arg.isEmpty) {
          _lines.add('rm: 대상을 입력하세요');
        } else {
          final p = arg.startsWith('/')
              ? arg
              : (_dir == '/' ? '/$arg' : '$_dir/$arg');
          if (fs.exists(p)) {
            fs.delete(p);
            _lines.add('삭제: $arg');
          } else {
            _lines.add('rm: $arg: 그런 항목이 없어요');
          }
        }
        break;
      case 'mv':
        final mv = arg.split(RegExp(r'\s+'));
        if (mv.length < 2 || mv[0].isEmpty) {
          _lines.add('사용법: mv <원래> <새이름>');
        } else {
          final from = mv[0].startsWith('/')
              ? mv[0]
              : (_dir == '/' ? '/${mv[0]}' : '$_dir/${mv[0]}');
          final to = fs.rename(from, mv[1]);
          _lines.add(to == null
              ? 'mv: 실패 (대상이 없거나 이름이 겹쳐요)'
              : '이름 변경: ${mv[0]} → ${mv[1]}');
        }
        break;
      case 'date':
        final now = DateTime.now();
        _lines.add('${robinDate(now)} ${robinTime(now)}');
        break;
      case 'whoami':
        _lines.add('robin');
        break;
      case 'robinos':
        _lines.add('  ╭─────────────╮');
        _lines.add('  │   RobinOS   │  네이티브 빌드 · Flutter');
        _lines.add('  ╰─────────────╯  개인 에이전트 Robin 탑재');
        break;
      case 'clear':
        _lines.clear();
        break;
      default:
        _lines.add('$name: 명령을 찾을 수 없어요 ("help" 참고)');
    }
    setState(() => _ctrl.clear());
    _scrollDown();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0C0C12);
    const fg = Color(0xFFD6D6E0);
    const green = Color(0xFF5BE49B);
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Container(
        color: bg,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemCount: _lines.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    _lines[i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.4,
                      color: fg,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Text('robin@robinos:$_promptDir\$ ',
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13, color: green)),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    autofocus: true,
                    onSubmitted: _run,
                    cursorColor: green,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13, color: fg),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
