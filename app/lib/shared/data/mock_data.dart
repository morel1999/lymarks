import 'package:lymarks/shared/models/knowledge.dart';
import 'package:lymarks/shared/models/lymark.dart';

/// Jeu de données de démonstration.
///
/// Il reprend fidèlement le contenu des maquettes (`Ecran/`) pour que les
/// écrans soient comparables au design de référence. Il sera remplacé par
/// l'API Hono à l'étape 3 de la roadmap ; aucun écran ne doit dépendre de
/// cette classe autrement que par les providers.
abstract final class MockData {
  /// Instant de référence du jeu de démo, lu une seule fois.
  ///
  /// Pas `DateTime.now()` à chaque ligne : deux lymarks déclarés « il y a
  /// neuf jours » recevaient alors des instants séparés de quelques
  /// microsecondes — ou rigoureusement égaux, selon la granularité de
  /// l'horloge à cet instant-là. Leur ordre changeait donc d'un lancement à
  /// l'autre, et un rendu de référence échouait au hasard une fois sur deux.
  /// Ancrées au même instant, deux durées égales donnent la même date, et
  /// [Lymark.byRecency] départage sur l'identifiant.
  static final DateTime _now = DateTime.now();

  static DateTime _ago(Duration d) => _now.subtract(d);

  static final List<Lymark> lymarks = [
    Lymark(
      id: 'lm-agents',
      url: 'https://huggingface.co/learn/agents-course',
      domain: 'huggingface.co',
      title: 'Building AI Agents',
      savedAt: _ago(const Duration(days: 2)),
      categoryId: 'ai',
      bullets: const [
        'AI agents combine reasoning, tools and memory to act autonomously.',
        'Tool calling allows agents to interact with external systems.',
        'Good agent design relies on clear boundaries and feedback loops.',
      ],
      keywords: const ['AI', 'Agents', 'Tools', 'Framework', 'LLM'],
      note: "This could be useful for the agent system I'm building.",
      // Aperçus : trois lymarks suffisent à juger le rendu. Sans réseau
      // (tests, goldens) l'image échoue et la vignette de source reprend.
      imageUrl:
          'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=1200',
    ),
    Lymark(
      id: 'lm-next',
      url: 'https://vercel.com/blog/nextjs-15-performance',
      domain: 'vercel.com',
      title: 'Next.js 15 Performance Guide',
      savedAt: _ago(const Duration(days: 3)),
      categoryId: 'development',
      bullets: const [
        'Partial prerendering improves performance with dynamic content.',
        'Optimize images, fonts and scripts for Core Web Vitals.',
        'Use caching and streaming to deliver content faster.',
      ],
      keywords: const ['Next.js', 'Performance', 'Web', 'Rendering'],
      imageUrl:
          'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=1200',
    ),
    Lymark(
      id: 'lm-ds',
      url: 'https://medium.com/design-systems-that-scale',
      domain: 'medium.com',
      title: 'Design Systems that Scale',
      savedAt: _ago(const Duration(days: 5)),
      categoryId: 'design',
      bullets: const [
        'Tokens keep visual decisions in one place instead of in components.',
        'Document intent, not just usage, so the system survives its authors.',
        'Adoption matters more than completeness.',
      ],
      keywords: const ['Design', 'Systems', 'Tokens'],
      note: 'Reference for the Lymarks design system.',
      imageUrl:
          'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=1200',
    ),
    Lymark(
      id: 'lm-rsc',
      url: 'https://react.dev/reference/rsc/server-components',
      domain: 'react.dev',
      title: 'React Server Components',
      savedAt: _ago(const Duration(days: 7)),
      categoryId: 'development',
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
    ),
    // ---------------------------------------------------------------------
    // Le reste de la bibliotheque de demonstration.
    //
    // Les quatorze entrees ci-dessus viennent des maquettes et gardent leur
    // place : la Home n'affiche que les six premieres. Celles qui suivent
    // habitent les chemins — un cluster vide casse le parcours d'une
    // categorie, qui debouche alors sur un etat vide.
    // ---------------------------------------------------------------------
    Lymark(
      id: 'lm-agent-eval',
      url: 'https://blog.langchain.dev/evaluating-agent-trajectories',
      domain: 'blog.langchain.dev',
      title: 'Evaluating agent trajectories',
      savedAt: _ago(const Duration(days: 9)),
      categoryId: 'ai',
      bullets: const [
        'Judging the final answer hides where the agent went wrong.',
        'Step-level traces make failures reproducible.',
      ],
      keywords: const ['AI', 'Agents', 'Evaluation'],
    ),
    Lymark(
      id: 'lm-rag-chunking',
      url: 'https://www.pinecone.io/learn/chunking-strategies',
      domain: 'pinecone.io',
      title: 'Chunking strategies that actually work',
      savedAt: _ago(const Duration(days: 16)),
      categoryId: 'ai',
      bullets: const [
        'Fixed-size chunks break arguments in half.',
        'Splitting on structure keeps a passage answerable.',
      ],
      keywords: const ['RAG', 'Chunking', 'Context'],
    ),
    Lymark(
      id: 'lm-rag-hybrid',
      url: 'https://dev.to/hybrid-search-beats-pure-vectors',
      domain: 'dev.to',
      title: 'Hybrid search beats pure vectors',
      savedAt: _ago(const Duration(days: 40)),
      categoryId: 'ai',
      bullets: const [
        'Keyword matching still wins on names, codes and acronyms.',
        'Reciprocal rank fusion merges both rankings cheaply.',
      ],
      keywords: const ['RAG', 'Search', 'Ranking'],
      note: 'Worth trying before we tune the embedding model again.',
    ),
    Lymark(
      id: 'lm-vector-hnsw',
      url: 'https://github.com/nmslib/hnswlib',
      domain: 'github.com',
      title: 'HNSW explained without the math',
      savedAt: _ago(const Duration(days: 23)),
      categoryId: 'ai',
      bullets: const [
        'A navigable graph trades a little recall for a lot of speed.',
        'One dial decides between latency and accuracy.',
      ],
      keywords: const ['Vector', 'Index', 'ANN'],
    ),
    Lymark(
      id: 'lm-vector-choice',
      url: 'https://medium.com/choosing-a-vector-store',
      domain: 'medium.com',
      title: 'Choosing a vector store in 2026',
      savedAt: _ago(const Duration(days: 68)),
      categoryId: 'ai',
      bullets: const [
        'Most teams never outgrow Postgres with pgvector.',
        'Filtering before the scan matters more than raw throughput.',
      ],
      keywords: const ['Vector', 'Database', 'Postgres'],
    ),
    Lymark(
      id: 'lm-emb-basics',
      url: 'https://huggingface.co/blog/what-embeddings-encode',
      domain: 'huggingface.co',
      title: 'What embeddings really encode',
      savedAt: _ago(const Duration(days: 9)),
      categoryId: 'ai',
      bullets: const [
        'Distance encodes usage, not meaning as humans define it.',
        'Two opposite words can sit close if they share contexts.',
      ],
      keywords: const ['Embeddings', 'Vectors', 'NLP'],
    ),
    Lymark(
      id: 'lm-emb-matryoshka',
      url: 'https://huggingface.co/blog/matryoshka-embeddings',
      domain: 'huggingface.co',
      title: 'Matryoshka embeddings, shorter and sharper',
      savedAt: _ago(const Duration(days: 29)),
      categoryId: 'ai',
      bullets: const [
        'One model serves several dimensions by truncation.',
        'Storage drops without retraining anything.',
      ],
      keywords: const ['Embeddings', 'Compression', 'Models'],
    ),
    Lymark(
      id: 'lm-emb-eval',
      url: 'https://dev.to/benchmark-embeddings-on-your-own-data',
      domain: 'dev.to',
      title: 'Benchmarking embedding models on your own data',
      savedAt: _ago(const Duration(days: 95)),
      categoryId: 'ai',
      bullets: const [
        'Public leaderboards rarely match a private corpus.',
        'A hundred labelled pairs already separate the candidates.',
      ],
      keywords: const ['Embeddings', 'Evaluation', 'Benchmark'],
    ),
    Lymark(
      id: 'lm-prompt-struct',
      url: 'https://dev.to/structured-output-without-the-fight',
      domain: 'dev.to',
      title: 'Structured output without the fight',
      savedAt: _ago(const Duration(days: 5)),
      categoryId: 'ai',
      bullets: const [
        'A schema beats three paragraphs of formatting instructions.',
        'Validate and reprompt rather than parse defensively.',
      ],
      keywords: const ['Prompt', 'Schema', 'JSON'],
    ),
    Lymark(
      id: 'lm-prompt-fewshot',
      url: 'https://medium.com/few-shot-examples-that-earn-their-tokens',
      domain: 'medium.com',
      title: 'Few-shot examples that earn their tokens',
      savedAt: _ago(const Duration(days: 23)),
      categoryId: 'ai',
      bullets: const [
        'Three well-chosen examples outperform ten average ones.',
        'Examples should cover the edges, not the obvious case.',
      ],
      keywords: const ['Prompt', 'Examples', 'LLM'],
    ),
    Lymark(
      id: 'lm-prompt-caching',
      url: 'https://dev.to/prompt-caching-what-to-put-where',
      domain: 'dev.to',
      title: 'Prompt caching: what to put where',
      savedAt: _ago(const Duration(days: 75)),
      categoryId: 'ai',
      bullets: const [
        'Stable content goes first, the variable part last.',
        'A cache hit changes the economics of long system prompts.',
      ],
      keywords: const ['Prompt', 'Caching', 'Cost'],
    ),
    Lymark(
      id: 'lm-ds-tokens',
      url: 'https://medium.com/design-tokens-three-layers-deep',
      domain: 'medium.com',
      title: 'Design tokens, three layers deep',
      savedAt: _ago(const Duration(days: 16)),
      categoryId: 'design',
      bullets: const [
        'Primitive, semantic and component layers each have one job.',
        'Themes only ever touch the semantic layer.',
      ],
      keywords: const ['Design', 'Tokens', 'Theming'],
    ),
    Lymark(
      id: 'lm-ds-naming',
      url: 'https://dev.to/naming-components-so-people-find-them',
      domain: 'dev.to',
      title: 'Naming components so people find them',
      savedAt: _ago(const Duration(days: 45)),
      categoryId: 'design',
      bullets: const [
        'Name by intent, not by appearance.',
        'A name that describes a colour ages in one redesign.',
      ],
      keywords: const ['Design', 'Components', 'Naming'],
    ),
    Lymark(
      id: 'lm-ds-docs',
      url: 'https://medium.com/documentation-is-part-of-the-component',
      domain: 'medium.com',
      title: 'Documentation is part of the component',
      savedAt: _ago(const Duration(days: 110)),
      categoryId: 'design',
      bullets: const [
        'An undocumented variant will be rebuilt somewhere else.',
        'Usage rules belong next to the code, not in a wiki.',
      ],
      keywords: const ['Design', 'Documentation', 'Systems'],
    ),
    Lymark(
      id: 'lm-motion-curves',
      url: 'https://frontendmasters.com/easing-curves-and-what-they-say',
      domain: 'frontendmasters.com',
      title: 'Easing curves and what they say',
      savedAt: _ago(const Duration(days: 9)),
      categoryId: 'design',
      bullets: const [
        'Linear motion reads as mechanical on anything physical.',
        'Entrances decelerate, exits accelerate.',
      ],
      keywords: const ['Motion', 'Animation', 'Easing'],
    ),
    Lymark(
      id: 'lm-motion-budget',
      url: 'https://medium.com/a-motion-budget-for-product-ui',
      domain: 'medium.com',
      title: 'A motion budget for product UI',
      savedAt: _ago(const Duration(days: 34)),
      categoryId: 'design',
      bullets: const [
        'Under 200ms feels instant, over 500ms feels slow.',
        'Animate one thing per transition, not four.',
      ],
      keywords: const ['Motion', 'Interaction', 'Timing'],
    ),
    Lymark(
      id: 'lm-motion-reduced',
      url: 'https://dev.to/respecting-reduced-motion-by-default',
      domain: 'dev.to',
      title: 'Respecting reduced motion by default',
      savedAt: _ago(const Duration(days: 130)),
      categoryId: 'design',
      bullets: const [
        'Reduced motion means replaced, not removed.',
        'A cross-fade still communicates the change of state.',
      ],
      keywords: const ['Motion', 'Accessibility', 'Preferences'],
    ),
    Lymark(
      id: 'lm-type-scale',
      url: 'https://medium.com/a-type-scale-that-survives-translation',
      domain: 'medium.com',
      title: 'A type scale that survives translation',
      savedAt: _ago(const Duration(days: 23)),
      categoryId: 'design',
      bullets: const [
        'German and Finnish add a third to most labels.',
        'A scale with too many steps collapses under translation.',
      ],
      keywords: const ['Typography', 'Scale', 'i18n'],
    ),
    Lymark(
      id: 'lm-type-variable',
      url: 'https://frontendmasters.com/variable-fonts-in-production',
      domain: 'frontendmasters.com',
      title: 'Variable fonts in production',
      savedAt: _ago(const Duration(days: 62)),
      categoryId: 'design',
      bullets: const [
        'One file replaces six weights and loads faster.',
        'Subsetting matters more than the format.',
      ],
      keywords: const ['Typography', 'Fonts', 'Performance'],
    ),
    Lymark(
      id: 'lm-type-reading',
      url: 'https://medium.com/line-length-measure-and-reading-comfort',
      domain: 'medium.com',
      title: 'Line length, measure and reading comfort',
      savedAt: _ago(const Duration(days: 160)),
      categoryId: 'design',
      bullets: const [
        'Sixty to seventy-five characters per line stays comfortable.',
        'Line height should grow with measure, not with size alone.',
      ],
      keywords: const ['Typography', 'Readability', 'Layout'],
    ),
    Lymark(
      id: 'lm-react-suspense',
      url: 'https://react.dev/reference/react/Suspense',
      domain: 'react.dev',
      title: 'Suspense boundaries as a layout decision',
      savedAt: _ago(const Duration(days: 29)),
      categoryId: 'development',
      bullets: const [
        'A boundary defines what may appear late, and where.',
        'Placing them by layout region avoids cascading spinners.',
      ],
      keywords: const ['React', 'Suspense', 'Loading'],
    ),
    Lymark(
      id: 'lm-perf-inp',
      url: 'https://web.dev/articles/inp',
      domain: 'web.dev',
      title: 'INP, the metric that replaced FID',
      savedAt: _ago(const Duration(days: 16)),
      categoryId: 'development',
      bullets: const [
        'INP measures every interaction, not just the first.',
        'Long tasks on the main thread are the usual culprit.',
      ],
      keywords: const ['Performance', 'Web Vitals', 'INP'],
    ),
    Lymark(
      id: 'lm-perf-images',
      url: 'https://web.dev/articles/image-budgets-on-mobile',
      domain: 'web.dev',
      title: 'Image budgets on mobile networks',
      savedAt: _ago(const Duration(days: 100)),
      categoryId: 'development',
      bullets: const [
        'Images are still the largest share of most pages.',
        'Serving the right size beats any compression trick.',
      ],
      keywords: const ['Performance', 'Images', 'Mobile'],
    ),
    Lymark(
      id: 'lm-arch-modular',
      url: 'https://medium.com/modular-monolith-before-microservices',
      domain: 'medium.com',
      title: 'Modular monolith before microservices',
      savedAt: _ago(const Duration(days: 12)),
      categoryId: 'development',
      bullets: const [
        'Module boundaries are cheap to move, network ones are not.',
        'Split a service when a team owns it, not when a file grows.',
      ],
      keywords: const ['Architecture', 'Monolith', 'Services'],
      note: 'The argument I keep failing to make in review.',
    ),
    Lymark(
      id: 'lm-arch-edge',
      url: 'https://vercel.com/blog/edge-runtimes-and-their-limits',
      domain: 'vercel.com',
      title: 'Edge runtimes and their limits',
      savedAt: _ago(const Duration(days: 50)),
      categoryId: 'development',
      bullets: const [
        'No filesystem, no long-lived connections, short budgets.',
        'Latency wins evaporate if the database stays far away.',
      ],
      keywords: const ['Architecture', 'Edge', 'Runtime'],
    ),
    Lymark(
      id: 'lm-arch-contracts',
      url: 'https://github.com/typed-contracts-client-server',
      domain: 'github.com',
      title: 'Typed contracts between client and server',
      savedAt: _ago(const Duration(days: 140)),
      categoryId: 'development',
      bullets: const [
        'A shared schema removes a whole class of integration bugs.',
        'Generate the client, never hand-write the types twice.',
      ],
      keywords: const ['Architecture', 'Types', 'API'],
    ),
    Lymark(
      id: 'lm-price-anchor',
      url: 'https://medium.com/anchoring-and-the-middle-tier',
      domain: 'medium.com',
      title: 'Anchoring and the middle tier',
      savedAt: _ago(const Duration(days: 6)),
      categoryId: 'business',
      bullets: const [
        'The top tier exists to make the middle one reasonable.',
        'Three tiers decide faster than five.',
      ],
      keywords: const ['Pricing', 'Strategy', 'SaaS'],
    ),
    Lymark(
      id: 'lm-price-usage',
      url: 'https://linkedin.com/pulse/usage-based-pricing',
      domain: 'linkedin.com',
      title: 'Usage-based pricing without bill shock',
      savedAt: _ago(const Duration(days: 27)),
      categoryId: 'business',
      bullets: const [
        'Caps and alerts matter more than the rate itself.',
        'Unpredictable bills cost more churn than they earn.',
      ],
      keywords: const ['Pricing', 'Billing', 'Churn'],
    ),
    Lymark(
      id: 'lm-price-freemium',
      url: 'https://medium.com/when-freemium-stops-paying',
      domain: 'medium.com',
      title: 'When freemium stops paying',
      savedAt: _ago(const Duration(days: 72)),
      categoryId: 'business',
      bullets: const [
        'A free tier is a marketing budget with a server bill.',
        'It works when the free user brings the paying one.',
      ],
      keywords: const ['Pricing', 'Freemium', 'Growth'],
    ),
    Lymark(
      id: 'lm-strat-wedge',
      url: 'https://www.ycombinator.com/library/find-the-narrow-wedge',
      domain: 'ycombinator.com',
      title: 'Find the narrow wedge first',
      savedAt: _ago(const Duration(days: 19)),
      categoryId: 'business',
      bullets: const [
        'A small market you dominate beats a large one you sample.',
        'The wedge is a beachhead, not the final scope.',
      ],
      keywords: const ['Strategy', 'Markets', 'Focus'],
    ),
    Lymark(
      id: 'lm-strat-moat',
      url: 'https://medium.com/moats-that-are-not-features',
      domain: 'medium.com',
      title: 'Moats that are not features',
      savedAt: _ago(const Duration(days: 105)),
      categoryId: 'business',
      bullets: const [
        'Any feature can be copied in a quarter.',
        'Data, distribution and switching costs compound instead.',
      ],
      keywords: const ['Strategy', 'Moat', 'Competition'],
    ),
    Lymark(
      id: 'lm-growth-loops',
      url: 'https://medium.com/growth-loops-beat-funnels',
      domain: 'medium.com',
      title: 'Growth loops beat funnels',
      savedAt: _ago(const Duration(days: 11)),
      categoryId: 'business',
      bullets: const [
        'A funnel ends, a loop reinvests its own output.',
        'Name the input, the action and what it produces.',
      ],
      keywords: const ['Growth', 'Loops', 'Acquisition'],
    ),
    Lymark(
      id: 'lm-growth-retention',
      url: 'https://linkedin.com/pulse/retention-is-the-only-growth-metric',
      domain: 'linkedin.com',
      title: 'Retention is the only growth metric',
      savedAt: _ago(const Duration(days: 38)),
      categoryId: 'business',
      bullets: const [
        'Acquisition without retention is a leaking bucket.',
        'A flattening curve matters more than its height.',
      ],
      keywords: const ['Growth', 'Retention', 'Metrics'],
    ),
    Lymark(
      id: 'lm-growth-onboard',
      url: 'https://medium.com/activation-in-the-first-session',
      domain: 'medium.com',
      title: 'Activation happens in the first session',
      savedAt: _ago(const Duration(days: 155)),
      categoryId: 'business',
      bullets: const [
        'Most users decide before they finish the first screen.',
        'Time to first value is the number to move.',
      ],
      keywords: const ['Growth', 'Onboarding', 'Activation'],
    ),
    Lymark(
      id: 'lm-disc-interviews',
      url: 'https://medium.com/interviews-without-leading-questions',
      domain: 'medium.com',
      title: 'Interviews that avoid leading questions',
      savedAt: _ago(const Duration(days: 21)),
      categoryId: 'product',
      bullets: const [
        'Ask about last time, not about next time.',
        'Past behaviour is evidence, intent is a guess.',
      ],
      keywords: const ['Product', 'Research', 'Interviews'],
    ),
    Lymark(
      id: 'lm-disc-jobs',
      url: 'https://medium.com/jobs-to-be-done-applied-honestly',
      domain: 'medium.com',
      title: 'Jobs to be done, applied honestly',
      savedAt: _ago(const Duration(days: 58)),
      categoryId: 'product',
      bullets: const [
        'The job is the progress someone is trying to make.',
        'Competitors include the spreadsheet and doing nothing.',
      ],
      keywords: const ['Product', 'JTBD', 'Discovery'],
    ),
    Lymark(
      id: 'lm-disc-signals',
      url: 'https://linkedin.com/pulse/signal-from-loud-users',
      domain: 'linkedin.com',
      title: 'Separating signal from loud users',
      savedAt: _ago(const Duration(days: 175)),
      categoryId: 'product',
      bullets: const [
        'The loudest request rarely represents the median user.',
        'Weight feedback by the behaviour behind it.',
      ],
      keywords: const ['Product', 'Feedback', 'Prioritisation'],
    ),
    Lymark(
      id: 'lm-craft-positioning',
      url: 'https://medium.com/positioning-is-a-decision',
      domain: 'medium.com',
      title: 'Positioning is a decision, not a tagline',
      savedAt: _ago(const Duration(days: 14)),
      categoryId: 'product',
      bullets: const [
        'Positioning says who it is not for, out loud.',
        'The category you claim sets the comparison.',
      ],
      keywords: const ['Product', 'Positioning', 'Marketing'],
    ),
    Lymark(
      id: 'lm-craft-naming',
      url: 'https://medium.com/naming-a-product-people-repeat',
      domain: 'medium.com',
      title: 'Naming a product people can repeat',
      savedAt: _ago(const Duration(days: 82)),
      categoryId: 'product',
      bullets: const [
        'A name that survives a noisy room survives everything.',
        'Spelling it once on the phone is the real test.',
      ],
      keywords: const ['Product', 'Naming', 'Brand'],
    ),
    Lymark(
      id: 'lm-craft-changelog',
      url: 'https://dev.to/a-changelog-users-actually-read',
      domain: 'dev.to',
      title: 'A changelog users actually read',
      savedAt: _ago(const Duration(days: 210)),
      categoryId: 'product',
      bullets: const [
        'Lead with what changed for the reader, not the version.',
        'Screenshots do more than bullet points.',
      ],
      keywords: const ['Product', 'Changelog', 'Communication'],
    ),
  ];

  /// Les cinq catégories mises en avant par la démonstration.
  ///
  /// Chaque `count` est le nombre réel de lymarks rangés dans la catégorie ou
  /// le cluster — `mock_data_test.dart` le vérifie. Un compte décoratif se
  /// verrait à l'écran : l'en-tête d'un chemin annoncerait sept lymarks au
  /// dessus d'un état vide.
  static const List<KnowledgeCategory> categories = [
    KnowledgeCategory(
      id: 'ai',
      name: 'AI',
      tagline: 'Explore your AI knowledge',
      count: 18,
      iconKey: 'ai',
      accent: 0,
    ),
    KnowledgeCategory(
      id: 'design',
      name: 'Design',
      tagline: 'Systems, type and interface craft',
      count: 10,
      iconKey: 'design',
      accent: 1,
    ),
    KnowledgeCategory(
      id: 'development',
      name: 'Development',
      tagline: 'Architecture, performance and tooling',
      count: 11,
      iconKey: 'development',
      accent: 2,
    ),
    KnowledgeCategory(
      id: 'business',
      name: 'Business',
      tagline: 'Markets, pricing and strategy',
      count: 9,
      iconKey: 'business',
      accent: 3,
    ),
    KnowledgeCategory(
      id: 'product',
      name: 'Product',
      tagline: 'Discovery, positioning and craft',
      count: 6,
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
