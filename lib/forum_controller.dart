import 'package:flutter/foundation.dart';
import 'api.dart';
import 'donnees_demo.dart';
import 'models.dart';

// L'état partagé de l'application, avec ChangeNotifier (fourni par Flutter).
// notifyListeners() demande aux ListenableBuilder de mettre l'écran à jour.
class ForumController extends ChangeNotifier {
  ForumController({ApiService? api}) : _api = api ?? ApiService() {
    utilisateurs = creerUtilisateursDemo();
    _messagesDemo = creerMessagesDemo(utilisateurs);
  }

  final ApiService _api;
  List<Message> _messagesApi = [];
  late final List<Message> _messagesDemo;
  late final List<Utilisateur> utilisateurs;
  Utilisateur? _sessionDemo;
  // En mémoire uniquement, pas de stockage sur le téléphone.
  Session? _sessionApi;
  bool demonstration = false;
  bool chargement = false;
  String? erreur;
  bool _ferme = false;
  int _numero = 100;

  Utilisateur? get utilisateur =>
      demonstration ? _sessionDemo : _sessionApi?.utilisateur;
  bool get estAdmin => demonstration && utilisateur?.admin == true;
  bool get peutEcrire => utilisateur != null && !utilisateur!.suspendu;
  List<Message> get messages =>
      List.unmodifiable(demonstration ? _messagesDemo : _messagesApi);

  List<Message> discussions({bool seulementLesMiens = false}) {
    final liste = messages
        .where(
          (m) =>
              m.parentId == null &&
              (!seulementLesMiens || m.auteur.id == utilisateur?.id),
        )
        .toList();
    liste.sort(
      (a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)),
    );
    return liste;
  }

  List<Message> reponses(Message parent) =>
      messages.where((m) => m.parentId == parent.id).toList()..sort(
        (a, b) =>
            (a.date ?? DateTime(1970)).compareTo(b.date ?? DateTime(1970)),
      );

  Future<void> chargerMessages() async {
    if (chargement) return;
    chargement = true;
    erreur = null;
    notifyListeners();
    try {
      _messagesApi = await _api.lireMessages();
    } on ApiException catch (e) {
      erreur = e.message;
    } catch (_) {
      erreur = 'Impossible de lire les messages du forum.';
    } finally {
      chargement = false;
      if (!_ferme) notifyListeners();
    }
  }

  void choisirMode(bool demo) {
    demonstration = demo;
    notifyListeners();
  }

  void connecter(Utilisateur compte) {
    if (!demonstration || !utilisateurs.contains(compte)) {
      throw StateError('Choisissez un compte de démonstration.');
    }
    _sessionDemo = compte;
    notifyListeners();
  }

  Future<void> inscrireApi(
    String prenom,
    String nom,
    String email,
    String password,
  ) => _api.inscrire(prenom, nom, email, password);

  Future<void> connecterApi(String email, String password) async {
    final session = await _api.connecter(email, password);
    if (_ferme) return;
    _sessionApi = session;
    notifyListeners();
  }

  Future<void> modifierProfilApi(
    String prenom,
    String nom,
    String email,
  ) async {
    final session = _sessionApi;
    if (demonstration || session == null) {
      throw StateError('Connectez-vous pour modifier votre profil.');
    }
    try {
      final compte = await _api.modifierProfil(prenom, nom, email, session);
      if (_ferme) return;
      // Un changement d’e-mail nécessite une connexion avec le nouvel identifiant.
      if (compte.email != session.utilisateur.email) {
        _sessionApi = null;
      } else {
        _sessionApi = Session(token: session.token, utilisateur: compte);
      }
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && !_ferme) {
        _sessionApi = null;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> publierSurApi(String titre, String contenu) async {
    final session = _sessionApi;
    if (demonstration || session == null) {
      throw StateError('Connectez-vous pour publier.');
    }
    try {
      final message = await _api.publier(titre, contenu, session);
      if (_ferme) return;
      // Ajout seulement après la confirmation HTTP 201.
      _messagesApi.add(message);
      erreur = null;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && !_ferme) {
        _sessionApi = null;
        notifyListeners();
      }
      rethrow;
    }
  }

  void deconnecter() {
    _sessionApi = null;
    _sessionDemo = null;
    notifyListeners();
  }

  bool peutModifier(Message message) =>
      peutEcrire &&
      _messagesDemo.contains(message) &&
      message.auteur.id == utilisateur!.id;
  bool peutSupprimer(Message message) =>
      peutEcrire &&
      _messagesDemo.contains(message) &&
      (estAdmin || message.auteur.id == utilisateur!.id);

  Message publier(String titre, String contenu, {Message? parent}) {
    _verifierEcriture();
    if (titre.trim().isEmpty || contenu.trim().isEmpty) {
      throw StateError('Complétez le titre et le message.');
    }
    if (parent != null && !_messagesDemo.contains(parent)) {
      throw StateError('Cette discussion n’existe plus.');
    }
    final message = Message(
      id: 'demo-${_numero++}',
      titre: titre.trim(),
      contenu: contenu.trim(),
      auteur: utilisateur!,
      date: DateTime.now(),
      parentId: parent?.id,
    );
    _messagesDemo.add(message);
    notifyListeners();
    return message;
  }

  void modifier(Message message, String titre, String contenu) {
    if (!peutModifier(message)) {
      throw StateError('Vous ne pouvez pas modifier ce message.');
    }
    if (titre.trim().isEmpty || contenu.trim().isEmpty) {
      throw StateError('Complétez les champs.');
    }
    message.titre = titre.trim();
    message.contenu = contenu.trim();
    notifyListeners();
  }

  void supprimer(Message message) {
    if (!peutSupprimer(message)) throw StateError('Suppression non autorisée.');
    // Choix local explicite : supprimer aussi les réponses du message supprimé.
    final ids = <String>{message.id};
    bool ajout;
    do {
      ajout = false;
      for (final m in _messagesDemo) {
        if (ids.contains(m.parentId) && ids.add(m.id)) ajout = true;
      }
    } while (ajout);
    _messagesDemo.removeWhere((m) => ids.contains(m.id));
    notifyListeners();
  }

  Utilisateur enregistrerCompte(
    String prenom,
    String nom,
    String email, {
    Utilisateur? compte,
    bool inscription = false,
  }) {
    if (!demonstration) {
      throw StateError('Cette action appartient à la démo locale.');
    }
    if (inscription && compte != null) {
      throw StateError('Inscription invalide.');
    }
    if (!inscription) {
      _verifierEcriture();
      if (!estAdmin && compte != utilisateur) {
        throw StateError('Action non autorisée.');
      }
    }
    final adresse = email.trim().toLowerCase();
    if (prenom.trim().isEmpty || nom.trim().isEmpty || !adresse.contains('@')) {
      throw StateError('Complétez les informations du compte.');
    }
    if (utilisateurs.any(
      (u) => u != compte && u.email.toLowerCase() == adresse,
    )) {
      throw StateError('Cette adresse est déjà utilisée dans la démo.');
    }
    final resultat =
        compte ??
        Utilisateur(id: 'demo-user-${_numero++}', prenom: '', nom: '');
    resultat.prenom = prenom.trim();
    resultat.nom = nom.trim();
    resultat.email = adresse;
    if (compte == null) utilisateurs.add(resultat);
    if (inscription) _sessionDemo = resultat;
    notifyListeners();
    return resultat;
  }

  void suspendre(Utilisateur compte) {
    _verifierAdministration(compte);
    compte.suspendu = !compte.suspendu;
    notifyListeners();
  }

  void supprimerCompte(Utilisateur compte) {
    _verifierAdministration(compte);
    utilisateurs.remove(compte);
    // Les textes restent lisibles mais le compte supprimé est anonymisé.
    compte.prenom = 'Compte';
    compte.nom = 'supprimé';
    compte.email = '';
    notifyListeners();
  }

  void _verifierEcriture() {
    if (!demonstration || !peutEcrire) {
      throw StateError('Connectez-vous avec un compte de démo actif.');
    }
  }

  void _verifierAdministration(Utilisateur compte) {
    _verifierEcriture();
    if (!estAdmin || compte == utilisateur || !utilisateurs.contains(compte)) {
      throw StateError('Cette action n’est pas autorisée sur ce compte.');
    }
  }

  @override
  void dispose() {
    _ferme = true;
    _api.close();
    super.dispose();
  }
}
