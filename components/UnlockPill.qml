import QtQuick 2.11

//
// UnlockPill — the idle "Type your password to unlock" pill.
//
Item {
    id: pill
    property real u: 1
    property rect frostRect: Qt.rect(0, 0, 0, 0)
    signal activated()

    implicitWidth:  row.implicitWidth + root.s(40)
    implicitHeight: root.s(42)
    width:  implicitWidth
    height: implicitHeight

    FrostedBackdrop {
        anchors.fill: parent
        sourceItem: bgLayer
        sourceRect: pill.frostRect
        cornerRadius: pill.height / 2
        blurRadius: root.pillBlur
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: area.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : root.cGlass
        border.color: root.cStroke
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: pill.height
        spacing: root.s(11)

        Icon {
            width: root.s(15)
            height: row.height
            name: "lock"
            color: root.cText
        }
        Text {
            height: row.height
            text: root.promptText
            color: root.cText
            font.family: root.monoFamily
            font.pixelSize: root.s(16)
            font.letterSpacing: root.s(0.6)
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: pill.activated()
    }
}
