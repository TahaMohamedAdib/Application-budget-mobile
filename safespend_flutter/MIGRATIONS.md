# Registre des migrations Supabase

## Statut

**Préphase B en cours — SQL préparé, aucune migration exécutée par Codex.**

La migration `goal_id` manquante sur `c22904bf` a été restaurée dans le dépôt.
Son application en production reste une étape humaine.

## Migrations présentes

Ordre chronologique des fichiers avec préfixe timestamp :

- [ ] `20260415000000_storage_sync_trigger.sql` — appliquée en production :
  **À VÉRIFIER** — crée `public.app_config`, ajoute
  `profiles.avatar_url` et `transactions.receipt_url`, puis installe un trigger
  sur `storage.objects` pour associer les uploads des buckets `avatars`,
  `receipts` et `logos` aux tables concernées.
- [ ] `20260415010000_add_account_tracking_and_holding_funding.sql` — appliquée
  en production : **À VÉRIFIER** — ajoute et rétroalimente
  `accounts.added_at`, puis ajoute `source_account_id`,
  `affects_source_balance` et `source_amount` à `stock_holdings`.
- [ ] `20260723000000_add_transaction_goal_id.sql` — appliquée en production :
  **NON** — ajoute `transactions.goal_id`, clé étrangère UUID nullable vers
  `public.goals(id)` avec `ON DELETE SET NULL`, ainsi qu'un index.
- [ ] `20260723010000_secure_financial_storage.sql` — appliquée en production :
  **NON** (T2) — passe les buckets `receipts` et `logos` en privé avec
  `file_size_limit` et `allowed_mime_types`, active RLS sur `storage.objects` et
  installe des politiques propriétaire (`auth.uid()` = premier segment du
  chemin), puis neutralise le trigger legacy pour les buckets financiers afin
  qu'il ne devine plus le reçu/compte d'après l'ordre d'upload.
- [ ] `20260723090000_add_transaction_daret_id.sql` — appliquée en production :
  **NON** (T4) — ajoute `transactions.daret_id` (UUID nullable, **sans** clé
  étrangère) + index. Décision d'architecture actée : les darets restent
  persistés côté client (SharedPreferences) ; aucune table Postgres `darets`
  n'est créée, donc pas de FK. Le client tolère l'absence de la colonne tant
  que la migration n'est pas appliquée.
- [ ] `20260723100000_add_updated_at_sync.sql` — appliquée en production :
  **NON** (T5) — ajoute `updated_at timestamptz NOT NULL DEFAULT now()` sur
  chaque table synchronisée existante + un trigger `BEFORE UPDATE` commun
  (`public.set_updated_at`). Idempotent ; ignore les tables absentes.

Fichier sans préfixe timestamp :

- [ ] `ai_conversations_and_projects.sql` — appliquée en production :
  **À VÉRIFIER** — crée `ai_conversations`, `ai_projects`, leurs index, clés
  étrangères vers `auth.users` et politiques RLS.

L'ordre d'exécution de `ai_conversations_and_projects.sql` ne peut pas être
déduit de son nom. Il doit être confirmé manuellement.

## Indice de dérive de schéma

`SupabaseSyncService._saveTransactionRemote()` tente d'abord l'upsert avec
`transactions.description` et `transactions.goal_id`. Si Supabase signale que
l'une de ces colonnes est absente, le client la retire et réessaie ; toute autre
erreur est relancée. La boucle est bornée aux deux colonnes compatibles.

La colonne existe dans `supabase_complete_setup.sql` et
`supabase_migration_flutter.sql`, mais aucune migration timestampée du dossier
ne l'ajoute. Cela indique qu'au moins un environnement peut ne pas avoir reçu
toutes les évolutions de schéma.

## Tables synchronisées observées

Le service de synchronisation utilise :

- `profiles`
- `accounts`
- `transactions`
- `goals`
- `recurring_rules`
- `stock_holdings`
- `user_categories`
- `ai_conversations`
- `ai_projects`

## Écarts bloquants pour les migrations futures

- Il n'existe aucune table Supabase Daret dans `supabase_migrations/`,
  `supabase_complete_setup.sql`, `supabase_migration_flutter.sql` ou
  `SupabaseSyncService`.
- Les Darets sont uniquement persistés dans SharedPreferences sous la clé
  `darets`.
- **Décision (T4)** : `transactions.daret_id` est ajouté **sans** FK (colonne
  UUID nullable + index). Option retenue par l'humain : les darets restent
  locaux (SharedPreferences), pas de table Postgres `darets`, pas de
  synchronisation cloud des darets. L'état d'idempotence des payouts
  (`Daret.lastPayoutMonthProcessed`) est persisté localement.

## À exécuter maintenant, dans cet ordre

Ordre provisoire à confirmer par l'humain avant exécution :

1. vérifier si `20260415000000_storage_sync_trigger.sql` est déjà appliquée ;
2. vérifier si
   `20260415010000_add_account_tracking_and_holding_funding.sql` est déjà
   appliquée ;
3. appliquer `20260723000000_add_transaction_goal_id.sql` ;
4. appliquer `20260723010000_secure_financial_storage.sql` (T2) — après quoi les
   anciennes URLs publiques cessent d'être servies ; les nouveaux uploads
   stockent un chemin d'objet signé à la demande ;
5. appliquer `20260723090000_add_transaction_daret_id.sql` (T4) — colonne
   nullable sans FK ; jusque-là le client sauvegarde la transaction sans
   `daret_id` grâce à la garde défensive ;
6. appliquer `20260723100000_add_updated_at_sync.sql` (T5) — colonnes
   `updated_at` + trigger sur les tables synchronisées ;
7. positionner manuellement `ai_conversations_and_projects.sql`, dont le nom ne
   fournit aucun ordre chronologique.

Les migrations T4 et T5 seront ajoutées plus tard à cette liste. Conserver les
gardes défensives côté client pendant toute la transition. La décision
d'architecture de persistance Supabase des Darets reste nécessaire avant T4.
