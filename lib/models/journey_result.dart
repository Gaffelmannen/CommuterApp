class JourneyResult {
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String duration;
  final String line;
  final String origin;
  final String destination;
  final int numberOfStops;

  const JourneyResult({
    this.departureTime,
    this.arrivalTime,

    String? duration,
    String? durationLabel,

    String? line,
    String? lineNumber,
    String? number,

    String? origin,
    String? departureStation,
    String? departureName,
    String? from,

    String? destination,
    String? arrivalStation,
    String? arrivalName,
    String? to,

    int? numberOfStops,
    int? stops,
    int? stopCount,
  })  : duration = duration ?? durationLabel ?? '',
        line = line ?? lineNumber ?? number ?? '',
        origin = origin ?? departureStation ?? departureName ?? from ?? '',
        destination =
            destination ?? arrivalStation ?? arrivalName ?? to ?? '',
        numberOfStops = numberOfStops ?? stops ?? stopCount ?? 0;

  factory JourneyResult.fromJson(Map<String, dynamic> json) {
    final legs = (json['legs'] as List?) ?? [];

    if (legs.isEmpty) {
      return const JourneyResult();
    }

    final firstLeg = legs.first as Map<String, dynamic>;
    final lastLeg = legs.last as Map<String, dynamic>;

    final departurePlanned =
        firstLeg['origin']?['departureTimePlanned'] as String?;
    final departureEstimated =
        firstLeg['origin']?['departureTimeEstimated'] as String?;

    final arrivalPlanned =
        lastLeg['destination']?['arrivalTimePlanned'] as String?;
    final arrivalEstimated =
        lastLeg['destination']?['arrivalTimeEstimated'] as String?;

    final departureTime =
        _parseDateTime(departureEstimated ?? departurePlanned);
    final arrivalTime =
        _parseDateTime(arrivalEstimated ?? arrivalPlanned);

    final originName = firstLeg['origin']?['name']?.toString() ?? '';
    final destinationName =
        lastLeg['destination']?['name']?.toString() ?? '';

    final transportation =
        (firstLeg['transportation'] as Map<String, dynamic>?) ?? {};
    final line = transportation['number']?.toString() ?? '';

    final stopSequence = firstLeg['stopSequence'] as List?;
    final stops = stopSequence?.length ?? 0;

    final durationSeconds = json['tripDuration'] as int? ?? 0;

    return JourneyResult(
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      duration: _formatDuration(durationSeconds),
      line: line,
      origin: originName,
      destination: destinationName,
      numberOfStops: stops,
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}