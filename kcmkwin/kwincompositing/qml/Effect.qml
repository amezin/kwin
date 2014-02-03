/**************************************************************************
* KWin - the KDE window manager                                          *
* This file is part of the KDE project.                                  *
*                                                                        *
* Copyright (C) 2013 Antonis Tsiapaliokas <kok3rs@gmail.com>             *
*                                                                        *
* This program is free software; you can redistribute it and/or modify   *
* it under the terms of the GNU General Public License as published by   *
* the Free Software Foundation; either version 2 of the License, or      *
* (at your option) any later version.                                    *
*                                                                        *
* This program is distributed in the hope that it will be useful,        *
* but WITHOUT ANY WARRANTY; without even the implied warranty of         *
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
* GNU General Public License for more details.                           *
*                                                                        *
* You should have received a copy of the GNU General Public License      *
* along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
**************************************************************************/


import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import org.kde.kwin.kwincompositing 1.0
import QtMultimedia 5.0 as Multimedia
import org.kde.qtextracomponents 2.0 as QtExtra

Item {
    id: item
    width: parent.width
    height: 40
    signal changed()
    property alias checked: effectStatusCheckBox.checked

    Rectangle {
        id: background
        color: item.ListView.isCurrentItem ? effectView.backgroundActiveColor : index % 2 ? effectView.backgroundNormalColor : effectView.backgroundAlternateColor
        anchors.fill : parent

        RowLayout {
            id: rowEffect
            anchors.fill: parent
            CheckBox {
                function isDesktopSwitching() {
                    if (model.ServiceNameRole == "kwin4_effect_slide") {
                        return true;
                    } else if (model.ServiceNameRole == "kwin4_effect_fadedesktop") {
                        return true;
                    } else if (model.ServiceNameRole == "kwin4_effect_cubeslide") {
                        return true;
                    } else {
                        return false;
                    }
                }
                function isWindowManagementEnabled() {
                    if (model.ServiceNameRole == "kwin4_effect_dialogparent") {
                        windowManagementEnabled = effectStatusCheckBox.checked;
                        return windowManagementEnabled = effectStatusCheckBox.checked && windowManagementEnabled;
                    } else if (model.ServiceNameRole == "kwin4_effect_desktopgrid") {
                        windowManagementEnabled = effectStatusCheckBox.checked;
                        return windowManagementEnabled = effectStatusCheckBox.checked && windowManagementEnabled;
                    } else if (model.ServiceNameRole == "kwin4_effect_presentwindows") {
                        windowManagementEnabled = effectStatusCheckBox.checked;
                        return windowManagementEnabled = effectStatusCheckBox.checked && windowManagementEnabled;
                    }
                    return windowManagementEnabled;
                }

                id: effectStatusCheckBox
                property bool windowManagementEnabled;
                checked: model.EffectStatusRole
                exclusiveGroup: isDesktopSwitching() ? desktopSwitching : null

                onCheckedChanged: item.changed()
                Connections {
                    target: searchModel
                    onDataChanged: {
                        effectStatusCheckBox.checked = model.EffectStatusRole;
                    }
                }
            }

            Item {
                id: effectItem
                width: effectView.width - effectStatusCheckBox.width - aboutButton.width - configureButton.width
                height: item.height
                anchors.top: rowEffect.top
                anchors.left: effectStatusCheckBox.right
                MouseArea {
                    id: area
                    width: effectView.width - effectStatusCheckBox.width
                    height: effectView.height
                    onClicked: {
                        effectView.currentIndex = index;
                    }
                }
                Column {
                    id: col
                    height: parent.height
                    Text {
                        text: model.NameRole
                    }
                    Text {
                        id: desc
                        function wrapDescription() {
                            if (wrapMode == Text.NoWrap) {
                                wrapMode = Text.WordWrap;
                                elide = Text.ElideNone;
                            } else {
                                wrapMode = Text.NoWrap;
                                elide = Text.ElideRight;
                            }
                        }
                        text: model.DescriptionRole
                        width: effectView.width - 100
                        elide: Text.ElideRight
                    }
                    Item {
                        id:aboutItem
                        anchors.top: desc.bottom
                        anchors.topMargin: 20
                        visible: false

                        Text {
                            text: "Author: " + model.AuthorNameRole + "\n" + "License: " + model.LicenseRole
                            font.bold: true
                        }
                        PropertyAnimation {id: animationAbout; target: aboutItem; property: "visible"; to: !aboutItem.visible}
                        PropertyAnimation {id: animationAboutSpacing; target: item; property: "height"; to: item.height == 40 ?  item.height + 100 : 40}
                    }
                    Multimedia.Video {
                        id: videoItem
                        function showHide() {
                            replayButton.visible = false;
                            if (videoItem.visible === true) {
                                videoItem.stop();
                                videoItem.visible = false;
                                // TODO: this should be done in a better way
                                item.height = item.height - 400;
                            } else {
                                videoItem.visible = true;
                                videoItem.play();
                                item.height = item.height + 400;
                            }
                        }
                        autoLoad: false
                        source: model.VideoRole
                        visible: false
                        width: 400
                        height: 400
                        anchors.bottom: parent.bottom
                        BusyIndicator {
                            anchors.centerIn: parent
                            visible: videoItem.status == Multimedia.MediaPlayer.Loading
                            running: true
                        }
                        MouseArea {
                            // it's a mouse area with icon inside to not have an ugly button background
                            id: replayButton
                            visible: false
                            anchors.fill: parent
                            onClicked: {
                                replayButton.visible = false;
                                videoItem.play();
                            }
                            QtExtra.QIconItem {
                                id: replayIcon
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                icon: "media-playback-start"
                            }
                            Connections {
                                target: videoItem
                                onStopped: {
                                    replayButton.visible = true
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                anchors.right: parent.right
                Button {
                    id: videoButton
                    visible: model.VideoRole.toString() !== ""
                    iconName: "video"
                    onClicked: videoItem.showHide()
                }
                Button {
                    id: configureButton
                    visible: effectConfig.effectUiConfigExists(model.ServiceNameRole)
                    enabled: effectStatusCheckBox.checked
                    iconName: "configure"
                    onClicked: {
                        effectConfig.openConfig(model.NameRole);
                    }
                }

                Button {
                    id: aboutButton
                    iconName: "dialog-information"
                    onClicked: {
                        animationAbout.running = true;
                        animationAboutSpacing.running = true;
                        desc.wrapDescription();
                    }
                }
            }

            EffectConfig {
                id: effectConfig
            }

        } //end Row
    } //end Rectangle
} //end item
