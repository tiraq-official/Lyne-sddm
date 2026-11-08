import QtQuick 2.11
import QtQuick.Controls 2.4

//
// SessionSelector — the desktop-environment / session picker shown on the
// RIGHT of the unlock pill. The list is whatever SDDM reports (Hyprland,
// i3, Plasma, GNOME, ...), so it always matches what is installed.
//
Item {
    id: session
    property real u: 1

    property int selIndex: {
        if (typeof sessionModel === "undefined" || sessionModel === null) return 0;
        var li = sessionModel.lastIndex;
        return (li !== undefined && li >= 0) ? li : 0;
    }
    property string selName: ""
    property rect   frostRect: Qt.rect(0, 0, 0, 0)

    implicitWidth:  row.implicitWidth + root.s(30)
    implicitHeight: root.s(42)
    width:  implicitWidth
    height: implicitHeight

    Repeater {
        id: proxy
        model: sessionModel
        onCountChanged: session.sync()
        delegate: Item {
            visible: false
            property string n: (typeof model.name !== "undefined" && model.name) ? model.name : ""
        }
    }

    function sync() {
        var it = proxy.itemAt(session.selIndex);
        if (it) session.selName = it.n;
    }
    Component.onCompleted: Qt.callLater(session.sync)

    FrostedBackdrop {
        anchors.fill: parent
        sourceItem: bgLayer
        sourceRect: session.frostRect
        cornerRadius: session.height / 2
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
        height: session.height
        spacing: root.s(9)

        Icon {
            width: root.s(18)
            height: row.height
            name: "monitor"
            color: root.cText
        }
        Text {
            height: row.height
            text: session.selName !== "" ? session.selName : "Session"
            color: root.cText
            font.family: root.fontFamily
            font.pixelSize: root.s(17)
            verticalAlignment: Text.AlignVCenter
        }
        Icon {
            width: root.s(13)
            height: row.height
            name: "chevron"
            color: root.cText
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: popup.open()
    }

    Popup {
        id: popup
        parent: session
        x: 0
        y: -height - root.s(8)
        width: Math.max(session.width, root.s(210))
        padding: root.s(8)

        background: Rectangle {
            radius: root.s(16)
            color: root.cGlassStrong
            border.color: root.cStroke
            border.width: 1
        }

        contentItem: ListView {
            id: sessionList
            clip: true
            implicitHeight: Math.min(contentHeight, root.s(280))
            model: sessionModel
            currentIndex: session.selIndex
            delegate: ItemDelegate {
                width: sessionList.width
                height: root.s(44)
                leftPadding: root.s(14)
                rightPadding: root.s(14)
                background: Rectangle {
                    radius: root.s(10)
                    color: parent.hovered ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                }
                contentItem: Text {
                    text: model.name
                    color: root.cText
                    font.family: root.fontFamily
                    font.pixelSize: root.s(17)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                onClicked: {
                    session.selIndex = index;
                    popup.close();
                }
            }
        }
    }
}
