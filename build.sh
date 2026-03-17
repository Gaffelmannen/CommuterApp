#!/bin/bash

set -e

flutter clean
flutter pub get
flutter gen-l10n
flutter pub run flutter_launcher_icons
flutter run --dart-define=TRAFIKLAB_API_KEY=$TRAFIKLAB_API_KEY
