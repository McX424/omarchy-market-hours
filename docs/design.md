# Design notes: Market Hours

**Plugin id:** `mcx424.market-hours`  
**Kind:** `bar-widget` (chip + details panel)  
**Role:** Session clock only — not a quote ticker.

## Product

- Bar chip: US equity aggregate (NYSE/NASDAQ hours) with status colour and optional countdown
- Panel: NYSE, NASDAQ, LSE, TSE (Tokyo), ASX, NZX — each with OPEN / CLOSED / EXTENDED and next change
- Offline: no network, no prices, no API keys
- US holidays / early closes: bundled JSON for the current calendar year (`data/us-equity-holidays-2026.json`)

## Status colours

| Status | Meaning | Colour |
|--------|---------|--------|
| OPEN | Regular cash session | Green |
| EXTENDED | Pre-market or after-hours (US) | Amber |
| CLOSED | Outside session / weekend / holiday | Red |

## Non-goals

- Live quotes or watchlists (use a markets/stocks plugin)
- Crypto liquidity windows
- Broker-specific extended hours beyond configurable US windows

## Known limitations

- Non-US venues use weekday cash sessions only (no LSE/TSE/ASX/NZX holiday calendars in v1)
- US holiday pack is year-scoped; add `data/us-equity-holidays-YYYY.json` before each new year
- Extended-hours windows vary by broker; defaults match common US pre 04:00 / AH to 20:00 ET

## Implementation

| File | Responsibility |
|------|----------------|
| `manifest.json` | Plugin metadata, defaults, settings schema |
| `BarWidget.qml` | Chip UI + tick + panel host |
| `Panel.qml` | Exchange list UI |
| `SessionEngine.qml` | Pure session math (timezones, holidays, countdowns) |
| `data/us-equity-holidays-*.json` | US holiday / early-close calendar |

## Validation checklist

- [x] Panel order: NYSE → NASDAQ → LSE → TSE → ASX → NZX
- [x] US early-close / full holiday data bundled for 2026
- [x] TSE lunch gap modeled as closed in SessionEngine
- [x] Manifest settings cover display TZ, countdown, US windows, tick
- [ ] Run `omarchy plugin validate ~/.config/omarchy/plugins/mcx424.market-hours` on an Omarchy host before each release
- [ ] Spot-check chip across a US DST change and a display-timezone DST change
