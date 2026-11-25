import 'package:flutter/material.dart';
import '../api.dart';
import '../forum_controller.dart';
import '../models.dart';
import '../widgets.dart';

// Même formulaire pour l’inscription, le profil et les comptes de démo.
class ComptePage extends StatefulWidget {
  const ComptePage({
    super.key,
    required this.controller,
    this.compte,
    this.inscription = false,
  });
  final ForumController controller;
  final Utilisateur? compte;
  final bool inscription;
  @override
  State<ComptePage> createState() => _ComptePageState();
}

class _ComptePageState extends State<ComptePage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _envoi = false;
  String? _erreur;
  bool get _inscriptionApi =>
      widget.inscription && !widget.controller.demonstration;
  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  late final TextEditingController _email;
  @override
  void initState() {
    super.initState();
    _prenom = TextEditingController(text: widget.compte?.prenom);
    _nom = TextEditingController(text: widget.compte?.nom);
    _email = TextEditingController(text: widget.compte?.email);
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_envoi || !_form.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      if (_inscriptionApi) {
        await widget.controller.inscrireApi(
          _prenom.text,
          _nom.text,
          _email.text,
          _password.text,
        );
        _password.clear();
        // L'inscription crée le compte. La connexion reste une étape séparée.
        if (mounted) Navigator.pop(context, _email.text.trim());
      } else if (!widget.controller.demonstration) {
        await widget.controller.modifierProfilApi(
          _prenom.text,
          _nom.text,
          _email.text,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        widget.controller.enregistrerCompte(
          _prenom.text,
          _nom.text,
          _email.text,
          compte: widget.compte,
          inscription: widget.inscription,
        );
        if (mounted) Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } on StateError catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_envoi,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          _inscriptionApi
              ? 'Inscription'
              : widget.inscription
              ? 'Inscription démo'
              : widget.compte == null
              ? 'Ajouter un utilisateur'
              : 'Informations du compte',
        ),
      ),
      body: Column(
        children: [
          if (widget.controller.demonstration) const BandeauDemo(),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    _inscriptionApi
                        ? 'Créez votre compte pour participer au forum.'
                        : !widget.controller.demonstration
                        ? 'Modifiez vos informations. Si vous changez d’e-mail, vous devrez vous reconnecter.'
                        : 'Utilisez des informations fictives. Aucun mot de passe n’est demandé dans cette démo.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _prenom,
                    enabled: !_envoi,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Indiquez un prénom.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nom,
                    enabled: !_envoi,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Indiquez un nom.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _email,
                    enabled: !_envoi,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: widget.controller.demonstration
                          ? 'E-mail fictif'
                          : 'E-mail',
                    ),
                    validator: (v) =>
                        v == null ||
                            !RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v.trim())
                        ? 'Indiquez une adresse valide.'
                        : null,
                  ),
                  if (_inscriptionApi) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _password,
                      enabled: !_envoi,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                      ),
                      // Règle imposée par l'API, reprise telle quelle dans le formulaire.
                      validator: (v) =>
                          v == null ||
                              !RegExp(
                                r'^((?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,})$',
                              ).hasMatch(v)
                          ? 'Le mot de passe ne respecte pas les critères ci-dessous.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '12 caractères minimum, avec une majuscule, une minuscule, un chiffre et un caractère spécial.',
                    ),
                  ],
                  if (_erreur != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _erreur!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _envoi ? null : _enregistrer,
                    child: Text(
                      _envoi
                          ? 'Enregistrement…'
                          : _inscriptionApi
                          ? 'Créer mon compte'
                          : widget.inscription
                          ? 'Créer mon compte démo'
                          : 'Enregistrer',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
