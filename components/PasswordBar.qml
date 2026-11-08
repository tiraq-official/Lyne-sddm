import QtQuick 2.11
import QtQuick.Controls 2.4

//
// PasswordBar — the frosted bar that appears once the user starts typing.
// Layout (left to right): avatar | password field + submit | power icons.
//
Item {
    id: bar
    property real u: 1

    property string userName:    ""
    property string userDisplay: ""
    property string userIcon:    ""
    property rect   frostRect:   Qt.rect(0, 0, 0, 0)

    property alias password: field.text
    signal submitted()

    property real h:        root.s(94)
    property real padH:     root.s(20)
    property real avatarD:  root.s(56)
    property real fieldH:   root.s(52)
    property real fieldW:   root.s(250)
    property real submitD:  root.s(40)
    property real iconD:    root.s(34)
    property real gap:      root.s(16)

    implicitWidth:  padH * 2 + row.implicitWidth
    implicitHeight: h
    width:  implicitWidth
    height: implicitHeight

    function focusPassword() { field.forceActiveFocus() }
    function clearPassword() { field.text = "" }
    function appendText(t)   { field.text += t; field.cursorPosition = field.text.length }

    FrostedBackdrop {
        anchors.fill: parent
        sourceItem: bgLayer
        sourceRect: bar.frostRect
        cornerRadius: root.s(27)
        blurRadius: root.pillBlur
    }

    Rectangle {
        anchors.fill: parent
        radius: root.s(27)
        color: root.cGlassStrong
        border.color: root.cStroke
        border.width: 1
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: bar.h
        spacing: bar.gap

        // ------------------------------------------------------------ avatar
        Item {
            width: bar.avatarD
            height: bar.h

            Item {
                id: avatarWrap
                width: bar.avatarD
                height: bar.avatarD
                anchors.centerIn: parent

                // an avatar set in theme.conf always wins; otherwise fall back to
                // the account's own ~/.face.icon when we can crop it
                readonly property bool showUserIcon: root.avatarImage === "" && roundLoader.status === Loader.Ready && bar.userIcon !== ""

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.cGlass
                    border.color: root.cStroke
                    border.width: 1
                }

                Loader {
                    id: roundLoader
                    anchors.fill: parent
                    active: root.avatarImage === "" && bar.userIcon !== ""
                    source: "RoundImage.qml"
                    onLoaded: item.source = bar.userIcon
                }

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: root.avatarImage
                    fillMode: Image.PreserveAspectCrop
                    visible: !avatarWrap.showUserIcon && root.avatarImage !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !avatarWrap.showUserIcon && (root.avatarImage === "" || avatarImg.status !== Image.Ready)
                    text: bar.userDisplay !== "" ? bar.userDisplay.charAt(0).toUpperCase() : "?"
                    color: root.cText
                    font.family: root.fontFamily
                    font.pixelSize: root.s(22)
                }
            }
        }

        // ---------------------------------------------------- password field
        Item {
            width: bar.fieldW
            height: bar.h

            Rectangle {
                id: frame
                anchors.centerIn: parent
                width: bar.fieldW
                height: bar.fieldH
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.30)
                border.width: 1
                border.color: field.activeFocus ? root.cAccent : Qt.rgba(1, 1, 1, 0.18)
                Behavior on border.color { ColorAnimation { duration: 140 } }

                TextField {
                    id: field
                    anchors.left: parent.left
                    anchors.leftMargin: root.s(20)
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - bar.submitD - root.s(34)
                    height: parent.height
                    background: null
                    color: root.cText
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    passwordMaskDelay: 0
                    font.family: root.fontFamily
                    font.pixelSize: root.s(20)
                    font.letterSpacing: root.s(4)
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    onAccepted: bar.submitted()
                }

                Rectangle {
                    id: submit
                    anchors.right: parent.right
                    anchors.rightMargin: root.s(6)
                    anchors.verticalCenter: parent.verticalCenter
                    width: bar.submitD
                    height: bar.submitD
                    radius: height / 2
                    color: submitArea.containsMouse ? "#ffffff" : "#e9f3ff"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.46
                        height: width
                        name: "arrow"
                        color: "#13294a"
                    }

                    MouseArea {
                        id: submitArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: bar.submitted()
                    }
                }
            }
        }

        // ------------------------------------------------------- power icons
        Row {
            id: powerRow
            height: bar.h
            spacing: root.s(8)

            IconButton { width: bar.iconD; height: powerRow.height; iconName: "moon";    visible: root.canSuspend;  onClicked: sddm.suspend() }
            IconButton { width: bar.iconD; height: powerRow.height; iconName: "restart"; visible: root.canReboot;   onClicked: sddm.reboot() }
            IconButton { width: bar.iconD; height: powerRow.height; iconName: "power";   visible: root.canPowerOff; onClicked: sddm.powerOff() }
        }
    }
}
