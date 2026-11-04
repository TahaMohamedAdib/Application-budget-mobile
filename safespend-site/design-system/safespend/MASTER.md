# SafeSpend Website — Design System

> Source of truth for the marketing site. `dist/index.html` is the reference implementation.
> Page-specific overrides go in `design-system/pages/[page-name].md`.

**Direction:** The site looks like the app. Colors and type come from the Flutter theme (`safespend_flutter/lib/theme/app_colors.dart`, `app_text_styles.dart`). If the app theme changes, update these tokens to match. Every claim must be true of the shipping app.

---

## Color

Mirrors `AppColors` in the app. Do not introduce other hues (the app's purple `aiAccent` is for AI features only and is not used on the site).

| Token | Hex | App name | Use |
|---|---|---|---|
| `--teal` | `#0B715F` | goldPrimary | Primary button, links, focus ring, “your turn” |
| `--teal-600` | `#095C4D` | gold600 | Button hover |
| `--teal-200` | `#5ECFBC` | gold200 | Teal on dark surfaces (key figure, ÷, checks) |
| `--expense` | `#EF4444` | error / expenseIcon | Minus signs on the receipt |
| `--bg` | `#FFFFFF` | lightBackground | Page background |
| `--surface` | `#F7F7F8` | lightSurface | Alternate band, hover fills |
| `--text` | `#202123` | lightTextPrimary | Headings, body |
| `--text-2` | `#6E6E80` | lightTextSecondary | Secondary text |
| `--text-3` | `#8E8EA0` | lightTextTertiary | Meta only |
| `--border` | `#E5E5E5` | lightBorder | Hairlines |
| `--dark-bg` | `#181A1B` | darkBackground | Daret band |
| `--dark-card` | `#212121` | goldCard (dark) | Cards on dark |
| `--dark-text` / `-2` / `-3` | `#ECECEC` / `#AAAAAA` / `#8E8E8E` | darkText* | Text on dark |

Dark hero cards (receipt, callouts) use the app's `AppTheme.goldCard(isDark: true)`: `linear-gradient(135deg, #2F2F2F, #212121 50%, #1A1A1A)`, 1px white 8% border, radius 20. The app's teal glow shadow is left out on purpose.

## Type

Inter only, like the app (`app_fonts.dart`). Self-hosted `assets/Inter-Variable.woff2`, no Google Fonts requests.

- **Headings:** Inter 700 with tight tracking, as the app's titles (40px/-1.5, 34px/-1). Hero clamp(40–68px) at `-0.04em`, sections clamp(30–46px) at `-0.035em`. No italic, no trailing periods.
- **Body/UI:** Inter 400–600, 16px, line-height 1.6.
- **Numbers:** always `font-variant-numeric: tabular-nums` (`.num`).

## Layout

- Container `min(1120px, 100% - 48px)`; sections separated by 1px hairlines, not shadows.
- Lists are ruled (hairline between rows), not grids of identical cards.
- Breakpoints: 960px (stack two-column), 720px (mobile).

## Signature elements

- **The receipt:** the safe-to-spend calculation shown as a worked sum. Formula must match `AppProvider.getSafeToSpendToday()`: (monthly income − this month's expenses, Daret, goal, debt and friend-repayment outflows) ÷ days remaining including today.
- **Dashed teal stitching** (`1.5px dashed` gold200 at 45%) echoing the wallet icon — receipt only.

## Do not

- No glassmorphism, blurred blobs, glow orbs, decorative rings, or gradient hero backgrounds.
- No uppercase tracked "kicker" labels; section labels are sentence case, 13px, secondary text color.
- No vague copy ("calm, connected home", "financial journey"). Name real things: Daret, ATM withdrawals, rent.
- No features that are not live (the AI Coach is currently closed — do not advertise it).
- No "no data shared with third parties"-style claims unless verified against the app.
- No fake store buttons; link stores only once listings exist.
- No emoji icons. Avoid icons entirely unless they carry meaning.

## Pages

| URL | File | Purpose |
|---|---|---|
| `/` | `index.html` | Landing page (inline CSS) |
| `/privacy` | `privacy.html` | Privacy policy — store listing URL |
| `/delete-account` | `delete-account.html` | Google Play account deletion URL |
| `/support` | `support.html` | App Store support URL |
| `/terms` | `terms.html` | Terms of use |
| 404 | `404.html` | Not found |

Document pages share `assets/doc.css`. `vercel.json` sets clean URLs and security headers (CSP allows no scripts — add a `script-src` if you ever add JS).
Home page sections: hero (receipt) · screen tour (real supplied app screens) · The math · Daret · What it tracks · Languages · Coming next (Coach preview in the app's chat styles) · Privacy · closing.
**Coming next** lists only features that exist in the app code but are not released (AI Coach, voice, reminders and alerts). No dates. When one ships, move it into What it tracks and update `privacy.html` first.
Real app screenshots: the home-page tour shows one framed iPhone screen at a time, in the app's actual onboarding then product order. Use the paired dark/white captures only on screens that have both. It must offer previous/next, pause, visible focus and reduced-motion behaviour; see `SCREENSHOTS.md` for the current assets and mapping.
Placeholders to replace before launch: `{{YOUR FULL NAME}}` and `support@safespend.app`.
Keep `privacy.html` in sync with the app: if a new service receives data (e.g. the AI Coach provider), update it first.

## Unslop

Polished with the `unslop` skill by Damir Sokolovsky (github.com/heydamir/unslop, CC BY 4.0). Run `/unslop` after big changes.

- Spacing on a 4px grid; nested radius = outer − padding
- Teal accents stay on the primary action and the two moments (receipt, Daret rotation)
- Easing `cubic-bezier(.22, 1, .36, 1)`, 150–200ms
- Body weights 400–600; headings 700 to match the app (deliberate exception to unslop); one number format (`1,000.00`)

## Checklist

- [ ] Text contrast ≥ 4.5:1; visible `:focus-visible` outline
- [ ] Touch targets ≥ 44px
- [ ] No horizontal scroll at 375px
- [ ] `prefers-reduced-motion` respected
- [ ] Transitions 150–200ms, transform/opacity/color only
