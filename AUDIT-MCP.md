# AUDIT-MCP.md — Journal d'audit du serveur `mcp-auchan-drive`

Journal vivant. **Avant d'utiliser une fonctionnalité du serveur** (outil MCP, module de
`src/`), lire l'entrée du commit courant ; si elle est absente ou incomplète pour cette
fonctionnalité, auditer le code concerné puis compléter ce fichier. Règles complètes dans
`AGENTS.md` (« Règle d'audit »).

---

## Entrée courante — commit `7199631` (audit initial, 2026-09-30)

- **Cloné depuis** : https://github.com/nicolascoutureau/mcp-auchan-drive.git
- **Périmètre audité** : tout `src/` (~2 600 lignes TS), `package.json`, `scripts/smoke-test.mjs`
  (survol), `README.md`. **Non audité** : `tools/ollama-mcp-bridge/` (sous-projet non
  utilisé par ce projet), `tests/` (consultés pour comprendre, pas ligne à ligne).
- **Verdict global : OK pour usage personnel, avec réserves listées plus bas.**

### Réseau (verdict : propre)

- Seuls deux domaines contactés par le code du serveur :
  - `https://www.auchan.fr` (recherche, panier, fidélité, commandes, favoris)
  - `https://api-adresse.data.gouv.fr` (géocodage public officiel, pour `find_stores`)
- Aucune autre destination, aucun téléhone-home, aucune télémétrie, aucune écriture de
  données vers un tiers. Vérifié par passe systématique sur toutes les URLs de `src/` et
  `scripts/`.

### Cookies et authentification (verdict : propre, point de vigilance majeur)

- Le serveur lit les cookies `www.auchan.fr`/`.auchan.fr` depuis le profil Chrome local
  (via `chrome-cookies-secure`, qui déchiffre la base de cookies de Chrome) ou Firefox
  (copie temporaire en lecture seule de `cookies.sqlite`, supprimée après lecture).
  L'utilisateur utilise Chrome : profil `Default`.
- Le fournisseur Firefox exclut volontairement `compte.auchan.fr` (tokens Keycloak). Le
  fournisseur Chrome demande au module tous les cookies de l'URL auchan.fr uniquement.
- Les cookies sont conservés **en mémoire uniquement** (cache, invalidé sur 403) et ne
  sont envoyés qu'à `www.auchan.fr`. Aucune trace disque, aucun log de cookies.
- **Vigilance** : le point sensible reste que le processus serveur manipule la session
  authentifiée complète. C'est le risque accepté du projet ; les garde-fous (pas de
  paiement, rapport humain, review du code à chaque mise à jour) visent à l'encadrer.

### Système de fichiers (verdict : propre)

- Seule écriture persistante : `~/.mcp-auchan-drive-state.json` (drive sélectionné,
  écrit par `set_store`). Fichier local, sans données sensibles (id + nom du drive).
- Firefox uniquement : copie temporaire de `cookies.sqlite` dans le tmp système, en
  lecture seule, supprimée après (avec WAL/SHM). Non concerné par notre usage Chrome.

### Exécution de code (verdict : propre)

- Aucun `child_process`, aucun `exec`/`spawn`, aucun `eval`. Les `.exec(` trouvés sont
  tous des appels `RegExp.exec` (parsing HTML).
- Seule construction dynamique de regex : l'outil `debug_page_html` compile un pattern
  fourni par l'appelant (risque ReDoS théorique ; outil de diagnostic, interdit en usage
  normal par notre spec).

### Dépendances (verdict : minimales, à re-vérifier à chaque MAJ)

- Production : `@modelcontextprotocol/sdk` 1.29.0, `zod` 4.4.3, `chrome-cookies-secure`
  3.0.2 (dépendances transitives natives : sqlite3, tldjs — installées via `npm install`,
  scripts de build autorisés dans `package.json` : msw, sqlite3, tldjs).
- `chrome-cookies-secure` lit la base de cookies de Chrome : c'est sa fonction, mais
  c'est la dépendance à surveiller en priorité lors des mises à jour (vérifier version,
  repo, diff).
- Dev : TypeScript, Vitest, msw. Rien d'exotique.

### Comportement anti-bot (verdict : raisonnable)

- `Throttler` : requêtes **sérialisées** (file, jamais en parallèle), délai min 1 000 ms
  + jitter aléatoire 400 ms, retries max 3 sur 403/429 avec backoff exponentiel
  (base 1 500 ms). Réglable par `AUCHAN_MIN_INTERVAL_MS`, `AUCHAN_JITTER_MS`,
  `AUCHAN_MAX_RETRIES`, `AUCHAN_BACKOFF_BASE_MS`.
- Sur 403, le cache de cookies est invalidé pour relire la session (récupération du
  `datadome` régénéré par le navigateur).

### Réserves et risques résiduels

1. **Fragilité** : toute la lecture des données passe par du parsing HTML par regex sur
   des pages server-side d'auchan.fr. Toute refonte du site casse des outils (l'historique
   du repo le confirme : série de `fix:` d'adaptation au markup). Symptôme typique :
   réponses vides ou erreurs de parsing → utiliser `debug_page_html` pour diagnostiquer.
2. **`add_to_cart`** exige que le produit ait été vu par `search_product` ou
   `get_favorites` dans la même session (cache en mémoire des `offerId`/`sellerId`),
   et le cache est vidé au changement de drive. Design voulu, pas un bug.
3. **Ajout silencieux possible** : `POST /cart/update` renvoie 200 même quand Auchan
   refuse la ligne (rupture du drive). Le client le détecte (comparaison des quantités)
   et lève une erreur explicite. Bonne surprise, mais ceinture utile pour l'agent :
   toujours finir par `get_cart` pour confirmer.
4. **Flag `available` de la recherche** = catalogue national, pas le stock du drive
   actif. Une rupture ne se voit qu'à l'ajout.
5. `tools/ollama-mcp-bridge/` : non audité, non utilisé. Ne pas l'activer sans audit.
6. README du serveur indique Node 18+, mais `package.json` exige Node ≥ 20.19 :
   faire foi sur le package.json.

---

## Résumé fonctionnel — ce que le MCP sait faire (15 outils)

| Outil | Usage | Dans notre pipeline |
|---|---|---|
| `search_product` | Recherche catalogue : nom, marque, prix, prix/kg, dispo | Oui — étape principale |
| `search_promos` | Promos du drive actif, par mot-clé ou rayon | Optionnel (évolutions) |
| `add_to_cart` | Ajoute un produit (après recherche/favoris) | Oui — étape principale |
| `update_quantity` | Change une quantité (0 = retire) | Oui — ajustements |
| `remove_from_cart` | Retire une ligne | Oui — correction d'erreur |
| `get_cart` | Panier complet + total | Oui — état initial et final |
| `find_stores` | Drives proches d'une ville/CP (via data.gouv) | Non (drive déjà dans le compte) |
| `set_store` | Sélectionne le drive actif | Non, sauf demande explicite |
| `get_store` | Drive actif courant | Oui — précondition du run |
| `get_favorites` | Produits achetés régulièrement, prix et promos | Optionnel (évolutions) |
| `get_orders` | Historique des commandes | Optionnel (évolutions) |
| `get_order_detail` | Détail d'une commande (produits, créneau) | Non |
| `get_loyalty_info` | Cagnotte Waaoh, carte, Jour W!, défis | Non |
| `get_loyalty_history` | Historique des transactions de cagnotte | Non |
| `debug_page_html` | Diagnostic : extraits du HTML brut du site | Diagnostic uniquement |

**Ce que le MCP ne sait pas faire (et c'est voulu)** : payer, valider une commande,
réserver un créneau, gérer le compte. Le pipeline s'arrête au panier ; l'utilisateur
valide et paie dans l'app Auchan.

## Résumé du fonctionnement

```
Agent Vibe ──(MCP stdio)──► Serveur Node mcp-auchan-drive
                              ├── CookieProvider : cookies de session Chrome
                              ├── Throttler      : 1 req/s + jitter, retry 403/429
                              ├── AuchanClient    : /recherche, /cart, /client/*, /fidelite/*
                              ├── Parsers         : HTML → données (regex)
                              └── StoreLocator    : data.gouv + /offering-contexts
                                        │
                                        ▼
                            www.auchan.fr (site SPA « CREST » rendu serveur)
```

- Le serveur **reverse-engineer les requêtes XHR de la SPA auchan.fr** et rejoue les
  mêmes appels avec les cookies de session du navigateur : il se fait passer pour le
  navigateur de l'utilisateur déjà connecté.
- Recherche : `GET /recherche?text=…` → HTML parsé. Panier : `GET /cart` (JSON) pour le
  `cartId`, puis `POST /cart/update` par ligne. Fidélité/commandes/favoris : pages HTML
  `/fidelite/*` et `/client/*` parsées.
- Pas d'API officielle : si le site change, les parsers cassent (d'où le plan de
  maintenance dans `NOTES.md`).

## Procédure de mise à jour (résumé)

```bash
cd mcp-auchan-drive
git fetch && git log HEAD..origin/main --oneline     # voir ce qui arrive
git diff HEAD..origin/main -- src/ scripts/ package.json   # AUDITER AVANT
git pull
npm install && npm run build && npm test
```

Puis : mettre à jour ce journal (nouvelle section de commit ou complément), en
re-vérifiant systématiquement : nouvelles URLs contactées, nouvelles dépendances,
nouveaux fichiers lus/écrits, nouveaux outils exposés.

---

## Historique des audits

| Date | Commit | Périmètre | Verdict | Notes |
|---|---|---|---|---|
| 2026-09-30 | `7199631` | src/ complet, package.json, scripts (survol) | OK, réserves listées ci-dessus | Audit initial à l'initialisation du projet |
