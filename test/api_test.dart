import 'dart:convert';
import 'package:flutter_api/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('GET uniquement, pagination et lien de réponse', () async {
    final appels = <Uri>[];
    final api = ApiService(
      client: MockClient((r) async {
        expect(r.method, 'GET');
        appels.add(r.url);
        final suite = r.url.queryParameters['page'] == '2';
        return http.Response(
          jsonEncode({
            'member': [
              {
                '@id': '/forum/api/messages/${suite ? 2 : 1}',
                'titre': suite ? 'Réponse' : 'Discussion',
                'contenu': 'Bonjour',
                'user': {
                  '@id': '/forum/api/users/1',
                  'prenom': 'Maya',
                  'nom': 'Laurent',
                },
                if (suite) 'parent': {'@id': '/forum/api/messages/1'},
              },
            ],
            if (!suite) 'view': {'next': '/forum/api/messages?page=2'},
          }),
          200,
          headers: {'content-type': 'application/ld+json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    final messages = await api.lireMessages();
    expect(appels, hasLength(2));
    expect(messages, hasLength(2));
    expect(messages.last.parentId, messages.first.id);
    expect(messages.first.auteur.nomComplet, 'Maya Laurent');
  });

  test('Une collection vide est valide', () async {
    final api = ApiService(
      client: MockClient((_) async => http.Response('{"member":[]}', 200)),
    );
    addTearDown(api.close);
    expect(await api.lireMessages(), isEmpty);
  });

  test('Une erreur serveur et une réponse illisible sont expliquées', () async {
    for (final response in [
      http.Response('indisponible', 503),
      http.Response('<html>', 200),
    ]) {
      final api = ApiService(client: MockClient((_) async => response));
      addTearDown(api.close);
      await expectLater(api.lireMessages(), throwsA(isA<ApiException>()));
    }
  });

  test('Refuse une pagination cyclique ou vers un autre serveur', () async {
    for (final suite in [
      '/forum/api/messages',
      'https://example.org/messages',
    ]) {
      var appels = 0;
      final api = ApiService(
        client: MockClient((_) async {
          appels++;
          return http.Response(
            jsonEncode({
              'member': [],
              'view': {'next': suite},
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      await expectLater(api.lireMessages(), throwsA(isA<ApiException>()));
      expect(appels, 1);
    }
  });
}
