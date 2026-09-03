import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Jeu de données de démonstration.
///
/// Il reprend fidèlement le contenu des maquettes (`Ecran/`) pour que les
/// écrans soient comparables au design de référence. Il sera remplacé par
/// l'API Hono à l'étape 3 de la roadmap ; aucun écran ne doit dépendre de
/// cette classe autrement que par les providers.
abstract final class MockData {
  static DateTime _ago(Duration d) => DateTime.now().subtract(d);

  static final List<Lymark> lymarks = [
    Lymark(
      id: 'lm-agents',
      url: 'https://huggingface.co/learn/agents-course',
      domain: 'huggingface.co',
      title: 'Building AI Agents',
      savedAt: _ago(const Duration(days: 2)),
      categoryId: 'ai',
      accentSlot: 0,
      clusterId: 'ai-agents',
      bullets: const [
        'AI agents combine reasoning, tools and memory to act autonomously.',
        'Tool calling allows agents to interact with external systems.',
        'Good agent design relies on clear boundaries and feedback loops.',
      ],
      keywords: const ['AI', 'Agents', 'Tools', 'Framework', 'LLM'],
      note: "This could be useful for the agent system I'm building.",
    ),
    Lymark(
      id: 'lm-next',
      url: 'https://vercel.com/blog/nextjs-15-performance',
      domain: 'vercel.com',
      title: 'Next.js 15 Performance Guide',
      savedAt: _ago(const Duration(days: 3)),
      categoryId: 'development',
      accentSlot: 2,
      clusterId: 'dev-performance',
      bullets: const [
        'Partial prerendering improves performance with dynamic content.',
        'Optimize images, fonts and scripts for Core Web Vitals.',
        'Use caching and streaming to deliver content faster.',
      ],
      keywords: const ['Next.js', 'Performance', 'Web', 'Rendering'],
    ),
    Lymark(
      id: 'lm-ds',
      url: 'https://medium.com/design-systems-that-scale',
      domain: 'medium.com',
      title: 'Design Systems that Scale',
      savedAt: _ago(const Duration(days: 5)),
      categoryId: 'design',
      accentSlot: 1,
      clusterId: 'design-systems',
      bullets: const [
        'Tokens keep visual decisions in one place instead of in components.',
        'Document intent, not just usage, so the system survives its authors.',
        'Adoption matters more than completeness.',
      ],
      keywords: const ['Design', 'Systems', 'Tokens'],
      note: 'Reference for the Lymarks design system.',
    ),
    Lymark(
      id: 'lm-rsc',
      url: 'https://react.dev/reference/rsc/server-components',
      domain: 'react.dev',
      title: 'React Server Components',
      savedAt: _ago(const Duration(days: 7)),
      categoryId: 'development',
      accentSlot: 2,
      clusterId: 'dev-react',
      bullets: const [
        'Server Components render on the server and reduce client JS.',
        'They can access backend resources directly.',
        'Use them to build faster, more secure React apps.',
      ],
      keywords: const ['React', 'Architecture', 'Server Components'],
    ),
    Lymark(
      id: 'lm-scalable',
      url: 'https://dev.to/designing-scalable-react-apps',
      domain: 'dev.to',
      title: 'Designing Scalable React Apps',
      savedAt: _ago(const Duration(days: 14)),
      categoryId: 'development',
      accentSlot: 2,
      clusterId: 'dev-react',
      bullets: const [
        'Component architecture affects scalability and maintainability.',
        'Feature-based folder structure works well for large apps.',
        'Keep components small, focused and composable.',
      ],
      keywords: const ['React', 'Architecture', 'Best Practices'],
    ),
    Lymark(
      id: 'lm-deep-react',
      url: 'https://medium.com/a-deep-dive-into-react-architecture',
      domain: 'medium.com',
      title: 'A Deep Dive into React Architecture',
      savedAt: _ago(const Duration(days: 21)),
      categoryId: 'development',
      accentSlot: 2,
      clusterId: 'dev-react',
      bullets: const [
        'Understand the trade-offs between different patterns.',
        'Choose the right approach for your team and product.',
        'Modularity and boundaries are key.',
      ],
      keywords: const ['React', 'Architecture', 'Patterns'],
    ),
    Lymark(
      id: 'lm-composition',
      url: 'https://frontendmasters.com/component-composition-in-react',
      domain: 'frontendmasters.com',
      title: 'Component Composition in React',
      savedAt: _ago(const Duration(days: 32)),
      categoryId: 'development',
      accentSlot: 2,
      clusterId: 'dev-react',
      bullets: const [
        'Compose components to build flexible UIs.',
        'Control data flow with props and composition.',
        'Avoid prop drilling with context and custom hooks.',
      ],
      keywords: const ['React', 'Composition', 'Patterns'],
    ),
    Lymark(
      id: 'lm-mcp',
      url: 'https://modelcontextprotocol.io/introduction',
      domain: 'modelcontextprotocol.io',
      title: 'MCP for AI Agents',
      savedAt: _ago(const Duration(days: 9)),
      categoryId: 'ai',
      accentSlot: 0,
      clusterId: 'ai-agents',
      bullets: const [
        'MCP gives agents a single protocol to reach tools and data.',
        'Servers expose resources; clients decide what the model may use.',
        'The boundary is explicit, which makes permissions auditable.',
      ],
      keywords: const ['AI', 'Agents', 'Protocol', 'Tools'],
    ),
    Lymark(
      id: 'lm-memory',
      url: 'https://blog.langchain.dev/agent-memory-patterns',
      domain: 'blog.langchain.dev',
      title: 'Agent Memory Patterns',
      savedAt: _ago(const Duration(days: 16)),
      categoryId: 'ai',
      accentSlot: 0,
      clusterId: 'ai-agents',
      bullets: const [
        'Short-term memory is context; long-term memory is retrieval.',
        'Summarize aggressively to keep the working set small.',
        'Store the reason a fact was kept, not only the fact.',
      ],
      keywords: const ['AI', 'Agents', 'Memory', 'RAG'],
      note: 'Same idea as the Lymarks re-surfacing algorithm.',
    ),
    Lymark(
      id: 'lm-rag',
      url: 'https://www.pinecone.io/learn/retrieval-augmented-generation',
      domain: 'pinecone.io',
      title: 'Retrieval Augmented Generation explained',
      savedAt: _ago(const Duration(days: 24)),
      categoryId: 'ai',
      accentSlot: 0,
      clusterId: 'ai-rag',
      bullets: const [
        'RAG grounds a model in documents it did not memorize.',
        'Chunking strategy affects recall more than the model does.',
        'Always keep the citation next to the retrieved passage.',
      ],
      keywords: const ['RAG', 'Retrieval', 'Embeddings'],
    ),
    Lymark(
      id: 'lm-pgvector',
      url: 'https://neon.tech/docs/extensions/pgvector',
      domain: 'neon.tech',
      title: 'pgvector and HNSW indexes',
      savedAt: _ago(const Duration(days: 28)),
      categoryId: 'ai',
      accentSlot: 0,
      clusterId: 'ai-vector',
      bullets: const [
        'HNSW trades memory for a large speed gain on cosine search.',
        'Build the index early: rebuilding it later locks the table.',
        'Tune ef_search per query, m and ef_construction per index.',
      ],
      keywords: const ['Vector DB', 'Postgres', 'pgvector'],
    ),
    // État `processing` : la carte affiche un squelette qui se remplit seul
    // (UX Bible règle 4). Aucune notification n'est envoyée.
    Lymark(
      id: 'lm-processing',
      url: 'https://www.anthropic.com/engineering/building-effective-agents',
      domain: 'anthropic.com',
      title: 'Building effective agents',
      savedAt: _ago(const Duration(seconds: 20)),
      status: LymarkStatus.processing,
      categoryId: 'ai',
      accentSlot: 0,
      clusterId: 'ai-agents',
    ),
    // État `partial` : page inaccessible au scraping, métadonnées seules.
    Lymark(
      id: 'lm-partial',
      url: 'https://www.ft.com/content/ai-infrastructure',
      domain: 'ft.com',
      title: 'The economics of AI infrastructure',
      savedAt: _ago(const Duration(days: 4)),
      status: LymarkStatus.partial,
      categoryId: 'business',
      accentSlot: 3,
      bullets: const [
        'Summary limited to the page metadata: the article is paywalled.',
      ],
      keywords: const ['Business', 'Infrastructure'],
    ),
    // État `failed` : jamais silencieux, toujours réessayable (PRD §3).
    Lymark(
      id: 'lm-failed',
      url: 'https://x.com/status/1234567890',
      domain: 'x.com',
      title: 'Thread on retrieval evaluation',
      savedAt: _ago(const Duration(days: 6)),
      source: LymarkSource.x,
      status: LymarkStatus.failed,
      categoryId: 'ai',
      accentSlot: 0,
    ),
  ];

  static const List<KnowledgeCategory> categories = [
    KnowledgeCategory(
      id: 'ai',
      name: 'AI',
      tagline: 'Explore your AI knowledge',
      count: 24,
      iconKey: 'ai',
      accent: 0,
      clusters: [
        KnowledgeCluster(
          id: 'ai-agents',
          categoryId: 'ai',
          name: 'AI Agents',
          description: 'Explore everything about AI agents and frameworks',
          count: 8,
          iconKey: 'agents',
          accent: 0,
        ),
        KnowledgeCluster(
          id: 'ai-rag',
          categoryId: 'ai',
          name: 'RAG',
          description: 'Retrieval Augmented Generation concepts',
          count: 6,
          iconKey: 'rag',
          accent: 2,
        ),
        KnowledgeCluster(
          id: 'ai-vector',
          categoryId: 'ai',
          name: 'Vector Databases',
          description: 'Vector storage and similarity search',
          count: 4,
          iconKey: 'vector',
          accent: 1,
        ),
        KnowledgeCluster(
          id: 'ai-embeddings',
          categoryId: 'ai',
          name: 'Embeddings',
          description: 'Text embeddings and representation models',
          count: 3,
          iconKey: 'embeddings',
          accent: 3,
        ),
        KnowledgeCluster(
          id: 'ai-prompt',
          categoryId: 'ai',
          name: 'Prompt Engineering',
          description: 'Techniques and best practices',
          count: 3,
          iconKey: 'prompt',
          accent: 4,
        ),
      ],
    ),
    KnowledgeCategory(
      id: 'design',
      name: 'Design',
      tagline: 'Systems, type and interface craft',
      count: 12,
      iconKey: 'design',
      accent: 1,
      clusters: [
        KnowledgeCluster(
          id: 'design-systems',
          categoryId: 'design',
          name: 'Design Systems',
          description: 'Tokens, components and documentation',
          count: 7,
          iconKey: 'design',
          accent: 1,
        ),
        KnowledgeCluster(
          id: 'design-motion',
          categoryId: 'design',
          name: 'Motion',
          description: 'Transitions and micro-interactions',
          count: 5,
          iconKey: 'design',
          accent: 3,
        ),
      ],
    ),
    KnowledgeCategory(
      id: 'development',
      name: 'Development',
      tagline: 'Architecture, performance and tooling',
      count: 18,
      iconKey: 'development',
      accent: 2,
      clusters: [
        KnowledgeCluster(
          id: 'dev-react',
          categoryId: 'development',
          name: 'React',
          description: 'Component architecture and patterns',
          count: 11,
          iconKey: 'development',
          accent: 2,
        ),
        KnowledgeCluster(
          id: 'dev-performance',
          categoryId: 'development',
          name: 'Performance',
          description: 'Core Web Vitals and rendering budgets',
          count: 7,
          iconKey: 'development',
          accent: 0,
        ),
      ],
    ),
    KnowledgeCategory(
      id: 'business',
      name: 'Business',
      tagline: 'Markets, pricing and strategy',
      count: 7,
      iconKey: 'business',
      accent: 3,
    ),
    KnowledgeCategory(
      id: 'product',
      name: 'Product',
      tagline: 'Discovery, positioning and craft',
      count: 7,
      iconKey: 'product',
      accent: 4,
    ),
  ];

  static final UserProfile profile = UserProfile(
    name: 'Morel Herval',
    email: 'morel@lymarks.app',
    plan: UserPlan.pro,
    lymarkCount: 243,
    noteCount: 28,
    memberSince: DateTime(2026, 3, 14),
  );

  /// Sélection du jour. Les raisons sont celles que produirait l'algorithme
  /// de re-surfaçage (`05-data/01-knowledge-vault-spec.md` §4).
  static const List<DigestEntry> digest = [
    DigestEntry(
      lymarkId: 'lm-memory',
      reason: 'Close to what you saved this week',
    ),
    DigestEntry(
      lymarkId: 'lm-composition',
      reason: 'Saved a month ago, never opened',
    ),
  ];

  static const List<String> recentSearches = [
    'AI agents',
    'React architecture',
    'design systems',
  ];
}
