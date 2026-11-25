import 'package:flutter/material.dart';
import '../api.dart';
import '../forum_controller.dart';
import '../widgets.dart';
import 'compte_page.dart';

class ConnexionPage extends StatelessWidget {
  const ConnexionPage({super.key, required this.controller});
  final ForumController controller;
  @override
  Widget build(BuildContext context) => controller.demonstration
      ? _demo(context)
      : _ConnexionApi(controller: controller);

  Widget _demo(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connexion de démonstration')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const BandeauDemo(),
        const SizedBox(height: 24),
        Text(
          'Choisir un compte',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Ces comptes sont fictifs et sans mot de passe. Vous pouvez tester les droits d’un membre ou d’un administrateur.',
        ),
        const SizedBox(height: 24),
        for (final compte in controller.utilisateurs) ...[
          Card(
            child: ListTile(
              leading: Avatar(compte),
              title: Text(compte.nomComplet),
              subtitle: Text(
                compte.suspendu
                    ? 'Suspendu · lecture uniquement'
                    : compte.admin
                    ? 'Administrateur'
                    : 'Membre',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                controller.connecter(compte);
                Navigator.pop(context, true);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () async {
            final resultat = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ComptePage(controller: controller, inscription: true),
              ),
            );
            if (context.mounted && resultat == true) {
              Navigator.pop(context, true);
            }
          },
          child: const Text('Créer un compte de démo'),
        ),
      ],
    ),
  );
}

// Réutilisé avant de publier ou de répondre : le parcours reprend ensuite.
Future<bool> demanderConnexion(
  BuildContext context,
  ForumController controller,
) async {
  if (controller.utilisateur == null) {
    if (!context.mounted) return false;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ConnexionPage(controller: controller)),
    );
  }
  if (!controller.peutEcrire) {
    if (context.mounted && controller.utilisateur?.suspendu == true) {
      informer(
        context,
        'Ce compte est suspendu. Il peut seulement lire les messages.',
      );
    }
    return false;
  }
  return true;
}

// Le formulaire réel réutilise le même contrôleur et la même navigation.
class _ConnexionApi extends StatefulWidget {
  const _ConnexionApi({required this.controller});
  final ForumController controller;
  @override
  State<_ConnexionApi> createState() => _ConnexionApiState();
}

class _ConnexionApiState extends State<_ConnexionApi> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ComptePage(controller: widget.controller, inscription: true),
      ),
    );
    if (!mounted || email == null) return;
    _email.text = email;
    _password.clear();
    setState(() => _erreur = null);
    informer(context, 'Compte créé. Vous pouvez maintenant vous connecter.');
  }

  Future<void> _connecter() async {
    if (_chargement || !_form.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await widget.controller.connecterApi(_email.text, _password.text);
      _password.clear();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_chargement,
    child: Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Retrouver le forum',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Connectez-vous avec votre compte existant pour publier un message.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              enabled: !_chargement,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (v) => v == null || !v.trim().contains('@')
                  ? 'Saisissez votre e-mail.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !_chargement,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _connecter(),
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              validator: (v) => v == null || v.isEmpty
                  ? 'Saisissez votre mot de passe.'
                  : null,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 16),
              Text(
                _erreur!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _chargement ? null : _connecter,
              child: Text(_chargement ? 'Connexion…' : 'Se connecter'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _chargement ? null : _inscrire,
              child: const Text('Créer un compte'),
            ),
          ],
        ),
      ),
    ),
  );
}
