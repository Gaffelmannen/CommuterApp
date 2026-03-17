import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SL Commuter'**
  String get appTitle;

  /// No description provided for @tripsTab.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tripsTab;

  /// No description provided for @boardTab.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardTab;

  /// No description provided for @startupLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get startupLoading;

  /// No description provided for @departureBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Departure Board'**
  String get departureBoardTitle;

  /// No description provided for @station.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get station;

  /// No description provided for @searchStationHint.
  ///
  /// In en, this message translates to:
  /// **'Search station, e.g. Stuvsta'**
  String get searchStationHint;

  /// No description provided for @selectedStation.
  ///
  /// In en, this message translates to:
  /// **'Selected: {station}'**
  String selectedStation(Object station);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @openWallboard.
  ///
  /// In en, this message translates to:
  /// **'Open wallboard'**
  String get openWallboard;

  /// No description provided for @setAsWallboardDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as wallboard default'**
  String get setAsWallboardDefault;

  /// No description provided for @savedAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Saved as default'**
  String get savedAsDefault;

  /// No description provided for @clearDefault.
  ///
  /// In en, this message translates to:
  /// **'Clear default'**
  String get clearDefault;

  /// No description provided for @launchWallboardOnStart.
  ///
  /// In en, this message translates to:
  /// **'Launch wallboard on app start'**
  String get launchWallboardOnStart;

  /// No description provided for @launchWallboardOnStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses the saved default wallboard station'**
  String get launchWallboardOnStartSubtitle;

  /// No description provided for @filterByDestination.
  ///
  /// In en, this message translates to:
  /// **'Filter by destination'**
  String get filterByDestination;

  /// No description provided for @filterByDestinationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Stockholm City'**
  String get filterByDestinationHint;

  /// No description provided for @filterByRoute.
  ///
  /// In en, this message translates to:
  /// **'Filter by route #'**
  String get filterByRoute;

  /// No description provided for @filterByRouteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 40 or 41'**
  String get filterByRouteHint;

  /// No description provided for @bus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// No description provided for @tram.
  ///
  /// In en, this message translates to:
  /// **'Tram'**
  String get tram;

  /// No description provided for @subway.
  ///
  /// In en, this message translates to:
  /// **'Subway'**
  String get subway;

  /// No description provided for @train.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get train;

  /// No description provided for @allTrains.
  ///
  /// In en, this message translates to:
  /// **'All trains'**
  String get allTrains;

  /// No description provided for @northCity.
  ///
  /// In en, this message translates to:
  /// **'North / City'**
  String get northCity;

  /// No description provided for @southbound.
  ///
  /// In en, this message translates to:
  /// **'Southbound'**
  String get southbound;

  /// No description provided for @showingDepartures.
  ///
  /// In en, this message translates to:
  /// **'Showing {filtered} of {total} departures'**
  String showingDepartures(Object filtered, Object total);

  /// No description provided for @noStationsMatch.
  ///
  /// In en, this message translates to:
  /// **'No stations match \"{query}\"'**
  String noStationsMatch(Object query);

  /// No description provided for @siteId.
  ///
  /// In en, this message translates to:
  /// **'Site ID: {id}'**
  String siteId(Object id);

  /// No description provided for @searchForStationToOpenBoard.
  ///
  /// In en, this message translates to:
  /// **'Search for a station to open its departure board'**
  String get searchForStationToOpenBoard;

  /// No description provided for @noDeparturesFound.
  ///
  /// In en, this message translates to:
  /// **'No departures found for this station'**
  String get noDeparturesFound;

  /// No description provided for @noDeparturesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No departures match the current filters'**
  String get noDeparturesMatchFilters;

  /// No description provided for @wallboardUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String wallboardUpdated(Object time);

  /// No description provided for @northCityGroup.
  ///
  /// In en, this message translates to:
  /// **'North / City'**
  String get northCityGroup;

  /// No description provided for @southboundGroup.
  ///
  /// In en, this message translates to:
  /// **'Southbound'**
  String get southboundGroup;

  /// No description provided for @otherGroup.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherGroup;

  /// No description provided for @noDepartures.
  ///
  /// In en, this message translates to:
  /// **'No departures'**
  String get noDepartures;

  /// No description provided for @leaveNowToMakeNextConnection.
  ///
  /// In en, this message translates to:
  /// **'Leave now to make the next connection'**
  String get leaveNowToMakeNextConnection;

  /// No description provided for @leaveInToMakeNextConnection.
  ///
  /// In en, this message translates to:
  /// **'Leave in {minutes} to make the next connection'**
  String leaveInToMakeNextConnection(Object minutes);

  /// No description provided for @noReachableDepartures.
  ///
  /// In en, this message translates to:
  /// **'No reachable departures with current walking time'**
  String get noReachableDepartures;

  /// No description provided for @leaveByDepartsLineDestination.
  ///
  /// In en, this message translates to:
  /// **'Leave by {leaveBy} • Departs {departs} • {linePrefix}{destination}'**
  String leaveByDepartsLineDestination(Object leaveBy, Object departs, Object linePrefix, Object destination);

  /// No description provided for @linePrefix.
  ///
  /// In en, this message translates to:
  /// **'Line {line} • '**
  String linePrefix(Object line);

  /// No description provided for @kioskModeActive.
  ///
  /// In en, this message translates to:
  /// **'Kiosk mode active'**
  String get kioskModeActive;

  /// No description provided for @tooLate.
  ///
  /// In en, this message translates to:
  /// **'Too late'**
  String get tooLate;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @lessThanOneMinute.
  ///
  /// In en, this message translates to:
  /// **'<1 min'**
  String get lessThanOneMinute;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(Object minutes);

  /// No description provided for @wallboardDefaultSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'{station} saved as wallboard default'**
  String wallboardDefaultSavedMessage(Object station);

  /// No description provided for @wallboardDefaultClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallboard default cleared'**
  String get wallboardDefaultClearedMessage;

  /// No description provided for @journeyFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get journeyFrom;

  /// No description provided for @journeyTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get journeyTo;

  /// No description provided for @journeySwapStations.
  ///
  /// In en, this message translates to:
  /// **'Swap stations'**
  String get journeySwapStations;

  /// No description provided for @journeySearching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get journeySearching;

  /// No description provided for @journeySearchJourneys.
  ///
  /// In en, this message translates to:
  /// **'Search journeys'**
  String get journeySearchJourneys;

  /// No description provided for @journeyEnterBothOriginAndDestination.
  ///
  /// In en, this message translates to:
  /// **'Please enter both origin and destination.'**
  String get journeyEnterBothOriginAndDestination;

  /// No description provided for @journeyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search to see upcoming trips'**
  String get journeyEmptyTitle;

  /// No description provided for @journeyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This app includes your commuter lookup logic split into pages, services, models, and widgets.'**
  String get journeyEmptyBody;

  /// No description provided for @journeyStops.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String journeyStops(Object count);

  /// No description provided for @journeyDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String journeyDuration(Object duration);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'sv': return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
