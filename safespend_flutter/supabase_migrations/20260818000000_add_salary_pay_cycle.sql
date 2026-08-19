-- Pay cycles for salary auto-credit.
--
-- Before this, `salary_day` was always a day of the month and every salary was
-- assumed monthly. The onboarding questionnaire asks how the user is actually
-- paid, so the cycle has to round-trip:
--
--   salary_frequency   'monthly' | 'weekly' | 'biweekly'. NULL reads as
--                      'monthly', which is what every existing row means.
--   salary_day         monthly  -> day of month, 1-31
--                      weekly / biweekly -> ISO weekday, 1 = Monday .. 7 = Sunday
--   salary_anchor_date any past pay date; fixes which fortnight a biweekly
--                      cycle falls on so it agrees across devices.
--
-- `last_salary_date` also widens from 'yyyy-MM' to a full 'yyyy-MM-dd'. It is
-- already a text column, and the client still reads the short form, so no data
-- migration is needed.

alter table if exists public.accounts
  add column if not exists salary_frequency text,
  add column if not exists salary_anchor_date text;

alter table if exists public.accounts
  drop constraint if exists accounts_salary_frequency_check;

alter table if exists public.accounts
  add constraint accounts_salary_frequency_check
  check (salary_frequency is null
         or salary_frequency in ('monthly', 'weekly', 'biweekly'));
