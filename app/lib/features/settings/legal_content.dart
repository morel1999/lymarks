import 'package:lymarks/features/settings/legal_screen.dart';

/// Les deux textes, écrits d'après `04-securite/03-privacy-spec.md`.
///
/// Ils décrivent ce que le code fait réellement — pas un gabarit générique.
/// Toute évolution du pipeline (un fournisseur qui change, une donnée qu'on
/// se met à garder) doit passer ici avant d'être livrée.
///
/// Les points un peu longs sont nommés plutôt qu'écrits dans la liste : deux
/// littéraux côte à côte dans une liste se lisent comme une virgule oubliée,
/// et l'analyseur le refuse à juste titre.
abstract final class LegalTexts {
  static const String _updated = 'Updated 22 September 2026';

  static const String _pageDropped =
      'The text of the page itself is read to write the summary, then '
      'dropped. We keep the summary, not the article.';

  static const String _noteIsYours =
      'Your note is yours alone. It is stored with the lymark and shown '
      'only to you.';

  static const String _embeddingSees =
      'The embedding model receives the title and the bullets, and your '
      'search wording on the Pro semantic search.';

  static const String _identityHeld =
      'Your identity is held by our sign-in provider, and your purchases '
      'by the store that billed you.';

  static const String _logsKept =
      'Server logs: seven days, and they never contain the body of a '
      'request.';

  static const String _digestKept =
      'Digest events — what was resurfaced and when: ninety days, to keep '
      'the algorithm honest.';

  static const String _exportGives =
      'Export gives you a JSON file with your links, notes, summaries, '
      'keywords and dates. It is available on every plan, Free included.';

  static const String _deletionRemoves =
      'Deleting your account removes your lymarks, their vectors, your '
      'digest history, your sign-in record and your subscriber record. '
      'Access stops at once.';

  static const String _deleteOne =
      'Deleting a single lymark also deletes its vector and its digest '
      'events.';

  static const String _cancelInStore =
      'Changing or cancelling a subscription happens in that store, and '
      'takes effect at the end of the period you already paid for.';

  static LegalPage get privacy => LegalPage(
    title: 'Privacy',
    updated: _updated,
    accent: (ly) => ly.blue,
    essence:
        'We keep what you save so you can find it again. '
        'We never sell it, and we never build an advertising profile.',
    sections: const [
      LegalSection(
        heading: 'What we store',
        body:
            'Your account identity, and the lymarks you save: the link, its '
            'title, the three-bullet summary, the keywords, your own note, '
            'and a vector used for search.',
        points: [_pageDropped, _noteIsYours],
      ),
      LegalSection(
        heading: 'What leaves Lymarks',
        body:
            'Summarising and searching need outside models. Only what the '
            'task requires is sent, and nothing is sold to anyone.',
        points: [
          'The summariser receives the page text — never your note.',
          _embeddingSees,
          _identityHeld,
        ],
      ),
      LegalSection(
        heading: 'What stays on your phone',
        body:
            'The queue of links saved while offline, your interface '
            'preferences, and the display cache. Everything else lives on '
            'the server, which is what lets your memory follow you between '
            'devices.',
      ),
      LegalSection(
        heading: 'How long we keep it',
        body:
            'Your account and your lymarks stay as long as the account does. '
            'Two exceptions, both short.',
        points: [_logsKept, _digestKept],
      ),
      LegalSection(
        heading: 'Leaving, and taking your memory with you',
        body: 'Both are in the app, and neither requires writing to us.',
        points: [_exportGives, _deletionRemoves, _deleteOne],
      ),
      LegalSection(
        heading: 'Your rights',
        body:
            'We process your data to provide the service you signed up for, '
            'under the GDPR in the European Union and the KVKK in Türkiye. '
            'The Daily Digest reads your interests to choose what comes '
            'back, so it can be switched off at any time without losing '
            'anything you saved.',
      ),
    ],
    footer:
        'Questions about any of this reach a person, not a queue: '
        'privacy@lymarks.app.',
  );

  static LegalPage get terms => LegalPage(
    title: 'Terms',
    updated: _updated,
    accent: (ly) => ly.steel,
    essence:
        'Lymarks turns the links you save into a memory you can search. '
        'What you save stays yours.',
    sections: const [
      LegalSection(
        heading: 'What the service does',
        body:
            'You send a link, Lymarks reads the page, writes a short summary '
            'and files it so you can find it later by describing what you '
            'remember. Summaries are written by language models: they are a '
            'useful shortcut, not a guarantee of accuracy, and the original '
            'page remains the source of truth.',
      ),
      LegalSection(
        heading: 'Your account',
        body:
            'One account belongs to one person. Keep your sign-in to '
            'yourself — anyone who reaches it reaches everything you saved.',
      ),
      LegalSection(
        heading: 'What you save',
        body:
            'Your links and notes remain yours. You grant us only what is '
            'needed to run the service: storing them, summarising them, and '
            'indexing them so search works. Save links you are allowed to '
            'read, and do not use Lymarks to gather material you have no '
            'right to.',
      ),
      LegalSection(
        heading: 'Free and Pro',
        body:
            'Free covers a capped library and keyword search. Pro adds '
            'semantic search, the Daily Digest and an unlimited library.',
        points: [
          'Subscriptions are sold and billed by the app store, not by us.',
          _cancelInStore,
        ],
      ),
      LegalSection(
        heading: 'Availability',
        body:
            'Lymarks is young and runs on services we do not own. We work to '
            'keep it up and your data intact, but we cannot promise it will '
            'never be interrupted. Your export is always one tap away, and '
            'that is the promise we can keep.',
      ),
      LegalSection(
        heading: 'Ending it',
        body:
            'Delete your account whenever you like, from Settings. Export '
            'first if you want to keep a copy — deletion is final. We may '
            'close an account that abuses the service or the people running '
            'it, and we will say why.',
      ),
    ],
    footer:
        'These terms describe how Lymarks actually behaves today. '
        'They will be revised as the product grows, and the date above '
        'tells you which version you are reading.',
  );
}
