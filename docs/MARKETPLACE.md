# Omarchy Plugins submission draft

**Repository:** https://github.com/McX424/omarchy-market-hours  
**Plugin id:** `mcx424.market-hours`  
**Version:** 1.0.1  
**Category suggestion:** Markets / Bar widget  
**Tags suggestion:** markets, sessions, nyse, nasdaq, clock, offline

## Short description (marketplace)

Equity session clock for the Omarchy bar — NYSE, NASDAQ, LSE, TSE, ASX, NZX. Shows open / closed / extended with countdowns. Offline — no quotes, no API keys.

## Longer blurb

Market Hours is a bar chip plus details panel that answers “is cash open?” without fetching prices. The chip tracks the US session (including pre and after-hours). The panel lists six major equity venues with status pills and time until the next change. US holidays and early closes ship as a bundled calendar. Configure display timezone and US session windows from Omarchy widget settings.

## Install command

```bash
omarchy plugin add https://github.com/McX424/omarchy-market-hours.git --enable
```

## Checklist before submit

- [ ] `omarchy plugin validate` passes on Omarchy host
- [ ] Preview image `preview.png` looks good on listing
- [ ] README install / update / remove verified
- [ ] Open https://omarchyplugins.com/publish.html and submit the repo URL
