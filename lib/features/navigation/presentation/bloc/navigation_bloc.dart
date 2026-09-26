import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_destinations.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

export 'navigation_event.dart';
export 'navigation_state.dart';

/// BLoC controlling desktop shell routing, active page state, and sidebar visibility
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc({String initialDestination = AppDestinations.dashboard})
      : super(NavigationState(activeDestinationId: initialDestination)) {
    on<NavigateTo>(_onNavigateTo);
    on<ToggleSidebar>(_onToggleSidebar);
  }

  void _onNavigateTo(NavigateTo event, Emitter<NavigationState> emit) {
    if (state.activeDestinationId != event.destinationId) {
      emit(state.copyWith(activeDestinationId: event.destinationId));
    }
  }

  void _onToggleSidebar(ToggleSidebar event, Emitter<NavigationState> emit) {
    emit(state.copyWith(isSidebarCollapsed: !state.isSidebarCollapsed));
  }
}
