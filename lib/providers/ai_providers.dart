import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';

/// Provider pour le service d'IA (Claude)
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});
