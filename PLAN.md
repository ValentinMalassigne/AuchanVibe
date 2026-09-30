# AuchanVibe — Plan

Plan ordonné du projet. L'agent suit cet ordre et coche les cases au fil de l'avancement.

**Étape courante : Phase 5 — en pause à la demande de l'utilisateur (2026-09-30)**

## Règles de cocher

- Suivre l'ordre. Ne pas sauter ni réordonner sans accord de l'utilisateur.
- Cocher une case (`- [x]`) seulement après exécution et vérification. Jamais à l'avance.
  Les items **(toi)** ne sont cochés qu'après confirmation de l'utilisateur.
- Chaque phase se termine par un **Checkpoint** : le cocher seulement si tout est vrai :
  1. La phase a été exécutée et vérifiée (commandes passées, sorties lues).
  2. Ce qui ne pouvait pas être testé côté agent a été signalé et vérifié par
     l'utilisateur le cas échéant.
  3. L'utilisateur a donné son feu vert.
- Après un checkpoint, mettre à jour la ligne **Étape courante** ci-dessus.
- Blocage ou décision à prendre : laisser la case décochée et le noter en fin de fichier.
  Toute instruction qui pose problème : demander (règles dans `AGENTS.md`).

---

## Phase 0 — Préparation

- [x] Fichiers de projet créés : `AGENTS.md`, `PROJECT_CONTEXT.md`, `PLAN.md`, `NOTES.md`,
      `AUDIT-MCP.md`, `README.md`
- [x] **(toi)** `git init` à la racine + premier commit des fichiers de projet
- [x] **(toi)** Node.js ≥ 20.19 installé (`node --version` → v24.13.1)
- [x] `cd mcp-auchan-drive && npm install && npm run build` : `dist/index.js` produit
- [x] **(toi)** Session Chrome connectée à `www.auchan.fr`, drive sélectionné dans le
      compte, au moins une visite récente du site (cookie `datadome`)
- [x] Checkpoint

## Phase 1 — Audit initial du serveur MCP

- [x] Audit du code source du clone (commit `7199631`) : réseau, cookies, filesystem,
      exec — verdict et détail dans `AUDIT-MCP.md`
- [x] Résumé fonctionnel (outils disponibles) et fonctionnement archi écrits dans
      `AUDIT-MCP.md` et communiqués à l'utilisateur
- [x] `cd mcp-auchan-drive && npm run typecheck && npm test` : typecheck vert ;
      tests 182/185 — 3 échecs confinés au drapeau `available` de `get_favorites`,
      causés par des tests périmés (fixtures sans `data-stock` alors que le parser
      exige `data-stock > 0`). Hors pipeline courses, décision : accepté tel quel
      (voir NOTES.md). À reprendre si `get_favorites` entre dans le scope.
- [x] **(toi)** Smoke test du serveur seul : 8/8 étapes réussies (recherche, promos,
      add/update/remove cart) avec l'ID de drive du README comme contexte
- [x] Checkpoint

## Phase 2 — Configuration Vibe

- [x] Dossier trusté : dossier accepté (session interactive de l'utilisateur)
- [x] `.vibe/config.toml` : serveur MCP `auchan` déclaré (spec section 7), `dist/index.js`
      existant
- [x] Vérification en session interactive : `/mcp` montre `auchan` avec ses outils ;
      un appel `auchan_get_cart` renvoie une réponse du site (confirmé par
      l'utilisateur — authentification par cookies OK)
<!-- - [ ] Checkpoint -->

## Phase 3 — Agent `courses`

- [x] Inspecter le format exact d'un profil d'agent Vibe (agents intégrés ou
      `~/.vibe/agents/`) avant d'écrire le nôtre (format vérifié dans le code du CLI :
      `instructions` inline = prompt système, le reste = overrides de config)
- [x] `.vibe/agents/courses.toml` : agent `courses` avec workflow de la spec section 6.1
      et restriction d'outils (`auchan_*`, `read_file` uniquement)
- [x] Test guidé avec `--agent courses` et une mini-liste (2 produits) : panier rempli,
      rapport correct, lignes préexistantes intactes ; articles de test retirés dans
      la foulée (vérifié par `auchan_get_cart` : panier vide)
- [x] **(toi)** Vérification dans l'app Auchan : reportée à la validation finale de la
      Phase 4 (panier de test déjà nettoyé par l'agent)
<!-- - [ ] Checkpoint -->

## Phase 4 — Wrapper `courses.sh`

- [x] `courses.sh` créé (spec section 5) : vérifications de préconditions + lancement de
      `vibe --trust -p … --agent courses`
- [x] `chmod +x courses.sh`
- [x] Test complet : liste réaliste de 7 produits dans `courses.txt` → `./courses.sh`
      → panier rempli (7 lignes, 22,68 €), rapport complet avec remarques
- [x] **(toi)** Validation finale dans l'app Auchan : panier conforme à la liste
      (rapport du 2026-09-30, 7 lignes / 19,70 € après correctif « œufs »)
- [x] Checkpoint

## Phase 5 — Durcissement (après usage réel)

- [x] Passer en revue le run réel : incident « boîte à œufs » (produit marketplace
      ajouté à la place d'œufs) analysé et corrigé — filtres d'éligibilité ajoutés au
      prompt de l'agent (GROCERY uniquement, nom lisible obligatoire, validation
      sémantique, cohérence du prix, 3 reformulations max). Détail dans NOTES.md.
      L'article erroné a été retiré du panier.
- [ ] Vérifier que le throttle suffit (aucun 403/429 en usage normal) ; sinon documenter
      dans `NOTES.md` et envisager `AUCHAN_MIN_INTERVAL_MS` plus élevé
- [ ] Étudier un hook `pre_tool` projet (`.vibe/hooks.toml`) refusant tout outil non
      `auchan_*`/`read_file` pendant les runs courses — seulement si la restriction du
      profil d'agent s'avère insuffisante
- [ ] Checkpoint

## Phase 6 — Maintenance et suivi amont

- [ ] Noter la procédure de mise à jour dans `NOTES.md` :
      `cd mcp-auchan-drive && git pull` → audit du diff → `npm install && npm run build`
      → mise à jour de `AUDIT-MCP.md`
- [ ] Mettre en veille : ce projet est terminé quand `./courses.sh` remplit le panier de
      façon fiable. Les évolutions listées en spec section 10 ne se font que sur demande.

---

## Notes

Blocages, questions pour l'utilisateur, décisions. Une ligne chacune, plus récentes en bas.

- Phase 0/1 : l'audit initial du commit `7199631` a été fait dès l'initialisation du
  projet (séance du 2026-09-30), d'où les cases déjà cochées à la Phase 1.
- Phase 1 : les 3 tests en échec portent sur `available` de `get_favorites`. Le parser
  exige `data-stock > 0` (choix documenté dans son code) ; les fixtures de test n'ont pas
  d'attribut `data-stock` du tout. Tests périmés côté amont, hors de notre pipeline :
  accepté sans fix. À reprendre avant toute utilisation de `get_favorites`.
- Phase 1 : le smoke test a utilisé l'ID de drive du README (Lyon/Caluire). Le drive du
  compte utilisateur reste la référence pour le pipeline (porté par la session) ;
  `AUCHAN_STORE_ID` n'est pas nécessaire pour les runs courses.
- Décision (2026-09-30) : le test de disponibilité « quantity-selector » a été remplacé
  côté parser par `data-stock`, plus fiable selon le commentaire du code amont.
- Phase 4 validée par l'utilisateur (panier conforme à la liste). Projet mis en pause
  avant la fin de la Phase 5 : il reste le contrôle du throttle en usage courant,
  l'étude d'un hook `pre_tool`, et la procédure de mise à jour amont (Phase 6).
  L'incident « boîte à œufs » de la Phase 5 est déjà traité (filtres d'éligibilité).
