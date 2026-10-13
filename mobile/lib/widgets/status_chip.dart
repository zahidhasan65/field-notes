import 'package:flutter/material.dart';
import '../data/data.dart';

class StatusChip extends StatelessWidget {
  final NoteStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: status.color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(status.label,
              style: TextStyle(color: status.color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );
}
