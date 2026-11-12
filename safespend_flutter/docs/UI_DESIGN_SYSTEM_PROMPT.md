# UI design system prompt

Paste everything below this line into the coding agent working on the new project. Fill in the `[BRACKETED]` values first.

---

You are building the user interface for **[APP NAME]**, a **[ONE-LINE PRODUCT DESCRIPTION]** mobile app, using **[FRAMEWORK, e.g. Flutter / React Native / SwiftUI]**.

Reproduce the visual language specified here: its tokens, shapes, components, motion, and behaviour. Treat every number as the spec unless it can't be expressed in the framework. Don't substitute framework defaults such as Material ripples, stock app bars, stock bottom navigation, or stock dialogs. Replace the finance-specific content with this product's content, and keep the structure and feel.

Before writing screens, build the tokens and shared components in sections 1–6. Screens only compose those. A screen should never invent its own font size, radius, shadow, or colour.

## 0. The design in one paragraph

A calm, iOS-first interface with a monochrome base and one deep teal accent. Near-white or charcoal backgrounds, neutral grey icons, Inter type with tight display tracking, generously rounded cards, and frosted glass reserved for things that float above content: the navigation pill, the quick-action panel, and form sheets. Colour carries meaning, never decoration. Amounts and status are coloured, while icons and containers stay neutral. Motion is short, eased-out, and interruptible, and pressing anything shrinks it slightly. The same iOS-styled design ships on Android as well, with no Material variant.

### Rules that define the look

1. **Colour means something.** Accent marks the primary action and current selection. Red, teal, blue, and amber mark data semantics only. Never give a feature its own decorative colour.
2. **Icons are neutral.** List and row icons use the adaptive grey on a neutral tile. The value beside the icon carries the colour.
3. **Glass is for floating layers only.** Page content sits on solid or gradient surfaces. Blur needs something behind it, so don't apply it to a flat background and expect it to read as glass.
4. **One iOS design everywhere.** Use iOS page transitions, bouncing scroll, iOS text-selection behaviour, and iOS-style icons on every platform.
5. **Numbers never break the layout.** See `MoneyAmount` in section 5.
6. **Press feedback everywhere.** Every tappable element scales down on press.
7. **Dark and light are equal.** Build and check both for every component.
8. **Support RTL from the start.** Use start/end layout properties rather than left/right.

## 1. Colour tokens

### Brand and semantic

| Token | Hex | Use |
|---|---|---|
| `accent` / `success` / `info` | `#0B715F` | Primary action, selected state, focus, positive values, income |
| `accent-700` | `#07443A` | Deep shade |
| `accent-600` | `#095C4D` | Darker shade |
| `accent-400` | `#0D8A74` | Lighter shade |
| `accent-300` | `#11A88E` | Medium |
| `accent-200` | `#5ECFBC` | Soft |
| `accent-100` | `#C2EDE7` | Pale |
| `accent-50` | `#E8F9F7` | Very pale |
| `accent-rim` | `#168A74` | 1px border on the filled add button |
| `error` | `#EF4444` | Expense, negative, destructive, over-limit |
| `error-on-dark` | `#FF8A80` | Softer red for negative stats on dark hero cards |
| `warning` | `#FBBF24` | Offline or pending states, cash, withdrawal |
| `transfer` | `#3B82F6` | Neutral movement between own accounts |
| `ai` / `ai-deep` | `#AB68FF` / `#8E4EC6` | AI features only, and the second onboarding glow |

Text on `accent`, `error`, and `transfer` fills is white. **Text on `warning` fills must be near-black `#171719`**, because white on amber is unreadable.

### Light theme

| Token | Hex |
|---|---|
| `background` | `#FFFFFF` |
| `surface` | `#F7F7F8` |
| `text-primary` | `#202123` |
| `text-secondary` | `#6E6E80` |
| `text-tertiary` | `#8E8EA0` |
| `border` | `#E5E5E5` |
| `divider` | `#ECECF1` |
| `icon` | `#73757F` |
| `icon-surface` | `#DADDE0` |
| `hero-text` | `#1C1C1E` |
| `hero-label` | `#5F6368` |
| `hero-caption` | `#74777C` |

### Dark theme

| Token | Hex |
|---|---|
| `background` | `#181A1B` |
| `surface` | `#1A1A1A` |
| `surface-elevated` | `#2D2D2D` |
| `text-primary` | `#ECECEC` |
| `text-secondary` | `#AAAAAA` |
| `text-tertiary` | `#8E8E8E` |
| `border` | `#3A3A3A` |
| `divider` | `#2A2A2A` |
| `icon` | `#D1D1D6` |
| `icon-surface` | `#303233` |
| `hero-text` | `#FFFFFF` |
| `hero-label` | white at 80% |
| `hero-caption` | white at 60% |

### Semantic mapping for values

- Balance: zero is neutral (anything that would display as `0.00`), positive is `success`, negative is `error`.
- Row amounts by type: outgoing `error`, incoming `accent`, internal transfer `transfer`, cash-related `warning`, anything else the adaptive `icon` colour.

## 2. Typography

Bundle **Inter** (variable) with the app so type is stable offline. Use tabular figures for every numeric value.

### Semantic roles

Choose a role at each call site, never a raw size.

| Role | Size | Weight | Tracking | Line height |
|---|---|---|---|---|
| Screen title | 24 | 700 | -0.4 | 1.2 |
| Section title | 18 | 600 | -0.1 | 1.3 |
| Item title | 15 | 600 | 0 | 1.4 |
| Description | 13 | 400 | 0 | 1.45 |
| Label | 12 | 600 | 0 | 1.3 |
| Money hero | 36 (default) | 700 | -1.2 | 1.0 |
| Stat | 13 | 600 | +0.1 | default |

### Full scale

| Style | Size / weight / tracking / line height | Colour |
|---|---|---|
| displayLarge | 40 / 700 / -1.5 / 1.1 | primary |
| displayMedium | 34 / 700 / -1 / 1.1 | primary |
| displaySmall | 28 / 700 / -0.6 / 1.15 | primary |
| headlineLarge | 28 / 700 / -0.6 / 1.2 | primary |
| headlineMedium | 24 / 700 / -0.4 / 1.2 | primary |
| headlineSmall | 20 / 600 / -0.2 / 1.25 | primary |
| titleLarge | 18 / 600 / -0.1 / 1.3 | primary |
| titleMedium | 15 / 600 / 0 / 1.4 | primary |
| titleSmall | 14 / 600 / 0 / 1.4 | primary |
| bodyLarge | 15 / 400 / 0 / 1.55 | primary |
| bodyMedium | 14 / 400 / 0 / 1.5 | secondary |
| bodySmall | 13 / 400 / 0 / 1.45 | tertiary |
| labelLarge | 14 / 600 / +0.1 / 1.35 | primary |
| labelMedium | 12 / 600 / 0 / 1.3 | secondary |
| labelSmall | 11 / 600 / +0.1 / 1.3 | tertiary |

The app-wide text scale is a user preference that **multiplies** the operating system's scale and never replaces it.

## 3. Shape, spacing, elevation

### Radii

| Element | Radius |
|---|---|
| Form sheet | 32 |
| Quick-action panel, help sheet top corners | 30 |
| Navigation pill | 36 |
| Bottom sheet top corners | 28 |
| Selected nav indicator | 28 |
| Amount-entry card | 26 |
| Dialog, overview glass card | 24 |
| Hero card | 20 |
| Grouped settings panel | 22 |
| Sheet fields, sheet primary button, filter pill | 20 |
| Standard card, transaction group | 16–20 |
| Selector chip, segment, chips | 16 / 12 |
| Inputs outside sheets | 12 |
| Row icon tile (44px) | 12–14 |
| Settings icon tile (34px) | 8 |
| Capsules and progress bars | full |

Onboarding uses true **squircles** (continuous-corner superellipse) at radii 20–26. The rest of the app uses ordinary circular corners.

### Spacing

Spacing sits on a loose 2/4 grid: 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 36.

- Tab screen horizontal gutter: **20**. Settings gutter: **16**.
- Vertical gap between major cards: **20**.
- Hero card padding: **24**. Chart and summary card padding: **20**. Overview card padding: **22**.
- List row padding: 16 horizontal, 14 vertical.
- Icon-to-text gap: 14 in rows, 12 in compact rows.
- Row dividers are inset to align with the text: 74 for 44px-icon rows, 60 for settings rows. Last row has no divider.
- Minimum touch target: **44px**. Tab content scrolls under the nav pill, so reserve bottom padding to clear it.

### Shadows

| Name | Values (y, blur, spread, colour) |
|---|---|
| Card light | 2, 8, 0, black 5% |
| Card dark | 2, 12, 0, black 15% |
| Elevated light | 8, 24, -2, `#0F172A` 8% + 2, 8, 0, `#0F172A` 4% |
| Selected pill | 6, 20, -2, black 18% |
| Grouped panel | 5, 12, -7, black 5.5% light / 24% dark |
| Floating nav | 12, 28, -7, black 10% light / 46% dark |
| Form sheet | 8, 32, 0, black 16% light / 40% dark |

Negative spread is intentional: shadows stay soft and sit under the element instead of forming a halo.

## 4. Surfaces

- **Standard card:** `surface`, radius 20, 1px `border`, card shadow.
- **Bordered card:** `surface`, radius 16, 1px `border` (dark: white 9%), no shadow.
- **Hero card:** the signature surface for the main figure on each tab. Radius 20.
  - Light: top-left→bottom-right gradient `#F3F4F5`→`#E9EBED`, 1px `#D9DCE0`, shadow 8/22/-6 black 7%.
  - Dark: same direction `#2F2F2F`→`#212121`→`#1A1A1A` (stops 0, .5, 1), 1px white 8%, a soft accent glow 4/20/0 accent 15% plus depth 8/24/-4 black 30%.
- **Overview glass card:** radius 24, padding 22, fill `#242627` at 94% dark / `#F0F1F3` at 92% light, 1px white 10% / black 7.5%, shadow 10/24/-10 black 22% / 8%, blur 22.
- **Grouped panel:** vertical gradient `#252829`→`#222526` dark, `#FFFFFF`→`#F8F9F8` light, radius 22, 1px white 7.5% / black 5.5%.
- **Glass recipe:** clip to shape, backdrop blur 24–30, translucent fill, hairline border that is lighter than the fill, shadow placed outside the clip so it isn't cut off.
- **Settings backdrop:** vertical gradient `#111415`→`#0D1010` dark, `#F4F6F5`→`#EEF2F0` light, with two very faint blurred accent orbs (280px top-end at 7.5–9%, 250px left at 3.5–5%, blur 55).
- **Onboarding backdrop:** scaffold colour with two radial glows: 380px accent top-right (30% dark / 20% light), 420px `ai` bottom-left (22% dark / 14% light). This gives the glass panels something to refract.

## 5. Shared components

### Bottom navigation pill

A floating glass pill, not a docked bar. There are 4 destinations plus a centred add button in 5 equal cells: `[Tab 1] [Tab 2] [+] [Tab 3] [Tab 4]`.

- Height 66, radius 36, horizontal margin 14, top margin 8, bottom margin = safe-area aware (12 with no inset; clear Android's 3-button bar, but overlap thin gesture bars).
- Blur 30. Fill: dark `background` colour; light gradient `#F3F4F5`→`#E9EBED`. Border: white 14% dark / `#D9DCE0` light.
- Icons only, 23px, Phosphor bold. Active: white / `#1C1C1E`. Inactive: white 66% / `#777B81`. Active icon scales to 1.05 over 240ms.
- **Sliding indicator:** a glass capsule, 52 high, width `clamp(cellWidth - 8, 58, 78)`, radius 28, top 7. It slides between cells over 320ms ease-out-cubic and skips the centre cell. Fill is a diagonal white gradient (dark 25/16/11%, light 94/68/48%) with a 1px white rim and a small outer shadow.
- **Add button:** 48px filled accent circle, 1px `accent-rim`, white plus at 24px, accent-tinted shadow 8/16/-4 at 26–32%. It rotates 45° over 250ms while the menu is open.
- Each item has an accessibility label and tooltip with its name. Pressing scales to 0.92.
- Tabs live in a pager with swiping disabled. Switching animates over 300ms ease-out-cubic and keeps each tab's state. Tapping a tab pops any pushed routes first.

### Quick-action menu (opened by the add button)

- Black scrim fades to 40% and covers everything, including the nav pill. Tapping it closes the menu.
- A 254px-wide glass panel centred horizontally, 22px above the pill. Radius 30, padding 10, blur 26.
  - Fill: dark `#242427` at 72%, light white at 58%, with a diagonal sheen. Border: white 12% dark / 74% light. Shadow 18/34/-8 black 50% / 16%.
- Rows are 58 high, radius 20, gap 6, padding 10. Each has a 40px `icon-surface` tile, radius 14, a 20px icon in its **semantic colour**, gap 14, and a 16/700 label.
- Open and close: 250ms ease-out-cubic, opacity plus 16px upward translate. Rows press to 0.985.

### Form sheet (every add/edit flow)

One floating card for all create and edit forms. It's detached from the screen edges, so the page stays visible around it.

- Height `min(available, 680, 74% of screen)`, max width 560, side margin 10, top 12, bottom = keyboard + 8, or `max(12, safe area)`.
- Radius 32. Blur 28. Fill `#111214` (dark) / `#F7F7F9` (light) at 94%. Border white 14% dark / 90% light.
- Barrier is black 38%. Open over 340ms, close over 240ms. Keyboard adjustment animates over 220ms ease-out-cubic.
- Structure, top to bottom:
  1. Handle 46×5, full radius, white 16% / black 14%.
  2. Header: 38px tinted icon tile (radius 12, accent 12–18% fill, 28% border), title in `titleLarge`/700 tinted, centred, max 2 lines, and a 44px circular close button (white 8% / black 5%, 20px icon).
  3. Divider.
  4. Scrolling fields, padding 20/16/20/18. Dragging dismisses the keyboard.
  5. Divider, then fixed actions, padding 20/12/20/14.
- The header and close button never move while fields scroll.
- If the sheet is under 400 high or text scale is over 1.4, actions scroll inside the fields instead of staying pinned.
- Swipe down, tapping outside, close, and system back all dismiss **without saving**. Only the primary action commits. The keyboard opens only when a field is tapped.

Inside sheets:

- Field: fill white 5.5% dark / 76% light, 1px white 10% / black 7%, radius 20, padding 18/18. Focus border is the accent at 55%, width 1.2. Where a type selector exists, focus and floating label use the selected type's colour.
- **Hero input** (the main number of the form): radius 26, padding 18/14/18/16, diagonal gradient (dark white 9.5→4%, light white 96→68%), big 36/800 value, 28/800 currency prefix in the type colour, always-floating label, no inner border.
- **Type selector:** a row of equal chips, gap 8, min height 48, radius 16, padding 11/6, a 20px icon over a 10/700 label. Selected: type colour at 12–20% fill, 72% border, icon and text in that colour. Unselected: white 4.5% / black 2.5%, hairline border.
- **Segmented options:** radius 16, min height 44, 12px text. Selected: white 14% / 96% with a soft shadow. 220ms ease-out-cubic.
- **Primary button:** full width, height 56, radius 20, diagonal gradient of the type colour (lerp 8% to white → 8% to black), 1px white 20%, coloured shadow 10/24/-8, 16/700 label that reads "Add [Type]" or "Save changes". Disabled while submitting.

### Picker field

Never use a native dropdown. A field-shaped trigger (radius 20, 11px label over 15px value, optional 18px leading image) opens a list in a sheet with radius 24: title 18, subtitle 13, optional search, options in radius-16 rows with 32px leading tiles, 15px label, 12px subtitle. Options use neutral icons.

### Capsule action button

A neutral, full-width, secondary call to action such as "Add category". Height 58, radius full, fill `#242626` dark / `#F1F2F3` light, 1px white 10% / black 8%, centred icon plus 10 gap plus `titleMedium`/600 with -0.2 tracking. Light haptic on tap, press scale 0.97 over 120ms.

### Filter pill

Padding 18/10, radius 20, 13/600. Active: accent fill, white text, selected-pill shadow. Inactive: `surface`, with a hairline in dark or card shadow in light. 200ms. Use a horizontally scrolling row with 10 gaps.

### Sliding segmented control

A track with a highlight that slides under the labels. Compact version (chart ranges): 163×44, padding 3, radius 12, track black 18% dark / 5.5% light, highlight accent, radius 9, slides over 320ms ease-out-cubic, labels 10/700 tabular, white when selected. Settings version: height 62, padding 4, radius 17, highlight radius 13, 260ms, with haptic selection click. Onboarding version: height 46.

### List rows and transaction groups

- Group items by date under uppercase `bodySmall`/600 headers with 0.5 tracking ("TODAY", "YESTERDAY", then a date). Padding 4/16/0/8.
- Each group is one card with inset dividers.
- Row: 44px neutral icon tile (radius 12), gap 14, title `titleMedium`/600 over `bodySmall` subtitle, both ellipsized, gap 8, and right-aligned value 15/700 in the semantic colour, with a tiny chip beneath (9/600, padding 6/2, radius 6, on `icon-surface`).
- When values are hidden, drop the +/- sign too, since a lone sign reveals direction.

### MoneyAmount (critical)

The widest string on the screen, and the only one whose length the app doesn't control. Build a single component and use it for every important figure.

- Font size 32 by default (hero 34), minimum 22, weight 600, tracking -0.4, line height 1.15, tabular figures, always LTR even in RTL layouts.
- Fit order, each step only if the previous one isn't enough:
  1. Shrink to the preferred minimum.
  2. Shrink further, to a hard legibility floor of 13.
  3. Only if still unreadable, abbreviate ("2.5M"), and only when the number has 6+ integer digits and the short form saves at least 2 characters and actually renders larger. Never abbreviate if the caller disables it.
- Measure text with the current text scale. Keep a scale-down wrapper as the final guard so digits are never clipped and no overflow occurs.
- Currency sits inline after the number, or as a small 11/500 caption underneath when width is tight.
- Long press shows the exact value in a tooltip. Screen readers read the exact value.
- **Privacy mode** masks the amount in the display, tooltip, and accessibility label alike.

### Settings components

- **Page chrome:** iOS large title (32 tall, -0.8 tracking, one-line subtitle) that collapses into a compact centred 15/600 title in a 50-high bar. Blur and background fade in with scroll (blur 0→26, fill to 72%), the hairline fades in, the compact title appears over the last 55% of the collapse, and the large title slides 10px up and fades. A 34px circular back button stays visible with a 17px chevron.
- **Group:** optional `labelMedium` header at inset 16, a grouped panel, optional `bodySmall` footer, 24 bottom margin.
- **Row:** min height 56, padding 12/9, 34px **accent-filled** icon tile (radius 8, 18px white icon, 1px white rim), gap 12, `titleMedium` label, optional `bodySmall` subtitle, trailing value (15, tertiary, max width 132), and a 62%-opacity directional chevron. Pressed background is white 5% / black 3.5%, 160ms. Haptic selection click. This is the one place icons are tinted.
- **Choice row:** padding 16/13, 24px radio indicator, 180ms. **Switch:** accent thumb when on, with track accent 30–35%.
- Preference pages open in the form sheet. Help, about, and read-only pages push normally.

### Other components

- **Header icon button:** 24px neutral glyph with 8 padding for touch; make the whole area tappable.
- **Help button:** 40px circular button with a question mark in each feature header. Opens a sheet (top radius 30) with an accent icon and a plain-language explanation of that screen, replayable at any time. The first visit to a feature shows it automatically once.
- **Progress bar:** height 7, full radius. Normal: accent (white on dark hero cards). Over limit: `error`.
- **Count chip:** padding 10/5, full radius, `icon-surface`, `bodySmall`.
- **Empty state:** centred, padding 40, 80px tile (radius 24), title, description, then a 52-high primary button.
- **Snackbar:** floating, radius 14, `#1A2029` light / `surface-elevated` dark, 14px text.
- **Dialog:** radius 24, no elevation, section-title heading, description body.
- **Sync status badge:** states and colours: synced (accent, check), syncing (accent, rotating arrows), pending (amber, count), offline (amber, warning), failed (red, count). Always show a short detail line.
- **Coming-soon feature:** keep the nav slot, centre a 76px tile, a 22px title, a 14px description, and keep help in the top end corner. A locked list row shows a lock icon, an "Upcoming" subtitle, and no value or navigation.

### Icons

- **Phosphor** bold for navigation and actions, light for edit/delete/close/settings details.
- **Cupertino / SF Symbols-style** icons for rows, forms, and settings.
- Map semantic names (`icon.add`, `icon.wealth`) to glyphs in one file. Screens only use the semantic names.
- Back and forward chevrons mirror in RTL.

## 6. Motion and feedback

- Standard curve: **ease-out-cubic**. Avoid bounce and spring overshoot, apart from the iOS scroll bounce.
- Durations: press 120ms, colour/fill 160–220ms, selection slide 260–320ms, page change 300ms, sheet 340 open / 240 close, chart data 350ms.
- Press scale: 0.92 nav icons, 0.97 buttons, 0.985 large rows. Use an animated scale that can be interrupted mid-press.
- **Screen entrance:** the header fades in over 260ms and slides from -5%. Then cards fade in over 280ms and slide from +3%, staggered by 40–60ms (header 0, filters 60, hero 100, chart 140). List items continue at +40ms each.
- **Page transitions:** the iOS push with outgoing-page parallax and interactive edge swipe-back, plus a fade on the incoming page that finishes in the first 55% of the transition.
- **Onboarding steps:** cross-fade with a 6% horizontal shift matching direction, 320ms.
- **Haptics:** selection click on rows, toggles, and segments. Light impact on primary and capsule buttons.
- Honour the OS reduced-motion setting by making sheets and transitions instant.

## 7. App shell and flows

Launch → splash → sign-in if there's no session → prepare local data → onboarding if setup is incomplete → guided tour on first run → main tabs. Everything is wrapped in a privacy layer above all routes:

- Optional PIN lock rendered inline, so no route can be dismissed around it.
- App-switcher mask: blur 28 with the background colour at 86% and a centred lock icon. Raise it when the app becomes inactive, not when paused, since paused is too late for the switcher snapshot.

### Sign-in

A single centred column with 28 side padding: an 80px circular `icon-surface` badge with a 40px neutral glyph (fades in over 260ms and scales from 0.85), 20 gap, the app name at 32/800 in `accent` with -0.5 tracking, a short subtitle, email and password fields, a 52-high primary button with an inline spinner while submitting, then Google and Apple options.

### Onboarding

Six steps: Welcome → Language → Hook → Aha → Preview → Setup.

- Lit backdrop, squircle glass cards (radius 26, blur 26, specular highlight along the top edge).
- Top bar: 40px circular back button, then a segmented progress bar (height 5, segments gap 5, 320ms), with the accent only on the current position.
- Hero: 62px glass icon tile (radius 22), `headlineLarge` title, `bodyLarge` description.
- Choice cards: radius 20, padding 14/13, accent rim when selected (45–55%).
- Bullets: radius 22, 42px tile, 15 title, 13 detail.
- Primary button: height 56, accent gradient, white 18px label with an optional 18px icon, accent shadow (blur 22, 35%), and a 22px white spinner while busy.
- The accent appears only on the primary action and current progress. System back goes one step back and doesn't exit.

### Guided tour

A skippable full-screen walkthrough of each main tab, shown once and replayable from Settings.

### Tab screen template

1. Header row (gutter 20, top 16): context selector or screen title on the start side; help, then action icons, on the end side. The context selector is a compact trigger (padding 14/10, radius 14, `surface`, hairline, up/down caret, 14/600).
2. Optional filter pills.
3. A hero card with one figure: 13/500 label, 34px `MoneyAmount`, 12px caption.
4. Supporting cards, 20 apart.
5. Grouped lists.

Use bouncing scroll, and let content pass underneath the nav pill. Don't apply a bottom safe area to the scroll content.

### Example dashboard

- Selector, help, hide-values toggle, settings.
- Filter pills: All / [Section] / [Section].
- Hero card with the main figure.
- Trend card: label + figure on the start side and range selector (1D 1W 1M 6M 1Y) on the end. Below 340px of width, stack the selector under the figure. Chart height 200.
- Grouped recent activity.

### Trend chart

Smooth line (smoothness 0.32, no overshoot), width 3, round caps, horizontal gradient from `accent` to the end colour, soft shadow blur 8 at 28%, and a fade fill below (14–20% → 0 by 75% height). No grid, no borders, no left or right axis. Bottom dates are 9/500, with both ends always labelled and no adjacent labels. Tapping or dragging keeps a selected point: dot radius 5 with a 3px background-coloured ring, dashed 1.5 guide line (4,4), dark tooltip `#1C1C1E` (radius 10, padding 14/9) with exact value 13/700 and date 11/500 at 60%, and the date label becomes a highlighted chip. Animate data changes over 350ms.

### Example summary tab

Hero card with progress bar and "X remaining / over by X", per-item cards with name, "spent of limit", progress, an "over" badge and edit action, then a capsule add button. Include an empty state.

### Example overview tab

Large title + settings, selector, hero with 38px figure, a fading gradient divider, a small 11px period label, three stat columns, then a "Breakdown" grouped list: rows padding 20/16, 44px neutral tile (radius 14), label + sublabel, right value 15, caret.

### Detail pages

Header: 44px circular glass back button, 20/700 title + `bodySmall` subtitle, help, 44px glass add button. Then an overview glass card: 44px tile + label, 34px figure, optional progress, divider, two metrics. Then section header with count chip, then rows.

## 8. Accessibility and internationalisation

- All user-visible text goes through the localisation layer, including tooltips, accessibility labels, and notifications.
- Language defaults to the first supported device language. An explicit user choice takes precedence. Numbers, dates, and currencies use the selected locale.
- Full RTL mirroring, with numbers kept LTR.
- Every icon-only control has a label and tooltip. Charts have a text summary.
- Test at 320px width, large phones, and 1.3× text scale, in the longest language you support, with **zero overflow**. Long labels ellipsize or wrap to at most two lines. Long numbers go through `MoneyAmount`.
- Theme options: System, Light, Dark. Text size is a preference that multiplies the system scale.

## 9. Things to avoid

- Material ripples as the main feedback, stock FABs, docked bottom bars, and native dropdowns.
- Colourful icon tiles, gradient text, decorative purple, emoji as icons.
- Blur on flat content, or on every card.
- Hard-coded colours or font sizes inside screens.
- Abbreviating numbers before trying smaller type.
- A sheet that grows or moves its close button as you scroll.
- Showing a sign or digits anywhere when privacy mode is on.

## 10. Build order and done criteria

1. Tokens, theme, fonts, icon mapping.
2. `MoneyAmount`, press-scale wrapper, glass surfaces.
3. Navigation pill, quick-action menu, form sheet, picker.
4. Settings components, then onboarding components.
5. Screens, composed only from the above.

Before you call it done, run the app and capture every main screen in light and dark, at 320px and at 1.3× text scale, and in one RTL language. Check them against this spec, and report anything you changed or couldn't match.
