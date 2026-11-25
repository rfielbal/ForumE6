import 'package:flutter/material.dart';
import '../forum_controller.dart';
import '../widgets.dart';
import 'compte_page.dart';
import 'connexion_page.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({
    super.key,
    required this.controller,
    required this.ouvrirMesMessages,
  });
  final ForumController controller;
  final VoidCallback ouvrirMesMessages;

  @override
  Widget build(BuildContext context) {
    final compte = controller.utilisateur;
    if (compte == null) {
      return EtatVide(
        'Votre espace personnel',
        controller.demonstration
            ? 'Choisissez un compte pour essayer la démo.'
            : 'Connectez-vous à votre compte du forum.',
        action: () => demanderConnexion(context, controller),
        bouton: controller.demonstration
            ? 'Choisir un compte de démo'
            : 'Se connecter',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (controller.demonstration) const BandeauDemo(),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(compte),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        compte.nomComplet,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(compte.email),
                Text(
                  !controller.demonstration
                      ? 'Compte connecté'
                      : compte.suspendu
                      ? 'Compte suspendu'
                      : compte.admin
                      ? 'Administrateur'
                      : 'Membre',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Mes informations'),
                trailing: const Icon(Icons.chevron_right),
                enabled: controller.peutEcrire,
                onTap: () async {
                  final enregistre = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ComptePage(controller: controller, compte: compte),
                    ),
                  );
                  if (!context.mounted || enregistre != true) return;
                  informer(
                    context,
                    controller.utilisateur == null
                        ? 'Profil enregistré. Reconnectez-vous avec votre nouvel e-mail.'
                        : 'Informations enregistrées.',
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: const Text('Mes messages'),
                trailing: const Icon(Icons.chevron_right),
                onTap: ouvrirMesMessages,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: controller.deconnecter,
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
        ),
        const SizedBox(height: 16),
        Text(
          controller.demonstration
              ? 'Les essais restent en mémoire jusqu’au redémarrage de l’application.'
              : 'Vous restez connecté jusqu’à la déconnexion ou à la fermeture de l’application.',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
