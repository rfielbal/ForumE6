import 'package:flutter/material.dart';
import '../forum_controller.dart';
import '../models.dart';
import '../widgets.dart';
import 'compte_page.dart';

class UtilisateursPage extends StatefulWidget {
  const UtilisateursPage({super.key, required this.controller});
  final ForumController controller;
  @override
  State<UtilisateursPage> createState() => _UtilisateursPageState();
}

class _UtilisateursPageState extends State<UtilisateursPage> {
  String _recherche = '';
  Future<void> _actions(Utilisateur compte) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                compte.nomComplet,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier les informations'),
              onTap: () => Navigator.pop(context, 'modifier'),
            ),
            if (compte != widget.controller.utilisateur) ...[
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(
                  compte.suspendu
                      ? 'Réactiver le compte'
                      : 'Suspendre le compte',
                ),
                onTap: () => Navigator.pop(context, 'suspendre'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer le compte'),
                onTap: () => Navigator.pop(context, 'supprimer'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'modifier') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ComptePage(controller: widget.controller, compte: compte),
        ),
      );
      return;
    }
    final supprimer = action == 'supprimer';
    final label = supprimer
        ? 'Supprimer'
        : compte.suspendu
        ? 'Réactiver'
        : 'Suspendre';
    final accord = await confirmer(
      context,
      '$label ${compte.prenom} ?',
      supprimer
          ? 'Le compte local sera supprimé. Ses messages resteront visibles avec un auteur anonymisé.'
          : compte.suspendu
          ? 'Ce compte pourra à nouveau participer dans la démo.'
          : 'Ce compte pourra lire, mais plus publier, répondre ou modifier. Ses messages resteront visibles.',
      action: label,
    );
    if (!accord || !mounted) return;
    try {
      if (supprimer) {
        widget.controller.supprimerCompte(compte);
      } else {
        widget.controller.suspendre(compte);
      }
    } on StateError catch (e) {
      informer(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comptes = widget.controller.utilisateurs
        .where(
          (u) => u.nomComplet.toLowerCase().contains(_recherche.toLowerCase()),
        )
        .toList();
    return Column(
      children: [
        const BandeauDemo(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Rechercher par nom',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (valeur) => setState(() => _recherche = valeur),
              ),
              const SizedBox(height: 20),
              Text(
                '${comptes.length} utilisateur(s)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (final compte in comptes)
                      ListTile(
                        leading: Avatar(compte),
                        title: Text(compte.nomComplet),
                        subtitle: Text(
                          '${compte.admin ? 'Administrateur' : 'Membre'} · ${compte.suspendu ? 'Suspendu' : 'Actif'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _actions(compte),
                      ),
                    if (comptes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Aucun utilisateur trouvé.'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComptePage(controller: widget.controller),
                  ),
                ),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Ajouter un utilisateur'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Gestion simulée sur ce téléphone. La suspension n’est pas reliée à l’API.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
