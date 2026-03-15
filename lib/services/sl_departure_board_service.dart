import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/departure_result.dart';
import '../models/site_result.dart';

const String kSlTransportBaseUrl = 'https://transport.integration.sl.se/v1';

class SlDepartureBoardService {
  const SlDepartureBoardService();

  Future<List<SiteResult>> searchSites(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse('$kSlTransportBaseUrl/sites').replace(
      queryParameters: {
        'query': trimmed,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Site search failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return const [];

    final sites = data
        .whereType<Map<String, dynamic>>()
        .map((site) {
          final id = site['id'];
          final name = site['name'];

          if (id is int && name is String) {
            return SiteResult(id: id, name: name);
          }
          return null;
        })
        .whereType<SiteResult>()
        .toList();

    final normalizedQuery = _normalizeForSearch(trimmed);

    final filtered = sites.where((site) {
      final normalizedName = _normalizeForSearch(site.name);

      return normalizedName.contains(normalizedQuery) ||
          normalizedName.split(' ').any((part) => part.startsWith(normalizedQuery));
    }).toList();

    filtered.sort((a, b) {
      final aName = _normalizeForSearch(a.name);
      final bName = _normalizeForSearch(b.name);

      final aStarts = aName.startsWith(normalizedQuery);
      final bStarts = bName.startsWith(normalizedQuery);

      if (aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }

      final aIndex = aName.indexOf(normalizedQuery);
      final bIndex = bName.indexOf(normalizedQuery);

      if (aIndex != bIndex) {
        return aIndex.compareTo(bIndex);
      }

      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  Future<List<DepartureResult>> getDepartures({
    required int siteId,
  }) async {
    final uri = Uri.parse('$kSlTransportBaseUrl/sites/$siteId/departures');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Departure lookup failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return const [];

    final departures = (data['departures'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_mapDeparture)
        .toList();

    departures.sort((a, b) {
      final at = a.expectedTime ?? a.scheduledTime;
      final bt = b.expectedTime ?? b.scheduledTime;

      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });

    return departures;
  }

  DepartureResult _mapDeparture(Map<String, dynamic> json) {
    final line = (json['line'] as Map<String, dynamic>? ?? const {});
    final stopPoint = (json['stop_point'] as Map<String, dynamic>? ?? const {});

    final destination = (json['destination'] ?? json['direction'] ?? '').toString();
    final displayTime = (json['display'] ?? '--').toString();

    final scheduled = _parseDateTime(json['scheduled']?.toString());
    final expected = _parseDateTime(json['expected']?.toString());

    final transportMode = (line['transport_mode'] ?? '').toString();
    final lineDesignation = (line['designation'] ?? line['name'] ?? '').toString();
    final stopPointName = (stopPoint['name'] ?? '').toString();
    final stopPointDesignation = (stopPoint['designation'] ?? '').toString();

    final deviated =
        expected != null && scheduled != null && expected.isAfter(scheduled);

    final stopPointLabel = stopPointDesignation.isEmpty
        ? stopPointName
        : '$stopPointName ($stopPointDesignation)';

    return DepartureResult(
      line: lineDesignation,
      destination: destination,
      displayTime: displayTime,
      scheduledTime: scheduled,
      expectedTime: expected,
      transportMode: transportMode,
      stopPoint: stopPointLabel,
      deviated: deviated,
    );
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _normalizeForSearch(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('å', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}