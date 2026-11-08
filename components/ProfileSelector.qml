import QtQuick 2.11
import QtQuick.Controls 2.4

//
// ProfileSelector — the account ("profile") picker shown on the LEFT of the
// unlock pill. Only the profile's display name is shown, per the design.
//
Item {
    id: profile
    property real u: 1

    property int currentIndex: {
        if (typeof userModel === "undefined" || userModel === null) return 0;
        var li = userModel.lastIndex;
        return (li !== undefined && li >= 0) ? li : 0;
    }
    property string userName:    ""
    property string userDisplay: ""
    property string userIcon:    ""
    property rect   frostRect:   Qt.rect(0, 0, 0, 0)

    implicitWidth:  row.implicitWidth + root.s(30)
    implicitHeight: root.s(42)
    width:  implicitWidth
    height: implicitHeight

    // Reads the roles of every user so the selected one can be shown without
    // relying on index-dependent model access.
    Repeater {
        id: proxy
        model: userModel
        onCountChanged: profile.sync()
        delegate: Item {
            visible: false
            property string n:  (typeof model.name     !== "undefined" && model.name)     ? model.name     : ""
            property string d:  (typeof model.realName !== "undefined" && model.realName) ? model.realName : n
            property string ic: (typeof model.icon     !== "undefined" && model.icon)     ? model.icon     : ""
        }
    }

    function sync() {
        var it = proxy.itemAt(profile.currentIndex);
        if (it) {
            profile.userName    = it.n;
            profile.userDisplay = it.d;
            profile.userIcon    = it.ic;
        }
    }
    Component.onCompleted: Qt.callLater(profile.sync)

    FrostedBackdrop {
        anchors.fill: parent
        sourceItem: bgLayer
        sourceRect: profile.frostRect
        cornerRadius: profile.height / 2
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
        height: profile.height
        spacing: root.s(9)

        Icon {
            width: root.s(18)
            height: row.height
            name: "person"
            color: root.cText
        }
        Text {
            height: row.height
            text: profile.userDisplay !== "" ? profile.userDisplay : "User"
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
        parent: profile
        x: 0
        y: -height - root.s(8)
        width: Math.max(profile.width, root.s(210))
        padding: root.s(8)

        background: Rectangle {
            radius: root.s(16)
            color: root.cGlassStrong
            border.color: root.cStroke
            border.width: 1
        }

        contentItem: ListView {
            id: userList
            clip: true
            implicitHeight: Math.min(contentHeight, root.s(280))
            model: userModel
            currentIndex: profile.currentIndex
            delegate: ItemDelegate {
                width: userList.width
                height: root.s(44)
                leftPadding: root.s(14)
                rightPadding: root.s(14)
                background: Rectangle {
                    radius: root.s(10)
                    color: parent.hovered ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                }
                contentItem: Text {
                    text: (typeof model.realName !== "undefined" && model.realName && model.realName.length) ? model.realName : model.name
                    color: root.cText
                    font.family: root.fontFamily
                    font.pixelSize: root.s(17)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                onClicked: {
                    profile.currentIndex = index;
                    popup.close();
                }
            }
        }
    }
}
