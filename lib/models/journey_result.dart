class JourneyResult {
  const JourneyResult({
    required this.lineNumber,
    required this.departureName,
    required this.arrivalName,
    required this.departurePlanned,
    required this.departureEstimated,
    required this.arrivalPlanned,
    required this.arrivalEstimated,
    required this.numberOfStops,
    required this.durationLabel,
  });

  final String lineNumber;
  final String departureName;
  final String arrivalName;
  final String departurePlanned;
  final String departureEstimated;
  final String arrivalPlanned;
  final String arrivalEstimated;
  final int numberOfStops;
  final String durationLabel;
}
