# App screenshots — screen tour

The real iPhone screenshots supplied for SafeSpend are used by the interactive screen tour on the home page. Deployable copies live in `dist/assets/screens/`; the original `Iphone screenshots/` folder remains outside the deployable site assets.

The tour uses the app's own sequence. The first four onboarding screens are dark-only; the final four screens have matching dark and white appearances that visitors can switch between.

## Current order and assets

| # | Site asset(s) | Original file(s) | App screen | Appearance |
|---|---|---|---|---|
| 1 | `demo1.jpeg` | `demo1.jpeg` | Welcome to SafeSpend | Dark |
| 2 | `demo2.jpeg` | `demo2.jpeg` | See everything at a glance | Dark |
| 3 | `demo3.jpeg` | `demo3.jpeg` | Plan with budgets | Dark |
| 4 | `demo4.jpeg` | `demo4.jpeg` | Grow your wealth | Dark |
| 5 | `home-dark.jpeg`, `home-light.jpeg` | `home_screen.jpeg`, `white_home_screen.jpeg` | Home | Dark / White |
| 6 | `quick-add-dark.jpeg`, `quick-add-light.jpeg` | `transactions_features.jpeg`, `white_transactions_features.jpeg` | Quick add actions | Dark / White |
| 7 | `budgets-dark.jpeg`, `budgets-light.jpeg` | `budget_screen.jpeg`, `white_budget_screen.jpeg` | Budgets | Dark / White |
| 8 | `wealth-dark.jpeg`, `wealth-light.jpeg` | `wealth_screen.jpeg`, `white_wealth_screen.jpeg` | Wealth | Dark / White |

The gallery has previous, next and pause controls, step buttons and a dark/white switch when a paired screen is available. It stops rotating while it is hovered or focused, and honours `prefers-reduced-motion`.

## How to capture (iOS Simulator)

1. Use **iPhone 17 Pro Max** or **iPhone 16 Pro Max**. Their screenshots (1320 × 2868) are also the size
   App Store Connect requires for the 6.9" display, so the same captures serve the store listing.
2. **Light mode** (the site is light), English unless noted.
3. Clean status bar, so every shot shows 9:41 and full battery:
   ```
   xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
   ```
4. Use **demo data, never your real accounts**. Match the website's example so the story is consistent:
   - Monthly income 9,500 MAD
   - Daret group "Daret with the cousins", 10 shares, 1,000 MAD a month, payout in December
   - Some cash, a bank account, a couple of bills (rent, internet), one savings goal (Emergency fund)
5. Save with **⌘S** in Simulator (full resolution PNG). Send the PNGs as they are; they get cropped,
   framed and converted to WebP for the web.

## Rules when placing them

- One phone is shown at a time in the tour; never use floating cards around it.
- Simple device frame in CSS (rounded corners and a thin dark bezel), no glossy mockup images.
- Displayed around 300px wide on desktop, with `width`/`height` set to avoid layout shift and an `alt`
  that says what the screen shows. The current supplied assets are 735 × 1600 JPEGs.
- On phones, the screenshot comes after the text and actions of its section.
