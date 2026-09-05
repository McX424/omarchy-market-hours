# Design notes: Market Hours

**Plugin id:** `mcx424.market-hours`  
**Kind:** `bar-widget` (chip + details panel)  
**Role:** Session clock only — not a quote ticker.

## Product

- Bar chip: US equity aggregate (NYSE/NASDAQ hours) with status colour and optional countdown
- Panel: NYSE, NASDAQ, LSE, TSE (Tokyo), ASX, NZX — each with OPEN / CLOSED / EXTENDED and next change
- Offline: no network, no prices, no API keys
- US holidays / early closes: bundled JSON for the current calendar year

## Status colours

| Status | Meaning | Colour |
|--------|---------|--------|
| OPEN | Regular cash session | Green |
| EXTENDED | Pre-market or after-hours (US) | Amber |
| CLOSED | Outside session / weekend / holiday | Red |

## Non-goals

- Live quotes or watchlists (use a markets/stocks plugin)
- Crypto liquidity windows
- Broker-specific extended hours (defaults are common US windows; configurable)

## Implementation sketch

| File | Responsibility |
|------|----------------|
| `manifest.json` | Plugin metadata, defaults, settings schema |
| `BarWidget.qml` | Chip UI + tick + panel host |
| `Panel.qml` | Exchange list UI |
| `SessionEngine.qml` | Pure session math (timezones, holidays, countdowns) |
| `data/us-equity-holidays-*.json` | US holiday / early-close calendar |

## Validation checklist

- [ ] Chip correct across a US DST change and a display-timezone DST change
- [ ] Early-close day ends regular session at 13:00 ET
- [ ] Full holiday shows CLOSED with next open
- [ ] TSE lunch gap is CLOSED
- [ ] Panel order: NYSE → NASDAQ → LSE → TSE → ASX → NZX
- [ ] `omarchy plugin validate` passes
