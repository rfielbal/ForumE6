import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';

class Avatar extends StatelessWidget {
  const Avatar(this.utilisateur, {super.key});
  final Utilisateur utilisateur;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: fond,
    foregroundColor: graphite,
    child: Text(
      utilisateur.initiales.isEmpty ? '?' : utilisateur.initiales,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

String dateLisible(DateTime? date) {
  if (date == null) return 'Date non renseignée';
  String deux(int n) => n.toString().padLeft(2, '0');
  return '${deux(date.day)}/${deux(date.month)}/${date.year} · ${deux(date.hour)}:${deux(date.minute)}';
}

class CarteMessage extends StatelessWidget {
  const CarteMessage({
    super.key,
    required this.message,
    this.onTap,
    this.onModifier,
    this.nombreReponses,
    this.complet = false,
  });
  final Message message;
  final VoidCallback? onTap;
  final VoidCallback? onModifier;
  final int? nombreReponses;
  final bool complet;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(message.auteur),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.auteur.nomComplet,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        dateLisible(message.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onModifier != null)
                  IconButton(
                    tooltip: 'Modifier mon message',
                    onPressed: onModifier,
                    icon: const Icon(Icons.edit_outlined, size: 21),
                  ),
              ],
            ),
            if (message.parentId == null) ...[
              const SizedBox(height: 18),
              Text(
                message.titre,
                maxLines: complet ? null : 3,
                overflow: complet ? null : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              message.contenu,
              maxLines: complet ? null : 3,
              overflow: complet ? null : TextOverflow.ellipsis,
            ),
            if (nombreReponses != null) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$nombreReponses réponse(s)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class EtatVide extends StatelessWidget {
  const EtatVide(
    this.titre,
    this.description, {
    super.key,
    this.action,
    this.bouton = 'Réessayer',
  });
  final String titre;
  final String description;
  final VoidCallback? action;
  final String bouton;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 36),
            const SizedBox(height: 18),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(description, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: action, child: Text(bouton)),
            ],
          ],
        ),
      ),
    ),
  );
}

class BandeauDemo extends StatelessWidget {
  const BandeauDemo({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xFFFAEEEB),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    child: const Text(
      'DÉMO LOCALE · Aucun changement sur le serveur',
      style: TextStyle(
        fontSize: 12,
        color: Color(0xFF8D2B1F),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

void informer(BuildContext context, String texte) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
}

Future<bool> confirmer(
  BuildContext context,
  String titre,
  String texte, {
  String action = 'Supprimer',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: Text(texte),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
