import 'package:equatable/equatable.dart';

enum LoadStatus { loading, loaded, failure }

enum SubmitStatus { idle, saving, success, failure }

/// State shared by the add/edit form BLoCs.
class SubmitState extends Equatable {
  final SubmitStatus status;
  final String? error;

  const SubmitState({this.status = SubmitStatus.idle, this.error});

  bool get isSaving => status == SubmitStatus.saving;

  @override
  List<Object?> get props => [status, error];
}
