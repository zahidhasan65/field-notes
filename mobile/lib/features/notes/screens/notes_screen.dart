import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../bloc/notes_bloc.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  void _pickSite(BuildContext context, NotesState state) {
    final bloc = context.read<NotesBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .7),
          child: ListView(shrinkWrap: true, children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Filter by site', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              title: const Text('All sites'),
              trailing: state.siteId == null ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                bloc.add(const NotesSiteFilterChanged(null));
                Navigator.pop(sheetContext);
              },
            ),
            ...state.sites.map((v) => ListTile(
                  title: Text(v.site.siteName),
                  subtitle: Text(v.customerName),
                  trailing:
                      state.siteId == v.site.id ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    bloc.add(NotesSiteFilterChanged(v.site.id));
                    Navigator.pop(sheetContext);
                  },
                )),
          ]),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : context.pal.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: context.pal.surface,
          side: BorderSide(color: context.pal.border),
        ),
      );

  @override
  Widget build(BuildContext context) => BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          final bloc = context.read<NotesBloc>();

          Widget body;
          if (state.status == LoadStatus.loading) {
            body = const ListSkeleton();
          } else if (state.status == LoadStatus.failure) {
            body = SizedBox(
              height: 320,
              child: ErrorState(
                message: "We couldn't load your field notes.",
                onRetry: () => bloc.add(const NotesStarted()),
              ),
            );
          } else if (state.notes.isEmpty) {
            body = SizedBox(
              height: 320,
              child: EmptyState(
                Icons.note_alt_outlined,
                state.query.isEmpty && state.statusFilter == null && state.siteId == null
                    ? 'No field notes yet. Tap + to add one.'
                    : 'No field notes match your search or filters',
              ),
            );
          } else {
            body = Column(
              children: List.generate(
                state.notes.length,
                (i) => AnimatedEntrance(
                  index: i,
                  child: NoteCard(
                    view: state.notes[i],
                    onTap: () => Navigator.pushNamed(context, Routes.noteDetail,
                        arguments: state.notes[i].note.id),
                  ),
                ),
              ),
            );
          }

          SiteLocal? filterSite;
          for (final v in state.sites) {
            if (v.site.id == state.siteId) filterSite = v.site;
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Field Notes')),
            floatingActionButton: FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: () => Navigator.pushNamed(context, Routes.noteForm, arguments: filterSite),
              child: const Icon(Icons.add),
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const OfflineBanner(),
                Row(children: [
                  Expanded(
                    child: SearchBox(
                      hint: 'Search title, description, site, customer',
                      onChanged: (v) => bloc.add(NotesQueryChanged(v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: state.siteId == null ? context.pal.surface : AppColors.primary.withOpacity(.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.pal.border),
                    ),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () => _pickSite(context, state),
                      child: const Padding(
                        padding: EdgeInsets.all(11),
                        child: Icon(Icons.filter_alt_outlined, size: 22, color: AppColors.primary),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _chip(context, 'All', state.statusFilter == null,
                        () => bloc.add(const NotesStatusFilterChanged(null))),
                    ...NoteStatus.values.map((s) => _chip(context, s.label, state.statusFilter == s,
                        () => bloc.add(NotesStatusFilterChanged(s)))),
                  ]),
                ),
                if (state.siteName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InputChip(
                      label: Text('Site: ${state.siteName}'),
                      onDeleted: () => bloc.add(const NotesSiteFilterChanged(null)),
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => refreshWithSync(context),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [body],
                    ),
                  ),
                ),
              ]),
            ),
          );
        },
      );
}
