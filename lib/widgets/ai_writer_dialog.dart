import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/email_providers.dart';
import '../theme/app_theme_2025.dart';

class AiWriterDialog extends ConsumerStatefulWidget {
  final String? originalBody; // Si null, c'est un nouveau brouillon

  const AiWriterDialog({super.key, this.originalBody});

  @override
  ConsumerState<AiWriterDialog> createState() => _AiWriterDialogState();
}

class _AiWriterDialogState extends ConsumerState<AiWriterDialog> {
  final _instructionController = TextEditingController();
  String _selectedTone = 'professionnel';
  bool _isGenerating = false;
  String? _generatedContent;
  String? _generatedSubject;

  final List<String> _tones = ['professionnel', 'amical', 'concis', 'formel'];

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_instructionController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedContent = null;
      _generatedSubject = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      String result;

      if (widget.originalBody != null) {
        // Réponse
        result = await aiService.generateReply(
          originalBody: widget.originalBody!,
          instruction: _instructionController.text,
          tone: _selectedTone,
        );
        _generatedContent = result;
      } else {
        // Nouveau brouillon
        result = await aiService.generateDraft(
          instruction: _instructionController.text,
          tone: _selectedTone,
        );
        
        // Parser Sujet/Corps
        final subjectMatch = RegExp(r'SUJET:\s*(.*)').firstMatch(result);
        final bodyMatch = RegExp(r'CORPS:\s*([\s\S]*)').firstMatch(result);

        if (subjectMatch != null && bodyMatch != null) {
          _generatedSubject = subjectMatch.group(1)?.trim();
          _generatedContent = bodyMatch.group(1)?.trim();
        } else {
          _generatedContent = result; // Fallback
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme2025.laPosteYellow),
                const SizedBox(width: 12),
                Text(
                  widget.originalBody != null
                      ? 'Réponse IA'
                      : 'Rédaction IA',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (_generatedContent == null) ...[
              // Étape 1: Instruction
              TextField(
                controller: _instructionController,
                decoration: InputDecoration(
                  labelText: 'Instruction',
                  hintText: widget.originalBody != null
                      ? 'Ex: Accepte la proposition mais demande un délai'
                      : 'Ex: Demande un rendez-vous pour mardi prochain',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Sélection du ton
              Text('Ton :', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tones.map((tone) {
                  final isSelected = _selectedTone == tone;
                  return ChoiceChip(
                    label: Text(tone),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTone = tone);
                    },
                    selectedColor: AppTheme2025.laPosteYellow.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Bouton Générer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generate,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating ? 'Génération...' : 'Générer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme2025.laPosteYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              // Étape 2: Résultat (avec scroll pour contenu long)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5, // Max 50% de l'écran
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_generatedSubject != null) ...[
                          Text('Sujet: $_generatedSubject',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                        ],
                        Text(_generatedContent!),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _generatedContent = null),
                    child: const Text('Réessayer'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'subject': _generatedSubject,
                        'body': _generatedContent,
                      });
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Insérer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme2025.laPosteYellow,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
