#!/bin/bash
echo "🔨 Build Flutter pour Développement..."

flutter clean
flutter pub get

flutter build apk --dart-define=ENVIRONMENT=development --debug

echo "✅ Build terminé!"