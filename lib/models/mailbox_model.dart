import 'package:isar/isar.dart';
import 'package:enough_mail/enough_mail.dart' hide Id;

part 'mailbox_model.g.dart';

@collection
class MailboxModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String path; // Ex: "INBOX", "Sent", "Spam"
  late String name; // Nom d'affichage
  late int messageCount; // Nombre de messages
  late int unseenCount; // Nombre de non lus

  String? parentPath; // Pour les dossiers imbriqués

  // Dossiers spéciaux (flags IMAP)
  bool isInbox = false;
  bool isSent = false;
  bool isTrash = false;
  bool isSpam = false;
  bool isDrafts = false;
  bool isArchive = false;

  DateTime? lastSync;

  MailboxModel();

  factory MailboxModel.fromImapMailbox(Mailbox mailbox) {
    return MailboxModel()
      ..path = mailbox.path
      ..name = mailbox.name
      ..messageCount = mailbox.messagesExists
      ..unseenCount = mailbox.messagesUnseen
      ..isInbox = mailbox.isInbox
      ..isSent = mailbox.isSent
      ..isTrash = mailbox.isTrash
      ..isSpam = mailbox.isJunk
      ..isDrafts = mailbox.isDrafts
      ..isArchive = mailbox.isArchive
      ..lastSync = DateTime.now();
  }
}
