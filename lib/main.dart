import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/email_model.dart';
import 'models/chat_message.dart';
import 'models/chat_session.dart';
import 'models/mailbox_model.dart';
import 'models/trusted_sender.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme_2025.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le formatage de date pour le français
  await initializeDateFormatting('fr', null);

  // Charger les variables d'environnement
  await dotenv.load(fileName: ".env");

  // 🔐 MIGRATION AUTOMATIQUE: .env → Stockage Sécurisé
  await _migrateCredentialsToSecureStorage();

  // Initialiser Isar avec tous les schémas
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      EmailModelSchema,
      ChatMessageSchema,
      ChatSessionSchema,
      MailboxModelSchema,
      TrustedSenderSchema,
    ],
    directory: dir.path,
  );

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const MyApp(),
    ),
  );
}

/// Migre automatiquement les credentials de .env vers le stockage sécurisé.
/// Cette migration ne s'exécute qu'une seule fois au premier lancement.
Future<void> _migrateCredentialsToSecureStorage() async {
  final secureStorage = SecureStorageService();

  try {
    // Vérifier si la migration a déjà été effectuée
    final hasEmail = await secureStorage.hasEmailCredentials();
    final hasApiKey = await secureStorage.hasAnthropicApiKey();
    final hasPerplexity = await secureStorage.hasPerplexityApiKey();

    // Migration des credentials email
    if (!hasEmail) {
      print('🔄 Migration des credentials email vers le stockage sécurisé...');
      await secureStorage.migrateEmailCredentials(
        emailAddress: dotenv.env['EMAIL_ADDRESS'] ?? '',
        emailPassword: dotenv.env['EMAIL_PASSWORD'] ?? '',
        imapHost: dotenv.env['IMAP_HOST'] ?? 'imap.laposte.net',
        imapPort: dotenv.env['IMAP_PORT'] ?? '993',
        smtpHost: dotenv.env['SMTP_HOST'] ?? 'smtp.laposte.net',
        smtpPort: dotenv.env['SMTP_PORT'] ?? '465',
      );
      print('✅ Migration email terminée');
    } else {
      print('✅ Credentials email déjà présents dans le stockage sécurisé');
    }

    // Migration de la clé API Anthropic
    if (!hasApiKey) {
      print('🔄 Migration de la clé API Anthropic vers le stockage sécurisé...');
      await secureStorage.migrateAnthropicApiKey(
        dotenv.env['ANTHROPIC_API_KEY'] ?? '',
      );
      print('✅ Migration Anthropic terminée');
    } else {
      print('✅ Clé API Anthropic déjà présente dans le stockage sécurisé');
    }

    // Migration de la clé API Perplexity
    if (!hasPerplexity) {
      print('🔄 Migration de la clé API Perplexity vers le stockage sécurisé...');
      await secureStorage.migratePerplexityApiKey(
        dotenv.env['PERPLEXITY_API_KEY'] ?? '',
      );
      print('✅ Migration Perplexity terminée');
    } else {
      print('✅ Clé API Perplexity déjà présente dans le stockage sécurisé');
    }

    print('🎉 Toutes les migrations sont complètes. Les credentials sont maintenant stockés de manière sécurisée.');
  } catch (e) {
    print('❌ Erreur lors de la migration: $e');
    // On ne bloque pas l'app, mais on log l'erreur
  }
}

// Provider global pour Isar
final isarProvider = Provider<Isar>((ref) => throw UnimplementedError());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Mail La Poste',
      debugShowCheckedModeBanner: false,
      // 🎨 Nouveau thème 2025 avec Material 3 complet
      theme: AppTheme2025.lightTheme,
      darkTheme: AppTheme2025.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
