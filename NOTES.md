# NOTES.md — AuchanVibe

Justifications des choix non évidents et constats utiles au projet.

## Choix de conception

- **Chrome, pas Firefox** : l'utilisateur a sa session Auchan dans Chrome (profil
  `Default`). C'est le défaut du serveur MCP, aucune variable `AUCHAN_*` n'est donc
  nécessaire. Les modes Firefox (`AUCHAN_BROWSER=firefox`) et cookie manuel
  (`AUCHAN_COOKIE`) ne sont pas utilisés — ce dernier ne doit jamais l'être ici
  (copier un cookie dans un env revient à manipuler le secret à la main).
- **Clone Git plutôt que paquet npm** : le serveur n'est pas publié sur npm de façon
  exploitable pour nous et l'objectif est de suivre l'amont (`git pull`) tout en
  pouvant patcher localement si le markup du site casse. Chaque pull impose un audit
  du diff (règle dans `AGENTS.md`).
- **Wrapper minimal** (`courses.sh`) : il ne fait que des vérifications de
  préconditions et délègue tout à l'agent Vibe. Toute l'intelligence reste dans
  l'agent et le serveur MCP, ce qui garde le pipeline facile à modifier.
- **`--trust` dans le wrapper** : le mode `-p` de Vibe ne propose jamais de trusté le
  dossier, et la config projet `.vibe/` (déclaration du serveur MCP, agent) n'est
  chargée que si le dossier est trusté. Sans `--trust`, le serveur `auchan` serait
  invisible pour l'agent.
- **Nom du serveur MCP : `auchan`** (court) : les outils s'appellent `auchan_get_cart`,
  etc. Le préfixe est imposé par Vibe (`{serveur}_{outil}`).

## Constats sur le serveur MCP (compléments à AUDIT-MCP.md)

- **Aucune étape paiement côté serveur** : le serveur n'expose aucune commande de
  checkout, créneau ou paiement. Le « l'agent prépare, l'humain valide et paie » n'est
  donc pas seulement une règle de prompt, c'est la réalité du périmètre technique.
- **Disponibilité trompeuse** : le flag `available` de la recherche reflète le
  catalogue national, pas le stock du drive ; une rupture n'apparaît qu'à l'ajout
  (le serveur le détecte et le remonte explicitement).
- **Anti-bot DataDome** : le throttling par défaut (1 s + jitter 400 ms, 3 retries
  backoff) semble adapté à un usage personnel. Si des 403/429 apparaissent en usage
  normal, ne pas multiplier les tentatives : naviguer sur auchan.fr dans Chrome pour
  régénérer le cookie `datadome`, et éventuellement monter `AUCHAN_MIN_INTERVAL_MS`.
- **`add_to_cart` dépend du cache de recherche** : un produit non vu par
  `search_product`/`get_favorites` dans la session courante ne peut pas être ajouté
  (ids offer/seller manquants). Vider le cache sur changement de drive est voulu.
- **Sous-projet `tools/ollama-mcp-bridge/`** : présent dans le clone, non utilisé ni
  audité. Ne pas l'exécuter.

## Maintenance

- **Mise à jour du serveur** (à faire périodiquement, procédure complète dans
  `AUDIT-MCP.md`) : `git pull` → **audit du diff** → `npm install && npm run build`
  → `npm test` → mise à jour d'`AUDIT-MCP.md`.
- **Signes d'un markup auchan.fr changé** : résultats de recherche vides, erreurs de
  parsing, champs manquants dans les réponses. Diagnostic : `debug_page_html`
  (interdit en usage normal, autorisé pour diagnostiquer), puis fix sur une branche
  locale, éventuellement PR amont.

## Fichiers non créés

- **COMPATIBILITY.md** : pas de cible de compatibilité navigateur dans ce projet
  (l'exemple md-files-example en avait une, ce projet n'en a pas besoin). Le rôle de
  « journal vivant » est tenu par `AUDIT-MCP.md`.
