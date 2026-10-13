import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

class SiteSubmitted extends Equatable {
  final SiteDraft draft;
  const SiteSubmitted(this.draft);
  @override
  List<Object?> get props => [draft.customerId, draft.name, draft.address, draft.latitude, draft.longitude];
}

class SiteFormBloc extends Bloc<SiteSubmitted, SubmitState> {
  SiteFormBloc({
    required this.repository,
    required this.userId,
    this.existing,
  }) : super(const SubmitState()) {
    on<SiteSubmitted>((event, emit) async {
      emit(const SubmitState(status: SubmitStatus.saving));
      try {
        if (existing == null) {
          await repository.create(userId, event.draft);
        } else {
          await repository.update(userId, existing!, event.draft);
        }
        emit(const SubmitState(status: SubmitStatus.success));
      } catch (_) {
        emit(const SubmitState(status: SubmitStatus.failure, error: 'Could not save the site.'));
      }
    });
  }

  final SiteRepository repository;
  final String userId;
  final SiteLocal? existing;
}
