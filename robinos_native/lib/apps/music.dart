import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/platform_backend.dart';
import '../widgets/anim.dart';
import '../widgets/app_icon.dart';

// 음악 — 홈의 오디오 파일을 나열하고 mpv로 재생(리눅스). 웹/개발은 데모 트랙.
// 재생 제어는 단순(재생/정지) — mpv detached. 진행바 대신 정직하게 애니 이퀄라이저로 표현.
const _musicColor = Color(0xFFFF9F4A);
const _audioExts = ['.mp3', '.flac', '.wav', '.ogg', '.m4a', '.aac', '.opus'];

class _Track {
  final String path; // RobinFs 경로 ('/음악/곡.mp3')
  final String name; // 확장자 뺀 표시 이름
  final String folder; // 상위 폴더 이름
  const _Track(this.path, this.name, this.folder);
}

class MusicApp extends StatefulWidget {
  const MusicApp({super.key});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  List<_Track> _tracks = const [];
  bool _loaded = false;
  String? _playing; // 재생 중 트랙 path

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!platformBackend.isReal) {
      setState(() {
        _tracks = const [
          _Track('/음악/Aurora - Daydream.mp3', 'Aurora - Daydream', '음악'),
          _Track('/음악/Midnight Drive.flac', 'Midnight Drive', '음악'),
          _Track('/음악/Robin Theme.ogg', 'Robin Theme', '음악'),
          _Track('/다운로드/sample.wav', 'sample', '다운로드'),
        ];
        _loaded = true;
      });
      return;
    }
    final nodes = await platformBackend.fsScan();
    final tracks = <_Track>[];
    for (final n in nodes) {
      if (n.isDir) continue;
      final lower = n.path.toLowerCase();
      if (!_audioExts.any(lower.endsWith)) continue;
      tracks.add(_Track(n.path, _noExt(_base(n.path)), _folderOf(n.path)));
    }
    tracks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (!mounted) return;
    setState(() {
      _tracks = tracks;
      _loaded = true;
    });
  }

  String _base(String p) => p.split('/').last;
  String _noExt(String f) {
    final i = f.lastIndexOf('.');
    return i > 0 ? f.substring(0, i) : f;
  }

  String _folderOf(String p) {
    final parts = p.split('/').where((s) => s.isNotEmpty).toList();
    return parts.length >= 2 ? parts[parts.length - 2] : '홈';
  }

  void _play(_Track t) {
    setState(() => _playing = t.path);
    platformBackend.playAudio(t.path);
  }

  void _stop() {
    platformBackend.stopAudio();
    setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Container(
      color: sys.windowSurface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Text('음악',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: sys.textPrimary)),
                const SizedBox(width: 8),
                if (_loaded)
                  Text('${_tracks.length}곡',
                      style: TextStyle(fontSize: 13, color: sys.textSec(0.45))),
              ],
            ),
          ),
          Expanded(child: _body(sys)),
          if (_playing != null) _nowPlaying(sys),
        ],
      ),
    );
  }

  Widget _body(SystemState sys) {
    if (!_loaded) {
      return Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child:
                  CircularProgressIndicator(strokeWidth: 2.4, color: sys.accent)));
    }
    if (_tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            '오디오 파일이 없어요.\n홈의 ~/음악 폴더에 음악을 넣어보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: sys.textSec(0.5), height: 1.5),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _tracks.length,
      itemBuilder: (_, i) => StaggerIn(index: i, child: _row(sys, _tracks[i])),
    );
  }

  Widget _row(SystemState sys, _Track t) {
    final playing = t.path == _playing;
    return GestureDetector(
      onTap: () => _play(t),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: playing ? sys.accent.withValues(alpha: 0.12) : sys.textSec(0.04),
          borderRadius: BorderRadius.circular(12),
          border: playing
              ? Border.all(color: sys.accent.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            const RobinAppIcon(
                glyph: Icons.music_note_rounded, color: _musicColor, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: sys.textPrimary)),
                  const SizedBox(height: 1),
                  Text(t.folder,
                      style:
                          TextStyle(fontSize: 11.5, color: sys.textSec(0.45))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              playing ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: playing ? sys.accent : sys.textSec(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nowPlaying(SystemState sys) {
    final t = _tracks.firstWhere((e) => e.path == _playing,
        orElse: () => _Track(_playing!, _noExt(_base(_playing!)), ''));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
      decoration: BoxDecoration(
        color: sys.textSec(0.04),
        border: Border(top: BorderSide(color: sys.textSec(0.1))),
      ),
      child: Row(
        children: [
          _Equalizer(color: sys.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: sys.textPrimary)),
                Text(platformBackend.isReal ? '재생 중' : '웹 데모 · 리눅스에서 mpv로 재생',
                    style: TextStyle(fontSize: 11.5, color: sys.textSec(0.5))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _stop,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [sys.accent, sys.accent2]),
                boxShadow: [
                  BoxShadow(
                      color: sys.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.stop_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// 재생 중 표시용 애니메이션 이퀄라이저 — 5개 막대가 사인파로 춤춘다.
// 이 위젯이 보일 때(재생 중)만 컨트롤러가 돌아 최적화 OK(닫히면 dispose).
class _Equalizer extends StatefulWidget {
  final Color color;
  const _Equalizer({required this.color});

  @override
  State<_Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<_Equalizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  static const _phases = [0.0, 1.1, 2.3, 0.6, 1.8];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final tau = _c.value * 2 * math.pi;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < _phases.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                _bar(0.3 + 0.7 * (0.5 + 0.5 * math.sin(tau + _phases[i]))),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _bar(double frac) => Container(
        width: 3.5,
        height: 8 + 22 * frac,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: widget.color,
        ),
      );
}
