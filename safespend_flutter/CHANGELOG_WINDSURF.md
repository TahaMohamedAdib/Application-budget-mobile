# CHANGELOG WINDSURF

## Phase 0 — Baseline et vérifications — 2026-07-23

### Statut

**BLOQUÉ — arrêt obligatoire en Phase 0.4.**

La première vague de corrections décrite en section B n'est pas présente dans
la révision courante. Aucun changement de code produit n'a été effectué et les
tâches T0 à T10 n'ont pas été commencées.

### Révision et état de travail

- Branche : `claude/fix-user-data-loading-6exEA`
- Révision : `c22904bf93f28fd5897366aa5bf376792927875f`
- Cette révision correspond aussi à `origin/main` au moment de la vérification.
- Changements préexistants laissés intacts :
  - `windows/flutter/generated_plugin_registrant.cc`
  - `windows/flutter/generated_plugins.cmake`
- Fichiers créés uniquement pour la Phase 0 :
  - `CHANGELOG_WINDSURF.md`
  - `MIGRATIONS.md`

### Phase 0.1 — Baseline Flutter

Environnement :

- Flutter `3.41.4` stable, révision `ff37bef603`
- Dart `3.11.1`

`flutter pub get` :

- **SUCCÈS**
- 1 package est abandonné : `flutter_markdown`
- 64 packages ont des versions plus récentes incompatibles avec les contraintes
  actuelles.

`flutter analyze --no-pub` :

- **568 issues existantes**
- 0 erreur
- 39 warnings
- 529 infos

Répartition exacte par règle :

| Règle | Nombre |
|---|---:|
| `curly_braces_in_flow_control_structures` | 62 |
| `deprecated_member_use` | 364 |
| `no_leading_underscores_for_local_identifiers` | 3 |
| `prefer_conditional_assignment` | 2 |
| `prefer_const_constructors` | 60 |
| `prefer_const_declarations` | 10 |
| `prefer_const_literals_to_create_immutables` | 3 |
| `prefer_final_fields` | 1 |
| `prefer_interpolation_to_compose_strings` | 5 |
| `unnecessary_brace_in_string_interps` | 15 |
| `unnecessary_cast` | 2 |
| `unnecessary_const` | 1 |
| `unnecessary_import` | 3 |
| `unnecessary_non_null_assertion` | 3 |
| `unnecessary_null_comparison` | 1 |
| `unused_element` | 12 |
| `unused_field` | 1 |
| `unused_import` | 5 |
| `unused_local_variable` | 15 |

Répartition exacte par fichier :

| Fichier | Nombre |
|---|---:|
| `lib/main.dart` | 18 |
| `lib/providers/app_provider.dart` | 34 |
| `lib/screens/account_screen.dart` | 9 |
| `lib/screens/accounts_screen.dart` | 15 |
| `lib/screens/all_subscriptions_screen.dart` | 4 |
| `lib/screens/auth_screen.dart` | 12 |
| `lib/screens/budgets_screen.dart` | 16 |
| `lib/screens/cash_on_hand_screen.dart` | 4 |
| `lib/screens/chat_widgets/message_bubble.dart` | 12 |
| `lib/screens/chat_widgets/suggestion_card.dart` | 2 |
| `lib/screens/chat_widgets/typing_indicator.dart` | 2 |
| `lib/screens/coach_screen.dart` | 29 |
| `lib/screens/daret_screen.dart` | 20 |
| `lib/screens/debt_screen.dart` | 33 |
| `lib/screens/goals_screen.dart` | 16 |
| `lib/screens/onboarding/aha_screen.dart` | 1 |
| `lib/screens/onboarding/hook_screen.dart` | 2 |
| `lib/screens/onboarding/language_selection_screen.dart` | 4 |
| `lib/screens/onboarding/preview_screen.dart` | 1 |
| `lib/screens/onboarding/setup_screen.dart` | 15 |
| `lib/screens/onboarding/welcome_screen.dart` | 9 |
| `lib/screens/personal_debts_screen.dart` | 15 |
| `lib/screens/plan_screen.dart` | 11 |
| `lib/screens/portfolio_screen.dart` | 76 |
| `lib/screens/settings_screen.dart` | 9 |
| `lib/screens/spending_screen.dart` | 8 |
| `lib/screens/today_screen.dart` | 65 |
| `lib/screens/transactions_screen.dart` | 21 |
| `lib/screens/wealth_screen.dart` | 8 |
| `lib/services/chat_service.dart` | 2 |
| `lib/services/image_service.dart` | 2 |
| `lib/services/secure_storage_service.dart` | 1 |
| `lib/services/stock_price_service.dart` | 2 |
| `lib/services/supabase_sync_service.dart` | 4 |
| `lib/theme/app_theme.dart` | 25 |
| `lib/widgets/add_transaction_modal.dart` | 23 |
| `lib/widgets/app_logo.dart` | 15 |
| `lib/widgets/app_picker_field.dart` | 6 |
| `lib/widgets/balance_chart.dart` | 10 |
| `lib/widgets/modern_chart.dart` | 4 |
| `lib/widgets/quick_actions_sheet.dart` | 3 |

Liste exacte des 39 warnings :

1. `lib/main.dart:2:8` — `unused_import` — `dart:io`
2. `lib/main.dart:276:8` — `unused_element` — `_openAddBillModal`
3. `lib/providers/app_provider.dart:1430:11` — `unused_local_variable` — `totalBalance`
4. `lib/providers/app_provider.dart:1438:11` — `unused_local_variable` — `totalBalance`
5. `lib/screens/accounts_screen.dart:813:10` — `unused_element` — `_buildTypeChip`
6. `lib/screens/auth_screen.dart:127:16` — `unused_element` — `_signInWithGoogle`
7. `lib/screens/auth_screen.dart:138:16` — `unused_element` — `_signInWithApple`
8. `lib/screens/coach_screen.dart:14:8` — `unused_import` — `shared_preferences`
9. `lib/screens/coach_screen.dart:602:31` — `unnecessary_cast`
10. `lib/screens/coach_screen.dart:603:29` — `unnecessary_cast`
11. `lib/screens/coach_screen.dart:742:8` — `unused_element` — `_addProject`
12. `lib/screens/coach_screen.dart:2801:10` — `unused_element` — `_fmtDate`
13. `lib/screens/daret_screen.dart:213:11` — `unused_local_variable` — `sourceAccount`
14. `lib/screens/daret_screen.dart:218:11` — `unused_local_variable` — `destAccount`
15. `lib/screens/personal_debts_screen.dart:11:8` — `unused_import` — `transaction.dart`
16. `lib/screens/personal_debts_screen.dart:611:53` — `unnecessary_non_null_assertion`
17. `lib/screens/plan_screen.dart:1655:12` — `unused_element` — `_accountIcon`
18. `lib/screens/portfolio_screen.dart:39:37` — `unused_field` — `_holdingHistories`
19. `lib/screens/portfolio_screen.dart:1066:11` — `unused_local_variable` — `allocation`
20. `lib/screens/portfolio_screen.dart:2204:7` — `unused_element` — `_HoldingCard`
21. `lib/screens/portfolio_screen.dart:3310:11` — `unused_local_variable` — `destItems`
22. `lib/screens/settings_screen.dart:23:15` — `unused_local_variable` — `isDark`
23. `lib/screens/spending_screen.dart:40:11` — `unused_local_variable` — `daysInMonth`
24. `lib/screens/today_screen.dart:18:8` — `unused_import` — `spending_screen.dart`
25. `lib/screens/today_screen.dart:19:8` — `unused_import` — `transactions_screen.dart`
26. `lib/screens/today_screen.dart:940:72` — `unnecessary_null_comparison`
27. `lib/screens/today_screen.dart:2758:19` — `unnecessary_non_null_assertion`
28. `lib/screens/today_screen.dart:2909:37` — `unused_local_variable` — `confirmed`
29. `lib/screens/today_screen.dart:2929:49` — `unnecessary_non_null_assertion`
30. `lib/screens/today_screen.dart:3265:8` — `unused_element` — `_showAllSubscriptions`
31. `lib/screens/transactions_screen.dart:76:15` — `unused_local_variable` — `totalExpenses`
32. `lib/screens/transactions_screen.dart:79:15` — `unused_local_variable` — `totalIncome`
33. `lib/screens/transactions_screen.dart:357:11` — `unused_local_variable` — `isDark`
34. `lib/screens/transactions_screen.dart:358:11` — `unused_local_variable` — `cf`
35. `lib/screens/transactions_screen.dart:459:11` — `unused_local_variable` — `yPadding`
36. `lib/screens/transactions_screen.dart:461:12` — `unused_element` — `formatYLabel`
37. `lib/screens/transactions_screen.dart:484:10` — `unused_element` — `_chartLegendDot`
38. `lib/screens/wealth_screen.dart:302:15` — `unused_local_variable` — `totalWeekSpending`
39. `lib/widgets/balance_chart.dart:10:7` — `unused_element` — `_kBlue`

Les 529 infos sont couvertes par les répartitions exactes par règle et par
fichier ci-dessus.

`flutter test --no-pub` :

- **ÉCHEC INITIAL**
- 1 test chargé, 0 réussi, 1 échoué.
- `test/widget_test.dart` est toujours le test compteur du template Flutter.
- `MyApp` lève `ProviderNotFoundException`, car le harness ne fournit pas
  `AppProvider` au `Selector` de `main.dart:102`.
- L'assertion qui cherche `Text("0")` échoue également, car SafeSpend n'est pas
  l'application compteur du template.

### Phase 0.2 — Vérification de chaque élément de la section B

| Élément annoncé comme déjà corrigé | Résultat sur `c22904bf` |
|---|---|
| Virement dans `addTransaction()` | **PASS** — source débitée et destination créditée (`app_provider.dart:691-725`). |
| Virement dans `deleteTransaction()` | **PASS** — source restaurée (`741-764`) et destination reprise (`765-775`). |
| Virement dans `updateTransaction()` | **ÉCHEC** — seuls les anciens/nouveaux comptes sources sont traités (`789-829`) ; aucun ancien/nouveau `toAccountId`. |
| `Transaction.goalId`, sérialisation et `_adjustLinkedGoal` | **ÉCHEC** — `goalId` est absent de `transaction.dart:3-102`, `_adjustLinkedGoal` n'existe pas et les quatre méthodes objectif/dette ne renseignent aucun lien (`app_provider.dart:1125-1281`). |
| Mapping et tolérance Supabase `goal_id` | **ÉCHEC** — absents de `_transactionToRow` (`supabase_sync_service.dart:535-551`) et `_rowToTransaction` (`553-567`). La garde existante concerne seulement `description`. |
| Migration `20260723000000_add_transaction_goal_id.sql` | **ÉCHEC BLOQUANT** — absente du dossier `supabase_migrations/` et de toutes les références Git disponibles. |
| `deleteCategory()` détache les transactions | **ÉCHEC** — la méthode retire seulement la catégorie (`app_provider.dart:1328-1334`). |
| `processSubscriptions()` préserve le type | **ÉCHEC** — la méthode force toujours `income` ou `expense` (`513-526`). |
| UUID dans les six méthodes financières citées | **ÉCHEC (0/6)** — timestamps aux lignes `1130`, `1179`, `1228`, `1275`, `1654` et `1696`. |
| Suppression de `getSafeToSpend*` | **ÉCHEC** — les méthodes existent encore (`1425-1441`). |
| `getBalanceForAccount(null)` | **PASS isolé** — exclut les investissements et ajoute le cash (`1475-1487`). |
| Tableau de bord « Solde disponible » et helper | **ÉCHEC** — `today_screen.dart:176-185` utilise encore `totalBalance`; `_getAccountBalance()` recalcule directement le solde (`2294-2301`). |
| i18n `safeToSpend` supprimée / `availableBalance` ajoutée | **ÉCHEC** — `safeToSpend` est encore dans les 16 langues et son getter ; `availableBalance` est absente. |
| Affichage conditionnel de `fees` | **PASS** — seulement pour `expense`, `withdrawal` et `transfer` (`add_transaction_modal.dart:214-229`). |
| Renommage `gold*` → `brand*` | **ÉCHEC** — 345 lignes dans 31 fichiers contiennent encore `gold`; `brandPrimary` est absent. |
| Palette `success`, `info`, `brandPrimary` | **ÉCHEC** — `app_colors.dart` conserve `gold*`; `success` et `info` valent tous deux `#0B715F`, au lieu des couleurs distinctes annoncées. |
| 24 doublons de couleur remplacés | **NON DÉMONTRÉ / ÉCHEC DU LOT** — 180 lignes contenant `Color(...)` subsistent hors de `lib/theme`. |
| Clés i18n mortes supprimées | **ÉCHEC** — `createDaretLabel`, `saveChangesLabel` et `yourSlotsLabel` ont chacune 17 occurrences. |
| Reformulations FR | **PASS sur les valeurs présentes** — `Conseiller`, `dépôt du versement`, `Engagement restant`, `Tontine`, `Retirer en espèces — ajoute à Espèces`, `Conseiller financier`. |
| Appel redondant `loadFromSupabase()` retiré | **ÉCHEC** — chargement principal `main.dart:79-87`, puis second appel dans `MainScreen.initState` (`211-220`). |

Conclusion : quelques sous-points sont conformes, mais les corrections
financières centrales et la migration annoncée sont absentes. La section B ne
peut pas être considérée comme vérifiée.

### Phase 0.3 — Migrations

Voir `MIGRATIONS.md`.

Le dossier contient trois migrations plus anciennes. La garde défensive de
`_saveTransactionRemote()` pour `transactions.description` est bien présente
dans `supabase_sync_service.dart:583-602`, ce qui constitue un indice de dérive
de schéma. Aucune migration ne crée cependant `goal_id`.

### Décision et limites connues

Application stricte de la règle Phase 0.4 : arrêt avant T0, sans improviser ni
réimplémenter la section B.

La future migration Daret décrite en T4 est également sous-spécifiée : aucune
table Daret n'existe dans les migrations, les scripts racine ou le service de
synchronisation. Les Darets sont uniquement persistés dans SharedPreferences.

Aucun commit n'est créé : la Phase 0 est bloquée avant la première tâche T0 et
la révision correcte contenant B doit encore être fournie, ou le périmètre doit
être explicitement élargi.

### Action humaine requise avant reprise

Une des deux décisions suivantes est nécessaire :

1. fournir la révision qui contient réellement toute la section B ;
2. autoriser explicitement une phase préalable qui implémente les corrections B
   manquantes sur `c22904bf`, avant de reprendre T0 à T10.

## Préphase autorisée — assainissement du test template — 2026-07-23

Autorisation humaine reçue pour implémenter la section B manquante avant T0.

### Fichier modifié

- `test/widget_test.dart`

### Changement

Le test compteur Flutter, sans rapport avec SafeSpend et impossible à construire
sans ses providers, a été remplacé par un smoke test déterministe du modèle
`Transaction`. Il vérifie que `totalWithFees` additionne correctement le montant
et les frais bancaires.

### Décision

Ce changement est isolé avant le code produit afin de rétablir une suite verte.
Il ne remplace pas le filet financier T0, qui sera ajouté après restauration de
la section B.

### Vérifications

- `flutter analyze --no-pub` : **568 issues**, identique à la baseline
  (39 warnings, 529 infos, 0 erreur).
- `flutter test --no-pub` : **1 test réussi, 100 % vert**.

### Limites et étapes humaines

- Aucun comportement produit modifié.
- Aucune étape humaine supplémentaire.

## Préphase B1 — invariants financiers et liaison objectif — 2026-07-23

### Statut

**TERMINÉ.**

L'autorisation humaine d'implémenter la section B manquante sur `c22904bf`
permet de lever le blocage de la Phase 0.4. Ce lot couvre uniquement la partie
financière et sa migration ; les éléments UI/thème/i18n de B sont traités dans
le lot B2 suivant.

### Fichiers modifiés

- `lib/models/transaction.dart`
- `lib/providers/app_provider.dart`
- `lib/services/supabase_sync_service.dart`
- `lib/widgets/add_transaction_modal.dart`
- `supabase_migrations/20260723000000_add_transaction_goal_id.sql`
- `MIGRATIONS.md`
- `CHANGELOG_WINDSURF.md`

### Changements

- `updateTransaction()` reprend désormais l'effet de l'ancien compte
  destinataire d'un virement, applique le nouveau et synchronise chaque compte
  affecté une seule fois.
- `Transaction.goalId` est sérialisé localement, envoyé sous `goal_id` à
  Supabase et préservé lors de l'édition générique d'une transaction.
- Les quatre flux objectif/dette renseignent `goalId`. Leur suppression ou
  modification ajuste l'entité liée via `_adjustLinkedGoal()`.
- Les six flux financiers imposés utilisent des UUID v4 au lieu d'identifiants
  timestamp incompatibles avec PostgreSQL UUID.
- `deleteCategory()` détache les transactions concernées sans modifier leurs
  soldes ni perdre leurs autres champs, puis les resynchronise.
- `processSubscriptions()` conserve le type exact du template, notamment
  `daret_contribution` et `goal_contribution`.
- `personal_debt_return` est traité symétriquement comme une sortie dans les
  chemins création/modification/suppression et dans le calcul du cash.
- Le constructeur `AppProvider(autoLoad: false)` fournit une seam minimale et
  optionnelle aux tests ; le comportement de production reste `autoLoad: true`.
- La reprise Supabase retire successivement `description` ou `goal_id` seulement
  lorsque PostgreSQL signale précisément l'absence de la colonne. Toute autre
  erreur est relancée.

### Décisions

- `_adjustLinkedGoal()` applique un plancher à zéro sans plafonner à la cible,
  afin de restituer exactement les montants déjà autorisés par les flux
  existants.
- La migration utilise une FK nullable
  `transactions.goal_id → public.goals(id)` avec `ON DELETE SET NULL`.
- Le contournement par reconstruction directe dans `deleteCategory()` est
  conservé jusqu'à T7, car le `copyWith` actuel ne sait pas effacer un nullable.

### Checklist financière complète

- Virements création/modification/suppression : **PASS**.
- Objectifs, contributions et modification par delta : **PASS**.
- Dettes et retours de dette personnelle, lien `goalId`, UUID : **PASS**.
- Suppression de catégorie sans variation de solde : **PASS**.
- Récurrents : type préservé et second traitement idempotent : **PASS**.
- Salaires automatiques : comportement inchangé et idempotence couverte :
  **PASS**.
- Solde disponible : investissements exclus, cash inclus : **PASS**.

### Vérifications

- `flutter analyze` : **568 issues**, identique à la baseline
  (39 warnings, 529 infos, 0 erreur).
- `flutter test` : **15 tests réussis, 100 % vert**.
- Diff de `add_transaction_modal.dart` contrôlé : une seule ligne fonctionnelle,
  la préservation de `goalId`.

### Limites et étapes humaines

- Appliquer
  `supabase_migrations/20260723000000_add_transaction_goal_id.sql` en suivant
  l'ordre de `MIGRATIONS.md`.
- Tant que la migration n'est pas appliquée, la reprise compatible sauvegarde la
  transaction sans `goal_id`; une sauvegarde ultérieure sera nécessaire pour
  rétroalimenter le lien distant.
- Les anciennes transactions dont l'identifiant est un timestamp ne sont pas
  migrées automatiquement.
- Le service envoie actuellement `fees` alors que les scripts de schéma racine
  déclarent `fee_amount`; cet écart préexistant est documenté mais hors du lot
  B autorisé.
