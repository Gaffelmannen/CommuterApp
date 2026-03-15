class DepartureResult {
  const DepartureResult({
    required this.line,
    required this.destination,
    required this.displayTime,
    required this.scheduledTime,
    required this.expectedTime,
    required this.transportMode,
    required this.stopPoint,
    required this.deviated,
  });

  final String line;
  final String destination;
  final String displayTime;
  final DateTime? scheduledTime;
  final DateTime? expectedTime;
  final String transportMode;
  final String stopPoint;
  final bool deviated;
}