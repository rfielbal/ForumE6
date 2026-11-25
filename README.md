# Forum — Flutter

Les points **1 à 4, 7 et 8** du cahier des charges sont reliés à l’API :

1. Lire les messages : `GET /forum/api/messages`, avec pagination.
2. Se connecter : `POST /forum/api/authentication_token` avec l’e-mail et le mot de passe.
3. Se déconnecter : supprimer la session et le token en mémoire.
4. Publier : `POST /forum/api/messages` avec `Authorization: Bearer <token>`.

**Point 7 — Modifier son profil** : `PATCH /forum/api/users/{id}` avec uniquement les champs modifiés (prénom, nom, e-mail).

**Point 8 — S’inscrire** : `POST /forum/api/users` avec prénom, nom, e-mail et mot de passe.

## Utiliser l’application

Dans **Messages API**, appuyer sur **Se connecter**, saisir un compte existant,
puis utiliser **+ Message**. Le message est envoyé au vrai serveur et apparaît
après sa confirmation. Pour vérifier sa persistance, actualiser le fil.
La déconnexion se trouve dans **Profil**.

Pour modifier son profil : **Profil → Mes informations → Enregistrer**. Les
informations affichées sont mises à jour après confirmation du serveur. Si
l’e-mail change, l’app déconnecte le compte : se reconnecter avec la nouvelle
adresse et le même mot de passe. Les champs restent saisis en cas d’erreur.

Pour s’inscrire : **Se connecter → Créer un compte**. Après confirmation du
serveur, retour à la connexion avec l’e-mail prérempli. Le mot de passe doit
respecter la règle de l’API : 12 caractères minimum, une majuscule, une minuscule,
un chiffre et un caractère spécial. L’inscription ne connecte pas automatiquement.
Le formulaire affiche les erreurs de validation renvoyées par le serveur.

Le token reste uniquement en mémoire. Il faut se reconnecter après fermeture
complète de l’app. Le mot de passe n’est pas enregistré. L’API ne documente pas
une route de déconnexion : l’app oublie le token, sans le révoquer côté serveur.
Si le serveur refuse un token (401), l’app demande une nouvelle connexion.

**Démo locale** conserve les anciens essais : réponses, modification/suppression,
administration (ainsi que des comptes fictifs). Ces fonctions ne sont pas
encore reliées au serveur. Les données de démo disparaissent au redémarrage.

## Lire et modifier le code

| Fichier | Rôle |
| --- | --- |
| `lib/api.dart` | Les requêtes HTTP et leurs erreurs |
| `lib/models.dart` | Message, Utilisateur et Session (token + utilisateur) |
| `lib/forum_controller.dart` | Les données partagées et les actions |
| `lib/pages/connexion_page.dart` | Formulaire e-mail/mot de passe et ancien choix de compte démo |
| `lib/pages/compte_page.dart` | Formulaire partagé : inscription, profil réel et comptes de démo |
| `lib/pages/redaction_page.dart` | Formulaire partagé, envoi réel ou local selon le mode |
| `lib/pages/accueil_page.dart` | Fil des messages et bouton + |
| `lib/pages/profil_page.dart` | Compte connecté et déconnexion |
| `lib/theme.dart` | Couleurs et styles |
| `lib/widgets.dart` | Composants visuels réutilisés |

Exemple : **publier un message**.

1. `RedactionPage` lit les deux champs et appelle `publierSurApi`.
2. Le contrôleur transmet le titre, le contenu et la session à `ApiService.publier`.
3. L’API reçoit le texte, la date et l’adresse du compte auteur, avec le token dans l’en-tête.
4. Après HTTP 201, le contrôleur ajoute le message renvoyé et appelle `notifyListeners()`.
5. L’accueil se met à jour grâce à `ListenableBuilder`.

L’API actuelle renvoie uniquement un token à la connexion. Elle n’a ni route `/me`
ni filtre e-mail documenté. `ApiService.connecter` lit donc la liste des comptes,
puis leurs détails jusqu’à retrouver l’e-mail connecté. Cela peut rendre la
connexion plus lente si le nombre d’utilisateurs augmente. Une route `/me`
côté API simplifierait cela, mais aucune modification du serveur n’est incluse.

Le code conserve `setState`, `ChangeNotifier` et la dépendance `http` déjà présente.
Aucune nouvelle dépendance, aucun stockage persistant ni architecture supplémentaire.

## Lancer

Ouvrir ce dossier dans l’éditeur, sélectionner un simulateur iPhone et lancer
`lib/main.dart`, ou utiliser le terminal :

```sh
cd /Users/raphael/Flutter/BTS2/forum_flutter
flutter pub get
flutter devices
flutter run
```

Si `flutter` n’est pas reconnu, utiliser
`/Users/raphael/dart-sdk/flutter/flutter/bin/flutter` à sa place.
Le terminal propose `r` pour recharger les changements et `R` pour redémarrer.

L’ancien état du code est conservé dans E6 :
`Forum - Maquette/Archives/Avant connexion API`.

Contrat consulté : https://4719.s3.nuage-peda.fr/forum/api
