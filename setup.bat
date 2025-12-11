@echo off
echo.
echo 🚀 Configuration de Smart Mail La Poste
echo.

:: Vérifier si Flutter est installé
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter n'est pas installé. Installez-le depuis https://flutter.dev
    pause
    exit /b 1
)

echo ✅ Flutter détecté
echo.

:: Vérifier si .env existe
if not exist ".env" (
    echo ⚠️  Le fichier .env n'existe pas.
    echo 📝 Copie de .env.example vers .env
    copy .env.example .env
    echo.
    echo ⚠️  IMPORTANT : Éditez le fichier .env avec vos identifiants !
    echo.
)

echo 📦 Installation des dépendances...
call flutter pub get

echo.
echo 🔧 Génération du code (Isar + Riverpod)...
call flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo ✅ Configuration terminée !
echo.
echo 📋 Prochaines étapes :
echo    1. Éditez le fichier .env avec vos identifiants
echo    2. Lancez l'application avec : flutter run
echo.
pause
