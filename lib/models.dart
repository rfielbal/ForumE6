// Les deux objets manipulés par les écrans. Pas de génération de code.
class Utilisateur {
  Utilisateur({
    required this.id,
    required this.prenom,
    required this.nom,
    this.email = '',
    this.admin = false,
    this.suspendu = false,
  });

  final String id;
  String prenom;
  String nom;
  String email;
  final bool admin;
  bool suspendu;

  String get nomComplet => '$prenom $nom'.trim();
  String get initiales => [
    prenom,
    nom,
  ].where((s) => s.isNotEmpty).map((s) => s[0]).join().toUpperCase();

  factory Utilisateur.fromJson(Map<String, dynamic> json) => Utilisateur(
    id: json['@id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    prenom: json['prenom']?.toString() ?? '',
    nom: json['nom']?.toString() ?? 'Auteur inconnu',
  );
}

class Message {
  Message({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.auteur,
    required this.date,
    this.parentId,
  });

  final String id;
  String titre;
  String contenu;
  final Utilisateur auteur;
  final DateTime? date;
  final String? parentId;

  factory Message.fromJson(Map<String, dynamic> json) {
    final parent = json['parent'];
    final user = json['user'];
    return Message(
      id: json['@id']?.toString() ?? '/forum/api/messages/${json['id']}',
      titre: json['titre']?.toString() ?? 'Sans titre',
      contenu: json['contenu']?.toString() ?? '',
      auteur: Utilisateur.fromJson(user is Map<String, dynamic> ? user : {}),
      date: DateTime.tryParse(json['datePoste']?.toString() ?? '')?.toLocal(),
      // L'API peut fournir le parent sous forme d'objet ou d'adresse (IRI).
      parentId: parent is Map ? parent['@id']?.toString() : parent as String?,
    );
  }
}

// Le mot de passe n’est jamais conservé dans la session.
class Session {
  const Session({required this.token, required this.utilisateur});
  final String token;
  final Utilisateur utilisateur;
}
