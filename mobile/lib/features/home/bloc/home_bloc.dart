import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/local_customer_repository.dart';
import '../../../data/repositories/local_site_repository.dart';
import '../../../data/repositories/local_field_note_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final String userId;
  final LocalCustomerRepository customerRepository;
  final LocalSiteRepository siteRepository;
  final LocalFieldNoteRepository fieldNoteRepository;

  HomeBloc({
    required this.userId,
    LocalCustomerRepository? customerRepository,
    LocalSiteRepository? siteRepository,
    LocalFieldNoteRepository? fieldNoteRepository,
  }) : customerRepository = customerRepository ?? LocalCustomerRepository(),
       siteRepository = siteRepository ?? LocalSiteRepository(),
       fieldNoteRepository = fieldNoteRepository ?? LocalFieldNoteRepository(),
       super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint('[HOME DEBUG] Loading dashboard for userId: ');
    emit(const HomeLoading());

    try {
      final customers = await customerRepository.getCustomers(userId);
      final sites = <dynamic>[];
      final fieldNotes = <dynamic>[];

      for (final customer in customers) {
        final customerSites = await siteRepository.getSites(customer.id);

        sites.addAll(customerSites);

        for (final site in customerSites) {
          final notes = await fieldNoteRepository.getFieldNotes(site.id);
          fieldNotes.addAll(notes);
        }
      }

      emit(
        HomeLoaded(
          customers: customers,
          sites: sites.cast(),
          fieldNotes: fieldNotes.cast(),
        ),
      );
    } catch (error) {
      emit(HomeError('Unable to load dashboard data. Please try again.'));
    }
  }
}
