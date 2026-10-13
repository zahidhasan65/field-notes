import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../bloc/note_detail_bloc.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key});

  Widget _row(IconData i, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(i, size: 17, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: const TextStyle(color: AppColors.muted, fontSize: 13.5))),
        ]),
      );

  Future<void> _delete(BuildContext context) async {
    if (!await confirmDelete(context, 'note')) return;
    if (context.mounted) context.read<NoteDetailBloc>().add(const NoteDeleteRequested());
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<NoteDetailBloc, NoteDetailState>(
        listenWhen: (prev, curr) => !prev.deleted && curr.deleted,
        listener: (context, state) {
          final m = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          m.showSnackBar(const SnackBar(
              content: Text('Note deleted'), behavior: SnackBarBehavior.floating));
        },
        builder: (context, state) {
          final v = state.view;
          if (v == null) {
            return Scaffold(
              appBar: AppBar(),
              body: state.status == LoadStatus.failure
                  ? ErrorState(
                      message: "We couldn't load this note.",
                      onRetry: () => context.read<NoteDetailBloc>().add(const NoteDetailStarted()))
                  : const Center(child: CircularProgressIndicator()),
            );
          }
          final n = v.note;

          return Scaffold(
            appBar: AppBar(actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.pushNamed(context, Routes.noteForm, arguments: n),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                onPressed: () => _delete(context),
              ),
            ]),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              AnimatedEntrance(
                child: n.photoPath != null
                    ? NotePhoto(path: n.photoPath, height: 220, radius: 16)
                    : Container(
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          n.photoUrl != null ? 'Photo is being downloaded...' : 'No photo attached',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              AnimatedEntrance(
                index: 1,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                        child: Text(n.title,
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
                    StatusChip(n.status),
                  ]),
                  const SizedBox(height: 4),
                  SyncBadge(syncStatus: n.syncStatus, showLabel: true),
                  const SizedBox(height: 8),
                  _row(Icons.business, v.customerName),
                  _row(Icons.location_city, v.siteName),
                  _row(Icons.calendar_today_outlined, fmtDate(n.noteDate)),
                ]),
              ),
              const SizedBox(height: 8),
              AnimatedEntrance(
                index: 2,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    (n.description == null || n.description!.isEmpty) ? 'No description' : n.description!,
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text('Location', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const MapPlaceholder(height: 130),
                  const SizedBox(height: 6),
                  Text(n.coordsLabel ?? 'No location recorded',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ]),
              ),
            ]),
          );
        },
      );
}
