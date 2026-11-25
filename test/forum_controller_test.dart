import 'package:flutter_api/api.dart';
import 'package:flutter_api/forum_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late ForumController c;
  late int reseau;
  setUp(() {
    reseau = 0;
    c = ForumController(
      api: ApiService(
        client: MockClient((r) async {
          reseau++;
          expect(r.method, 'GET');
          return http.Response(
            '{"member":[{"@id":"/forum/api/messages/50","titre":"API","contenu":"Réel"}]}',
            200,
            headers: {'content-type': 'application/ld+json; charset=utf-8'},
          );
        }),
      ),
    );
  });
  tearDown(() => c.dispose());

  test(
    'Les écritures de démo ne touchent ni le réseau ni la liste API',
    () async {
      await c.chargerMessages();
      expect(c.messages.single.titre, 'API');
      expect(() => c.publier('Interdit', 'Texte'), throwsStateError);
      c.choisirMode(true);
      c.connecter(c.utilisateurs.first);
      c.publier('Essai local', 'Bonjour');
      c.choisirMode(false);
      expect(c.messages.single.titre, 'API');
      expect(reseau, 1);
    },
  );

  test('Auteur et admin : droits distincts, réponses incluses', () {
    c.choisirMode(true);
    final maya = c.utilisateurs[1];
    final discussion = c.messages.first;
    c.connecter(c.utilisateurs.first);
    expect(c.peutModifier(discussion), isFalse);
    expect(c.peutSupprimer(discussion), isTrue);
    c.connecter(maya);
    expect(c.peutModifier(discussion), isTrue);
    final autre = c.messages[1];
    expect(() => c.modifier(autre, 'Non', 'Non'), throwsStateError);
    expect(() => c.supprimer(autre), throwsStateError);
    final reponse = c.publier('Re', 'Réponse locale', parent: autre);
    c.modifier(reponse, 'Re', 'Corrigée');
    expect(c.reponses(autre).single.contenu, 'Corrigée');
  });

  test('Suppression parent et suspension respectent les règles locales', () {
    c.choisirMode(true);
    final admin = c.utilisateurs.first;
    final maya = c.utilisateurs[1];
    c.connecter(admin);
    c.suspendre(maya);
    c.connecter(maya);
    expect(c.peutEcrire, isFalse);
    expect(() => c.publier('Non', 'Non'), throwsStateError);
    c.connecter(admin);
    final discussion = c.messages.first;
    c.supprimer(discussion);
    expect(
      c.messages.any(
        (m) => m.id == discussion.id || m.parentId == discussion.id,
      ),
      isFalse,
    );
    expect(() => c.suspendre(admin), throwsStateError);
  });

  test('Inscription membre, modification et suppression anonymisée', () {
    c.choisirMode(true);
    final membre = c.enregistrerCompte(
      'Alex',
      'Test',
      'alex@example.test',
      inscription: true,
    );
    expect(membre.admin, isFalse);
    expect(c.utilisateur, membre);
    expect(
      () => c.enregistrerCompte('Faux', 'Admin', 'a@example.test'),
      throwsStateError,
    );
    final message = c.publier('Mon message', 'Contenu');
    c.connecter(c.utilisateurs.first);
    c.enregistrerCompte(
      'Alexandre',
      'Test',
      'alex@example.test',
      compte: membre,
    );
    expect(message.auteur.prenom, 'Alexandre');
    c.supprimerCompte(membre);
    expect(message.auteur.nomComplet, 'Compte supprimé');
    expect(c.utilisateurs.contains(membre), isFalse);
    expect(reseau, 0);
  });
}
