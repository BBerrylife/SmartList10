import bb.cascades 1.4
import bb.cascades.pickers 1.0
import bb.system 1.0
import QtQuick 1.0

Sheet {
    id: settingsSheetRoot

    property variant logicRef   // AppLogic instance

    Page {
        titleBar: TitleBar {
            title: "Settings"
            acceptAction: ActionItem {
                title: "Close"
                onTriggered: {
                    logicRef.storage.saveAll(logicRef.dataSnapshot())
                    settingsSheetRoot.close()
                }
            }
        }

        attachedObjects: [
            SystemToast {
                id: volKeyWarningToast
                body: "WARNING: Using 'Volume key navigation' will disable the system volume controls while the SmartFrame is active."
                position: SystemUiPosition.MiddleCenter
            },
            SystemToast {
                id: howToToast
                body: "Export saves a backup .json file to /accounts/1000/shared/documents/smartlist10. Import reads a SmartList10 backup, a Microsoft To Do export, or a Google Keep note .json file. Full guide coming soon."
                position: SystemUiPosition.MiddleCenter
            },
            SystemToast {
                id: backupResultToast
                body: ""
                position: SystemUiPosition.MiddleCenter
            },
            FilePicker {
                id: importPicker
                title: "Select a .json file to import"
                type: FileType.Other
                filter: [ "*.json" ]
                mode: FilePickerMode.Picker
                directories: [ app.downloadsPath(), "/accounts/1000/shared/misc/" ]
                onFileSelected: {
                    logicRef.importFromFile(selectedFiles[0])
                }
            },
            Connections {
                target: logicRef
                onExportFinished: {
                    backupResultToast.body = message
                    backupResultToast.show()
                }
                onImportFinished: {
                    backupResultToast.body = message
                    backupResultToast.show()
                }
            }
        ]

        ScrollView {
            Container {
                horizontalAlignment: HorizontalAlignment.Fill
                topPadding: 30; leftPadding: 30; rightPadding: 30; bottomPadding: 60

                Label { text: "Settings"; textStyle.base: SystemDefaults.TextStyles.TitleText }

                Container {
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    topMargin: 20
                    Label {
                        text: "Use SmartFrame when minimized"
                        layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                        verticalAlignment: VerticalAlignment.Center; multiline: true
                    }
                    ToggleButton {
                        checked: logicRef.useSmartFrame
                        onCheckedChanged: { logicRef.useSmartFrame = checked }
                    }
                }

                Container {
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    topMargin: 10
                    enabled: logicRef.useSmartFrame
                    opacity: logicRef.useSmartFrame ? 1.0 : 0.4
                    Label {
                        text: "Use headers in lists when these are bigger than 8"
                        layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                        verticalAlignment: VerticalAlignment.Center; multiline: true
                    }
                    ToggleButton {
                        checked: logicRef.useHeadersInLists
                        onCheckedChanged: { logicRef.useHeadersInLists = checked }
                    }
                }

                Container {
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    topMargin: 10
                    enabled: logicRef.useSmartFrame
                    opacity: logicRef.useSmartFrame ? 1.0 : 0.4
                    Label {
                        text: "Show SmartFrame info when app is minimized"
                        layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                        verticalAlignment: VerticalAlignment.Center; multiline: true
                    }
                    ToggleButton {
                        checked: logicRef.showSmartFrameInfo
                        onCheckedChanged: { logicRef.showSmartFrameInfo = checked }
                    }
                }

                Label {
                    text: "Choose a mode for the SmartFrame scrolling"
                    multiline: true; topMargin: 20
                }
                DropDown {
                    id: scrollModeDropDown
                    horizontalAlignment: HorizontalAlignment.Fill
                    Option { text: "Smooth scroll (default)"; value: 0; selected: logicRef.smartFrameScrollMode === 0 }
                    Option { text: "Volume key navigation";   value: 1; selected: logicRef.smartFrameScrollMode === 1 }
                    onSelectedValueChanged: {
                        if (selectedValue === 1 && logicRef.smartFrameScrollMode !== 1) {
                            logicRef.smartFrameScrollMode = 1
                            volKeyWarningToast.show()
                        } else {
                            logicRef.smartFrameScrollMode = selectedValue
                        }
                    }
                }

                Container {
                    visible: logicRef.smartFrameScrollMode === 0
                    topMargin: 20
                    Label {
                        text: "Control the sensitivity of the scrolling speed in SmartFrame (slow to fast)"
                        multiline: true; textStyle.color: Color.Gray
                    }
                    Container {
                        topPadding: 20; bottomPadding: 20
                        horizontalAlignment: HorizontalAlignment.Fill
                        Slider {
                            id: speedSlider
                            fromValue: 0.0; toValue: 2.0
                            value: app.smartFrameScrollSpeed
                            horizontalAlignment: HorizontalAlignment.Fill
                            onImmediateValueChanged: { app.smartFrameScrollSpeed = immediateValue }
                        }
                    }
                }

                Container {
                    visible: logicRef.smartFrameScrollMode === 0
                    topMargin: 10
                    Label {
                        text: "Change the size of list elements in the SmartFrame:"
                        multiline: true; textStyle.color: Color.Gray
                    }
                    Slider {
                        fromValue: 1.0; toValue: 1.25
                        value: logicRef.itemScale
                        horizontalAlignment: HorizontalAlignment.Fill; topMargin: 10
                        onValueChanged: {
                            logicRef.itemScale    = value
                            logicRef.useLargeItems = (value > 1.15)
                        }
                    }
                }

                Divider { topMargin: 30; bottomMargin: 20 }

                Label { text: "Backup"; textStyle.base: SystemDefaults.TextStyles.TitleText }
                Label {
                    text: "Export your data, or import lists from a SmartList10 backup, Microsoft To Do, or Google Keep. Backups are saved to Documents/smartlist10."
                    multiline: true; textStyle.color: Color.Gray; topMargin: 10
                }

                Button {
                    text: "Export"
                    horizontalAlignment: HorizontalAlignment.Fill; topMargin: 16
                    onClicked: {
                        logicRef.storage.saveAll(logicRef.dataSnapshot())
                        logicRef.exportToFile()
                    }
                }
                Button {
                    text: "Import"
                    horizontalAlignment: HorizontalAlignment.Fill; topMargin: 10
                    onClicked: { importPicker.open() }
                }
                Button {
                    text: "How to Export / Import"
                    horizontalAlignment: HorizontalAlignment.Fill; topMargin: 10
                    onClicked: { howToToast.show() }
                }

                Container {
                    visible: app.themeSwitchSupported

                    Divider { topMargin: 30; bottomMargin: 20 }

                    Label { text: "Appearance"; textStyle.base: SystemDefaults.TextStyles.TitleText }
                    Container {
                        layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                        topMargin: 20
                        Label {
                            text: "Dark Theme"
                            layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                            verticalAlignment: VerticalAlignment.Center; multiline: true
                        }
                        ToggleButton {
                            checked: logicRef.darkTheme
                            onCheckedChanged: {
                                logicRef.darkTheme = checked
                                app.setDarkTheme(checked)
                                logicRef.storage.saveAll(logicRef.dataSnapshot())
                            }
                        }
                    }
                    Label {
                        text: "Enabling dark mode at night reduces eye strain and saves battery on OLED displays."
                        multiline: true; textStyle.color: Color.Gray; topMargin: 10
                    }
                }
            }
        }
    }
}
