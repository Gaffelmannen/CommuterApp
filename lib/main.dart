import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/site_result.dart';
import 'models/wallboard_filters.dart';
import 'pages/departure_board_page.dart';
import 'pages/journey_search_page.dart';
import 'pages/wallboard_page.dart';
import 'services/sl_departure_board_service.dart';
import 'settings/wallboard_settings.dart';

void main() {
  runApp(const CommuterApp());
}

class CommuterApp extends StatelessWidget {
  const CommuterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SL Commuter',
      debugShowCheckedModeBanner: false,
      locale: const Locale('sv', 'SE'),
      supportedLocales: const [
        Locale('sv', 'SE'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF050505),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111111),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0x22FFFFFF)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF101010),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF0B0B0B),
          indicatorColor: Color(0x33FFD54F),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const AppStartupPage(),
    );
  }
}

class AppStartupPage extends StatefulWidget {
  const AppStartupPage({super.key});

  @override
  State<AppStartupPage> createState() => _AppStartupPageState();
}

class _AppStartupPageState extends State<AppStartupPage> {
  final _service = const SlDepartureBoardService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final launchWallboard = await WallboardSettings.getLaunchWallboardOnStart();
    final saved = await WallboardSettings.getDefaultStation();

    if (!mounted) return;

    if (launchWallboard && saved.siteId != null && saved.siteName != null) {
      try {
        final departures = await _service.getDepartures(siteId: saved.siteId!);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WallboardPage(
              site: SiteResult(
                id: saved.siteId!,
                name: saved.siteName!,
              ),
              initialDepartures: departures,
              filters: const WallboardFilters(
                destinationFilter: '',
                routeFilter: '',
                selectedModes: <String>{},
                trainDirectionFilter: TrainDirectionFilter.all,
              ),
            ),
          ),
        );
        return;
      } catch (_) {
        // Fall back to the normal app if wallboard startup fails.
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const RootPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 1;

  final _pages = const [
    JourneySearchPage(),
    DepartureBoardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.departure_board_outlined),
            selectedIcon: Icon(Icons.departure_board),
            label: 'Board',
          ),
        ],
      ),
    );
  }
}