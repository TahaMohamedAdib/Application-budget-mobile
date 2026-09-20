"""Generate currency/region catalogs from Unicode CLDR via Babel.
Run: python -m pip install Babel==2.18.0; python tool/generate_currency_translations.py
"""
from pathlib import Path
from babel import Locale
from babel.numbers import get_currency_name
import re,json
locales='en fr ar es de pt it tr nl ru zh ja ko hi id pl'.split()
codes=re.findall(r"^    '([A-Z]{3})':",Path('lib/utils/currency_helper.dart').read_text(encoding='utf-8'),re.M)
# CLDR names are language data, generated locally, not automatic prose translation.
lines=['// Generated from Babel/Unicode CLDR currency and territory names.','// Regenerate with tool/generate_currency_translations.py.','const translationsCurrencies = <String, Map<String, String>>{']
for lang in locales:
 l=Locale.parse(lang);items={f'currency_{c}':get_currency_name(c,locale=lang) for c in codes}
 items.update({f'currencyRegion_{k}':l.territories[v] for k,v in {'Africa':'002','MiddleEast':'145','Americas':'019','Europe':'150','Asia':'142','Pacific':'009'}.items()})
 lines.append(f"  '{lang}': {{")
 for k,v in items.items():lines.append('    '+json.dumps(k)+': '+json.dumps(v,ensure_ascii=True).replace('$',r'\$')+',')
 lines.append('  },')
lines.append('};')
Path('lib/l10n/translations_currencies.dart').write_text('\n'.join(lines)+'\n',encoding='utf-8')
