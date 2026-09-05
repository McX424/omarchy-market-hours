# Market Hours

Session clock for the [Omarchy](https://omarchy.org) Quattro bar. Shows when major equity markets are open, closed, or in extended hours — no quotes, no network, no API keys.

**Exchanges:** NYSE · NASDAQ · LSE · TSE (Tokyo) · ASX · NZX

## Install

```bash
omarchy plugin add https://github.com/McX424/omarchy-market-hours.git --enable
```

Place or move the widget if needed:

```bash
omarchy bar put mcx424.market-hours --section right
```

## Usage

- **Left click** the chip to open the details panel
- Chip shows US session state and countdown (for example `US · open · 2h 14m` or `US · extended · 1h 20m`)
- Panel lists each exchange with **OPEN** / **CLOSED** / **EXTENDED** and time until the next change

## Session hours

| Exchange | Timezone | Session |
|----------|----------|---------|
| NYSE / NASDAQ | America/New_York | Pre 04:00–09:30 EXTENDED · regular 09:30–16:00 OPEN · AH 16:00–20:00 EXTENDED |
| LSE | Europe/London | 08:00–16:30 |
| TSE (Tokyo) | Asia/Tokyo | 09:00–11:30 · 12:30–15:00 (lunch closed) |
| ASX | Australia/Sydney | 10:00–16:00 |
| NZX | Pacific/Auckland | 10:00–16:45 |

US early-close and full holidays come from the bundled calendar in `data/us-equity-holidays-2026.json`.

## Configure

Defaults are in `manifest.json`. Override via Omarchy bar widget settings or the `mcx424.market-hours` entry in `shell.json`:

| Key | Default | Description |
|-----|---------|-------------|
| `displayTimezone` | `Pacific/Auckland` | IANA timezone for countdown display |
| `showCountdown` | `true` | Show time until next state change |
| `countDownToPre` | `false` | Count down to pre-market instead of regular open |
| `tickSeconds` | `30` | Refresh interval |

## Update

```bash
omarchy plugin update mcx424.market-hours
```

## Remove

```bash
omarchy plugin remove mcx424.market-hours
```

## Sources

- US hours and holidays: [NYSE Holidays & Trading Hours](https://www.nyse.com/markets/hours-calendars)
- Other venues: standard cash-session hours in local time (weekdays only in v1)

Not trading advice. Extended-hours windows vary by broker.

## License

MIT
