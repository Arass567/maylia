import 'package:isar/isar.dart';

part 'trusted_sender.g.dart';

@collection
class TrustedSender {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String email; // L'adresse email de l'expéditeur

  late String? name; // Nom affiché

  late bool isTrusted; // true = accepté, false = bloqué

  late DateTime firstSeenAt;
  late DateTime lastSeenAt;

  TrustedSender();

  factory TrustedSender.create({
    required String email,
    String? name,
    bool isTrusted = true,
  }) {
    return TrustedSender()
      ..email = email
      ..name = name
      ..isTrusted = isTrusted
      ..firstSeenAt = DateTime.now()
      ..lastSeenAt = DateTime.now();
  }
}
