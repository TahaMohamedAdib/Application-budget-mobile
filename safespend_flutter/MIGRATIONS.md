# Registre des migrations Supabase

## Statut

**BLOQUÉ — aucune migration ne doit être exécutée à partir de cet état.**

La migration annoncée comme déjà écrite,
`20260723000000_add_transaction_goal_id.sql`, est absente du checkout
`c22904bf` et de toutes les références Git disponibles.

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

Fichier sans préfixe timestamp :

- [ ] `ai_conversations_and_projects.sql` — appliquée en production :
  **À VÉRIFIER** — crée `ai_conversations`, `ai_projects`, leurs index, clés
  étrangères vers `auth.users` et politiques RLS.

L'ordre d'exécution de `ai_conversations_and_projects.sql` ne peut pas être
déduit de son nom. Il doit être confirmé manuellement.

## Indice de dérive de schéma

`SupabaseSyncService._saveTransactionRemote()`, dans
`lib/services/supabase_sync_service.dart:583-602`, tente d'abord l'upsert avec
`transactions.description`. Si Supabase signale que cette colonne est absente,
le client retire `description` et réessaie ; toute autre erreur est relancée.

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

- Aucune migration disponible ne crée `transactions.goal_id`.
- Il n'existe aucune table Supabase Daret dans `supabase_migrations/`,
  `supabase_complete_setup.sql`, `supabase_migration_flutter.sql` ou
  `SupabaseSyncService`.
- Les Darets sont uniquement persistés dans SharedPreferences sous la clé
  `darets`.
- La FK prévue par T4,
  `transactions.daret_id REFERENCES <table_darets>(id)`, exige donc une décision
  d'architecture préalable : création et synchronisation d'une table Daret, ou
  absence explicite de FK.

## À exécuter maintenant, dans cet ordre

**Rien pour le moment.**

Avant toute exécution SQL :

1. résoudre l'écart de la section B et restaurer la migration `goal_id` ;
2. confirmer quelles migrations existantes sont déjà appliquées en production ;
3. décider de l'architecture de persistance Supabase des Darets ;
4. reconstruire l'ordre final après création des migrations T4 et T5 ;
5. conserver les gardes défensives côté client pendant la transition.

