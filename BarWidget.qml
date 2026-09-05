import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mcx424.market-hours"

  SessionEngine {
    id: engine
  }

  readonly property string displayTimezone: String(setting("displayTimezone", "Pacific/Auckland"))
  readonly property bool showCountdown: setting("showCountdown", true) !== false
  readonly property bool countDownToPre: setting("countDownToPre", false) === true
  readonly property int tickSeconds: Math.max(5, Number(setting("tickSeconds", 30)) || 30)

  readonly property var engineConfig: ({
    displayTimezone: root.displayTimezone,
    showCountdown: root.showCountdown,
    countDownToPre: root.countDownToPre,
    usPreStart: String(setting("usPreStart", "04:00")),
    usRegularOpen: String(setting("usRegularOpen", "09:30")),
    usRegularClose: String(setting("usRegularClose", "16:00")),
    usAhEnd: String(setting("usAhEnd", "20:00"))
  })

  property date now: new Date()
  property string chipText: "US · …"
  property string colorRole: "foreground"

  readonly property color barFg: root.bar ? root.bar.foreground : Color.foreground
  readonly property color positiveColor: {
    if (typeof Color !== "undefined" && Color.accent) return Color.accent
    return "#3d9a5f"
  }
  readonly property color warningColor: {
    if (typeof Color !== "undefined" && Color.urgent) return Color.urgent
    return "#c9a227"
  }
  readonly property color chipForeground: {
    if (root.colorRole === "positive") return root.positiveColor
    if (root.colorRole === "warning") return root.warningColor
    return root.barFg
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("engine" in target) target.engine = engine
    if ("engineConfig" in target) target.engineConfig = root.engineConfig
    if ("now" in target) target.now = root.now
  }

  function refresh() {
    root.now = clock.date
    root.chipText = engine.chipLabel(root.now, root.engineConfig)
    root.colorRole = engine.chipColorRole(root.now, root.engineConfig)
    if (panelLoader.item) {
      if ("now" in panelLoader.item) panelLoader.item.now = root.now
      if ("engineConfig" in panelLoader.item) panelLoader.item.engineConfig = root.engineConfig
      if (typeof panelLoader.item.refresh === "function") panelLoader.item.refresh()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    refresh()
  }

  Component.onCompleted: {
    refresh()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
    onDateChanged: {
      if (!tick.running) root.refresh()
    }
  }

  Timer {
    id: tick
    interval: root.tickSeconds * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
      Qt.callLater(root.refresh)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.chipText
    foreground: root.chipForeground
    useActiveColor: false
    tooltipText: "Market hours — left click for details"
    onPressed: function (buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
