#!/bin/bash

echo "🚀 Configuration de Smart Mail La Poste"
echo ""

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter n'est pas installé. Installez-le depuis https://flutter.dev"
    exit 1
fi

echo "✅ Flutter détecté"
echo ""

# Vérifier si .env existe
if [ ! -f ".env" ]; then
    echo "⚠️  Le fichier .env n'existe pas."
    echo "📝 Copie de .env.example vers .env"
    cp .env.example .env
    echo ""
    echo "⚠️  IMPORTANT : Éditez le fichier .env avec vos identifiants !"
    echo ""
fi

echo "📦 Installation des dépendances..."
flutter pub get

echo ""
echo "🔧 Génération du code (Isar + Riverpod)..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Configuration terminée !"
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Éditez le fichier .env avec vos identifiants"
echo "   2. Lancez l'application avec : flutter run"
echo ""
