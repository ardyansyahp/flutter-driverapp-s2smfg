import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;

  const StatusBadge({super.key, required this.status, this.color});

  Color get _color {
    if (color != null) return color!;
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return Colors.green;
      case 'ADVANCED':
        return Colors.teal;
      case 'DELAY':
        return Colors.orange;
      case 'IN_TRANSIT':
        return Colors.blue;
      case 'ARRIVED':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.grey;
      case 'OPEN':
        return Colors.blueGrey;
      case 'READY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return 'Normal';
      case 'ADVANCED':
        return 'Lebih Awal';
      case 'DELAY':
        return 'Terlambat';
      case 'IN_TRANSIT':
        return 'Dalam Perjalanan';
      case 'ARRIVED':
        return 'Tiba';
      case 'COMPLETED':
        return 'Selesai';
      case 'OPEN':
        return 'Menunggu';
      case 'READY':
        return 'Siap Scan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
