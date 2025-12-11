import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../models/trusted_sender.dart';

final gatekeeperServiceProvider = Provider<GatekeeperService>((ref) {
  return GatekeeperService(ref.watch(isarProvider));
});

class GatekeeperService {
  final Isar _isar;

  GatekeeperService(this._isar);

  // Vérifier le statut d'un expéditeur
  Future<TrustedSender?> getSenderStatus(String email) async {
    return _isar.trustedSenders
        .filter()
        .emailEqualTo(email)
        .findFirst();
  }

  // Ajouter un expéditeur de confiance
  Future<void> trustSender(String email, String? name) async {
    final sender = TrustedSender.create(
      email: email,
      name: name,
      isTrusted: true,
    );

    await _isar.writeTxn(() async {
      // Supprimer l'ancien s'il existe (pour mise à jour)
      await _isar.trustedSenders.filter().emailEqualTo(email).deleteAll();
      await _isar.trustedSenders.put(sender);
    });
  }

  // Bloquer un expéditeur
  Future<void> blockSender(String email, String? name) async {
    final sender = TrustedSender.create(
      email: email,
      name: name,
      isTrusted: false,
    );

    await _isar.writeTxn(() async {
      await _isar.trustedSenders.filter().emailEqualTo(email).deleteAll();
      await _isar.trustedSenders.put(sender);
    });
  }

  // Analyser si un expéditeur est nouveau (pour l'UI)
  Future<bool> isNewSender(String email) async {
    final count = await _isar.trustedSenders
        .filter()
        .emailEqualTo(email)
        .count();
    return count == 0;
  }
}
