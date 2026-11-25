import 'package:flutter/material.dart';
import '../forum_controller.dart';
import '../theme.dart';
import '../widgets.dart';
import 'connexion_page.dart';
import 'discussion_page.dart';
import 'profil_page.dart';
import 'redaction_page.dart';
import 'utilisateurs_page.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key, required this.controller});
  final ForumController controller;
  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  int _onglet = 0; // 0 = Forum, 1 = Profil, 2 = Gestion (indépendant du rôle).
  bool _mesMessages = false;

  Future<void> _nouveauMessage() async {
    if (!await demanderConnexion(context, widget.controller) || !mounted) {
      return;
    }
    final publie = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RedactionPage(controller: widget.controller),
      ),
    );
    if (mounted && publie == true) {
      informer(
        context,
        widget.controller.demonstration
            ? 'Message publié dans la démo locale.'
            : 'Message publié sur le forum.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final onglet = _onglet == 2 && !c.estAdmin ? 0 : _onglet;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            onglet == 0
                ? 'Forum'
                : onglet == 1
                ? 'Mon profil'
                : 'Gestion',
          ),
          centerTitle: false,
          actions: [
            if (onglet == 0)
              IconButton(
                tooltip: 'Actualiser les vrais messages',
                onPressed: c.chargement ? null : c.chargerMessages,
                icon: const Icon(Icons.refresh),
              ),
          ],
          bottom: onglet != 0
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(90),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            for (final demo in [false, true])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: c.demonstration == demo
                                          ? Colors.white
                                          : const Color(0xFF3C3D40),
                                      foregroundColor: c.demonstration == demo
                                          ? graphite
                                          : Colors.white,
                                      minimumSize: const Size(0, 42),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() => _mesMessages = false);
                                      c.choisirMode(demo);
                                    },
                                    child: Text(
                                      demo ? 'Démo locale' : 'Messages API',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.demonstration
                              ? 'Données fictives · actions locales'
                              : 'Messages du forum · API',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        body: onglet == 0
            ? _fil()
            : onglet == 2
            ? UtilisateursPage(controller: c)
            : ProfilPage(
                controller: c,
                ouvrirMesMessages: () => setState(() {
                  _onglet = 0;
                  _mesMessages = true;
                }),
              ),
        floatingActionButton: onglet == 0
            ? FloatingActionButton.extended(
                onPressed: _nouveauMessage,
                icon: const Icon(Icons.add),
                label: const Text('Message'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: onglet == 2
              ? 1
              : onglet == 1
              ? (c.estAdmin ? 2 : 1)
              : 0,
          onDestinationSelected: (index) => setState(() {
            _onglet = index == 0
                ? 0
                : c.estAdmin && index == 1
                ? 2
                : 1;
          }),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              label: 'Forum',
            ),
            if (c.estAdmin)
              const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                label: 'Gestion',
              ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
        ),
      );
    },
  );

  Widget _fil() {
    final c = widget.controller;
    if (!c.demonstration && c.chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!c.demonstration && c.erreur != null) {
      return EtatVide(
        'Connexion indisponible',
        c.erreur!,
        action: c.chargerMessages,
      );
    }
    final messages = c.discussions(
      seulementLesMiens: _mesMessages && c.utilisateur != null,
    );
    return Column(
      children: [
        if (c.utilisateur == null)
          Material(
            color: Colors.white,
            child: ListTile(
              title: const Text(
                'Vous êtes visiteur',
                style: TextStyle(fontSize: 14),
              ),
              trailing: TextButton(
                onPressed: () => demanderConnexion(context, c),
                child: const Text('Se connecter'),
              ),
            ),
          ),
        if (c.utilisateur != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Tous les messages'),
                  selected: !_mesMessages,
                  onSelected: (_) => setState(() => _mesMessages = false),
                ),
                ChoiceChip(
                  label: const Text('Mes messages'),
                  selected: _mesMessages,
                  onSelected: (_) => setState(() => _mesMessages = true),
                ),
              ],
            ),
          ),
        if (c.utilisateur?.suspendu == true)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Compte suspendu : vous pouvez lire, mais pas participer.',
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (!c.demonstration) await c.chargerMessages();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    '${messages.length} discussion(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (messages.isEmpty)
                  const EtatVide(
                    'Aucun message',
                    'Les nouvelles discussions apparaîtront ici.',
                  ),
                for (final message in messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: CarteMessage(
                      message: message,
                      nombreReponses: c.reponses(message).length,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiscussionPage(
                            controller: c,
                            messageId: message.id,
                          ),
                        ),
                      ),
                      onModifier: c.peutModifier(message)
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RedactionPage(
                                  controller: c,
                                  message: message,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
