import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../bloc/restore_bloc.dart';


class RestoreDataScreen extends StatelessWidget {
  const RestoreDataScreen({super.key});

  static const _stages = <(RestoreStage, IconData, String)>[
    (RestoreStage.customers, Icons.people_outline, 'Customers'),
    (RestoreStage.sites, Icons.location_city, 'Sites'),
    (RestoreStage.notes, Icons.description_outlined, 'Field notes'),
    (RestoreStage.photos, Icons.photo_library_outlined, 'Photos'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = currentUserOf(context);

    return PopScope(
      canPop: false,
      child: BlocConsumer<RestoreBloc, RestoreState>(
        listener: (context, state) async {
          if (state.status == RestoreStatus.success) {
            await Future.delayed(const Duration(milliseconds: 800));
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
            }
          }
        },
        builder: (context, state) {
          final failed = state.status == RestoreStatus.failure;
          final finished = state.status == RestoreStatus.success;
          final done = state.done.length;
          final activeIndex = finished || failed ? -1 : done;

          return Scaffold(
            backgroundColor: context.pal.surface,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Spacer(),
                  const AppLogo(size: 72),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      failed
                          ? "Couldn't restore your data"
                          : finished
                              ? 'All set!'
                              : 'Restoring your data...',
                      key: ValueKey('${state.status}'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    failed
                        ? (state.error ?? 'Check your connection and try again.')
                        : 'Welcome back${user == null ? '' : ', ${user.name}'}. '
                            'We are downloading your customers, sites and notes from the server.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: done / _stages.length),
                      duration: const Duration(milliseconds: 400),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        color: failed ? AppColors.red : AppColors.primary,
                        backgroundColor: context.pal.bg,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_stages.length, (i) {
                    final (stage, icon, title) = _stages[i];
                    final isDone = state.done.containsKey(stage);
                    final active = i == activeIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Icon(icon, color: isDone ? AppColors.green : AppColors.muted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (isDone)
                                Text('${state.done[stage]} restored',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            ]),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: isDone
                                ? const Icon(Icons.check_circle, key: ValueKey('d'), color: AppColors.green)
                                : active
                                    ? const SizedBox(
                                        key: ValueKey('a'),
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2.2))
                                    : const SizedBox(key: ValueKey('w'), width: 18),
                          ),
                        ]),
                      ),
                    );
                  }),
                  const Spacer(),
                  if (failed)
                    AppButton('Try again',
                        icon: Icons.refresh,
                        onPressed: () => context.read<RestoreBloc>().add(const RestoreRetried())),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
