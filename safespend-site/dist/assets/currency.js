(() => {
  const baseCurrency = "MAD";
  const fallbackCurrency = "USD";
  const regions = { MA: "MAD", US: "USD", CA: "CAD", GB: "GBP", IE: "EUR", FR: "EUR", DE: "EUR", ES: "EUR", IT: "EUR", PT: "EUR", NL: "EUR", BE: "EUR", AT: "EUR", FI: "EUR", GR: "EUR", CH: "CHF", SE: "SEK", NO: "NOK", DK: "DKK", PL: "PLN", CZ: "CZK", HU: "HUF", RO: "RON", TR: "TRY", AE: "AED", SA: "SAR", QA: "QAR", KW: "KWD", BH: "BHD", OM: "OMR", EG: "EGP", TN: "TND", DZ: "DZD", ZA: "ZAR", NG: "NGN", KE: "KES", IN: "INR", PK: "PKR", BD: "BDT", JP: "JPY", KR: "KRW", CN: "CNY", HK: "HKD", SG: "SGD", MY: "MYR", TH: "THB", ID: "IDR", PH: "PHP", AU: "AUD", NZ: "NZD", BR: "BRL", MX: "MXN", AR: "ARS", CL: "CLP", CO: "COP" };
  const timeZones = { "Africa/Casablanca": "MAD", "Africa/Algiers": "DZD", "Africa/Tunis": "TND", "Africa/Cairo": "EGP", "Asia/Dubai": "AED", "Asia/Riyadh": "SAR", "Europe/London": "GBP", "America/New_York": "USD", "America/Chicago": "USD", "America/Denver": "USD", "America/Los_Angeles": "USD" };
  const locale = navigator.language || "en-US";

  function regionFromLocale() {
    try { return new Intl.Locale(locale).region; } catch { return locale.match(/-([A-Z]{2})\b/i)?.[1]?.toUpperCase(); }
  }

  function preferredCurrency() {
    const region = regionFromLocale();
    const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    return timeZones[timeZone] || regions[region] || fallbackCurrency;
  }

  function applyCurrency(currency, rate) {
    const formatter = new Intl.NumberFormat(locale, { style: "currency", currency, currencyDisplay: "symbol" });
    const format = (amount) => formatter.format(Number(amount) * rate);
    document.querySelectorAll("[data-currency-amount]").forEach((element) => { element.textContent = format(element.dataset.currencyAmount); });
    window.VVolletCurrency = { currency, format };
    window.dispatchEvent(new CustomEvent("vvollet:currencychange", { detail: { currency } }));
  }

  document.addEventListener("DOMContentLoaded", async () => {
    let currency = preferredCurrency();
    let rate = currency === baseCurrency ? 1 : null;
    if (rate === null) {
      try {
        const response = await fetch("https://open.er-api.com/v6/latest/MAD", { cache: "force-cache" });
        const data = await response.json();
        rate = data?.rates?.[currency];
      } catch { /* Fall back to USD below when exchange data is unavailable. */ }
    }
    if (!Number.isFinite(rate)) { currency = fallbackCurrency; rate = 0.10; }
    applyCurrency(currency, rate);
  });
})();
