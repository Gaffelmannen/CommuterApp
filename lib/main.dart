import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
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

class CommuterApp extends StatefulWidget {
  const CommuterApp({super.key});

  @override
  State<CommuterApp> createState() => _CommuterAppState();
}

class _CommuterAppState extends State<CommuterApp> {
  Locale? _locale;

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SL Commuter',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
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
      ),
      home: AppStartupPage(onChangeLocale: _setLocale),
    );
  }
}

class AppStartupPage extends StatefulWidget {
  const AppStartupPage({super.key, required this.onChangeLocale});

  final void Function(Locale) onChangeLocale;

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
    final launchWallboard =
        await WallboardSettings.getLaunchWallboardOnStart();
    final saved = await WallboardSettings.getDefaultStation();

    if (!mounted) return;

    if (launchWallboard &&
        saved.siteId != null &&
        saved.siteName != null) {
      try {
        final departures =
            await _service.getDepartures(siteId: saved.siteId!);

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
      } catch (_) {}
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RootPage(
          onChangeLocale: widget.onChangeLocale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            if (l10n != null) Text(l10n.startupLoading),
          ],
        ),
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key, required this.onChangeLocale});

  final void Function(Locale) onChangeLocale;

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: widget.onChangeLocale,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: Locale('en'),
                child: Text('English'),
              ),
              PopupMenuItem(
                value: Locale('sv'),
                child: Text('Svenska'),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: l10n.tripsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.departure_board_outlined),
            selectedIcon: const Icon(Icons.departure_board),
            label: l10n.boardTab,
          ),
        ],
      ),
    );
  }
}