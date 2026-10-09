import 'package:equatable/equatable.dart';

import '../../../data/local/models/customer_local.dart';
import '../../../data/local/models/site_local.dart';
import '../../../data/local/models/field_note_local.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<CustomerLocal> customers;
  final List<SiteLocal> sites;
  final List<FieldNoteLocal> fieldNotes;

  const HomeLoaded({
    required this.customers,
    required this.sites,
    required this.fieldNotes,
  });

  int get pendingCount => fieldNotes
      .where((note) => (note.status ?? '').toUpperCase() == 'PENDING')
      .length;

  int get inProgressCount => fieldNotes
      .where((note) => (note.status ?? '').toUpperCase() == 'IN_PROGRESS')
      .length;

  int get completedCount => fieldNotes
      .where((note) => (note.status ?? '').toUpperCase() == 'COMPLETED')
      .length;

  @override
  List<Object?> get props => [customers, sites, fieldNotes];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
