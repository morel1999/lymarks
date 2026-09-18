import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Table d'icônes Lymarks — **Lucide uniquement**.
///
/// Design System §Iconographie : Lucide, 20/24, trait 1,75. Aucun emoji dans
/// l'UI système (les maquettes en montrent quelques-uns dans les avatars de
/// source : ils sont remplacés ici par des icônes de la bibliothèque).
///
/// Le paquet retenu est `lucide_icons_flutter` (159k téléchargements/30 j,
/// 160/160 pts pub) et non `lucide_flutter` cité dans
/// `07-dev/01-coding-standards.md` : ce dernier est quasi inutilisé.
abstract final class LyIcons {
  // Navigation principale.
  static const IconData home = LucideIcons.house;
  static const IconData offline = LucideIcons.cloudOff;
  static const IconData search = LucideIcons.search;
  static const IconData digest = LucideIcons.sparkles;

  // Chrome et actions.
  static const IconData settings = LucideIcons.settings;
  static const IconData back = LucideIcons.chevronLeft;
  static const IconData forward = LucideIcons.chevronRight;
  static const IconData more = LucideIcons.ellipsis;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData plus = LucideIcons.plus;
  static const IconData enter = LucideIcons.arrowUpRight;
  static const IconData next = LucideIcons.arrowRight;
  static const IconData openExternal = LucideIcons.squareArrowOutUpRight;
  static const IconData copy = LucideIcons.copy;
  static const IconData share = LucideIcons.share2;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData retry = LucideIcons.rotateCw;
  static const IconData bookmark = LucideIcons.bookmark;
  static const IconData sparkle = LucideIcons.sparkles;
  static const IconData clock = LucideIcons.clock;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData link = LucideIcons.link;
  static const IconData warning = LucideIcons.circleAlert;
  static const IconData note = LucideIcons.fileText;

  // Réglages.
  static const IconData appearance = LucideIcons.palette;
  static const IconData language = LucideIcons.languages;
  static const IconData notifications = LucideIcons.bell;
  static const IconData security = LucideIcons.lock;
  static const IconData billing = LucideIcons.creditCard;
  static const IconData exportData = LucideIcons.download;
  static const IconData sync = LucideIcons.refreshCw;
  static const IconData about = LucideIcons.info;
  static const IconData help = LucideIcons.circleHelp;
  static const IconData privacy = LucideIcons.shieldCheck;
  static const IconData logout = LucideIcons.logOut;
  static const IconData tag = LucideIcons.tag;
  static const IconData collection = LucideIcons.folder;
  static const IconData moon = LucideIcons.moon;
  static const IconData sun = LucideIcons.sun;
  static const IconData system = LucideIcons.smartphone;

  // Sujets — catégories et clusters.
  static const Map<String, IconData> _topics = {
    'ai': LucideIcons.sparkles,
    'agents': LucideIcons.bot,
    'rag': LucideIcons.waypoints,
    'vector': LucideIcons.database,
    'embeddings': LucideIcons.brain,
    'prompt': LucideIcons.squareTerminal,
    'design': LucideIcons.penTool,
    'development': LucideIcons.codeXml,
    'business': LucideIcons.briefcase,
    'product': LucideIcons.package,
    'science': LucideIcons.flaskConical,
    'culture': LucideIcons.clapperboard,
    'sport': LucideIcons.trophy,
    'lifestyle': LucideIcons.leaf,
    'other': LucideIcons.bookmark,
    'web': LucideIcons.globe,
    'video': LucideIcons.play,
    'article': LucideIcons.newspaper,
    'people': LucideIcons.users,
  };

  /// Icône d'un sujet, avec repli neutre.
  static IconData topic(String key) =>
      _topics[key.toLowerCase()] ?? LucideIcons.bookmark;

  // Sources — un lymark affiche l'icône de sa plateforme, jamais un favicon
  // distant (aucune requête vers un tiers depuis la liste).
  //
  // Lucide a retiré ses icônes de marque (contraintes de licence) : les
  // plateformes sont donc représentées par une icône sémantique, pas par un
  // logo. Voir la note « Icônes de marque » du journal de démarrage.
  static const Map<String, IconData> _domains = {
    'youtube.com': LucideIcons.squarePlay,
    'x.com': LucideIcons.messageCircle,
    'twitter.com': LucideIcons.messageCircle,
    'linkedin.com': LucideIcons.briefcase,
    'github.com': LucideIcons.gitBranch,
    'medium.com': LucideIcons.bookOpen,
    'dev.to': LucideIcons.code,
    'react.dev': LucideIcons.atom,
    'vercel.com': LucideIcons.triangle,
    'huggingface.co': LucideIcons.bot,
    'modelcontextprotocol.io': LucideIcons.waypoints,
    'blog.langchain.dev': LucideIcons.brain,
    'frontendmasters.com': LucideIcons.graduationCap,
  };

  /// Icône déduite du domaine (le sous-domaine est ignoré si besoin).
  static IconData forDomain(String domain) {
    final d = domain.toLowerCase();
    final direct = _domains[d];
    if (direct != null) return direct;
    for (final entry in _domains.entries) {
      if (d.endsWith(entry.key)) return entry.value;
    }
    return LucideIcons.globe;
  }
}
