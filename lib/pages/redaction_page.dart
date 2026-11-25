import 'package:flutter/material.dart';
import '../api.dart';
import '../forum_controller.dart';
import 'connexion_page.dart';
import '../models.dart';
import '../widgets.dart';

// Un seul écran pour créer/modifier un message ou une réponse.
class RedactionPage extends StatefulWidget {
  const RedactionPage({
    super.key,
    required this.controller,
    this.message,
    this.parent,
  });
  final ForumController controller;
  final Message? message;
  final Message? parent;
  @override
  State<RedactionPage> createState() => _RedactionPageState();
}

class _RedactionPageState extends State<RedactionPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _titre;
  late final TextEditingController _contenu;
  bool _sortieAutorisee = false;
  bool _envoi = false;
  bool get _reponse =>
      widget.parent != null || widget.message?.parentId != null;
  bool get _modifie =>
      _titre.text != (widget.message?.titre ?? '') ||
      _contenu.text != (widget.message?.contenu ?? '');

  @override
  void initState() {
    super.initState();
    _titre = TextEditingController(text: widget.message?.titre);
    _contenu = TextEditingController(text: widget.message?.contenu);
  }

  @override
  void dispose() {
    _titre.dispose();
    _contenu.dispose();
    super.dispose();
  }

  Future<void> _quitter() async {
    if (_envoi) return;
    if (_modifie &&
        !await confirmer(
          context,
          'Abandonner la saisie ?',
          'Le texte non enregistré sera perdu.',
          action: 'Abandonner',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _sortieAutorisee = true);
    // Attendre que PopScope reçoive la nouvelle valeur avant de fermer la route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _enregistrer() async {
    if (_envoi || !_form.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      if (!widget.controller.demonstration) {
        if (!await demanderConnexion(context, widget.controller)) return;
        await widget.controller.publierSurApi(_titre.text, _contenu.text);
      } else if (widget.message != null) {
        widget.controller.modifier(widget.message!, _titre.text, _contenu.text);
      } else {
        widget.controller.publier(
          _reponse ? 'Re: ${widget.parent!.titre}' : _titre.text,
          _contenu.text,
          parent: widget.parent,
        );
      }
      if (!mounted) return;
      setState(() => _sortieAutorisee = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } on ApiException catch (e) {
      if (mounted) informer(context, e.message);
    } on StateError catch (e) {
      if (mounted) informer(context, e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _sortieAutorisee,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _quitter();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.message != null
              ? 'Modifier mon message'
              : _reponse
              ? 'Répondre'
              : 'Nouveau message',
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
                  if (widget.parent != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'En réponse à ${widget.parent!.auteur.nomComplet}\n${widget.parent!.titre}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (!_reponse) ...[
                    TextFormField(
                      controller: _titre,
                      enabled: !_envoi,
                      maxLength: 160,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Titre du message',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ajoutez un titre.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _contenu,
                    enabled: !_envoi,
                    minLines: 7,
                    maxLines: 14,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: _reponse ? 'Votre réponse' : 'Votre message',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Écrivez un message.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _envoi ? null : _enregistrer,
                    child: Text(
                      _envoi
                          ? 'Envoi…'
                          : widget.message != null
                          ? 'Enregistrer'
                          : _reponse
                          ? 'Publier la réponse'
                          : 'Publier le message',
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
