import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/email_providers.dart';
import '../theme/app_theme_2025.dart';
import '../widgets/ai_writer_dialog.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (_toController.text.isEmpty || _subjectController.text.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir le destinataire et le sujet')),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSending = true);

    try {
      await ref.read(sendEmailProvider({
        'to': _toController.text,
        'subject': _subjectController.text,
        'body': _bodyController.text,
      }).future);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Email envoyé avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: AppTheme2025.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _openAiWriter() async {
    HapticFeedback.lightImpact();
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const AiWriterDialog(),
    );

    if (result != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        if (result['subject'] != null) _subjectController.text = result['subject']!;
        if (result['body'] != null) _bodyController.text = result['body']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau message'),
        actions: [
          Semantics(
            button: true,
            label: _isSending ? 'Envoi en cours' : 'Envoyer l\'email',
            enabled: !_isSending,
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isSending ? null : _sendEmail,
              color: AppTheme2025.laPosteYellow,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Destinataire
            Semantics(
              label: 'Destinataire de l\'email',
              textField: true,
              child: TextField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'À',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 16),

            // Sujet
            Semantics(
              label: 'Sujet de l\'email',
              textField: true,
              child: TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Sujet',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Barre d'outils IA
            Semantics(
              label: 'Assistant de rédaction IA',
              hint: 'Touchez pour rédiger avec l\'intelligence artificielle',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme2025.laPosteYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme2025.laPosteYellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: const Icon(Icons.auto_awesome, color: AppTheme2025.laPosteBlue, size: 20),
                    ),
                    const SizedBox(width: 8),
                    ExcludeSemantics(
                      child: const Text(
                        'Besoin d\'aide ?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme2025.laPosteBlue),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: 'Rédiger avec l\'IA',
                      child: TextButton.icon(
                        onPressed: _openAiWriter,
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Rédiger avec l\'IA'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme2025.laPosteBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Corps
            Semantics(
              label: 'Corps du message',
              textField: true,
              multiline: true,
              child: TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  hintText: 'Rédigez votre message...',
                  border: InputBorder.none,
                  filled: false,
                ),
                maxLines: null,
                minLines: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
