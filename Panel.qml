import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "mcx424.market-hours"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var engine: null
  property var engineConfig: ({})
  property date now: new Date()

  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color mutedForeground: Qt.darker(contentForeground, 1.55)

  readonly property color openColor: "#2f6b45"
  readonly property color closedColor: "#7a2e2e"
  readonly property color extendedColor: "#9a7b2f"

  property var marketRows: []

  function open() {
    refresh()
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function pillColor(status) {
    if (status === "open") return root.openColor
    if (status === "extended") return root.extendedColor
    return root.closedColor
  }

  function refresh() {
    if (!root.engine) return
    root.marketRows = root.engine.allMarkets(root.now, root.engineConfig || {})
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function (direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(8)

        Text {
          width: parent.width
          text: "MARKET HOURS"
          color: root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: true
          font.letterSpacing: 1.2
        }

        Rectangle {
          width: parent.width
          height: Style.spacing.hairline
          color: root.contentForeground
          opacity: 0.18
        }

        Repeater {
          model: root.marketRows

          Column {
            width: content.width
            spacing: 0

            Item {
              width: parent.width
              height: Style.space(36)

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.name
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }

              Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                height: Style.space(22)
                width: pillLabel.implicitWidth + Style.space(16)
                radius: height / 2
                color: root.pillColor(modelData.status)

                Text {
                  id: pillLabel
                  anchors.centerIn: parent
                  text: modelData.statusLabel
                  color: "#ffffff"
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                  anchors.right: parent.right
                  text: modelData.verb
                  color: root.mutedForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                }

                Text {
                  anchors.right: parent.right
                  text: modelData.countdownHHMM
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
              }
            }

            Rectangle {
              width: parent.width
              height: Style.spacing.hairline
              color: root.contentForeground
              opacity: 0.12
              visible: index < root.marketRows.length - 1
            }
          }
        }
      }
    }
  }
}
