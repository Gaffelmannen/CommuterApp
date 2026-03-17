// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SL Commuter';

  @override
  String get tripsTab => 'Trips';

  @override
  String get boardTab => 'Board';

  @override
  String get startupLoading => 'Loading...';

  @override
  String get departureBoardTitle => 'Departure Board';

  @override
  String get station => 'Station';

  @override
  String get searchStationHint => 'Search station, e.g. Stuvsta';

  @override
  String selectedStation(Object station) {
    return 'Selected: $station';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get openWallboard => 'Open wallboard';

  @override
  String get setAsWallboardDefault => 'Set as wallboard default';

  @override
  String get savedAsDefault => 'Saved as default';

  @override
  String get clearDefault => 'Clear default';

  @override
  String get launchWallboardOnStart => 'Launch wallboard on app start';

  @override
  String get launchWallboardOnStartSubtitle => 'Uses the saved default wallboard station';

  @override
  String get filterByDestination => 'Filter by destination';

  @override
  String get filterByDestinationHint => 'e.g. Stockholm City';

  @override
  String get filterByRoute => 'Filter by route #';

  @override
  String get filterByRouteHint => 'e.g. 40 or 41';

  @override
  String get bus => 'Bus';

  @override
  String get tram => 'Tram';

  @override
  String get subway => 'Subway';

  @override
  String get train => 'Train';

  @override
  String get allTrains => 'All trains';

  @override
  String get northCity => 'North / City';

  @override
  String get southbound => 'Southbound';

  @override
  String showingDepartures(Object filtered, Object total) {
    return 'Showing $filtered of $total departures';
  }

  @override
  String noStationsMatch(Object query) {
    return 'No stations match \"$query\"';
  }

  @override
  String siteId(Object id) {
    return 'Site ID: $id';
  }

  @override
  String get searchForStationToOpenBoard => 'Search for a station to open its departure board';

  @override
  String get noDeparturesFound => 'No departures found for this station';

  @override
  String get noDeparturesMatchFilters => 'No departures match the current filters';

  @override
  String wallboardUpdated(Object time) {
    return 'Updated $time';
  }

  @override
  String get northCityGroup => 'North / City';

  @override
  String get southboundGroup => 'Southbound';

  @override
  String get otherGroup => 'Other';

  @override
  String get noDepartures => 'No departures';

  @override
  String get leaveNowToMakeNextConnection => 'Leave now to make the next connection';

  @override
  String leaveInToMakeNextConnection(Object minutes) {
    return 'Leave in $minutes to make the next connection';
  }

  @override
  String get noReachableDepartures => 'No reachable departures with current walking time';

  @override
  String leaveByDepartsLineDestination(Object leaveBy, Object departs, Object linePrefix, Object destination) {
    return 'Leave by $leaveBy • Departs $departs • $linePrefix$destination';
  }

  @override
  String linePrefix(Object line) {
    return 'Line $line • ';
  }

  @override
  String get kioskModeActive => 'Kiosk mode active';

  @override
  String get tooLate => 'Too late';

  @override
  String get now => 'Now';

  @override
  String get lessThanOneMinute => '<1 min';

  @override
  String minutesShort(Object minutes) {
    return '$minutes min';
  }

  @override
  String wallboardDefaultSavedMessage(Object station) {
    return '$station saved as wallboard default';
  }

  @override
  String get wallboardDefaultClearedMessage => 'Wallboard default cleared';

  @override
  String get journeyFrom => 'From';

  @override
  String get journeyTo => 'To';

  @override
  String get journeySwapStations => 'Swap stations';

  @override
  String get journeySearching => 'Searching...';

  @override
  String get journeySearchJourneys => 'Search journeys';

  @override
  String get journeyEnterBothOriginAndDestination => 'Please enter both origin and destination.';

  @override
  String get journeyEmptyTitle => 'Search to see upcoming trips';

  @override
  String get journeyEmptyBody => 'This app includes your commuter lookup logic split into pages, services, models, and widgets.';

  @override
  String journeyStops(Object count) {
    return '$count stops';
  }

  @override
  String journeyDuration(Object duration) {
    return 'Duration: $duration';
  }
}
