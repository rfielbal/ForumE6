import 'package:flutter/material.dart';
import '../forum_controller.dart';
import '../models.dart';
import '../widgets.dart';
import 'connexion_page.dart';
import 'redaction_page.dart';

class DiscussionPage extends StatelessWidget {
  const DiscussionPage({
    super.key,
    required this.controller,
    required this.messageId,
  });
  final ForumController controller;
  final String messageId;

  Future<void> _modifier(BuildContext context, Message message) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RedactionPage(controller: controller, message: message),
      ),
    );
  }

  Future<void> _supprimer(
    BuildContext context,
    Message message,
    bool principal,
  ) async {
    final accord = await confirmer(
      context,
      'Supprimer ce message ?',
      principal
          ? 'Ce message et ses réponses seront supprimés de la démo locale.'
          : 'Cette réponse sera supprimée de la démo locale.',
    );
    if (!accord || !context.mounted) return;
    try {
      controller.supprimer(message);
      if (principal) Navigator.pop(context);
    } on StateError catch (e) {
      informer(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final trouves = controller.messages.where((m) => m.id == messageId);
      if (trouves.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text('Discussion')),
          body: EtatVide(
            'Message supprimé',
            'Cette discussion n’est plus disponible.',
            action: () => Navigator.pop(context),
            bouton: 'Retour au forum',
          ),
        );
      }
      final message = trouves.first;
      final reponses = controller.reponses(message);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Discussion'),
          actions: [
            if (controller.peutSupprimer(message))
              IconButton(
                tooltip: 'Supprimer le message',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _supprimer(context, message, true),
              ),
          ],
        ),
        body: Column(
          children: [
            if (controller.demonstration) const BandeauDemo(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CarteMessage(
                    message: message,
                    complet: true,
                    onModifier: controller.peutModifier(message)
                        ? () => _modifier(context, message)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 4,
                    ),
                    child: Text(
                      'RÉPONSES · ${reponses.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (reponses.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Aucune réponse pour le moment.'),
                      ),
                    ),
                  for (final reponse in reponses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          CarteMessage(
                            message: reponse,
                            complet: true,
                            onModifier: controller.peutModifier(reponse)
                                ? () => _modifier(context, reponse)
                                : null,
                          ),
                          if (controller.peutSupprimer(reponse))
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _supprimer(context, reponse, false),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: const Text('Supprimer la réponse'),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: FilledButton(
              onPressed: () async {
                if (!controller.demonstration) {
                  // Un message réel n'est jamais copié dans les données de test.
                  Navigator.pop(context);
                  controller.choisirMode(true);
                  return;
                }
                if (!await demanderConnexion(context, controller) ||
                    !context.mounted) {
                  return;
                }
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RedactionPage(controller: controller, parent: message),
                  ),
                );
              },
              child: Text(
                !controller.demonstration
                    ? 'Tester les réponses en démo'
                    : controller.utilisateur == null
                    ? 'Se connecter pour répondre'
                    : 'Répondre',
              ),
            ),
          ),
        ),
      );
    },
  );
}
