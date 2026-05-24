import bb.cascades 1.4
import QtQuick 1.0

Sheet {
    id: addItemSheetRoot

    property int targetListId: -1
    property int editItemId:   -1
    property int smartMode:     2

    property variant logicRef   // AppLogic instance

    onOpened: {
        itName.text  = ""
        itNote.text  = ""
        itBatch.text = ""
        smartMode    = 2
        itemModeCtrl.setSelectedIndex(2)

        if (editItemId >= 0) {
            var li = logicRef.findListIdx(targetListId)
            if (li >= 0) {
                for (var i = 0; i < logicRef.lists[li].items.length; i = i + 1) {
                    if (logicRef.lists[li].items[i].id === editItemId) {
                        itName.text = logicRef.lists[li].items[i].name
                        itNote.text = logicRef.lists[li].items[i].note || ""
                        break
                    }
                }
            }
        }
    }

    Page {
        titleBar: TitleBar {
            title: addItemSheetRoot.editItemId < 0 ? "Add Items" : "Edit Item"
            dismissAction: ActionItem {
                title: "Cancel"
                onTriggered: { addItemSheetRoot.close() }
            }
            acceptAction: ActionItem {
                title: "Save"
                onTriggered: {
                    if (addItemSheetRoot.editItemId >= 0) {
                        logicRef.updateItem(addItemSheetRoot.targetListId,
                                            addItemSheetRoot.editItemId,
                                            itName.text, itNote.text)
                    } else if (addItemSheetRoot.smartMode === 2) {
                        logicRef.addItemSingle(addItemSheetRoot.targetListId, itName.text, itNote.text)
                    } else {
                        logicRef.addItemsBatch(addItemSheetRoot.targetListId, itBatch.text)
                    }
                    addItemSheetRoot.close()
                }
            }
        }

        Container {
            layout: StackLayout {}
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment:   VerticalAlignment.Fill

            ScrollView {
                layoutProperties: StackLayoutProperties { spaceQuota: -1 }
                horizontalAlignment: HorizontalAlignment.Fill
                Container {
                    leftPadding: 16; rightPadding: 16; topPadding: 20; bottomPadding: 16
                    horizontalAlignment: HorizontalAlignment.Fill

                    SegmentedControl {
                        id: itemModeCtrl
                        visible: addItemSheetRoot.editItemId < 0
                        onSelectedIndexChanged: { addItemSheetRoot.smartMode = selectedIndex }
                        Option { text: "Detection"; value: 0 }
                        Option { text: "Copy";      value: 1 }
                        Option { text: "Single";    value: 2; selected: true }
                    }

                    Container {
                        visible: addItemSheetRoot.smartMode === 2 || addItemSheetRoot.editItemId >= 0
                        topMargin: 20
                        Label { text: "Item name"; bottomMargin: 6 }
                        TextField { id: itName; hintText: "Enter item..."; preferredHeight: 80; horizontalAlignment: HorizontalAlignment.Fill }
                        Label { text: "Note (optional)"; topMargin: 20; bottomMargin: 6 }
                        TextArea { id: itNote; hintText: "Add a note..."; minHeight: 100; preferredHeight: 120; horizontalAlignment: HorizontalAlignment.Fill }
                    }

                    Label {
                        visible: (addItemSheetRoot.smartMode === 0 || addItemSheetRoot.smartMode === 1)
                                 && addItemSheetRoot.editItemId < 0
                        text: addItemSheetRoot.smartMode === 0
                              ? "Type items separated by comma, semicolon or newline:"
                              : "Paste clipboard text - items split automatically:"
                        multiline: true; textStyle.color: Color.Gray
                        topMargin: 20; bottomMargin: 6
                    }
                }
            }

            Container {
                visible: (addItemSheetRoot.smartMode === 0 || addItemSheetRoot.smartMode === 1)
                         && addItemSheetRoot.editItemId < 0
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment:   VerticalAlignment.Fill
                leftPadding: 16; rightPadding: 16; bottomPadding: 16
                layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                TextArea {
                    id: itBatch
                    hintText: addItemSheetRoot.smartMode === 0
                              ? "e.g. Milk, Eggs, Bread, Butter..."
                              : "Paste your clipboard text here..."
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment:   VerticalAlignment.Fill
                    minHeight: 200
                }
            }
        }
    }
}
