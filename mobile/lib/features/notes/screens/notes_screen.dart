import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/sync_constants.dart';
import '../../../data/local/models/customer_local.dart';
import '../../../data/local/models/field_note_local.dart';
import '../../../data/local/models/site_local.dart';
import '../../../data/local/models/sync_queue_item.dart';
import '../../../data/repositories/local_customer_repository.dart';
import '../../../data/repositories/local_field_note_repository.dart';
import '../../../data/repositories/local_site_repository.dart';

class NotesScreen extends StatefulWidget {
  final String userId;

  const NotesScreen({super.key, required this.userId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _customers = LocalCustomerRepository();
  final _sites = LocalSiteRepository();
  final _notes = LocalFieldNoteRepository();

  bool _loading = true;
  String? _error;
  List<FieldNoteLocal> _fieldNotes = [];
  Map<String, SiteLocal> _siteById = {};

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final customers = await _customers.getCustomers(widget.userId);
      final sites = <SiteLocal>[];
      final notes = <FieldNoteLocal>[];

      for (final customer in customers) {
        final customerSites = await _sites.getSites(customer.id);
        sites.addAll(customerSites);

        for (final site in customerSites) {
          notes.addAll(await _notes.getFieldNotes(site.id));
        }
      }

      if (!mounted) return;
      setState(() {
        _siteById = {for (final site in sites) site.id: site};
        _fieldNotes = notes
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load notes. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _addNote() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddFieldNoteScreen(userId: widget.userId),
      ),
    );

    if (saved == true && mounted) {
      await _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field note saved on this device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2877E8);
    const ink = Color(0xFF20304A);
    const muted = Color(0xFF7A879B);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Field Notes',
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loadNotes,
            tooltip: 'Refresh notes',
            icon: const Icon(Icons.refresh_rounded, color: blue),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        backgroundColor: blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Note'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadNotes,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              : _fieldNotes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Color(0xFF9AAAC0),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No field notes yet',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a note during your next site visit.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _addNote,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create Field Note'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotes,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                        children: [
                          Text(
                            '${_fieldNotes.length} notes',
                            style: const TextStyle(
                              fontSize: 14,
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (final note in _fieldNotes)
                            _NoteCard(
                              note: note,
                              site: _siteById[note.siteId],
                            ),
                        ],
                      ),
                    ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final FieldNoteLocal note;
  final SiteLocal? site;

  const _NoteCard({required this.note, required this.site});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF20304A);
    final status = (note.status ?? 'PENDING').toUpperCase();
    final completed = status == 'COMPLETED';
    final inProgress = status == 'IN_PROGRESS';
    final color = completed
        ? const Color(0xFF159A75)
        : inProgress
            ? const Color(0xFF2877E8)
            : const Color(0xFFDE9A25);
    final tint = completed
        ? const Color(0xFFE7F8F0)
        : inProgress
            ? const Color(0xFFEAF2FF)
            : const Color(0xFFFFF4DF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF2877E8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title?.trim().isNotEmpty == true
                          ? note.title!
                          : 'Untitled note',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      site?.siteName ?? 'Site',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A879B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  completed
                      ? 'Completed'
                      : inProgress
                          ? 'In Progress'
                          : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (note.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              note.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF65748B),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Color(0xFF8A97AA),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  note.noteDatetime ?? note.createdAt,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A97AA),
                  ),
                ),
              ),
              if (note.syncStatus != SyncStatus.synced)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 14,
                      color: Color(0xFFDE9A25),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Pending sync',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFDE9A25),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddFieldNoteScreen extends StatefulWidget {
  final String userId;

  const AddFieldNoteScreen({super.key, required this.userId});

  @override
  State<AddFieldNoteScreen> createState() => _AddFieldNoteScreenState();
}

class _AddFieldNoteScreenState extends State<AddFieldNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _customerRepository = LocalCustomerRepository();
  final _siteRepository = LocalSiteRepository();
  final _noteRepository = LocalFieldNoteRepository();

  List<CustomerLocal> _customers = [];
  List<SiteLocal> _sites = [];
  String? _customerId;
  String? _siteId;
  String _status = 'PENDING';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final customers =
          await _customerRepository.getCustomers(widget.userId);
      final sites = <SiteLocal>[];

      for (final customer in customers) {
        sites.addAll(await _siteRepository.getSites(customer.id));
      }

      if (!mounted) return;
      setState(() {
        _customers = customers;
        _sites = sites;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load customers and sites.';
      });
    }
  }

  List<SiteLocal> get _availableSites =>
      _sites.where((site) => site.customerId == _customerId).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_siteId == null || !_sites.any((site) => site.id == _siteId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a site.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now().toIso8601String();
      final id = _newUuid();
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      final note = FieldNoteLocal(
        id: id,
        siteId: _siteId!,
        title: title,
        description: description.isEmpty ? null : description,
        noteDatetime: now,
        status: _status,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pendingCreate,
      );

      final payload = jsonEncode({
        'id': note.id,
        'site_id': note.siteId,
        'title': note.title,
        'description': note.description,
        'latitude': note.latitude,
        'longitude': note.longitude,
        'note_datetime': note.noteDatetime,
        'status': note.status,
        'photo_url': note.photoUrl,
        'created_at': note.createdAt,
        'updated_at': note.updatedAt,
      });

      final queueItem = SyncQueueItem(
        entityType: SyncEntityType.fieldNote,
        entityId: id,
        operation: SyncOperation.create,
        payload: payload,
        createdAt: now,
        status: SyncQueueStatus.pending,
      );

      await _noteRepository.createFieldNoteWithSyncQueue(
        fieldNote: note,
        queueItem: queueItem,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save note: $e')),
      );
    }
  }

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2877E8);
    const ink = Color(0xFF20304A);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'New Field Note',
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadOptions,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              : _customers.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Create a customer and site before adding a field note.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text(
                            'Record your site visit',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your note is saved locally and queued for sync.',
                            style: TextStyle(
                              color: Color(0xFF7A879B),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _label('Customer'),
                          DropdownButtonFormField<String>(
                            value: _customerId,
                            isExpanded: true,
                            decoration: _decoration('Select customer'),
                            items: _customers
                                .map(
                                  (customer) => DropdownMenuItem<String>(
                                    value: customer.id,
                                    child: Text(
                                      customer.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (value) =>
                                value == null ? 'Select a customer' : null,
                            onChanged: (value) {
                              setState(() {
                                _customerId = value;
                                _siteId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          _label('Site'),
                          DropdownButtonFormField<String>(
                            value: _siteId,
                            isExpanded: true,
                            decoration: _decoration('Select site'),
                            items: _availableSites
                                .map(
                                  (site) => DropdownMenuItem<String>(
                                    value: site.id,
                                    child: Text(
                                      site.siteName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (value) =>
                                value == null ? 'Select a site' : null,
                            onChanged: _customerId == null
                                ? null
                                : (value) => setState(() => _siteId = value),
                          ),
                          if (_customerId != null && _availableSites.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'This customer has no sites yet. Add a site first.',
                                style: TextStyle(
                                  color: Color(0xFFDE9A25),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          _label('Title'),
                          TextFormField(
                            controller: _titleController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _decoration('Enter note title'),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Title is required'
                                    : null,
                          ),
                          const SizedBox(height: 18),
                          _label('Description'),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 4,
                            maxLines: 7,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _decoration(
                              'Describe observations or work completed',
                            ),
                          ),
                          const SizedBox(height: 18),
                          _label('Status'),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: _decoration('Select status'),
                            items: const [
                              DropdownMenuItem<String>(
                                value: 'PENDING',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'IN_PROGRESS',
                                child: Text('In Progress'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'COMPLETED',
                                child: Text('Completed'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              style: FilledButton.styleFrom(
                                backgroundColor: blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(_saving ? 'Saving...' : 'Save Note'),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _label(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF20304A),
          ),
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE1E8F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE1E8F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF2877E8), width: 1.5),
        ),
      );
}
