import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

// Tous les appels HTTP sont ici. Les écrans ne connaissent pas les URL.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static final origine = Uri.parse('https://4719.s3.nuage-peda.fr');

  Future<List<Message>> lireMessages() async {
    final liste = await _lireCollection('/forum/api/messages');
    return liste.map(Message.fromJson).toList();
  }

  Future<void> inscrire(
    String prenom,
    String nom,
    String email,
    String password,
  ) async {
    await _lireReponse(
      _client.post(
        origine.resolve('/forum/api/users'),
        headers: {
          'Content-Type': 'application/ld+json',
          'Accept': 'application/ld+json',
        },
        body: jsonEncode({
          'prenom': prenom.trim(),
          'nom': nom.trim(),
          'email': email.trim(),
          'password': password,
        }),
      ),
      attendu: 201,
    );
  }

  Future<Session> connecter(String email, String password) async {
    final adresse = email.trim();
    final json = await _lireReponse(
      _client.post(
        origine.resolve('/forum/api/authentication_token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': adresse, 'password': password}),
      ),
      connexion: true,
    );
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Le serveur n’a pas renvoyé de token.');
    }

    // L’API n’a pas de route /me ni de filtre e-mail documenté.
    // Le détail d’un utilisateur contient son e-mail, contrairement à la liste.
    final comptes = await _lireCollection('/forum/api/users', token: token);
    for (final compte in comptes) {
      final detail = await _get(compte['@id'] as String, token: token);
      if (detail['email']?.toString().toLowerCase() == adresse.toLowerCase()) {
        return Session(token: token, utilisateur: Utilisateur.fromJson(detail));
      }
    }
    throw const ApiException('Impossible de retrouver le compte connecté.');
  }

  Future<Utilisateur> modifierProfil(
    String prenom,
    String nom,
    String email,
    Session session,
  ) async {
    final compte = session.utilisateur;
    // PATCH envoie uniquement les informations qui ont changé.
    final changements = <String, String>{};
    if (prenom.trim() != compte.prenom) changements['prenom'] = prenom.trim();
    if (nom.trim() != compte.nom) changements['nom'] = nom.trim();
    if (email.trim() != compte.email) changements['email'] = email.trim();
    if (changements.isEmpty) return compte;

    final json = await _lireReponse(
      _client.patch(
        origine.resolve(compte.id),
        headers: {
          'Content-Type': 'application/merge-patch+json',
          'Accept': 'application/ld+json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: jsonEncode(changements),
      ),
    );
    return Utilisateur.fromJson(json);
  }

  Future<Message> publier(String titre, String contenu, Session session) async {
    final json = await _lireReponse(
      _client.post(
        origine.resolve('/forum/api/messages'),
        headers: {
          'Content-Type': 'application/ld+json',
          'Accept': 'application/ld+json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: jsonEncode({
          'titre': titre.trim(),
          'contenu': contenu.trim(),
          'datePoste': DateTime.now().toUtc().toIso8601String(),
          'user': session.utilisateur.id,
        }),
      ),
      attendu: 201,
      publication: true,
    );
    // Le POST renvoie l’auteur sous forme d’IRI. Nous connaissons déjà ce compte.
    final message = Message.fromJson(json);
    return Message(
      id: message.id,
      titre: message.titre,
      contenu: message.contenu,
      auteur: session.utilisateur,
      date: message.date,
    );
  }

  // Une même boucle de pagination sert aux messages et aux utilisateurs.
  Future<List<Map<String, dynamic>>> _lireCollection(
    String chemin, {
    String? token,
  }) async {
    final elements = <Map<String, dynamic>>[];
    final pagesLues = <String>{};
    String? page = chemin;
    while (page != null) {
      if (!pagesLues.add(page)) {
        throw const ApiException('La pagination du serveur est invalide.');
      }
      final json = await _get(page, token: token);
      final liste = json['member'] ?? json['hydra:member'];
      if (liste is! List) {
        throw const ApiException('Le serveur n’a pas renvoyé de liste.');
      }
      elements.addAll(liste.whereType<Map<String, dynamic>>());
      final vue = json['view'] ?? json['hydra:view'];
      page = vue is Map ? (vue['next'] ?? vue['hydra:next']) as String? : null;
    }
    return elements;
  }

  Future<Map<String, dynamic>> _get(String chemin, {String? token}) {
    final url = origine.resolve(chemin);
    // Conserve la vérification déjà présente pour les liens de pagination.
    if (url.origin != origine.origin) {
      throw const ApiException('Le lien du serveur est invalide.');
    }
    return _lireReponse(
      _client.get(
        url,
        headers: {
          'Accept': 'application/ld+json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  // Un seul endroit pour traduire les erreurs HTTP et réseau pour les écrans.
  Future<Map<String, dynamic>> _lireReponse(
    Future<http.Response> requete, {
    int attendu = 200,
    bool connexion = false,
    bool publication = false,
  }) async {
    try {
      final reponse = await requete.timeout(const Duration(seconds: 20));
      if (reponse.statusCode != attendu) {
        if (reponse.statusCode == 422) {
          final json = jsonDecode(utf8.decode(reponse.bodyBytes));
          final violations = json is Map ? json['violations'] : null;
          if (violations is List && violations.isNotEmpty) {
            final messages = violations
                .whereType<Map>()
                .map((v) => v['message'])
                .whereType<String>()
                .join('\n');
            if (messages.isNotEmpty) {
              throw ApiException(messages, statusCode: 422);
            }
          }
        }
        final message = switch (reponse.statusCode) {
          401 =>
            connexion
                ? 'E-mail ou mot de passe incorrect.'
                : 'Votre session a expiré. Reconnectez-vous.',
          403 => 'Votre compte n’est pas autorisé à effectuer cette action.',
          400 ||
          422 => 'Le serveur refuse ces informations. Vérifiez les champs.',
          _ => 'Le serveur est indisponible (HTTP ${reponse.statusCode}).',
        };
        throw ApiException(message, statusCode: reponse.statusCode);
      }
      final json = jsonDecode(utf8.decode(reponse.bodyBytes));
      if (json is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return json;
    } on TimeoutException {
      throw ApiException(
        publication
            ? 'Réponse trop longue. Vérifiez le fil avant de republier : le message a peut-être été reçu.'
            : 'Le serveur met trop de temps à répondre. Réessayez.',
      );
    } on http.ClientException {
      throw ApiException(
        publication
            ? 'Connexion interrompue. Vérifiez le fil avant de republier.'
            : 'Connexion impossible. Vérifiez votre accès Internet.',
      );
    } on FormatException {
      throw ApiException(
        publication
            ? 'Réponse illisible. Vérifiez le fil avant de republier.'
            : 'Le serveur a renvoyé une réponse illisible.',
      );
    }
  }

  void close() => _client.close();
}
