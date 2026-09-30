# AuchanVibe — Spécification technique (pour l'agent IA)

Objectif : **remplir automatiquement le panier Auchan Drive** à partir d'une simple liste
de courses, l'utilisateur validant et payant lui-même à la fin.

Cette spec fait autorité. Si elle contredit tes habitudes, **la spec gagne**. En cas
d'ambiguïté ou d'écart souhaité : demander avant d'agir.

---

## 0. Règles de travail de l'agent
- Les règles de travail détaillées sont dans `AGENTS.md` (audit du code tiers obligatoire,
  secrets, vérification).
- Le journal d'audit du serveur MCP est `AUDIT-MCP.md`. Il doit être lu avant toute
  utilisation d'une fonctionnalité du serveur et mis à jour après chaque audit.

## 1. Contraintes de base

- **Outil non officiel** : `mcp-auchan-drive` n'est ni affilié ni approuvé par Auchan.
  Usage strictement personnel, un seul compte (celui de l'utilisateur), pas de requêtage
  massif. Toute utilisation doit rester dans les limites d'un usage humain raisonnable.
- **Jamais de paiement automatisé** : le pipeline s'arrête au panier. La validation de la
  commande, le créneau et le paiement se font manuellement dans l'app Auchan, par
  l'utilisateur. C'est un principe de sécurité, pas une limite technique à contourner.
- **Session réelle** : le serveur MCP s'authentifie avec les cookies Chrome du profil
  `Default` de l'utilisateur. Il faut être connecté à `www.auchan.fr` dans Chrome et avoir
  visité le site récemment (cookie `datadome`), sinon requêtes 403 probables.
- **Navigateur** : Chrome (profil `Default`). Firefox non utilisé.
- **Node.js ≥ 20.19** requis par `package.json` du serveur (le README du serveur dit 18+ :
  c'est le package.json qui fait foi).
- **Dossier trusté** : la config projet `.vibe/` n'est chargée que si le dossier est
  trusté. Le mode `-p` ne le demande jamais : le wrapper passe donc `--trust`.

## 2. Architecture

```
courses.txt ──► courses.sh ──► vibe --trust -p "…" --agent courses
                                      │
                                      ▼
                        Agent Vibe « courses » (.vibe/agents/courses.toml)
                                      │  outils MCP : auchan_*
                                      ▼
                        Serveur MCP mcp-auchan-drive (stdio, Node)
                                      │  cookies Chrome, throttling
                                      ▼
                        www.auchan.fr ──► panier du compte utilisateur
                                      ▼
                        Rapport final ──► l'utilisateur vérifie et paie dans l'app
```

## 3. Structure du dépôt

```
AuchanVibe/
├── AGENTS.md                # règles de travail de l'agent (source de vérité secondaire)
├── PROJECT_CONTEXT.md       # cette spec
├── PLAN.md                  # plan ordonné du projet, cases à cocher
├── NOTES.md                 # justifications et constats
├── AUDIT-MCP.md             # journal vivant d'audit du code mcp-auchan-drive
├── README.md                # présentation et usage
├── courses.txt              # la liste de courses (créé par l'utilisateur, format section 4)
├── courses.sh               # wrapper : précondition-checks puis lancement de vibe (section 5)
├── .vibe/
│   ├── config.toml          # MCP `auchan` (stdio) + réglages projet
│   └── agents/courses.toml  # profil de l'agent courses (section 6)
└── mcp-auchan-drive/        # clone du serveur MCP tiers (audit obligatoire avant usage)
```

`mcp-auchan-drive/` reste un clone Git intact autant que possible : on tire les mises à
jour amont plutôt que de forker. Toute modification locale nécessaire (compatibilité,
parser cassé) est faite sur une branche locale dédiée (jamais poussée sans accord) et
documentée dans `NOTES.md`.

## 4. Format de `courses.txt`

Simple et lisible par un humain d'abord :

```text
# Lignes commençant par # ignorées. Une ligne = un besoin.
2x lait demi-écrémé 1L
1 paquet de pâtes penne
café moulu
500g de viande hachée 5%
# Substitution acceptée : oui par défaut ; écrire "strict" pour interdire
beurre doux strict
```

Règles pour l'agent :
- `2x`, `2 x`, `deux`… : quantité au début de ligne, sinon 1.
- Pas de marque imposée sauf si écrite : l'agent choisit le meilleur rapport
  qualité/prix/pertinence dans les résultats de recherche, en privilégiant le moins cher
  à caractéristiques équivalentes.
- L'agent peut ajuster au format disponible le plus proche (ex. « 1L » absent → 6×33cl
  si plus proche) et le signale dans le rapport.
- `strict` sur une ligne : pas de substitution, l'agent signale l'absence et passe à la
  suite.

## 5. Le wrapper `courses.sh`

Responsabilités exactes (garder ce script simple) :

1. Vérifier les préconditions : `mcp-auchan-drive/dist/index.js` existe (sinon indiquer
   `npm install && npm run build`), `courses.txt` existe et n'est pas vide.
2. Lancer : `vibe --trust -p "<prompt courses>" --agent courses --output text` depuis la
   racine du projet.
3. Le prompt programme contient : lire `courses.txt`, remplir le panier selon
   `PROJECT_CONTEXT.md` section 6.1, produire le rapport.

Le script n'analyse rien lui-même, ne touche pas aux cookies, et ne lance rien d'autre.

## 6. L'agent Vibe `courses`

### 6.1 Déroulé d'un run (workflow imposé)

1. `auchan_get_store` : vérifier qu'un drive est actif. Si aucun → stop avec un message
   clair (l'utilisateur sélectionne son drive dans son compte Auchan au préalable).
2. `auchan_get_cart` : capturer l'état initial du panier (pour le rapport, et pour ne pas
   toucher aux lignes existantes).
3. Pour chaque ligne de `courses.txt` : `auchan_search_product` → choisir le produit →
   `auchan_add_to_cart`. Si refus (rupture drive) : chercher un équivalent, sinon
   signaler.
4. `auchan_get_cart` final : vérifier le contenu et le total.
5. Rapport final (dans la sortie standard) : ajoutés / introuvables / substitutions /
   total, et rappel : « vérifie et paie dans l'app Auchan ».

### 6.2 Profil et garde-fous techniques

- Outils autorisés : les outils `auchan_*` et `read_file` (pour `courses.txt`). Tout le
  reste désactivé pour l'agent `courses` (bash, web, etc.) — via `enabled_tools` du profil
  d'agent si le format le permet, sinon via la ligne de commande du wrapper
  (`--enabled-tools`) et la relecture du format d'agent au moment de l'implémenter.
- Ne jamais appeler `auchan_debug_page_html` en usage normal (outil de diagnostic).
- Les erreurs d'un produit n'arrêtent pas le run : le run continue et le rapport liste
  les échecs.
- Un run ne doit pas dépasser la liste : pas de « panier complet » ni de suggestions
  d'achat non demandées (hormis la substitution autorisée).

## 7. Configuration Vibe (`.vibe/config.toml`)

```toml
[[mcp_servers]]
name = "auchan"
transport = "stdio"
command = "node"
args = ["/Users/valentin/Code/Tests/AuchanVibe/mcp-auchan-drive/dist/index.js"]
```

- Nom court `auchan` : les outils apparaissent sous la forme `auchan_search_product`, etc.
- Aucune variable d'environnement `AUCHAN_*` nécessaire : le serveur lit Chrome par
  défaut. `AUCHAN_BROWSER=firefox` et `AUCHAN_COOKIE` ne sont pas utilisés.
- Le dossier doit être trusté (`vibe` interactif une première fois, accepter ; le
  wrapper passe `--trust` ensuite).

## 8. Sécurité

- Les cookies de session ne transitent que entre le profil Chrome et le serveur MCP, en
  local. Ils ne doivent jamais apparaître dans un fichier, un log ou un message du projet.
- Le serveur MCP ne contacte que `www.auchan.fr` et `api-adresse.data.gouv.fr`
  (vérifié par audit, voir `AUDIT-MCP.md`). Tout changement après une mise à jour amont
  doit être re-vérifié avant relance.
- Ne jamais lancer le serveur MCP ou l'agent avec le flag `--yolo`/`--auto-approve` sur
  du code non audité.
- Risque account : rester sous un usage personnel (quelques dizaines de requêtes par run,
  espacées par le Throttler du serveur : ≥ 1 s entre requêtes).

## 9. Definition of done

- [ ] `./courses.sh` avec une liste de test remplit le panier du compte (vérifié par
      l'utilisateur dans l'app Auchan).
- [ ] Le rapport final distingue ajoutés / introuvables / substitutions, avec total.
- [ ] Le panier existait avant le run : ses lignes d'origine sont intactes.
- [ ] Aucun code de paiement ou de validation n'a été exécuté.
- [ ] L'agent `courses` n'a accès à aucun outil superflu.
- [ ] Audit du commit du serveur MCP en cours tracé dans `AUDIT-MCP.md`.

## 10. Évolutions possibles (sur demande explicite uniquement)

- Reprendre les courses précédentes (`auchan_get_orders`, `auchan_get_favorites`) pour
  préremplir une liste récurrente.
- Suggestions de promos sur les produits habituels (`auchan_search_promos`).
- Faire remonter les modifications nécessaires au serveur MCP vers le dépôt amont (PR).
- Skill Vibe dédiée en complément de l'agent (formats de listes avancés).
