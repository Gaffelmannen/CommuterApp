import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/journey_result.dart';

const String kJourneyPlannerBaseUrl =
    'https://journeyplanner.integration.sl.se/v2';

// Start with:
// flutter run --dart-define=TRAFIKLAB_API_KEY=your_key_here
const String kApiKey = String.fromEnvironment('TRAFIKLAB_API_KEY');

class SlJourneyService {
  const SlJourneyService();

  Future<List<JourneyResult>> lookupJourneys({
    required String stationOrigin,
    required String stationDestination,
    int numberOfTrips = 3,
  }) async {
    if (kApiKey.isEmpty) {
      throw Exception(
        'Missing API key. Start with --dart-define=TRAFIKLAB_API_KEY=...',
      );
    }

    final originId = await findStop(stationOrigin);
    final destinationId = await findStop(stationDestination);

    if (originId == null) {
      throw Exception('Could not find origin stop: $stationOrigin');
    }
    if (destinationId == null) {
      throw Exception('Could not find destination stop: $stationDestination');
    }

    final journeyTime = DateTime.now();
    final tripsData = await getTrips(
      originId: originId,
      destinationId: destinationId,
      journeyTime: journeyTime,
      numberOfTrips: numberOfTrips,
    );

    final journeys = (tripsData['journeys'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return journeys.map(_mapJourney).toList();
  }

  Future<String?> findStop(String name) async {
    final uri = Uri.parse('$kJourneyPlannerBaseUrl/stop-finder').replace(
      queryParameters: {
        'key': kApiKey,
        'name_sf': name,
        'type_sf': 'any',
        'any_obj_filter_sf': '2',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Stop lookup failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final locations = (data['locations'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return locations.isEmpty ? null : locations.first['id']?.toString();
  }

  Future<Map<String, dynamic>> getTrips({
    required String originId,
    required String destinationId,
    required DateTime journeyTime,
    required int numberOfTrips,
  }) async {
    final uri = Uri.parse('$kJourneyPlannerBaseUrl/trips').replace(
      queryParameters: {
        'key': kApiKey,
        'type_origin': 'any',
        'name_origin': originId,
        'type_destination': 'any',
        'name_destination': destinationId,
        'calc_number_of_trips': '$numberOfTrips',
        'itd_date': _formatDate(journeyTime),
        'itd_time': _formatClock(journeyTime),
        'itd_trip_date_time_dep_arr': 'dep',
        'calc_one_direction': 'true',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Trip lookup failed (${response.statusCode}).');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  JourneyResult _mapJourney(Map<String, dynamic> journey) {
    final legs = (journey['legs'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    if (legs.isEmpty) {
      throw Exception('Journey response did not include legs.');
    }

    final firstLeg = legs.first;
    final lastLeg = legs.last;

    String number = '';
    String departureName = '';
    String arrivalName = '';

    for (final leg in legs) {
      final transportation =
          (leg['transportation'] as Map<String, dynamic>? ?? {});
      number = transportation['number']?.toString() ?? number;
      departureName =
          ((leg['origin'] as Map<String, dynamic>? ?? const {})['name']
                  ?.toString()) ??
              departureName;
      arrivalName =
          ((leg['destination'] as Map<String, dynamic>? ?? const {})['name']
                  ?.toString()) ??
              arrivalName;
    }

    final firstOrigin = firstLeg['origin'] as Map<String, dynamic>? ?? {};
    final lastDestination = lastLeg['destination'] as Map<String, dynamic>? ?? {};

    final departurePlanned =
        getTimeFromDateTime(firstOrigin['departureTimePlanned']?.toString());
    final departureEstimated =
        getTimeFromDateTime(firstOrigin['departureTimeEstimated']?.toString()) ??
            departurePlanned;
    final arrivalPlanned =
        getTimeFromDateTime(lastDestination['arrivalTimePlanned']?.toString());
    final arrivalEstimated =
        getTimeFromDateTime(lastDestination['arrivalTimeEstimated']?.toString()) ??
            arrivalPlanned;

    final numberOfStops =
        (lastLeg['stopSequence'] as List<dynamic>? ?? const []).length;
    final durationSeconds = (journey['tripDuration'] as num?)?.toInt() ?? 0;

    return JourneyResult(
      lineNumber: number,
      departureName: departureName,
      arrivalName: arrivalName,
      departurePlanned: departurePlanned ?? '--:--',
      departureEstimated: departureEstimated ?? '--:--',
      arrivalPlanned: arrivalPlanned ?? '--:--',
      arrivalEstimated: arrivalEstimated ?? '--:--',
      numberOfStops: numberOfStops,
      durationLabel: convertFromSecondsToMinutes(durationSeconds),
    );
  }

  String convertFromSecondsToMinutes(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String? getTimeFromDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  String _formatClock(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour$minute';
  }
}
