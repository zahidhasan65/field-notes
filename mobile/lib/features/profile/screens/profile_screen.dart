import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes.dart';
import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../services/photo_service.dart';
import '../../../widgets/widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changePhoto(BuildContext context, bool hasPhoto) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Profile photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(sheet, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(sheet, 'gallery'),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: const Text('Remove photo', style: TextStyle(color: AppColors.red)),
              onTap: () => Navigator.pop(sheet, 'remove'),
            ),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;

    final bloc = context.read<ProfileBloc>();
    if (choice == 'remove') {
      bloc.add(const ProfilePhotoRemoved());
      return;
    }
    final path = await context.read<PhotoService>().pick(
          context,
          choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
    if (path != null) bloc.add(ProfilePhotoSelected(path));
  }

  Future<void> _editName(BuildContext context, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initial: current),
    );
    if (name != null && name.isNotEmpty && name != current && context.mounted) {
      context.read<ProfileBloc>().add(ProfileNameSubmitted(name));
    }
  }

  Widget _infoRow(IconData icon, String label, String value, {Widget? trailing, VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
            if (trailing != null) trailing,
          ]),
        ),
      );

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(icon, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      );

  @override
  Widget build(BuildContext context) => BlocListener<ProfileBloc, ProfileState>(
        // password results are shown on the change password screen itself
        listenWhen: (prev, curr) =>
            prev.nonce != curr.nonce && curr.action != ProfileAction.password,
        listener: (context, state) {
          if (state.error != null) {
            snack(context, state.error!);
          } else if (state.message != null) {
            snack(context, state.message!);
          }
        },
        child: Scaffold(
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, auth) {
              final user = auth is AuthAuthenticated ? auth.user : null;
              final name = user?.name ?? '';

              return BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profile) => ListView(padding: EdgeInsets.zero, children: [
                  // ---------------- header ----------------
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                    child: Container(
                      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
                      child: Stack(children: [
                        Positioned(
                          right: -50,
                          top: -40,
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.07), shape: BoxShape.circle),
                          ),
                        ),
                        Positioned(
                          left: -40,
                          bottom: -70,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.06), shape: BoxShape.circle),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 28),
                            child: Column(children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _changePhoto(context, profile.photoPath != null),
                                child: Stack(children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                        color: Colors.white, shape: BoxShape.circle),
                                    child: UserAvatar(
                                        name: name, photoPath: profile.photoPath, size: 104),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.photo_camera,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 14),
                              Text(name,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(user?.email ?? '',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // ---------------- stats ----------------
                      AnimatedEntrance(child: _Stats(userId: user?.id ?? currentUserId(context))),
                      const SizedBox(height: 22),

                      // ---------------- personal info ----------------
                      const SectionHeader('Personal information'),
                      const SizedBox(height: 8),
                      AnimatedEntrance(
                        index: 1,
                        child: AppCard(
                          child: Column(children: [
                            _infoRow(
                              Icons.person_outline,
                              'Name',
                              name,
                              onTap: profile.isBusy ? null : () => _editName(context, name),
                              trailing: profile.isBusy && profile.action == ProfileAction.none
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
                            ),
                            const Divider(height: 8),
                            _infoRow(
                              Icons.mail_outline,
                              'Email',
                              user?.email ?? '',
                              trailing: const Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ---------------- photo ----------------
                      const SectionHeader('Profile photo'),
                      const SizedBox(height: 8),
                      AnimatedEntrance(
                        index: 2,
                        child: Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                              onPressed: () => _changePhoto(context, profile.photoPath != null),
                              icon: const Icon(Icons.photo_camera_outlined, size: 18),
                              label: Text(profile.photoPath == null ? 'Add photo' : 'Change photo'),
                            ),
                          ),
                          if (profile.photoPath != null) ...[
                            const SizedBox(width: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(54, 46),
                                foregroundColor: AppColors.red,
                              ),
                              onPressed: () =>
                                  context.read<ProfileBloc>().add(const ProfilePhotoRemoved()),
                              child: const Icon(Icons.delete_outline, size: 20),
                            ),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 6),
                      const Text('The photo is stored on this device and shown on the home screen.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 22),

                      // ---------------- security / account ----------------
                      const SectionHeader('Security'),
                      const SizedBox(height: 8),
                      AnimatedEntrance(
                        index: 3,
                        child: _tile(Icons.lock_reset, 'Change password',
                            'Use a strong password you do not use elsewhere',
                            () => Navigator.pushNamed(context, Routes.changePassword)),
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader('More'),
                      const SizedBox(height: 8),
                      _tile(Icons.notifications_none, 'Notifications',
                          'Sync results and account alerts',
                          () => Navigator.pushNamed(context, Routes.notifications)),
                      const SizedBox(height: 10),
                      _tile(Icons.sync, 'Sync status', 'Last sync, waiting changes',
                          () => showSyncSheet(context)),
                    ]),
                  ),
                ]),
              );
            },
          ),
        ),
      );
}

class _Stats extends StatelessWidget {
  final String userId;
  const _Stats({required this.userId});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
        future: Future.wait([
          context.read<CustomerRepository>().count(userId),
          context.read<SiteRepository>().count(userId),
          context.read<FieldNoteRepository>().count(userId),
        ]),
        builder: (context, snap) {
          final v = snap.data ?? const [0, 0, 0];
          Widget item(IconData icon, String label, int value, Color color) => Expanded(
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(children: [
                    Icon(icon, color: color),
                    const SizedBox(height: 6),
                    Text('$value',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
              );
          return SizedBox();
        },
      );
}

class _EditNameDialog extends StatefulWidget {
  final String initial;
  const _EditNameDialog({required this.initial});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 100,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
}
