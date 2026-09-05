import QtQuick

// Pure session-clock logic for global equity exchanges.
// No network. Quickshell JS has no ECMA-402 — use IANA DST helpers only.
QtObject {
  id: root

  readonly property string etZone: "America/New_York"
  readonly property string londonZone: "Europe/London"
  readonly property string tokyoZone: "Asia/Tokyo"
  readonly property string sydneyZone: "Australia/Sydney"
  readonly property string aucklandZone: "Pacific/Auckland"
  readonly property string utcZone: "UTC"

  // Dual-maintain with data/us-equity-holidays-2026.json
  property var holidays: ({
    exchange: "NYSE/Nasdaq",
    source: "https://www.nyse.com/markets/hours-calendars",
    timezone: "America/New_York",
    year: 2026,
    fullClosures: [
      "2026-01-01", "2026-01-19", "2026-02-16", "2026-04-03", "2026-05-25",
      "2026-06-19", "2026-07-03", "2026-09-07", "2026-11-26", "2026-12-25"
    ],
    earlyCloses: [
      { date: "2026-11-27", regularClose: "13:00", lateClose: "17:00" },
      { date: "2026-12-24", regularClose: "13:00", lateClose: "17:00" }
    ]
  })

  property bool holidaysLoadedFromFile: false

  function loadHolidays(json) {
    if (!json || typeof json !== "object") return false
    var next = {
      exchange: json.exchange || root.holidays.exchange,
      source: json.source || root.holidays.source,
      timezone: json.timezone || root.holidays.timezone,
      year: json.year || root.holidays.year,
      fullClosures: Array.isArray(json.fullClosures) ? json.fullClosures.slice() : root.holidays.fullClosures.slice(),
      earlyCloses: Array.isArray(json.earlyCloses) ? json.earlyCloses.map(function (row) {
        return {
          date: row.date,
          regularClose: row.regularClose || "13:00",
          lateClose: row.lateClose || "17:00"
        }
      }) : root.holidays.earlyCloses.slice()
    }
    root.holidays = next
    root.holidaysLoadedFromFile = true
    return true
  }

  function defaultConfig() {
    return {
      displayTimezone: "Pacific/Auckland",
      showCountdown: true,
      countDownToPre: false,
      usPreStart: "04:00",
      usRegularOpen: "09:30",
      usRegularClose: "16:00",
      usAhEnd: "20:00",
      tickSeconds: 30
    }
  }

  function mergeConfig(config) {
    var base = defaultConfig()
    if (!config) return base
    for (var key in base) {
      if (config[key] !== undefined && config[key] !== null && config[key] !== "")
        base[key] = config[key]
    }
    return base
  }

  function pad2(n) {
    return (n < 10 ? "0" : "") + n
  }

  function parseHm(text) {
    var s = String(text || "00:00")
    var parts = s.split(":")
    var h = parseInt(parts[0], 10)
    var m = parseInt(parts[1] || "0", 10)
    if (!isFinite(h) || !isFinite(m)) return 0
    return h * 60 + m
  }

  // ---- Calendar helpers (UTC civil arithmetic) ----

  function weekdayUtc(y, m, d) {
    return new Date(Date.UTC(y, m - 1, d)).getUTCDay() // 0=Sun
  }

  function nthSunday(y, month, n) {
    var firstWd = weekdayUtc(y, month, 1)
    var day = 1 + ((7 - firstWd) % 7) + (n - 1) * 7
    return day
  }

  function firstSunday(y, month) {
    return nthSunday(y, month, 1)
  }

  function lastSunday(y, month) {
    var lastDay = new Date(Date.UTC(y, month, 0)).getUTCDate()
    var wd = weekdayUtc(y, month, lastDay)
    return lastDay - wd
  }

  function addCalendarDays(year, month, day, delta) {
    var utc = new Date(Date.UTC(year, month - 1, day))
    utc.setUTCDate(utc.getUTCDate() + delta)
    return {
      year: utc.getUTCFullYear(),
      month: utc.getUTCMonth() + 1,
      day: utc.getUTCDate()
    }
  }

  function dateKey(year, month, day) {
    return year + "-" + pad2(month) + "-" + pad2(day)
  }

  // ---- Zone offsets (minutes east of UTC) via IANA rules ----

  function usEasternOffsetMinutes(utcDate) {
    // EST UTC-5 / EDT UTC-4. US DST: 2nd Sun Mar 02:00 local → 1st Sun Nov 02:00 local
    var y = utcDate.getUTCFullYear()
    var startUtc = Date.UTC(y, 2, nthSunday(y, 3, 2), 7, 0, 0) // 02:00 EST = 07:00 UTC
    var endUtc = Date.UTC(y, 10, firstSunday(y, 11), 6, 0, 0) // 02:00 EDT = 06:00 UTC
    var t = utcDate.getTime()
    if (t >= startUtc && t < endUtc) return -4 * 60
    return -5 * 60
  }

  function nzOffsetMinutes(utcDate) {
    // NZST UTC+12 / NZDT UTC+13. NZ DST: last Sun Sep 02:00 NZST → first Sun Apr 03:00 NZDT
    var t = utcDate.getTime()
    function season(y) {
      var startUtc = Date.UTC(y, 8, lastSunday(y, 9), 14, 0, 0) // 02:00 NZST = 14:00 UTC
      var endDay = firstSunday(y, 4)
      var endUtc = Date.UTC(y, 3, endDay, 3, 0, 0) - 13 * 3600 * 1000 // 03:00 NZDT
      return { startUtc: startUtc, endUtc: endUtc }
    }
    var y = utcDate.getUTCFullYear()
    var thisStart = season(y).startUtc
    var thisEndNext = season(y + 1).endUtc
    var prevStart = season(y - 1).startUtc
    var thisEnd = season(y).endUtc
    if (t >= prevStart && t < thisEnd) return 13 * 60
    if (t >= thisStart && t < thisEndNext) return 13 * 60
    return 12 * 60
  }

  function londonOffsetMinutes(utcDate) {
    // GMT UTC+0 / BST UTC+1. EU/UK: last Sun Mar 01:00 UTC → last Sun Oct 01:00 UTC
    var y = utcDate.getUTCFullYear()
    var startUtc = Date.UTC(y, 2, lastSunday(y, 3), 1, 0, 0)
    var endUtc = Date.UTC(y, 9, lastSunday(y, 10), 1, 0, 0)
    var t = utcDate.getTime()
    if (t >= startUtc && t < endUtc) return 60
    return 0
  }

  function tokyoOffsetMinutes() {
    return 9 * 60 // JST, no DST
  }

  function sydneyOffsetMinutes(utcDate) {
    // AEST UTC+10 / AEDT UTC+11. AU: first Sun Oct 02:00 AEST → first Sun Apr 03:00 AEDT
    var t = utcDate.getTime()
    function season(y) {
      // start: first Sunday Oct 02:00 AEST = 02:00 - 10h = previous day 16:00 UTC
      var startDay = firstSunday(y, 10)
      var startUtc = Date.UTC(y, 9, startDay, 2, 0, 0) - 10 * 3600 * 1000
      // end: first Sunday Apr 03:00 AEDT = 03:00 - 11h = previous day 16:00 UTC
      var endDay = firstSunday(y, 4)
      var endUtc = Date.UTC(y, 3, endDay, 3, 0, 0) - 11 * 3600 * 1000
      return { startUtc: startUtc, endUtc: endUtc }
    }
    var y = utcDate.getUTCFullYear()
    var thisStart = season(y).startUtc
    var thisEndNext = season(y + 1).endUtc
    var prevStart = season(y - 1).startUtc
    var thisEnd = season(y).endUtc
    if (t >= prevStart && t < thisEnd) return 11 * 60
    if (t >= thisStart && t < thisEndNext) return 11 * 60
    return 10 * 60
  }

  function offsetMinutesForZone(utcDate, timeZone) {
    var z = String(timeZone || "UTC")
    if (z === "UTC" || z === "Etc/UTC" || z === "Z") return 0
    if (z === "America/New_York" || z === "US/Eastern") return usEasternOffsetMinutes(utcDate)
    if (z === "Pacific/Auckland" || z === "NZ" || z === "Antarctica/McMurdo") return nzOffsetMinutes(utcDate)
    if (z === "Europe/London" || z === "GB" || z === "GB-Eire" || z === "Europe/Belfast") return londonOffsetMinutes(utcDate)
    if (z === "Asia/Tokyo" || z === "Japan") return tokyoOffsetMinutes()
    if (z === "Australia/Sydney" || z === "Australia/NSW" || z === "Australia/Melbourne" || z === "Australia/Hobart")
      return sydneyOffsetMinutes(utcDate)
    return 0
  }

  function tzParts(date, timeZone) {
    var utcMs = date.getTime()
    var off = offsetMinutesForZone(new Date(utcMs), timeZone)
    var localMs = utcMs + off * 60000
    off = offsetMinutesForZone(new Date(utcMs), timeZone)
    localMs = utcMs + off * 60000
    var d = new Date(localMs)
    var year = d.getUTCFullYear()
    var month = d.getUTCMonth() + 1
    var day = d.getUTCDate()
    var hour = d.getUTCHours()
    var minute = d.getUTCMinutes()
    var second = d.getUTCSeconds()
    var weekdayIndex = d.getUTCDay()
    var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    return {
      weekday: names[weekdayIndex],
      weekdayIndex: weekdayIndex,
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      dateKey: dateKey(year, month, day),
      minutes: hour * 60 + minute,
      offsetMinutes: off
    }
  }

  function instantAtWall(year, month, day, hour, minute, timeZone) {
    var guess = Date.UTC(year, month - 1, day, hour, minute, 0)
    for (var i = 0; i < 4; i++) {
      var off = offsetMinutesForZone(new Date(guess), timeZone)
      var asLocal = guess + off * 60000
      var wanted = Date.UTC(year, month - 1, day, hour, minute, 0)
      guess += (wanted - asLocal)
    }
    return new Date(guess)
  }

  function isFullClosure(key) {
    var list = root.holidays.fullClosures || []
    for (var i = 0; i < list.length; i++) if (list[i] === key) return true
    return false
  }

  function earlyCloseRow(key) {
    var list = root.holidays.earlyCloses || []
    for (var i = 0; i < list.length; i++) if (list[i].date === key) return list[i]
    return null
  }

  function isWeekend(weekdayIndex) {
    return weekdayIndex === 0 || weekdayIndex === 6
  }

  function wallHm(hm) {
    return { h: Math.floor(hm / 60), m: hm % 60 }
  }

  function atWallHm(year, month, day, hm, timeZone) {
    var w = wallHm(hm)
    return instantAtWall(year, month, day, w.h, w.m, timeZone)
  }

  // ---- Market definitions ----
  // status: "open" | "closed" | "extended"
  // For US: pre/AH map to "extended"; regular → "open"

  function marketDefs(cfg) {
    return [
      {
        id: "nyse",
        name: "NYSE",
        zone: root.etZone,
        kind: "us",
        preStart: parseHm(cfg.usPreStart),
        open: parseHm(cfg.usRegularOpen),
        close: parseHm(cfg.usRegularClose),
        ahEnd: parseHm(cfg.usAhEnd),
        useUsHolidays: true
      },
      {
        id: "nasdaq",
        name: "NASDAQ",
        zone: root.etZone,
        kind: "us",
        preStart: parseHm(cfg.usPreStart),
        open: parseHm(cfg.usRegularOpen),
        close: parseHm(cfg.usRegularClose),
        ahEnd: parseHm(cfg.usAhEnd),
        useUsHolidays: true
      },
      {
        id: "lse",
        name: "LSE",
        zone: root.londonZone,
        kind: "simple",
        open: parseHm("08:00"),
        close: parseHm("16:30"),
        useUsHolidays: false
      },
      {
        id: "tse",
        name: "TSE (Tokyo)",
        zone: root.tokyoZone,
        kind: "split",
        morningOpen: parseHm("09:00"),
        morningClose: parseHm("11:30"),
        afternoonOpen: parseHm("12:30"),
        afternoonClose: parseHm("15:00"),
        useUsHolidays: false
      },
      {
        id: "asx",
        name: "ASX",
        zone: root.sydneyZone,
        kind: "simple",
        open: parseHm("10:00"),
        close: parseHm("16:00"),
        useUsHolidays: false
      },
      {
        id: "nzx",
        name: "NZX",
        zone: root.aucklandZone,
        kind: "simple",
        open: parseHm("10:00"),
        close: parseHm("16:45"),
        useUsHolidays: false
      }
    ]
  }

  function dayIsTradable(year, month, day, zone, useUsHolidays) {
    var probe = instantAtWall(year, month, day, 12, 0, zone)
    var wd = tzParts(probe, zone).weekdayIndex
    if (isWeekend(wd)) return { tradable: false, weekdayIndex: wd, holiday: false }
    var key = dateKey(year, month, day)
    if (useUsHolidays && isFullClosure(key))
      return { tradable: false, weekdayIndex: wd, holiday: true, key: key }
    return { tradable: true, weekdayIndex: wd, holiday: false, key: key }
  }

  function usDayBounds(year, month, day, def) {
    var info = dayIsTradable(year, month, day, def.zone, true)
    if (!info.tradable) return { tradable: false, key: info.key, weekdayIndex: info.weekdayIndex }
    var early = earlyCloseRow(info.key)
    return {
      tradable: true,
      key: info.key,
      weekdayIndex: info.weekdayIndex,
      preStart: def.preStart,
      open: def.open,
      close: early ? parseHm(early.regularClose) : def.close,
      ahEnd: early ? parseHm(early.lateClose || "17:00") : def.ahEnd,
      early: !!early
    }
  }

  function phaseUs(bounds, minutes) {
    if (!bounds || !bounds.tradable) return "closed"
    if (minutes < bounds.preStart) return "closed"
    if (minutes < bounds.open) return "extended" // pre
    if (minutes < bounds.close) return "open"
    if (minutes < bounds.ahEnd) return "extended" // AH
    return "closed"
  }

  function nextChangeUs(now, local, bounds, def, preferPre) {
    var y = local.year, m = local.month, d = local.day
    var minutes = local.minutes
    var openTarget = function (b) { return preferPre ? b.preStart : b.open }
    if (bounds && bounds.tradable) {
      // Closed before pre: next is start of next active phase (pre or regular)
      if (minutes < bounds.preStart) return atWallHm(y, m, d, openTarget(bounds), def.zone)
      // Extended pre → end of pre (= regular open)
      if (minutes < bounds.open) return atWallHm(y, m, d, bounds.open, def.zone)
      // Regular open → close
      if (minutes < bounds.close) return atWallHm(y, m, d, bounds.close, def.zone)
      // Extended AH → end of AH
      if (minutes < bounds.ahEnd) return atWallHm(y, m, d, bounds.ahEnd, def.zone)
    }
    for (var i = 1; i <= 14; i++) {
      var next = addCalendarDays(y, m, d, i)
      var nb = usDayBounds(next.year, next.month, next.day, def)
      if (!nb.tradable) continue
      return atWallHm(next.year, next.month, next.day, openTarget(nb), def.zone)
    }
    return null
  }

  function nextChangeSimple(now, local, def) {
    var y = local.year, m = local.month, d = local.day
    var minutes = local.minutes
    var info = dayIsTradable(y, m, d, def.zone, false)
    if (info.tradable) {
      if (minutes < def.open) return atWallHm(y, m, d, def.open, def.zone)
      if (minutes < def.close) return atWallHm(y, m, d, def.close, def.zone)
    }
    for (var i = 1; i <= 14; i++) {
      var next = addCalendarDays(y, m, d, i)
      var ni = dayIsTradable(next.year, next.month, next.day, def.zone, false)
      if (!ni.tradable) continue
      return atWallHm(next.year, next.month, next.day, def.open, def.zone)
    }
    return null
  }

  function phaseSimple(local, def) {
    var info = dayIsTradable(local.year, local.month, local.day, def.zone, false)
    if (!info.tradable) return "closed"
    if (local.minutes >= def.open && local.minutes < def.close) return "open"
    return "closed"
  }

  function phaseSplit(local, def) {
    var info = dayIsTradable(local.year, local.month, local.day, def.zone, false)
    if (!info.tradable) return "closed"
    var mins = local.minutes
    if (mins >= def.morningOpen && mins < def.morningClose) return "open"
    if (mins >= def.afternoonOpen && mins < def.afternoonClose) return "open"
    return "closed"
  }

  function nextChangeSplit(now, local, def) {
    var y = local.year, m = local.month, d = local.day
    var mins = local.minutes
    var info = dayIsTradable(y, m, d, def.zone, false)
    if (info.tradable) {
      if (mins < def.morningOpen) return atWallHm(y, m, d, def.morningOpen, def.zone)
      if (mins < def.morningClose) return atWallHm(y, m, d, def.morningClose, def.zone)
      if (mins < def.afternoonOpen) return atWallHm(y, m, d, def.afternoonOpen, def.zone)
      if (mins < def.afternoonClose) return atWallHm(y, m, d, def.afternoonClose, def.zone)
    }
    for (var i = 1; i <= 14; i++) {
      var next = addCalendarDays(y, m, d, i)
      var ni = dayIsTradable(next.year, next.month, next.day, def.zone, false)
      if (!ni.tradable) continue
      return atWallHm(next.year, next.month, next.day, def.morningOpen, def.zone)
    }
    return null
  }

  function marketState(def, nowDate, cfg) {
    var now = nowDate instanceof Date ? nowDate : new Date(nowDate)
    var local = tzParts(now, def.zone)
    var status = "closed"
    var nextChange = null

    if (def.kind === "us") {
      var bounds = usDayBounds(local.year, local.month, local.day, def)
      status = phaseUs(bounds, local.minutes)
      nextChange = nextChangeUs(now, local, bounds, def, cfg.countDownToPre === true)
    } else if (def.kind === "split") {
      status = phaseSplit(local, def)
      nextChange = nextChangeSplit(now, local, def)
    } else {
      status = phaseSimple(local, def)
      nextChange = nextChangeSimple(now, local, def)
    }

    var countdownMs = nextChange ? Math.max(0, nextChange.getTime() - now.getTime()) : 0
    var verb = (status === "closed") ? "opens in" : "closes in"
    return {
      id: def.id,
      name: def.name,
      status: status,
      statusLabel: status.toUpperCase(),
      verb: verb,
      nextChange: nextChange,
      countdownMs: countdownMs,
      countdownHHMM: formatCountdownHHMM(countdownMs),
      local: local
    }
  }

  function allMarkets(nowDate, config) {
    var cfg = mergeConfig(config)
    var now = nowDate instanceof Date ? nowDate : new Date(nowDate)
    var defs = marketDefs(cfg)
    var rows = []
    for (var i = 0; i < defs.length; i++)
      rows.push(marketState(defs[i], now, cfg))
    return rows
  }

  // US aggregate for chip (NYSE hours = NASDAQ hours)
  function usState(nowDate, config) {
    var cfg = mergeConfig(config)
    var defs = marketDefs(cfg)
    var us = marketState(defs[0], nowDate, cfg) // NYSE
    var phase = us.status === "open" ? "open" : (us.status === "extended" ? "extended" : "closed")
    return {
      phase: phase,
      status: us.status,
      label: us.statusLabel,
      shortLabel: "US",
      nextChange: us.nextChange,
      countdownMs: us.countdownMs,
      note: "",
      et: us.local,
      dateKey: us.local.dateKey
    }
  }

  function formatCountdown(ms) {
    var totalMin = Math.max(0, Math.floor(ms / 60000))
    var days = Math.floor(totalMin / (60 * 24))
    var hours = Math.floor((totalMin % (60 * 24)) / 60)
    var mins = totalMin % 60
    if (days > 0) return days + "d " + hours + "h"
    if (hours > 0) return hours + "h " + pad2(mins) + "m"
    return mins + "m"
  }

  function formatCountdownHHMM(ms) {
    var totalMin = Math.max(0, Math.floor(ms / 60000))
    var hours = Math.floor(totalMin / 60)
    var mins = totalMin % 60
    return pad2(hours) + ":" + pad2(mins)
  }

  function formatWallClock(date, timeZone) {
    if (!date) return ""
    var p = tzParts(date, timeZone)
    var h24 = p.hour
    var ap = h24 >= 12 ? "p" : "a"
    var h12 = h24 % 12
    if (h12 === 0) h12 = 12
    return h12 + ":" + pad2(p.minute) + ap
  }

  function formatFullTime(date, timeZone) {
    if (!date) return "—"
    var p = tzParts(date, timeZone)
    var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var h24 = p.hour
    var ap = h24 >= 12 ? "PM" : "AM"
    var h12 = h24 % 12
    if (h12 === 0) h12 = 12
    return names[p.weekdayIndex] + ", " + months[p.month - 1] + " " + p.day + ", " + h12 + ":" + pad2(p.minute) + " " + ap
  }

  function formatNowClock(date, timeZone) {
    var p = tzParts(date, timeZone)
    var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    var h24 = p.hour
    var ap = h24 >= 12 ? "PM" : "AM"
    var h12 = h24 % 12
    if (h12 === 0) h12 = 12
    var abbr = "UTC"
    if (timeZone === root.etZone || timeZone === "US/Eastern") abbr = (p.offsetMinutes === -4 * 60) ? "EDT" : "EST"
    else if (timeZone === root.aucklandZone || timeZone === "NZ") abbr = (p.offsetMinutes === 13 * 60) ? "NZDT" : "NZST"
    else if (timeZone === root.londonZone) abbr = (p.offsetMinutes === 60) ? "BST" : "GMT"
    else if (timeZone === root.tokyoZone) abbr = "JST"
    else if (timeZone === root.sydneyZone) abbr = (p.offsetMinutes === 11 * 60) ? "AEDT" : "AEST"
    else if (String(timeZone).indexOf("/") >= 0) abbr = String(timeZone).split("/").pop()
    return names[p.weekdayIndex] + " " + h12 + ":" + pad2(p.minute) + ":" + pad2(p.second) + " " + ap + " " + abbr
  }

  function chipLabel(nowDate, config) {
    var cfg = mergeConfig(config)
    var now = nowDate instanceof Date ? nowDate : new Date(nowDate)
    var us = usState(now, cfg)
    var statusWord = us.status // open | extended | closed
    var showCd = cfg.showCountdown !== false
    var parts = ["US", statusWord]
    if (showCd) parts.push(formatCountdown(us.countdownMs))
    return parts.join(" · ")
  }

  function chipColorRole(nowDate, config) {
    var us = usState(nowDate, config)
    if (us.status === "open") return "positive"
    if (us.status === "extended") return "warning"
    return "foreground"
  }
}
