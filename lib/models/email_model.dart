import 'package:isar/isar.dart';

part 'email_model.g.dart';

@embedded
class Attachment {
  late String filename;
  late String contentType; // MIME type (image/png, application/pdf, etc.)
  late int size; // Taille en bytes
  String? contentId; // Pour les images inline
  String? localPath; // Chemin local après téléchargement
  bool isDownloaded = false;

  // Données brutes de l'attachment (optionnel, pour petit fichiers)
  List<int>? data;
}

@collection
class EmailModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int uid; // UID du serveur IMAP

  @Index()
  late String mailboxPath; // Dossier où se trouve l'email (INBOX, Sent, etc.)

  late String from;
  late String to;
  late String subject;
  late String body;
  late String bodyHtml;
  late DateTime date;

  @Index()
  late bool isRead;

  late bool hasAttachments;
  List<Attachment> attachments = [];

  // Analyse IA
  String? aiResume;
  String? aiImportance; // haute, moyenne, faible
  String? aiCategory;

  @Index()
  late bool isAiAnalyzed;

  // Métadonnées
  late DateTime createdAt;
  DateTime? updatedAt;

  // Gatekeeper status
  String? senderTrustStatus; // trusted, blocked, null (unknown)

  EmailModel();

  factory EmailModel.create({
    required int uid,
    String mailboxPath = 'INBOX',
    required String from,
    required String to,
    required String subject,
    required String body,
    required String bodyHtml,
    required DateTime date,
    bool isRead = false,
    bool hasAttachments = false,
    List<Attachment>? attachments,
    String? aiResume,
    String? aiImportance,
    String? aiCategory,
    bool isAiAnalyzed = false,
    String? senderTrustStatus,
  }) {
    return EmailModel()
      ..uid = uid
      ..mailboxPath = mailboxPath
      ..from = from
      ..to = to
      ..subject = subject
      ..body = body
      ..bodyHtml = bodyHtml
      ..date = date
      ..isRead = isRead
      ..hasAttachments = hasAttachments
      ..attachments = attachments ?? []
      ..aiResume = aiResume
      ..aiImportance = aiImportance
      ..aiCategory = aiCategory
      ..isAiAnalyzed = isAiAnalyzed
      ..senderTrustStatus = senderTrustStatus
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }

  // Méthodes helper
  String get importanceColor {
    switch (aiImportance?.toLowerCase()) {
      case 'haute':
        return 'red';
      case 'moyenne':
        return 'orange';
      case 'faible':
        return 'green';
      default:
        return 'grey';
    }
  }

  String get displayFrom {
    // Extrait le nom de l'expéditeur (avant le <email>)
    final match = RegExp(r'^(.+?)\s*<').firstMatch(from);
    return match?.group(1) ?? from;
  }

  String get displayEmail {
    // Extrait l'email entre < >
    final match = RegExp(r'<(.+?)>').firstMatch(from);
    return match?.group(1) ?? from;
  }
}
