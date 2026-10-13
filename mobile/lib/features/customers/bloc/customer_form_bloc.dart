import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

class CustomerSubmitted extends Equatable {
  final CustomerDraft draft;
  const CustomerSubmitted(this.draft);
  @override
  List<Object?> get props => [draft.name, draft.contactPerson, draft.email, draft.phone, draft.address];
}

/// Creates a customer, or updates [existing].
class CustomerFormBloc extends Bloc<CustomerSubmitted, SubmitState> {
  CustomerFormBloc({
    required this.repository,
    required this.userId,
    this.existing,
  }) : super(const SubmitState()) {
    on<CustomerSubmitted>((event, emit) async {
      emit(const SubmitState(status: SubmitStatus.saving));
      try {
        if (existing == null) {
          await repository.create(userId, event.draft);
        } else {
          await repository.update(existing!, event.draft);
        }
        emit(const SubmitState(status: SubmitStatus.success));
      } catch (_) {
        emit(const SubmitState(
            status: SubmitStatus.failure, error: 'Could not save the customer.'));
      }
    });
  }

  final CustomerRepository repository;
  final String userId;
  final CustomerLocal? existing;
}
