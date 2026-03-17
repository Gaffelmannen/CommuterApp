// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'SL Commuter';

  @override
  String get tripsTab => 'Resor';

  @override
  String get boardTab => 'Tavla';

  @override
  String get startupLoading => 'Laddar...';

  @override
  String get departureBoardTitle => 'Avgångstavla';

  @override
  String get station => 'Station';

  @override
  String get searchStationHint => 'Sök station, t.ex. Stuvsta';

  @override
  String selectedStation(Object station) {
    return 'Vald: $station';
  }

  @override
  String get refresh => 'Uppdatera';

  @override
  String get openWallboard => 'Öppna väggtavla';

  @override
  String get setAsWallboardDefault => 'Spara som standard för väggtavla';

  @override
  String get savedAsDefault => 'Sparad som standard';

  @override
  String get clearDefault => 'Rensa standard';

  @override
  String get launchWallboardOnStart => 'Starta väggtavlan vid appstart';

  @override
  String get launchWallboardOnStartSubtitle => 'Använder den sparade standardstationen';

  @override
  String get filterByDestination => 'Filtrera på destination';

  @override
  String get filterByDestinationHint => 't.ex. Stockholm City';

  @override
  String get filterByRoute => 'Filtrera på linje #';

  @override
  String get filterByRouteHint => 't.ex. 40 eller 41';

  @override
  String get bus => 'Buss';

  @override
  String get tram => 'Spårvagn';

  @override
  String get subway => 'Tunnelbana';

  @override
  String get train => 'Tåg';

  @override
  String get allTrains => 'Alla tåg';

  @override
  String get northCity => 'Norr / City';

  @override
  String get southbound => 'Söderut';

  @override
  String showingDepartures(Object filtered, Object total) {
    return 'Visar $filtered av $total avgångar';
  }

  @override
  String noStationsMatch(Object query) {
    return 'Inga stationer matchar \"$query\"';
  }

  @override
  String siteId(Object id) {
    return 'Plats-ID: $id';
  }

  @override
  String get searchForStationToOpenBoard => 'Sök efter en station för att öppna avgångstavlan';

  @override
  String get noDeparturesFound => 'Inga avgångar hittades för den här stationen';

  @override
  String get noDeparturesMatchFilters => 'Inga avgångar matchar nuvarande filter';

  @override
  String wallboardUpdated(Object time) {
    return 'Uppdaterad $time';
  }

  @override
  String get northCityGroup => 'Norr / City';

  @override
  String get southboundGroup => 'Söderut';

  @override
  String get otherGroup => 'Övrigt';

  @override
  String get noDepartures => 'Inga avgångar';

  @override
  String get leaveNowToMakeNextConnection => 'Gå nu för att hinna nästa anslutning';

  @override
  String leaveInToMakeNextConnection(Object minutes) {
    return 'Gå om $minutes för att hinna nästa anslutning';
  }

  @override
  String get noReachableDepartures => 'Inga avgångar går att nå med nuvarande gångtid';

  @override
  String leaveByDepartsLineDestination(Object leaveBy, Object departs, Object linePrefix, Object destination) {
    return 'Gå senast $leaveBy • Avgår $departs • $linePrefix$destination';
  }

  @override
  String linePrefix(Object line) {
    return 'Linje $line • ';
  }

  @override
  String get kioskModeActive => 'Kioskläge aktivt';

  @override
  String get tooLate => 'För sent';

  @override
  String get now => 'Nu';

  @override
  String get lessThanOneMinute => '<1 min';

  @override
  String minutesShort(Object minutes) {
    return '$minutes min';
  }

  @override
  String wallboardDefaultSavedMessage(Object station) {
    return '$station sparad som standard för väggtavlan';
  }

  @override
  String get wallboardDefaultClearedMessage => 'Standard för väggtavla rensad';

  @override
  String get journeyFrom => 'Från';

  @override
  String get journeyTo => 'Till';

  @override
  String get journeySwapStations => 'Byt stationer';

  @override
  String get journeySearching => 'Söker...';

  @override
  String get journeySearchJourneys => 'Sök resor';

  @override
  String get journeyEnterBothOriginAndDestination => 'Ange både start och destination.';

  @override
  String get journeyEmptyTitle => 'Sök för att se kommande resor';

  @override
  String get journeyEmptyBody => 'Appen innehåller din pendlingslogik uppdelad i sidor, tjänster, modeller och widgets.';

  @override
  String journeyStops(Object count) {
    return '$count stopp';
  }

  @override
  String journeyDuration(Object duration) {
    return 'Restid: $duration';
  }
}
