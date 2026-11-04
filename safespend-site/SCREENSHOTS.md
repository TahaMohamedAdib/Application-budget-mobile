# App screenshots — where each one goes

The site currently shows the product with coded visuals (the receipt, the Daret grid, the Coach preview).
Real iPhone screenshots replace or join them as below. Files go in `dist/assets/screens/`.

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

## Slots, in priority order

| # | File | Screen to capture | Where it goes on the site | What changes |
|---|---|---|---|---|
| 1 | `home.png` | **Home / Today** with the safe-to-spend amount and the balance chart visible | Hero, right column | The phone becomes the hero visual. The receipt moves down into **The math**, next to the “comes off / doesn’t touch” lists, where it explains the number. |
| 2 | `daret.png` | **Wealth → Daret** with the demo group open | **Daret** section, right column | Replaces the coded month grid. |
| 3 | `wealth.png` | **Wealth** overview (accounts, cash, goals, debts, net worth) | **What it tracks** | Section becomes two columns: phone on the left (sticky on desktop), the six items in one column on the right. |
| 4 | `home-ar.png` | **Home** with the app language set to **Arabic** | **Languages**, right column | Phone shows the real right-to-left layout; the three phrases move under the heading. |
| 5 (optional) | `budgets.png` | **Budgets** with two or three categories part-spent | Not placed by default | Spare for the store listing or a later section. |

The **Coach** is not captured: it is closed in the app, so the coded preview in **Coming next** stays.

## Rules when placing them

- One phone per section at most, never floating cards around it (unslop: one solid visual).
- Simple device frame in CSS (rounded corners and a thin dark bezel), no glossy mockup images.
- Displayed around 300px wide on desktop, served as WebP at 2× (≈ 600px wide), with `width`/`height`
  set to avoid layout shift, `loading="lazy"` below the fold, and an `alt` that says what the screen shows.
- On phones, the screenshot comes after the text and actions of its section.
