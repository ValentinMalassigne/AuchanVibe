# AuchanVibe — Plan

Plan ordonné du projet. L'agent suit cet ordre et coche les cases au fil de l'avancement.

**Étape courante : Phase 2**

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

- [ ] Dossier trusté : lancer `vibe` une première fois dans le dossier et accepter la
      confiance (ou cocher la case de trust à l'invite)
- [ ] `.vibe/config.toml` : serveur MCP `auchan` déclaré (spec section 7), `dist/index.js`
      existant
- [ ] Vérification en session interactive : `/mcp` montre `auchan` avec ses outils ;
      un appel `auchan_get_store` ou `auchan_get_cart` renvoie une réponse du site
      (authentification par cookies OK)
- [ ] Checkpoint

## Phase 3 — Agent `courses`

- [ ] Inspecter le format exact d'un profil d'agent Vibe (agents intégrés ou
      `~/.vibe/agents/`) avant d'écrire le nôtre
- [ ] `.vibe/agents/courses.toml` : agent `courses` avec workflow de la spec section 6.1
      et restriction d'outils (`auchan_*`, `read_file` uniquement)
- [ ] Test guidé en session interactive avec `--agent courses` et une mini-liste de 2-3
      produits : le panier se remplit, le rapport est correct
- [ ] **(toi)** Vérification dans l'app Auchan : les bonnes lignes au bon drive,
      lignes préexistantes intactes ; puis retrait des articles de test
- [ ] Checkpoint

## Phase 4 — Wrapper `courses.sh`

- [ ] `courses.sh` créé (spec section 5) : vérifications de préconditions + lancement de
      `vibe --trust -p … --agent courses`
- [ ] `chmod +x courses.sh`
- [ ] Test complet : liste réaliste dans `courses.txt` → `./courses.sh` → panier rempli,
      rapport complet
- [ ] **(toi)** Validation finale dans l'app Auchan et retrait/ajustement manuel si besoin
- [ ] Checkpoint

## Phase 5 — Durcissement (après usage réel)

- [ ] Passer en revue le run réel : faux positifs de recherche, produits refusés,
      substitutions douteuses → ajuster le prompt de l'agent
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
- `COMPATIBILITY.md` n'est pas créé : pas de cible de compatibilité navigateur dans ce
  projet. Son équivalent « journal vivant » est `AUDIT-MCP.md` (suivi du code tiers).
- Phase 1 : les 3 tests en échec portent sur `available` de `get_favorites`. Le parser
  exige `data-stock > 0` (choix documenté dans son code) ; les fixtures de test n'ont pas
  d'attribut `data-stock` du tout. Tests périmés côté amont, hors de notre pipeline :
  accepté sans fix. À reprendre avant toute utilisation de `get_favorites`.
- Phase 1 : le smoke test a utilisé l'ID de drive du README (Lyon/Caluire). Le drive du
  compte utilisateur reste la référence pour le pipeline (porté par la session) ;
  `AUCHAN_STORE_ID` n'est pas nécessaire pour les runs courses.
- Décision (2026-09-30) : le test de disponibilité « quantity-selector » a été remplacé
  côté parser par `data-stock`, plus fiable selon le commentaire du code amont.
