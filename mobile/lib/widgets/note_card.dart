import 'package:flutter/material.dart';

import '../core/core.dart';
import '../data/data.dart';
import 'app_card.dart';
import 'photo_placeholder.dart';
import 'status_chip.dart';
import 'sync_badge.dart';

class NoteCard extends StatelessWidget {
  final NoteView view;
  final VoidCallback onTap;
  const NoteCard({super.key, required this.view, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final note = view.note;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          NotePhoto(path: note.photoPath, seed: note.id.hashCode, width: 60, height: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                StatusChip(note.status),
              ]),
              const SizedBox(height: 3),
              Text('${view.siteName} • ${view.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(
                  child: Text(fmtDate(note.noteDate),
                      style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                ),
                SyncBadge(syncStatus: note.syncStatus),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
