import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/platform_backend.dart';

// 제어센터 — 메뉴바 우측 아이콘에서 열리는 빠른 토글 패널.
class ControlCenter extends StatefulWidget {
  final VoidCallback onLock;
  final VoidCallback onClose;
  const ControlCenter({super.key, required this.onLock, required this.onClose});

  @override
  State<ControlCenter> createState() => _ControlCenterState();
}

class _ControlCenterState extends State<ControlCenter> {
  bool _wifi = true;
  bool _bt = false;

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Stack(
      children: [
        // 바깥 클릭 → 닫기
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
          ),
        ),
        Positioned(
          top: 38,
          right: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sys.isLight
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF1C1C24).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sys.chromeBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _toggle(sys, Icons.wifi, 'Wi-Fi', _wifi, () {
                              setState(() => _wifi = !_wifi);
                              platformBackend.setWifi(_wifi); // 리눅스: nmcli
                            })),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _toggle(sys, Icons.bluetooth, 'Bluetooth',
                                _bt, () {
                              setState(() => _bt = !_bt);
                              platformBackend.setBluetooth(_bt); // 리눅스: rfkill
                            })),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _themeTile(sys),
                    const SizedBox(height: 10),
                    _card(
                      sys,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('밝기',
                              style: TextStyle(
                                  fontSize: 12, color: sys.textSec(0.6))),
                          Row(
                            children: [
                              Icon(Icons.brightness_low,
                                  size: 16, color: sys.textSec(0.5)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: sys.accent,
                                    thumbColor: sys.accent,
                                    inactiveTrackColor: sys.textSec(0.15),
                                    overlayColor:
                                        sys.accent.withValues(alpha: 0.12),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: sys.brightness,
                                    min: 0.25,
                                    max: 1.0,
                                    onChanged: sys.setBrightness,
                                  ),
                                ),
                              ),
                              Icon(Icons.brightness_high,
                                  size: 16, color: sys.textSec(0.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _card(
                      sys,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('볼륨',
                              style: TextStyle(
                                  fontSize: 12, color: sys.textSec(0.6))),
                          Row(
                            children: [
                              Icon(Icons.volume_down,
                                  size: 16, color: sys.textSec(0.5)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: sys.accent,
                                    thumbColor: sys.accent,
                                    inactiveTrackColor: sys.textSec(0.15),
                                    overlayColor:
                                        sys.accent.withValues(alpha: 0.12),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: sys.volume,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: sys.setVolume,
                                  ),
                                ),
                              ),
                              Icon(Icons.volume_up,
                                  size: 16, color: sys.textSec(0.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _card(
                      sys,
                      Row(
                        children: [
                          Text('강조색',
                              style: TextStyle(
                                  fontSize: 12, color: sys.textSec(0.6))),
                          const Spacer(),
                          for (final a in kAccents)
                            GestureDetector(
                              onTap: () => sys.setAccent(a.id),
                              child: Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(left: 5),
                                decoration: BoxDecoration(
                                  color: a.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: a.id == sys.accentId
                                        ? sys.textPrimary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(sys, Icons.lock_outline, '잠금', () {
                            widget.onClose();
                            widget.onLock();
                          }),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionBtn(sys, Icons.restart_alt, '재시작',
                              () => _confirmPower('재시작할까요?', platformBackend.reboot)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionBtn(
                              sys, Icons.power_settings_new, '종료',
                              () => _confirmPower(
                                  '시스템을 종료할까요?', platformBackend.powerOff),
                              danger: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(SystemState sys, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sys.textSec(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );

  // 잠금/재시작/종료 같은 세로형(아이콘+라벨) 액션 버튼.
  Widget _actionBtn(SystemState sys, IconData icon, String label,
      VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? const Color(0xFFFF5F57) : sys.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: _card(
        sys,
        Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  // 위험한 전원 동작은 확인 다이얼로그를 거친다. 웹/비리눅스는 action이 no-op.
  void _confirmPower(String msg, Future<void> Function() action) {
    final sys = context.read<SystemState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: sys.windowSurface,
        content:
            Text(msg, style: TextStyle(color: sys.textPrimary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: sys.textSec(0.7))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onClose();
              action();
            },
            child:
                const Text('확인', style: TextStyle(color: Color(0xFFFF5F57))),
          ),
        ],
      ),
    );
  }

  Widget _toggle(SystemState sys, IconData icon, String label, bool on,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: on ? sys.accent : sys.textSec(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: on ? Colors.white : sys.textSec(0.7)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: on ? Colors.white : sys.textSec(0.8))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeTile(SystemState sys) {
    return GestureDetector(
      onTap: sys.toggleTheme,
      child: _card(
        sys,
        Row(
          children: [
            Icon(sys.isLight ? Icons.light_mode : Icons.dark_mode,
                size: 18, color: sys.textPrimary),
            const SizedBox(width: 10),
            Text(sys.isLight ? '라이트 모드' : '다크 모드',
                style: TextStyle(fontSize: 13.5, color: sys.textPrimary)),
            const Spacer(),
            Text('전환',
                style: TextStyle(fontSize: 12, color: sys.accent)),
          ],
        ),
      ),
    );
  }
}
