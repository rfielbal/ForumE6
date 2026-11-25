import 'package:flutter/material.dart';
import 'package:flutter_api/api.dart';
import 'package:flutter_api/forum_controller.dart';
import 'package:flutter_api/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late ForumController c;
  setUp(() {
    c = ForumController(
      api: ApiService(
        client: MockClient((r) async {
          expect(r.method, 'GET');
          return http.Response(
            '{"member":[{"@id":"/forum/api/messages/1","titre":"Message réel",'
            '"contenu":"Lecture publique","user":{"prenom":"Auteur","nom":"Test"}}]}',
            200,
            headers: {'content-type': 'application/ld+json; charset=utf-8'},
          );
        }),
      ),
    );
  });
  tearDown(() => c.dispose());

  testWidgets('Lecture réelle, puis publication locale par le formulaire', (
    t,
  ) async {
    t.view.physicalSize = const Size(402, 874);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(ForumApp(controller: c));
    await t.pumpAndSettle();
    expect(find.text('Message réel'), findsOneWidget);
    await t.tap(find.text('Démo locale'));
    await t.pumpAndSettle();
    await t.tap(find.text('Se connecter'));
    await t.pumpAndSettle();
    await t.tap(find.text('Camille Martin'));
    await t.pumpAndSettle();
    expect(find.text('Gestion'), findsOneWidget);
    await t.tap(find.widgetWithText(FloatingActionButton, 'Message'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).first, 'Premier essai');
    await t.enterText(
      find.byType(TextFormField).last,
      'Un message de démonstration.',
    );
    await t.ensureVisible(find.text('Publier le message'));
    await t.tap(find.text('Publier le message'));
    await t.pumpAndSettle();
    expect(c.discussions().first.titre, 'Premier essai');
    expect(find.text('Premier essai'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Le membre reprend une réponse après la connexion', (t) async {
    await t.pumpWidget(ForumApp(controller: c));
    await t.pumpAndSettle();
    await t.tap(find.text('Démo locale'));
    await t.pumpAndSettle();
    await t.tap(find.text('Par où commencer un projet Flutter ?'));
    await t.pumpAndSettle();
    await t.tap(find.text('Se connecter pour répondre'));
    await t.pumpAndSettle();
    await t.tap(find.text('Maya Laurent'));
    await t.pumpAndSettle();
    expect(find.text('Votre réponse'), findsOneWidget);
    await t.enterText(find.byType(TextFormField), 'Merci pour les conseils.');
    await t.ensureVisible(find.text('Publier la réponse'));
    await t.tap(find.text('Publier la réponse'));
    await t.pumpAndSettle();
    expect(
      c.reponses(c.messages.first).last.contenu,
      'Merci pour les conseils.',
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('Petit écran et texte agrandi sans débordement du fil', (
    t,
  ) async {
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    t.view.physicalSize = const Size(320, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    c.choisirMode(true);
    c.connecter(c.utilisateurs.first);
    await t.pumpWidget(ForumApp(controller: c));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.tap(find.text('Profil'));
    await t.pumpAndSettle();
    expect(find.text('Mes informations'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
