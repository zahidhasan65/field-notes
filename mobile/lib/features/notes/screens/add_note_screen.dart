import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../services/location_service.dart';
import '../../../services/photo_service.dart';
import '../../../widgets/widgets.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../../sync/bloc/sync_bloc.dart';
import '../bloc/note_form_bloc.dart';


class AddNoteScreen extends StatefulWidget {
  final FieldNoteLocal? note;
  final SiteLocal? site;
  const AddNoteScreen({super.key, this.note, this.site});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.note?.title);
  late final _desc = TextEditingController(text: widget.note?.description);
  late String? _siteId = widget.note?.siteId ?? widget.site?.id;
  late NoteStatus _status =
      widget.note?.status ?? context.read<SettingsBloc>().state.defaultStatus;
  late DateTime _date = widget.note?.noteDate ?? DateTime.now();
  late double? _lat = widget.note?.latitude;
  late double? _lng = widget.note?.longitude;
  late String? _photoPath = widget.note?.photoPath;
  bool _photoChanged = false;
  bool _locating = false;
  List<SiteView> _sites = const [];

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final list = await context.read<SiteRepository>().list(currentUserId(context));
    if (mounted) setState(() => _sites = list);
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    setState(() => _date = DateTime(d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    final point = await context.read<LocationService>().getCurrent(context);
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (point != null) {
        _lat = point.latitude;
        _lng = point.longitude;
      }
    });
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    final path = await context.read<PhotoService>().pick(context, source);
    if (path != null && mounted) {
      setState(() {
        _photoPath = path;
        _photoChanged = true;
      });
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<NoteFormBloc>().add(NoteSubmitted(NoteDraft(
          siteId: _siteId!,
          title: _title.text,
          description: _desc.text,
          status: _status,
          noteDatetime: _date,
          latitude: _lat,
          longitude: _lng,
          photoPath: _photoPath,
          photoChanged: _photoChanged,
        )));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;
    final hasLocation = _lat != null && _lng != null;

    return BlocConsumer<NoteFormBloc, SubmitState>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          final offline = !context.read<SyncBloc>().state.isOnline;
          final m = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          m.showSnackBar(SnackBar(
            content: Text(editing
                ? 'Note updated'
                : offline
                    ? 'Note saved on this device. It will sync when you are online.'
                    : 'Note saved'),
            behavior: SnackBarBehavior.floating,
          ));
        } else if (state.status == SubmitStatus.failure) {
          snack(context, state.error ?? 'Could not save the note.');
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(editing ? 'Edit Field Note' : 'Add Field Note')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            AnimatedEntrance(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const FormSectionTitle(Icons.description_outlined, 'Note Information'),
                  AppDropdown<String>(
                    label: 'Site',
                    hint: 'Select site',
                    isRequired: true,
                    value: _sites.any((s) => s.site.id == _siteId) ? _siteId : null,
                    items: _sites
                        .map((s) => DropdownMenuItem(
                              value: s.site.id,
                              child: Text('${s.site.siteName} - ${s.customerName}',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _siteId = v),
                  ),
                  AppField(label: 'Title', hint: 'Enter note title', controller: _title, isRequired: true),
                  AppField(label: 'Description', hint: 'Enter description...', controller: _desc, maxLines: 4),
                  AppDropdown<NoteStatus>(
                    label: 'Status',
                    hint: 'Select status',
                    value: _status,
                    items: NoteStatus.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                  const FieldLabel('Date & Time'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.pal.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.pal.border),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
                        const SizedBox(width: 10),
                        Text(fmtDate(_date)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Location'),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    onPressed: _locating ? null : _getLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(hasLocation ? 'Update Location' : 'Get Current Location'),
                  ),
                  if (hasLocation)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.red),
                        const SizedBox(width: 4),
                        Text('${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ]),
                    ),
                  const SizedBox(height: 16),
                  const FieldLabel('Photo (Optional)'),
                  if (_photoPath != null)
                    Stack(children: [
                      NotePhoto(path: _photoPath, width: 110, height: 110),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _photoPath = null;
                            _photoChanged = true;
                          }),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ])
                  else
                    InkWell(
                      onTap: _addPhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(.5)),
                          color: AppColors.primary.withOpacity(.06),
                        ),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                          SizedBox(height: 4),
                          Text('Add Photo', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: AppButton('Cancel', outlined: true, onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(child: AppButton('Save', isLoading: state.isSaving, onPressed: _save)),
            ]),
          ]),
        ),
      ),
    );
  }
}
