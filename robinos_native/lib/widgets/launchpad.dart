import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/platform_backend.dart';
import '../apps/registry.dart';
import 'anim.dart';
import 'app_icon.dart';

// 런치패드 — 전체화면 앱 그리드. 앱 탭 → 실행, 빈 곳 탭 → 닫기.
class Launchpad extends StatelessWidget {
  final void Function(String id) onOpen;
  final VoidCallback onClose;
  const Launchpad({super.key, required this.onOpen, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          color: Colors.black.withValues(alpha: sys.isLight ? 0.25 : 0.45),
          child: Center(
            child: PopIn(
              from: 0.9,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 내장(RobinOS) 앱
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 40,
                        runSpacing: 36,
                        children: [
                          for (var i = 0; i < kApps.length; i++)
                            StaggerIn(index: i, child: _tile(sys, kApps[i])),
                        ],
                      ),
                      // 설치된 실제 리눅스 앱 (리눅스 실기기에서만 — labwc가 창으로 띄움)
                      if (sys.installedApps.isNotEmpty) ...[
                        const SizedBox(height: 40),
                        Text(
                          '설치된 앱',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 40,
                          runSpacing: 36,
                          children: [
                            for (var i = 0; i < sys.installedApps.length; i++)
                              StaggerIn(
                                  index: i,
                                  child: _realTile(sys.installedApps[i])),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(SystemState sys, AppDef a) {
    return GestureDetector(
      onTap: () {
        onOpen(a.id);
        onClose();
      },
      child: SizedBox(
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RobinAppIcon(app: a, size: 76),
            const SizedBox(height: 10),
            Text(a.name,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // 설치된 실제 리눅스 앱 타일 — 탭 시 launchApp(detached)으로 진짜 앱 실행.
  // (.desktop 아이콘 파싱은 추후; 지금은 앱 이름 첫 글자를 글래스 박스에 표시)
  Widget _realTile(InstalledApp app) {
    return GestureDetector(
      onTap: () {
        platformBackend.launchApp(app.exec);
        onClose();
      },
      child: SizedBox(
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.12),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.16)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _initial(app.name),
                style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return String.fromCharCode(t.runes.first).toUpperCase();
  }
}
