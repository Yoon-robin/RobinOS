import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/platform_backend.dart';

// 메뉴바 배터리 표시 — 리눅스 실기기면 실제 잔량/충전 상태(/sys/class/power_supply)를
// 30초마다 폴링. 배터리 없는 기기(데스크톱/QEMU/웹)는 기본 아이콘만.
class BatteryIndicator extends StatefulWidget {
  const BatteryIndicator({super.key});

  @override
  State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator> {
  BatteryInfo? _info;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  Future<void> _poll() async {
    final i = await platformBackend.batteryInfo();
    if (mounted) setState(() => _info = i);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final info = _info;
    // 배터리 없음 → 기존처럼 가득 찬 아이콘만(데스크톱/웹).
    if (info == null) {
      return Icon(Icons.battery_full, size: 15, color: sys.textSec(0.8));
    }
    final color = info.charging ? sys.accent : sys.textSec(0.8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon(info), size: 15, color: color),
        const SizedBox(width: 3),
        Text('${info.level}%',
            style: TextStyle(fontSize: 11.5, color: sys.textSec(0.8))),
      ],
    );
  }

  IconData _icon(BatteryInfo i) {
    if (i.charging) return Icons.battery_charging_full;
    if (i.level >= 90) return Icons.battery_full;
    if (i.level >= 60) return Icons.battery_5_bar;
    if (i.level >= 40) return Icons.battery_3_bar;
    if (i.level >= 15) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }
}
