import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/platform_backend.dart';
import '../widgets/anim.dart';

// 사진/갤러리 — 홈의 이미지 파일을 그리드로, 탭하면 전체 뷰어(좌우 이동·핀치 줌).
// 리눅스: 실제 파일 바이트(readImageBytes). 웹/개발: 파일이 없어 빈 상태.
const _imgExts = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp'];

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  List<String> _images = const [];
  bool _loaded = false;
  int? _viewer; // 전체 뷰어로 보고 있는 인덱스(null이면 그리드)
  final Map<String, Uint8List?> _cache = {}; // path → bytes(없으면 null)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final nodes = await platformBackend.fsScan();
    final imgs = <String>[];
    for (final n in nodes) {
      if (n.isDir) continue;
      final l = n.path.toLowerCase();
      if (_imgExts.any(l.endsWith)) imgs.add(n.path);
    }
    imgs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!mounted) return;
    setState(() {
      _images = imgs;
      _loaded = true;
    });
  }

  String _base(String p) => p.split('/').last;

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Container(
      color: sys.windowSurface,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  children: [
                    Text('사진',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: sys.textPrimary)),
                    const SizedBox(width: 8),
                    if (_loaded)
                      Text('${_images.length}장',
                          style:
                              TextStyle(fontSize: 13, color: sys.textSec(0.45))),
                  ],
                ),
              ),
              Expanded(child: _body(sys)),
            ],
          ),
          if (_viewer != null) _fullViewer(sys),
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
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: sys.accent)));
    }
    if (_images.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 36, color: sys.textSec(0.28)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                '이미지가 없어요.\n홈의 ~/사진 폴더에 이미지를 넣어보세요.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: sys.textSec(0.5), height: 1.5),
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _images.length,
      itemBuilder: (_, i) => StaggerIn(
        index: i,
        dy: 14,
        child: GestureDetector(
          onTap: () => setState(() => _viewer = i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: sys.textSec(0.06),
              child: _Img(path: _images[i], cache: _cache, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fullViewer(SystemState sys) {
    final idx = _viewer!;
    return Positioned.fill(
      child: FadeIn(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _viewer = null),
                child: Container(color: Colors.black.withValues(alpha: 0.92)),
              ),
            ),
            // 이미지 페이지(좌우 스와이프)
            Positioned.fill(
              child: PageView.builder(
                controller: PageController(initialPage: idx),
                itemCount: _images.length,
                onPageChanged: (i) => setState(() => _viewer = i),
                itemBuilder: (_, i) => Center(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: _Img(
                        path: _images[i], cache: _cache, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            // 상단 바
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_base(_images[idx]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text('${idx + 1} / ${_images.length}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.5)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _viewer = null),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 이미지 로더 — 바이트를 캐시에서 가져오거나 백엔드로 비동기 로드.
class _Img extends StatefulWidget {
  final String path;
  final Map<String, Uint8List?> cache;
  final BoxFit fit;
  const _Img({required this.path, required this.cache, required this.fit});

  @override
  State<_Img> createState() => _ImgState();
}

class _ImgState extends State<_Img> {
  @override
  void initState() {
    super.initState();
    _ensure();
  }

  Future<void> _ensure() async {
    if (widget.cache.containsKey(widget.path)) return;
    final b = await platformBackend.readImageBytes(widget.path);
    if (!mounted) return;
    widget.cache[widget.path] = b;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    if (!widget.cache.containsKey(widget.path)) {
      // 로딩 중 — 은은한 펄스 placeholder.
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: sys.textSec(0.3)),
        ),
      );
    }
    final b = widget.cache[widget.path];
    if (b == null) {
      return Center(
        child: Icon(Icons.broken_image_outlined,
            color: sys.textSec(0.35), size: 28),
      );
    }
    return Image.memory(b, fit: widget.fit, gaplessPlayback: true);
  }
}
