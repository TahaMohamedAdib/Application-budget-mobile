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

## Préphase B2 — solde disponible, thème, i18n et chargement — 2026-07-23

### Statut

**TERMINÉ.**

La section B annoncée par le plan est désormais entièrement présente. T0 peut
commencer.

### Fichiers modifiés

- `lib/providers/app_provider.dart`
- `lib/main.dart`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/translations_core.dart`
- `lib/l10n/translations_extra.dart`
- `lib/theme/app_colors.dart`
- `lib/theme/app_theme.dart`
- `lib/screens/account_screen.dart`
- `lib/screens/accounts_screen.dart`
- `lib/screens/all_subscriptions_screen.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/budgets_screen.dart`
- `lib/screens/cash_on_hand_screen.dart`
- `lib/screens/chat_widgets/chat_input_bar.dart`
- `lib/screens/chat_widgets/message_bubble.dart`
- `lib/screens/coach_screen.dart`
- `lib/screens/daret_screen.dart`
- `lib/screens/debt_screen.dart`
- `lib/screens/goals_screen.dart`
- `lib/screens/onboarding/aha_screen.dart`
- `lib/screens/onboarding/hook_screen.dart`
- `lib/screens/onboarding/language_selection_screen.dart`
- `lib/screens/onboarding/preview_screen.dart`
- `lib/screens/onboarding/setup_screen.dart`
- `lib/screens/onboarding/welcome_screen.dart`
- `lib/screens/personal_debts_screen.dart`
- `lib/screens/plan_screen.dart`
- `lib/screens/portfolio_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/spending_screen.dart`
- `lib/screens/today_screen.dart`
- `lib/screens/transactions_screen.dart`
- `lib/screens/wealth_screen.dart`
- `lib/widgets/add_transaction_modal.dart`
- `lib/widgets/app_picker_field.dart`
- `CHANGELOG_WINDSURF.md`

### Changements

- Les méthodes mortes et incorrectes `getSafeToSpendToday()` et
  `getSafeToSpendMonth()` ont été supprimées.
- La carte principale affiche la chaîne localisée `availableBalance` et délègue
  son montant à `getBalanceForAccount(selectedAccountId)`. Sans filtre de
  compte, le calcul exclut les investissements et inclut le cash.
- `availableBalance` est présent dans les 16 langues ; `safeToSpend` a disparu.
- Les clés réellement mortes `createDaretLabel`, `saveChangesLabel` et
  `yourSlotsLabel` ainsi que leurs getters ont été supprimés.
- Tous les identifiants, helpers et commentaires `gold*` ont été renommés en
  `brand*` dans `lib/`, sans modifier les couleurs codées en dur hors du lot
  explicitement autorisé.
- La palette est désormais distincte :
  `brandPrimary=#0B715F`, `success=#22C55E`, `info=#3B82F6`.
- Les 24 littéraux sémantiques ciblés ont été remplacés par les constantes du
  thème : 4 succès, 15 informations, 1 erreur et 4 couleurs primaires.
- L'appel redondant à `loadFromSupabase()` dans `MainScreen.initState()` a été
  retiré ; le chargement principal authentifié de `MyApp` reste inchangé.

### Décisions

- Le bleu `#3B82F6` associé à la catégorie de portefeuille `STOCK` reste un
  choix catégoriel explicite ; il ne fait pas partie des 24 doublons
  sémantiques.
- Les reformulations françaises annoncées étaient déjà conformes et n'ont pas
  été réécrites.
- Aucun autre littéral de couleur n'a été harmonisé, conformément à
  l'interdiction de changement visuel hors périmètre.

### Checklist financière complète

- Virements création/modification/suppression : **PASS**.
- Objectifs et dettes liés : **PASS**.
- Suppression de catégorie : **PASS**.
- Récurrents et salaires automatiques, idempotence : **PASS**.
- Solde disponible hors investissements, cash inclus : **PASS**.

### Vérifications

- `rg -i "gold" lib` : **0 occurrence**.
- `rg "getSafeToSpend|safeToSpend" lib test` : **0 occurrence**.
- `availableBalance` : **18 occurrences** — 16 traductions, 1 getter, 1 usage.
- Clés i18n mortes : **0 occurrence**.
- `loadFromSupabase` dans `lib/main.dart` : **1 occurrence**.
- `flutter analyze` : **560 issues**, soit 8 de moins que la baseline, aucune
  erreur et aucun nouveau diagnostic.
- `flutter test` : **15 tests réussis, 100 % vert**.

### Limites et étapes humaines

- Vérifier visuellement en thèmes clair et sombre la carte de solde, les états
  succès/info et les principaux parcours. Aucun appareil n'a été utilisé par
  Codex.

## T0 — tests unitaires de non-régression financière — 2026-07-23

### Statut

**TERMINÉ.**

### Fichiers modifiés

- `test/providers/app_provider_financial_test.dart`
- `CHANGELOG_WINDSURF.md`

### Couverture ajoutée

Quatorze tests exercent `AppProvider` uniquement par son API publique :

- virement à la création ;
- virement modifié avec nouveau montant et nouveau destinataire ;
- suppression d'un virement ;
- conversion d'un virement en dépense ;
- contribution à un objectif, liaison `goalId`, UUID et réversion ;
- modification d'un paiement de dette par delta exact ;
- déplacement d'une transaction liée vers un autre objectif ;
- retours/paiements de dette personnelle liés et réversibles ;
- suppression de catégorie sans variation de solde ;
- récurrent Daret : type conservé et traitement idempotent ;
- solde global : investissements exclus, cash inclus ;
- dépenses par catégorie limitées au mois et au type attendus ;
- salaire automatique crédité une seule fois par mois ;
- UUID des créations Daret directes.

Avec le smoke test du modèle `Transaction`, la suite contient 15 tests.

### Seam de test

Le paramètre optionnel `AppProvider(autoLoad: false)`, introduit lors de B1,
évite les lectures asynchrones de `SharedPreferences` pendant la construction
des scénarios. La valeur par défaut reste `true`; le comportement de production
est inchangé.

Chaque test initialise `TestWidgetsFlutterBinding` et réinitialise
`SharedPreferences` avec `setMockInitialValues({})`.

### Vérifications

- `flutter analyze` : **560 issues**, aucune erreur et aucun nouveau diagnostic
  par rapport à la baseline de 568.
- `flutter test` : **15 tests réussis, 100 % vert**.
- Le fichier financier reste sous le seuil de découpe prévu de 600 lignes.

### Limites et étapes humaines

- Les appels Supabase ne sont pas exercés : aucun utilisateur distant n'est
  injecté et aucune base de production n'est touchée.
- Aucun test widget visuel ni test appareil n'est ajouté dans ce lot.

## T1 — proxy IA authentifié, clé retirée du client — 2026-07-23

### Statut

**TERMINÉ CÔTÉ CODE — déploiement et secret restent humains.**

### Fichiers modifiés

- `lib/screens/coach_screen.dart`
- `lib/services/ai_access_policy.dart`
- `lib/services/ai_proxy_service.dart`
- `lib/services/ai_transaction_service.dart`
- `lib/services/chat_service.dart`
- `lib/services/env_config.dart`
- `scripts/build_debug_apk.ps1`
- `supabase/functions/chat/.env.example`
- `supabase/functions/chat/README.md`
- `supabase/functions/chat/index.ts`
- `supabase/functions/chat/request_policy.ts`
- `supabase/functions/chat/request_policy_test.ts`
- `test/services/ai_access_policy_test.dart`
- `CHANGELOG_WINDSURF.md`

### Changements

- Les deux clients IA utilisent désormais
  `SupabaseClient.functions.invoke('chat')` avec un timeout de 90 secondes.
- Les payloads et parseurs existants de
  `gemini-2.5-flash:generateContent` sont conservés : historique, instruction
  système, images/PDF `inlineData`, paramètres de génération, mode JSON de
  l'extraction transactionnelle et filtrage des parties de réflexion.
- L'ancienne Edge Function DeepSeek, jamais appelée, est remplacée par un proxy
  Gemini. Elle n'accepte que `POST`/`OPTIONS` et une whitelist exacte du modèle
  et de l'endpoint.
- Le proxy exige un bearer, refuse la clé projet anon comme identité, puis
  valide le token auprès de `/auth/v1/user` avant tout appel fournisseur.
- `GEMINI_API_KEY` est lu uniquement via `Deno.env` côté fonction. Son absence
  renvoie `503`; aucun secret de repli n'existe.
- Les statuts, corps et `Retry-After` Gemini sont relayés afin de préserver les
  branches d'erreur clientes.
- Le paramètre `token` mort de `ChatService` et son extraction dans le Coach ont
  été supprimés.
- `AI_OPEN_TO_ALL=true` n'autorise plus un mode local sans session Supabase :
  une session réelle reste obligatoire.
- Le script APK construit un fichier de définitions temporaire contenant
  seulement la liste blanche de paramètres publics/feature flags. Une éventuelle
  ancienne entrée Gemini de `.env.local` n'est plus incorporée au binaire.
- La documentation Edge impose un déploiement avec vérification JWT, sans
  `--no-verify-jwt`.

### Décisions de sécurité

- Le guide `insecure-defaults` a conduit à conserver un comportement
  fail-closed pour le secret, l'authentification et la whitelist du fournisseur.
- Les cinq `fromEnvironment` restants concernent uniquement l'URL/clé publique
  Supabase, le callback et les feature flags d'accès IA. Ils sont volontairement
  conservés ; aucune lecture `GEMINI_API_KEY` ne subsiste dans `lib/`.
- La fonction effectue sa propre vérification utilisateur même si la
  vérification JWT de la plateforme reste activée par défaut.

### Vérifications

- Recherche dans `lib/` de `generativelanguage`, `GEMINI_API_KEY`, `DEEPSEEK`,
  appels fournisseur directs et paramètres de clé : **0 occurrence**.
- Recherche de `DeepSeek` et `--no-verify-jwt` dans la fonction et les scripts :
  **0 occurrence**.
- Tests purs de politique Edge via Node : **3/3 réussis**.
- Tests Dart de politique d'accès : **4/4 réussis**.
- `flutter analyze` : **560 issues**, 0 erreur et aucun nouveau diagnostic.
- `flutter test` : **19 tests réussis, 100 % vert**.
- Analyse syntaxique PowerShell et TypeScript : **PASS**.

### Limites et étapes humaines

- Définir le secret :
  `supabase secrets set GEMINI_API_KEY=<valeur>`.
- Déployer avec `supabase functions deploy chat`, sans
  `--no-verify-jwt`.
- Retirer manuellement toute ancienne entrée `GEMINI_API_KEY` de `.env.local`
  puis révoquer/faire tourner la clé déjà embarquée dans d'anciens APK.
- Vérifier sur l'environnement déployé : sans JWT et avec clé anon → `401`;
  modèle/endpoint hors whitelist → `400`; secret absent → `503`.
- Tester manuellement chat texte, image, PDF et extraction transactionnelle.
- Deno et Supabase CLI ne sont pas installés dans cet environnement : la
  fonction n'a pas été servie ni déployée réellement.

## T2 — URLs signées pour les reçus/logos — 2026-07-23

### Statut

**TERMINÉ CÔTÉ CODE — passage des buckets en privé reste humain.**

### Fichiers modifiés / créés

- `lib/services/storage_url_resolver.dart` (nouveau)
- `lib/widgets/storage_image.dart` (nouveau)
- `lib/services/supabase_sync_service.dart`
- `lib/screens/accounts_screen.dart`
- `lib/screens/all_subscriptions_screen.dart`
- `lib/screens/today_screen.dart`
- `lib/screens/transactions_screen.dart`
- `lib/screens/wealth_screen.dart`
- `lib/screens/coach_screen.dart`
- `lib/screens/onboarding/setup_screen.dart`
- `lib/widgets/add_transaction_modal.dart`
- `lib/widgets/app_picker_field.dart`
- `supabase_migrations/20260723010000_secure_financial_storage.sql` (nouveau)
- `supabase_complete_setup.sql`
- `test/services/storage_url_resolver_test.dart` (nouveau)
- `test/widgets/storage_image_test.dart` (nouveau)
- `MIGRATIONS.md`, `CHANGELOG_WINDSURF.md`

### Changements

- `_uploadToStorage()` retourne désormais le chemin d'objet
  `<bucket>/<uid>/<uuid>.jpg` (plus aucun `getPublicUrl()` dans `lib/`) ; c'est
  ce chemin qui est persisté sur les modèles reçu/logo.
- `SupabaseSyncService.getSignedUrl(stored, {expiresInSeconds = 3600})` délègue
  à `StorageUrlResolver` : un chemin d'objet est signé via `createSignedUrl` ;
  une ancienne URL Supabase publique/signée est reconvertie en `bucket/objet`
  puis re-signée ; une URL externe ou un chemin local passe inchangé.
- `StorageReferenceParser` restreint la reconnaissance aux buckets `receipts` et
  `logos`, rejette les segments `.`/`..` et les échappements de chemin, et ne
  reconnaît que l'origine Supabase configurée.
- `StorageUrlResolver` met en cache par `(utilisateur|bucket/objet|durée)` avec
  une marge de rafraîchissement proportionnelle, déduplique les signatures
  concurrentes et purge le cache au changement d'utilisateur. Les URLs signées
  ne sont jamais persistées.
- Le widget `StorageImage` remplace les `Image.network` directs sur tous les
  points d'affichage (reçus, logos de comptes) : il résout le chemin en URL
  signée via `FutureBuilder`, affiche un placeholder pendant la résolution et
  ne change pas l'apparence.
- Migration `20260723010000_secure_financial_storage.sql` : buckets `receipts`
  et `logos` en privé (`public = false`) avec `file_size_limit` et
  `allowed_mime_types`, RLS activée sur `storage.objects`, politiques
  propriétaire `auth.uid()::text = (storage.foldername(name))[1]`, et
  neutralisation du trigger legacy pour les buckets financiers.

### Décisions

- Le resolver et le parseur sont des unités pures testables sans Supabase, ce
  qui permet la couverture unitaire complète (parsing, cache, dédup, isolation
  utilisateur).
- Compatibilité héritée conservée : les anciennes URLs déjà stockées restent
  affichables (re-signées), aucune migration de données n'est imposée.

### Vérifications

- `grep -rn "getPublicUrl" lib` : **0 occurrence**.
- `flutter analyze --no-pub` : **557 issues**, 0 erreur, 37 warnings — aucun
  nouveau diagnostic vs baseline (568).
- `flutter test --no-pub` : **31 tests réussis, 100 % vert**.

### Limites et étapes humaines

- Appliquer `20260723010000_secure_financial_storage.sql` (voir `MIGRATIONS.md`).
- Tant que les buckets ne sont pas privés en production, les anciennes URLs
  publiques restent accessibles à quiconque les détient. Le passage en privé se
  fait par la migration (ou le dashboard Storage).
- Aucune vérification visuelle appareil n'a été effectuée : contrôler
  l'affichage des reçus et logos après passage en privé.

## T3 — limites de taille/type de fichier — 2026-07-23

### Statut

**TERMINÉ.**

### Fichiers modifiés / créés

- `lib/services/file_validation.dart` (nouveau)
- `lib/widgets/add_transaction_modal.dart`
- `lib/screens/coach_screen.dart`
- `lib/l10n/translations_core.dart`
- `lib/l10n/translations_extra.dart`
- `lib/l10n/app_localizations.dart`
- `test/services/file_validation_test.dart` (nouveau)
- `CHANGELOG_WINDSURF.md`

### Changements

- `FileValidator` centralise un contrôle purement additif : rejette uniquement
  les fichiers > 10 Mo (`maxFileSizeBytes`) et les extensions jamais acceptées.
  `validateImage` (jpg/jpeg/png/webp/gif/heic/heif) et `validateDocument` (pdf)
  renvoient un `FileValidationResult` typé (`ok` / `tooLarge` /
  `unsupportedType`). Un fichier manquant/illisible est traité comme non
  surdimensionné pour laisser le chemin d'upload existant décider.
- Point d'entrée reçu (`add_transaction_modal._handleReceiptTap`) : le fichier
  choisi est validé avant tout upload ; en cas de refus, un SnackBar localisé
  s'affiche et l'upload est abandonné.
- Points d'entrée IA (`coach_screen._pickImage/_pickCamera/_pickDocument`) :
  même validation via un helper partagé `_showFileValidationError`. Les images
  et le PDF sont contrôlés ; aucun format existant n'a été restreint.
- Nouvelles clés i18n `fileTooLargeError` (mentionne « 10 MB ») et
  `unsupportedFileTypeError` ajoutées dans les 16 langues
  (`translations_core` : en/fr/ar/es/de/pt ; `translations_extra` :
  it/tr/nl/ru/zh/ja/ko/hi/id/pl) + getters dans `app_localizations.dart`.

### Décisions

- La taille limite (10 Mo) est alignée sur le `file_size_limit` du bucket
  `receipts` défini en T2, pour un refus côté client cohérent avant l'appel
  réseau.
- La validation est faite juste après la sélection (avant compression/upload),
  afin que l'utilisateur soit informé immédiatement et qu'aucun octet ne parte.

### Vérifications

- `flutter analyze --no-pub` : **555 issues**, 0 erreur, aucun nouveau
  diagnostic vs baseline (568).
- `flutter test --no-pub` : **41 tests réussis, 100 % vert**
  (10 tests `FileValidator` ajoutés, dont la borne exacte à 10 Mo).

### Limites et étapes humaines

- Aucune. Le contrôle est entièrement côté client ; la limite serveur reste
  posée par la migration T2.

## T4 — branchement réel du Daret — 2026-07-24

### Statut

**TERMINÉ CÔTÉ CODE — migration + décision d'architecture consignées.**

### Écart signalé et décision humaine

Le plan T4 prévoyait une FK `transactions.daret_id REFERENCES <table_darets>`.
Vérification du code réel : **aucune table `darets` n'existe** dans
`supabase_migrations/`, `supabase_complete_setup.sql`,
`supabase_migration_flutter.sql` ni `SupabaseSyncService` — les darets sont
persistés uniquement dans SharedPreferences. Décisions validées par l'humain :

1. `daret_id` = colonne UUID nullable **sans FK** (les darets restent locaux).
2. `Daret.totalReceivedSoFar` reflète les **payouts réellement traités** (et non
   plus un calcul purement calendaire).

### Fichiers modifiés / créés

- `lib/models/transaction.dart`
- `lib/models/daret.dart`
- `lib/providers/app_provider.dart`
- `lib/services/supabase_sync_service.dart`
- `lib/main.dart`
- `supabase_migrations/20260723090000_add_transaction_daret_id.sql` (nouveau)
- `test/providers/app_provider_financial_test.dart`
- `MIGRATIONS.md`, `CHANGELOG_WINDSURF.md`

### Changements

- `Transaction.daretId` (nullable) : modèle + copyWith + toJson/fromJson ;
  mapping `daret_id` dans `_transactionToRow`/`_rowToTransaction` avec la même
  tolérance défensive que `goal_id` (colonne ajoutée à la liste des colonnes
  compatibles potentiellement absentes).
- `Daret.lastPayoutMonthProcessed` (int, persisté) : filigrane d'idempotence des
  payouts. `pendingPayoutMonths` = mois de payout dus (<= `currentMonth`) et non
  encore traités. `totalReceivedSoFar` s'appuie désormais sur ce filigrane (repli
  calendaire pour les darets hérités où le filigrane vaut 0).
- `checkDaretPayout(daretId)` réécrite : génère **une** transaction
  `daret_payout` par mois de payout dû-non-traité, crédite le compte
  destinataire, tague `daretId`, puis avance le filigrane persisté.
- `processDaretPayouts()` : nouveau pilote qui traite tous les darets actifs.
  Appelé au démarrage (aux trois points de chargement d'`AppProvider`, à côté de
  `processSalaries()`/`processSubscriptions()`) et dans le timer périodique de
  `main.dart`.
- Contributions : la règle récurrente `daret_contrib_<id>` porte désormais
  `daretId` dans son template, propagé aux transactions créées par
  `processSubscriptions` (l'idempotence des contributions reste assurée par
  l'avancement de `nextDate`, inchangé).
- Réversion : `deleteTransaction`/`updateTransaction` intègrent
  `daret_contribution` et `daret_payout` dans les listes de réversion de solde
  de compte ; `_reverseLinkedDaretOnDelete` recule le filigrane persisté quand
  un `daret_payout` est supprimé, de sorte que le payout redevient éligible.

### Décisions

- Le filigrane recule au plus haut mois de payout strictement inférieur au
  filigrane courant (0 si aucun), ce qui rend la suppression réversible et la
  régénération idempotente.
- `processDaretContribution` (contribution manuelle directe) est conservée et
  tague `daretId`, mais la voie normale reste la règle récurrente.

### Vérifications (checklist non-régression app_provider)

- Virements création/modification/suppression : **PASS** (tests inchangés).
- Objectifs/dettes liés, UUID, `goalId` : **PASS**.
- Suppression de catégorie sans variation de solde : **PASS**.
- Récurrents : types préservés, aucun doublon : **PASS**.
- Salaires : comportement inchangé : **PASS**.
- Daret : payout généré une seule fois, bon compte crédité, réversion correcte à
  la suppression, mois futur non traité : **PASS** (4 tests ajoutés).
- Solde disponible hors investissement, cash inclus : **PASS**.
- `flutter analyze --no-pub` : **555 issues**, 0 erreur, aucun nouveau
  diagnostic vs baseline (568).
- `flutter test --no-pub` : **45 tests réussis, 100 % vert**.

### Limites et étapes humaines

- Appliquer `20260723090000_add_transaction_daret_id.sql` (voir `MIGRATIONS.md`).
- Les darets restent hors synchronisation cloud (choix assumé) : un
  changement d'appareil ne transporte pas l'état des darets ni leur filigrane.
- Les darets créés avant T4 ont `lastPayoutMonthProcessed = 0` : leur premier
  `processDaretPayouts` générera les payouts dus jusqu'au mois courant (repli
  calendaire pour l'affichage jusque-là). Vérifier ce comportement sur un jeu de
  données réel avant diffusion large.

## T5 — détection des conflits de synchronisation — 2026-07-24

### Statut

**TERMINÉ CÔTÉ CODE (noyau + référence Account) — déploiement staged documenté.**

### Portée décidée

Détection + last-write-wins par horodatage + log explicite. Pas de merge champ à
champ. Le cœur est une **fonction de décision pure** testée unitairement ; le
câblage read-before-write est implémenté sur `accounts` comme référence, et
étendu progressivement aux autres modèles mutables.

### Fichiers modifiés / créés

- `lib/services/sync_conflict.dart` (nouveau — résolveur pur)
- `lib/models/account.dart`
- `lib/services/supabase_sync_service.dart`
- `supabase_migrations/20260723100000_add_updated_at_sync.sql` (nouveau)
- `test/services/sync_conflict_test.dart` (nouveau)
- `MIGRATIONS.md`, `CHANGELOG_WINDSURF.md`

### Changements

- `SyncConflictResolver.resolve(...)` : décision pure `applyLocal` / `keepRemote`
  à partir des `updated_at` local et distant. Le plus récent gagne ;
  égalité → local (une sauvegarde en cours n'est jamais perdue) ; horodatage
  manquant/illisible → local (fail-open, comportement historique) avec log en
  debug ; normalisation UTC avant comparaison.
- `Account.updatedAt` (ISO-8601) ajouté : champ + constructeur + copyWith +
  toJson/fromJson + mapping `updated_at`. `copyWith` rafraîchit `updatedAt` à
  `now()` par défaut (toute mutation), sauf valeur épinglée explicitement
  (restauration depuis le distant). `_rowToAccount` relit `updated_at` pour que
  le modèle chargé porte l'horodatage serveur.
- `_saveAccountRemote` lit d'abord `updated_at` distant (`select` léger par id)
  et n'upserte que si le résolveur renvoie `applyLocal` ; sinon la version
  distante plus récente est conservée. Toute erreur de lecture → applique local
  (fail-open) pour ne jamais bloquer une sauvegarde légitime.
- Migration : `updated_at timestamptz NOT NULL DEFAULT now()` + trigger
  `BEFORE UPDATE` commun `public.set_updated_at` sur les 9 tables synchronisées
  existantes (idempotent, saute les tables absentes).

### Décisions et limites connues

- **Modèle de référence = `Account`.** Les autres modèles mutables (`Goal`,
  budgets, `Holding`, dettes, `Category`, `Transaction`) ne portent pas encore
  `updatedAt` côté client : leur write ne fait pas encore de read-before-write.
  Ils restent néanmoins protégés côté serveur (colonne + trigger `updated_at`
  posés par la migration), et l'extension suit exactement le même patron que
  `Account`. C'est un déploiement progressif assumé, pas un oubli.
- Le résolveur ne fusionne pas les champs : un conflit fait gagner un
  enregistrement entier. Conforme à la portée décidée.

### Vérifications

- `flutter analyze --no-pub` : **555 issues**, 0 erreur, aucun nouveau
  diagnostic vs baseline (568).
- `flutter test --no-pub` : **53 tests réussis, 100 % vert** (8 tests de la
  fonction de décision : local récent, distant récent, égalité, sans distant,
  local manquant, deux manquants, distant illisible, fuseaux horaires).
- Les tests financiers existants restent verts malgré le rafraîchissement
  automatique de `Account.updatedAt` dans `copyWith`.

### Étapes humaines

- Appliquer `20260723100000_add_updated_at_sync.sql` (voir `MIGRATIONS.md`).
- Étendre `updatedAt` aux autres modèles mutables en suivant le patron
  `Account` lorsque la synchronisation multi-appareils de ces entités devient
  prioritaire.

## T6 — course entre loadData() et loadFromSupabase() — 2026-07-24

### Statut

**TERMINÉ.**

### Fichiers modifiés

- `lib/providers/app_provider.dart`
- `CHANGELOG_WINDSURF.md`

### Changements

- Nouveau champ `_localLoadFuture` : le constructeur `AppProvider` y stocke le
  `Future` de `loadData()` (`_localLoadFuture = loadData()`).
- `loadFromSupabase` attend `_localLoadFuture` (s'il est non nul) juste après le
  garde de réentrance, avant d'écrire les champs partagés. Une erreur du load
  local est avalée pour ne jamais bloquer le load distant.
- Le garde de réentrance existant `_supabaseLoadInProgress` est conservé
  (empêche deux loads distants concurrents).

### Décisions

- L'ordre d'appel de `main.dart` est inchangé ; aucun comportement visible ne
  change. Le repli `await loadData()` en cas d'erreur distante reste séquentiel
  (postérieur à l'attente initiale), donc sans course.

### Vérifications

- `flutter analyze --no-pub` : **555 issues**, 0 erreur, aucun nouveau
  diagnostic.
- `flutter test --no-pub` : **53 tests réussis, 100 % vert**.
- Relecture : aucun chemin ne lance les deux écritures de champs en parallèle.

## T7 — copyWith capable d'effacer un champ (sentinel) — 2026-07-24

### Statut

**TERMINÉ (Transaction + Account) — extension aux autres modèles documentée.**

### Étape 0 — audit des appels copyWith passant null

`grep` de tous les `.copyWith(` de `lib/` avec un champ nullable de modèle mis
explicitement à `null` : **0 occurrence**. Aucun appel existant ne reposait sur
l'ancien no-op. Le nouveau comportement (null explicite = effacement) ne casse
donc sémantiquement aucun appel — les appels qui omettent l'argument gardent la
valeur, exactement comme avant.

### Fichiers modifiés / créés

- `lib/models/transaction.dart`
- `lib/models/account.dart`
- `lib/providers/app_provider.dart` (simplification `deleteCategory`)
- `test/models/copywith_clear_test.dart` (nouveau)
- `CHANGELOG_WINDSURF.md`

### Changements

- Sentinel privé `const Object _unset = Object();` par fichier modèle. Les
  paramètres nullables deviennent `Object? champ = _unset` et le corps utilise
  `identical(champ, _unset) ? this.champ : champ as T?`. Les champs non
  nullables conservent `champ ?? this.champ`.
- `Transaction` : `note`, `description`, `categoryId`, `toAccountId`, `goalId`,
  `daretId`, `imagePath`, `expenseSubType` peuvent désormais être effacés.
- `Account` : `bankName`, `color`, `imagePath`, `addedAt`, `salaryAmount`,
  `salaryDay`, `lastSalaryDate`, `debtPaymentAmount`, `debtPaymentDay`,
  `debtPaymentSourceId` peuvent être effacés. `updatedAt` conserve sa logique T5
  (rafraîchi à `now()` par défaut, épinglable).
- `deleteCategory()` simplifié : la reconstruction manuelle de la transaction
  (15 lignes) est remplacée par `transaction.copyWith(categoryId: null)`. Cela
  **corrige un bug latent** : la reconstruction manuelle avait omis `daretId`
  (ajouté en T4) et l'aurait donc effacé silencieusement lors d'un détachement
  de catégorie.

### Décisions / limites

- Sentinel appliqué à `Transaction` (besoin réel et testé via `deleteCategory`)
  et `Account` (champs salaire/dette réellement effaçables). Les modèles
  `Goal`, `Category`, `RecurringRule`, `Daret`, `Holding` gardent le pattern
  `?? this.` : aucun appel `copyWith(champ: null)` n'existe pour eux dans la base
  actuelle. L'extension est mécanique et suit le même patron dès qu'un besoin
  d'effacement apparaît. Le test n° 6 (`deleteCategory`) reste vert.

### Vérifications

- `flutter analyze --no-pub` : **555 issues**, 0 erreur, aucun nouveau
  diagnostic.
- `flutter test --no-pub` : **61 tests réussis, 100 % vert** (8 tests
  d'effacement ajoutés ; les 45 tests financiers, qui exercent de nombreux
  `copyWith`, restent verts → changement préservant le comportement).

## T8 — pagination / virtualisation des listes — 2026-07-24

### Statut

**TERMINÉ.**

### Fichiers modifiés

- `lib/screens/transactions_screen.dart`
- `lib/services/supabase_sync_service.dart`
- `CHANGELOG_WINDSURF.md`

### Changements

- `transactions_screen` : le `ListView(children: _buildTransactionGroups(...))`
  devient `ListView.builder` (itemCount + itemBuilder par index sur la liste de
  widgets groupés par date). Les seules lignes visibles sont mises en page /
  peintes. Zéro changement visuel (mêmes en-têtes de date et cartes groupées).
- `loadTransactions` : chargement par lots via `.range(offset, offset+499)` avec
  tri stable `date` puis `id`, en boucle jusqu'à épuisement (page < 500). Le
  total chargé est loggé. Comportement final identique (tout est chargé), sans
  requête monolithique ; une erreur en cours de pagination renvoie ce qui a déjà
  été récupéré au lieu d'une perte totale.

### Décisions / limites

- `_buildTransactionGroups` construit encore la liste de widgets en amont (le
  `.map` s'exécute), donc la virtualisation porte sur la mise en page/peinture,
  pas sur la construction. Aplatir chaque transaction en items de builder
  individuels serait un chantier plus large risquant la mise en forme des cartes
  groupées ; hors périmètre T8 (le vrai infinite-scroll UI est explicitement
  reporté par le plan).

### Vérifications

- `flutter analyze --no-pub` : **555 issues**, 0 erreur, aucun nouveau
  diagnostic.
- `flutter test --no-pub` : **61 tests réussis, 100 % vert**.

## T9 — rebuilds ciblés (conservateur) — 2026-07-24

### Statut

**TERMINÉ (transactions_screen) — today_screen laissé tel quel, justifié.**

### Fichiers modifiés

- `lib/screens/transactions_screen.dart`
- `CHANGELOG_WINDSURF.md`

### Changements

- `transactions_screen` : le `Consumer<AppProvider>` racine devient un
  `Selector<AppProvider, (...)>` qui projette une signature légère
  (hash de `id+amount+date+type+categoryId` de chaque transaction, nombre de
  catégories, devise). L'écran ne se reconstruit donc que lorsque ces données
  changent, plus à chaque `notifyListeners()` non lié (tick de prix d'un
  holding, changement d'état daret, etc.). Le corps lit toujours le provider
  complet via `context.read<AppProvider>()` — aucune logique modifiée, aucun
  changement visuel.
- La signature inclut les champs rendus (montant, date, type, catégorie) et pas
  seulement les `id`, afin qu'une **édition sur place** d'une transaction
  déclenche bien un rebuild (évite un bug d'UI obsolète).

### Décision — today_screen non modifié

Le `build` de `today_screen` lit de larges pans du provider (`totalCash`,
comptes, objectifs, transactions, abonnements, `settings`…). Une sélection fine
équivaudrait ici à « toute modification » (aucun gain) ou imposerait un
découpage du fichier — or le plan T9 **interdit explicitement de restructurer**.
Le `Consumer` racine y est donc conservé volontairement. L'extension propre
passera par un découpage de l'écran (chantier séparé, hors T9).

### Checklist manuelle (humain, sur appareil)

Après chacune de ces actions, vérifier que le **solde disponible** et la **liste
des transactions** se mettent bien à jour, sans figement :

1. Ajouter une transaction → la liste et le solde reflètent l'ajout.
2. Supprimer une transaction (glisser) → disparaît, solde ajusté.
3. Éditer le montant d'une transaction existante → montant à jour dans la liste.
4. Changer de thème (clair/sombre) → aucun figement, rendu correct.
5. Changer de langue → libellés à jour.

### Vérifications

- `flutter analyze --no-pub` : **555 issues**, 0 erreur, aucun nouveau
  diagnostic (transactions_screen : 21 → 20).
- `flutter test --no-pub` : **61 tests réussis, 100 % vert**.

## T10 — retrait du toggle Notifications décoratif — 2026-07-24

### Statut

**TERMINÉ (retrait appliqué par défaut).**

### Constat vérifié

`settings_screen` sauvegardait `notificationsEnabled`, mais aucun package de
notifications n'est installé (`flutter_local_notifications` absent de
`pubspec.yaml`) et rien n'était jamais programmé — le réglage mentait à
l'utilisateur (« Reminders for bills and budgets »).

### Fichiers modifiés

- `lib/screens/settings_screen.dart`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/translations_core.dart`
- `lib/l10n/translations_extra.dart`
- `CHANGELOG_WINDSURF.md`

### Changements

- Retrait du contrôle de l'UI : l'entrée de menu « Notifications » et sa
  `Divider`, ainsi que la méthode `_showNotificationsDialog` (dialogue +
  `SwitchListTile`), sont supprimées.
- La clé SharedPreferences orpheline `notificationsEnabled` (modèle `Settings`)
  est **conservée** — sans danger, rétrocompatible.
- Clés i18n devenues réellement mortes supprimées dans les 16 langues +
  getters : `notifications`, `pushNotifications`, `remindersForBills`
  (0 usage restant hors `Settings`).

### Décision et réintroduction

Retrait appliqué par défaut (conforme au plan). Une vraie réintroduction serait
une feature à part entière : `flutter_local_notifications`, permissions iOS +
Android 13+, et planification depuis les factures/abonnements existants
(`processSubscriptions`).

### Vérifications

- `grep` des 3 getters hors `Settings`/l10n : **0 occurrence**.
- `flutter analyze --no-pub` : **554 issues**, 0 erreur, aucun nouveau
  diagnostic (une entrée en moins suite au retrait du dialogue).
- `flutter test --no-pub` : **61 tests réussis, 100 % vert** (maps i18n des
  16 langues toujours valides).

## Phase 5 — Rapport final — 2026-07-24

### Statut par tâche

| Tâche | Statut | Note |
|---|---|---|
| Section B (prérequis) | ✅ | Restaurée puis vérifiée (B1/B2) avant T0. |
| T0 — tests non-régression | ✅ | Filet financier via API publique + seam `autoLoad`. |
| T1 — proxy IA (clé retirée) | ✅ code | Déploiement fonction + secret = humain. |
| T2 — URLs signées | ✅ code | Passage buckets en privé = migration/humain. |
| T3 — limites fichiers 10 Mo | ✅ | Entièrement client, 16 langues. |
| T4 — Daret branché | ✅ code | Colonne `daret_id` sans FK (darets locaux). |
| T5 — conflits de sync | ✅ code | Résolveur pur + `Account` de référence ; autres modèles = déploiement staged. |
| T6 — course de chargement | ✅ | `_localLoadFuture` attendu avant le load distant. |
| T7 — copyWith effaçable | ✅ | `Transaction` + `Account` ; corrige un bug latent `daretId`. |
| T8 — pagination | ✅ | `ListView.builder` + `loadTransactions` par lots de 500. |
| T9 — rebuilds ciblés | ✅ | `transactions_screen` via `Selector` ; `today_screen` documenté. |
| T10 — toggle notifications | ✅ | Retrait UI + clés i18n mortes. |

### Écarts constatés entre le plan et le code réel

1. **Section B absente au départ** de `c22904bf` (le plan la disait déjà
   présente). Restaurée sur autorisation humaine avant T0.
2. **Aucune table Daret en Postgres** (T4) : la FK prévue était impossible.
   Décision humaine : colonne `daret_id` nullable sans FK, darets restent locaux.
3. **`totalReceivedSoFar` calendaire** (T4) : re-basé sur les payouts réellement
   traités (filigrane persisté), sur décision humaine.

### Décisions et justifications

- T5 livré comme noyau pur + référence `Account` : sans base live pour valider,
  câbler read-before-write sur 7 tables aurait été risqué. La migration pose
  `updated_at` + trigger partout ; le client s'étend au même patron ensuite.
- T9 limité à `transactions_screen` : `today_screen` lit trop largement le
  provider pour une sélection fine sans le découpage interdit par le plan.
- T7 limité à `Transaction`/`Account` : seuls modèles avec un besoin
  d'effacement réel ; audit = 0 appel `copyWith(champ: null)` existant.

### Baseline vs final

- `flutter analyze` : **568 → 554 issues**, **0 erreur** (37 warnings).
- `flutter test` : **1 échec initial → 61 tests, 100 % vert**.

### Étapes humaines restantes (récapitulatif)

1. **Migrations SQL** (SQL Editor / CLI Supabase), dans l'ordre de `MIGRATIONS.md` :
   `…goal_id` → `…secure_financial_storage` → `…daret_id` → `…updated_at_sync`,
   plus les deux migrations antérieures « À VÉRIFIER ».
2. **T1** : `supabase secrets set GEMINI_API_KEY=…` puis
   `supabase functions deploy chat` (sans `--no-verify-jwt`) ; révoquer/roter la
   clé embarquée dans d'anciens APK.
3. **T2** : passer les buckets `receipts`/`logos` en privé (fait par la migration
   ou le dashboard) + policies Storage.
4. **T9** : vérifications visuelles sur appareil (checklist section T9).
5. **T3/T5/T7** : vérifications visuelles clair/sombre des écrans touchés.

### Risques résiduels connus

- Les darets ne sont pas synchronisés (choix assumé) : changement d'appareil =
  perte de l'état daret + filigrane.
- T5 : la détection de conflit read-before-write n'est active que sur `accounts`
  côté client ; les autres entités sont protégées au niveau serveur mais pas
  encore côté client.
- T8 : virtualisation de mise en page (pas de construction paresseuse complète
  ni d'infinite-scroll UI).
- Les anciennes transactions à id timestamp ne sont pas migrées automatiquement.
