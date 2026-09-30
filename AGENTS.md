# AuchanVibe — Instructions pour l'agent IA

## Source de vérité
Avant toute chose, lire `PROJECT_CONTEXT.md` en entier. Il fait autorité et l'emporte sur
tes habitudes et tes valeurs par défaut. Si ce fichier et la spec se contredisent, ou si la
spec est ambiguë, t'arrêter et demander à l'utilisateur. Ne jamais trancher seul en silence.

## Quand une instruction pose problème
Si une instruction de `AGENTS.md`, `PROJECT_CONTEXT.md` ou `AUDIT-MCP.md` te semble
impossible à suivre, floue, contradictoire, obsolète ou nuisible au projet (elle bloque une
fonctionnalité, elle contredit une autre règle, ou une option clairement meilleure existe),
t'arrêter et demander l'avis de l'utilisateur. Ne pas l'ignorer, la réinterpréter ni la
contourner en silence. Expliquer le problème en quelques lignes, proposer une ou des
options avec leurs compromis, et attendre la réponse. Si l'utilisateur décide de changer
l'instruction, proposer la formulation exacte. Ne pas modifier `AGENTS.md` ou
`PROJECT_CONTEXT.md` soi-même sans demande explicite.

## Le projet en bref
Un assistant de courses : l'utilisateur écrit une liste dans `courses.txt`, lance
`./courses.sh`, et un agent Vibe dédié (`courses`) remplit le panier Auchan Drive de son
compte via le serveur MCP local `mcp-auchan-drive` (dans `mcp-auchan-drive/`). L'utilisateur
relit ensuite le panier dans l'app Auchan, valide la commande et paie lui-même. Le paiement
et la validation ne sont jamais automatisés.

## Règle d'audit du code `mcp-auchan-drive` (obligatoire)
Le dépôt `mcp-auchan-drive/` est un projet open source tiers : l'utilisateur n'en est pas le
mainteneur et n'en garantit pas la fiabilité. En conséquence :

- **Avant d'utiliser une fonctionnalité du serveur** (un outil MCP, un module de `src/`),
  lire le code qui l'implémente dans `mcp-auchan-drive/src/`. Ne pas se fier uniquement au
  README.
- **Avant d'utiliser une fonctionnalité d'une nouvelle version** : après un `git pull`
  (ou tout changement de commit), auditer le diff (`git log HEAD..origin/main`,
  `git diff <ancien>..<nouveau> -- src/ scripts/`) avant tout usage, en particulier tout
  nouveau domaine réseau, fichier lu/écrit, ou dépendance ajoutée dans `package.json`.
- **Journaliser** chaque audit dans `AUDIT-MCP.md` : commit audité, périmètre lu, verdict,
  risques. Ce fichier est un journal vivant : mettre à jour l'entrée existante plutôt que
  d'en créer une nouvelle pour un même commit.
- En cas de doute sur un bout de code (exfiltration possible, comportement inattendu),
  ne pas utiliser la fonctionnalité et en avertir l'utilisateur.
- Le sous-dossier `mcp-auchan-drive/tools/` (pont Ollama) n'est pas utilisé par ce projet
  et n'est pas audité. Ne pas s'en servir sans audit préalable complet.

## Périmètre de l'agent `courses`
Quand tu opères comme agent `courses` (remplissage du panier) :

- Ne jamais tenter de payer, valider une commande, réserver un créneau, ni modifier le
  compte ou les données personnelles. Le serveur MCP ne l'expose pas : ne cherche pas à le
  contourner (pas de `debug_page_html` sur des URLs de paiement, pas de requêtes brutes).
- Travailler uniquement à partir de la liste `courses.txt`. Ne rien ajouter qui n'y figure
  pas, sauf substitution explicite (produit indisponible → équivalent le plus proche),
  signalée dans le rapport final.
- Le drive actif est celui du compte Auchan (déjà sélectionné). Ne pas changer de drive
  sauf demande explicite dans la liste.
- Produire en fin de run un rapport clair : produits ajoutés (nom, quantité, prix),
  introuvables, substitutions, total du panier.
- Respecter le rythme du serveur : pas d'appels en parallèle vers l'API Auchan (le
  Throttler du serveur sérialise, mais ne pas empiler les retries manuels). En cas de 403/429
  répétés (anti-bot DataDome), s'arrêter et le signaler plutôt que d'insister.

## Secrets et données sensibles
- Les cookies de session Auchan (lark-session, connect.sid…) sont lus localement par le
  serveur MCP depuis le profil Chrome. **Ne jamais** copier, afficher, journaliser ou
  committer une valeur de cookie dans un fichier du projet, une sortie de commande ou un
  message.
- `courses.txt` contient des informations personnelles sans caractère secret : il peut
  être commité ou non, au choix de l'utilisateur. Aucune autre donnée de compte ne doit
  finir dans un fichier committé.
- Ne pas toucher à `~/.vibe/.env` ni aux fichiers `.env` : ne jamais les lire ni les écrire.

## Vérification
- Ne jamais affirmer qu'une fonctionnalité marche sans l'avoir exécutée. Ce qui ne peut
  pas être testé ici (panier visible dans l'app Auchan, paiement, rendu du site) doit être
  explicitement signalé et vérifié par l'utilisateur.
- Après toute modification de `mcp-auchan-drive/` : `npm run typecheck` puis `npm test`
  dans ce dossier avant de considérer le travail terminé.
- Après toute modification de la config Vibe (`.vibe/`), la recharger (`/reload` en
  session interactive ou relancer `vibe`) avant de conclure qu'elle fonctionne.

## Commandes usuelles
```bash
./courses.sh                        # lance le remplissage du panier (une fois installé)
cd mcp-auchan-drive && npm run build    # recompiler le serveur MCP après un changement
cd mcp-auchan-drive && npm test         # tests du serveur (Vitest)
cd mcp-auchan-drive && npm run typecheck
vibe --trust                         # session interactive Vibe avec la config projet chargée
```

## Non-demandé, non-fait
Pas de fonctionnalité, fichier, dépendance ou refactor au-delà de ce que la spec
demande. Les évolutions possibles sont listées en fin de `PROJECT_CONTEXT.md` et ne
se font que sur demande explicite.
