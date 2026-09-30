# AuchanVibe

Remplissage automatique du panier Auchan Drive à partir d'une simple liste de courses,
via l'agent Vibe « courses » et le serveur MCP local `mcp-auchan-drive`.
L'IA prépare le panier ; la relecture, la validation et le paiement restent manuels
dans l'app Auchan.

## Usage (une fois installé)

```bash
./courses.sh
```

Puis : ouvrir l'app Auchan, vérifier le panier, valider et payer.

## Documents du projet

| Fichier | Rôle |
|---|---|
| `PROJECT_CONTEXT.md` | Spécification technique (source de vérité du projet) |
| `AGENTS.md` | Règles de travail de l'agent IA, dont l'audit obligatoire du code tiers |
| `PLAN.md` | Plan ordonné, cases à cocher au fil de l'avancement |
| `AUDIT-MCP.md` | Journal d'audit du serveur MCP + résumé de ses capacités |
| `NOTES.md` | Justifications et constats |

## Statut

Initialisation en cours — suivre `PLAN.md` (« Étape courante » en tête de fichier).
