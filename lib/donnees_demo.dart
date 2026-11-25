import 'models.dart';

// Données fictives. Modifie ces exemples pour personnaliser la démonstration.
List<Utilisateur> creerUtilisateursDemo() => [
  Utilisateur(
    id: 'demo-camille',
    prenom: 'Camille',
    nom: 'Martin',
    email: 'camille@example.test',
    admin: true,
  ),
  Utilisateur(
    id: 'demo-maya',
    prenom: 'Maya',
    nom: 'Laurent',
    email: 'maya@example.test',
  ),
  Utilisateur(
    id: 'demo-noah',
    prenom: 'Noah',
    nom: 'Petit',
    email: 'noah@example.test',
  ),
  Utilisateur(
    id: 'demo-jules',
    prenom: 'Jules',
    nom: 'Bernard',
    email: 'jules@example.test',
    suspendu: true,
  ),
];

List<Message> creerMessagesDemo(List<Utilisateur> utilisateurs) {
  final maintenant = DateTime.now();
  return [
    Message(
      id: 'demo-1',
      titre: 'Par où commencer un projet Flutter ?',
      contenu:
          'Vous commencez par les écrans ou par les données ?\n\n'
          'Je prépare mon projet et j’aimerais éviter de tout refaire au milieu.',
      auteur: utilisateurs[1],
      date: maintenant.subtract(const Duration(minutes: 12)),
    ),
    Message(
      id: 'demo-2',
      titre: 'Comment préparez-vous votre oral ?',
      contenu:
          'Je prépare une démonstration de mon application en cinq minutes.\n\n'
          'Vous montrez toutes les fonctionnalités ou un seul parcours utilisateur ?',
      auteur: utilisateurs[0],
      date: maintenant.subtract(const Duration(minutes: 35)),
    ),
    Message(
      id: 'demo-3',
      titre: 'Re: Flutter',
      parentId: 'demo-1',
      contenu:
          'Je commence par les écrans. Ça aide à voir les données nécessaires.',
      auteur: utilisateurs[2],
      date: maintenant.subtract(const Duration(minutes: 5)),
    ),
    Message(
      id: 'demo-4',
      titre: 'Re: Flutter',
      parentId: 'demo-1',
      contenu: 'Pareil. Je dessine le parcours complet avant de développer.',
      auteur: utilisateurs[0],
      date: maintenant.subtract(const Duration(minutes: 2)),
    ),
  ];
}
