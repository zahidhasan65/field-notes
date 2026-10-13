import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/core.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/models/auth_user_model.dart';
import '../features/sync/bloc/sync_bloc.dart';

AuthUserModel? currentUserOf(BuildContext context) {
  final state = context.read<AuthBloc>().state;
  return state is AuthAuthenticated ? state.user : null;
}

String currentUserId(BuildContext context) => currentUserOf(context)?.id ?? '';

Future<void> refreshWithSync(BuildContext context) async {
  final bloc = context.read<SyncBloc>();
  if (!bloc.state.isOnline) {
    snack(context, "You're offline. Showing data saved on this device.");
    return;
  }
  final done = Completer<void>();
  bloc.add(SyncRequested(completer: done));
  await done.future;
}
