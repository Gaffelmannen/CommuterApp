enum TrainDirectionFilter {
  all,
  northbound,
  southbound,
}

class WallboardFilters {
  const WallboardFilters({
    required this.destinationFilter,
    required this.routeFilter,
    required this.selectedModes,
    required this.trainDirectionFilter,
  });

  final String destinationFilter;
  final String routeFilter;
  final Set<String> selectedModes;
  final TrainDirectionFilter trainDirectionFilter;

  WallboardFilters copyWith({
    String? destinationFilter,
    String? routeFilter,
    Set<String>? selectedModes,
    TrainDirectionFilter? trainDirectionFilter,
  }) {
    return WallboardFilters(
      destinationFilter: destinationFilter ?? this.destinationFilter,
      routeFilter: routeFilter ?? this.routeFilter,
      selectedModes: selectedModes ?? this.selectedModes,
      trainDirectionFilter: trainDirectionFilter ?? this.trainDirectionFilter,
    );
  }
}
