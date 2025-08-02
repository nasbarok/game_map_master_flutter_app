#!/bin/bash
echo "🔨 Build Flutter pour Preprod Hetzner Cloud..."

flutter clean
flutter pub get

# Build APK pour preprod
flutter build apk --dart-define=ENVIRONMENT=preprod --release

echo "✅ Build terminé!"
echo "📱 APK disponible dans: F:\dev\airsoft_app\flutter-app\build\app\outputs\apk\release/app-release.apk"
