import bb.cascades 1.4
import QtQuick 1.0

Sheet {
    id: addListSheetRoot

    property int editListId:  -1   // -1 = thêm mới
    property int selCatId:    -1
    property int selSmartMode: 2

    property variant logicRef   // AppLogic instance
    property variant catDataModel  // catModel từ ModelManager

    onOpened: {
        lsName.text      = ""
        lsSmartInput.text = ""
        selSmartMode     = -1
        lsSmartDD.setSelectedIndex(-1)

        var savedCatId = selCatId
        lsCatDD.removeAll()
        lsCatDD.add(optNoneTmpl.createObject())
        for (var k = 0; k < catDataModel.size(); k = k + 1) {
            var opt  = optTmpl.createObject()
            opt.text  = catDataModel.value(k).name
            opt.value = catDataModel.value(k).id
            lsCatDD.add(opt)
        }
        selCatId = savedCatId

        if (editListId >= 0) {
            var li = logicRef.findListIdx(editListId)
            if (li >= 0) {
                lsName.text = logicRef.lists[li].name
                selCatId    = logicRef.lists[li].categoryId
            }
        }

        var foundIdx = 0
        for (var i = 0; i < lsCatDD.count(); i = i + 1) {
            if (lsCatDD.at(i).value === selCatId) {
                foundIdx = i; break
            }
        }
        lsCatDD.setSelectedIndex(foundIdx)
    }

    Page {
        titleBar: TitleBar {
            title: addListSheetRoot.editListId < 0 ? "Add a new list" : "Edit List"
            dismissAction: ActionItem {
                title: "Cancel"
                onTriggered: { addListSheetRoot.close() }
            }
            acceptAction: ActionItem {
                title: "Save"
                onTriggered: {
                    if (lsName.text.trim() === "") return
                    try {
                        var targetCatId = -1
                        if (lsCatDD.selectedValue !== undefined && lsCatDD.selectedValue !== null) {
                            targetCatId = parseInt(lsCatDD.selectedValue)
                        } else if (addListSheetRoot.selCatId !== undefined && addListSheetRoot.selCatId !== null) {
                            targetCatId = parseInt(addListSheetRoot.selCatId)
                        }
                        if (isNaN(targetCatId)) targetCatId = -1

                        var trimmed = lsName.text.trim()
                        if (addListSheetRoot.editListId < 0) {
                            var modeToUse = (addListSheetRoot.selSmartMode === -1) ? 2 : addListSheetRoot.selSmartMode
                            logicRef.createList(trimmed, targetCatId, modeToUse, lsSmartInput.text)
                        } else {
                            logicRef.renameList(addListSheetRoot.editListId, trimmed, targetCatId)
                        }
                        addListSheetRoot.close()
                    } catch (e) {
                        console.log("Lỗi Save List: " + e)
                        addListSheetRoot.close()
                    }
                }
            }
        }

        ScrollView {
            Container {
                horizontalAlignment: HorizontalAlignment.Fill
                topPadding: 8

                Label {
                    text: "Create a new list by filling out the forms below"
                    multiline: true; textStyle.color: Color.Gray
                    horizontalAlignment: HorizontalAlignment.Center
                    textStyle.textAlign: TextAlign.Center
                    leftMargin: 20; rightMargin: 20
                }

                Container { preferredHeight: 2 }

                Container {
                    horizontalAlignment: HorizontalAlignment.Fill
                    leftPadding: 20; rightPadding: 20; bottomPadding: 10
                    TextField {
                        id: lsName
                        hintText: "Enter the list name..."
                        horizontalAlignment: HorizontalAlignment.Fill
                    }
                }

                Container {
                    horizontalAlignment: HorizontalAlignment.Fill
                    leftPadding: 20; rightPadding: 20; topPadding: 10; bottomPadding: 10
                    DropDown {
                        id: lsCatDD
                        title: "Category"
                        horizontalAlignment: HorizontalAlignment.Fill
                        onSelectedValueChanged: {
                            if (selectedValue !== undefined && selectedValue !== null) {
                                addListSheetRoot.selCatId = selectedValue
                            }
                        }
                    }
                }

                Container {
                    visible: addListSheetRoot.editListId < 0
                    horizontalAlignment: HorizontalAlignment.Fill
                    leftPadding: 20; rightPadding: 20; topPadding: 10; bottomPadding: 10
                    DropDown {
                        id: lsSmartDD
                        title: "SmartMode"
                        horizontalAlignment: HorizontalAlignment.Fill
                        onSelectedValueChanged: {
                            if (selectedValue !== undefined && selectedValue !== null) {
                                addListSheetRoot.selSmartMode = selectedValue
                            }
                        }
                        Option { text: "Single Entries";  value: 2 }
                        Option { text: "SmartDetection";  value: 0 }
                        Option { text: "SmartCopy";       value: 1 }
                    }
                }

                Label {
                    visible: addListSheetRoot.editListId < 0
                    text: {
                        if (addListSheetRoot.selSmartMode === -1 || addListSheetRoot.selSmartMode === 2)
                            return "Items can be added after the list is created."
                        if (addListSheetRoot.selSmartMode === 0)
                            return "Type items below, separated by comma, semicolon or newline."
                        return "Paste clipboard text below — items will be split automatically."
                    }
                    multiline: true; textStyle.color: Color.Gray
                    horizontalAlignment: HorizontalAlignment.Center
                    textStyle.textAlign: TextAlign.Center
                    topMargin: 2; bottomMargin: 6; leftMargin: 20; rightMargin: 20
                }

                Container {
                    visible: (addListSheetRoot.selSmartMode === 0 || addListSheetRoot.selSmartMode === 1)
                             && addListSheetRoot.editListId < 0
                    horizontalAlignment: HorizontalAlignment.Fill
                    leftPadding: 20; rightPadding: 20; topPadding: 4; bottomPadding: 20
                    TextArea {
                        id: lsSmartInput
                        hintText: addListSheetRoot.selSmartMode === 0
                                  ? "e.g. Milk, Eggs, Bread, Butter..."
                                  : "Paste clipboard text here..."
                        minHeight: 200; preferredHeight: 260
                        horizontalAlignment: HorizontalAlignment.Fill
                    }
                }
            }
        }
    }

    attachedObjects: [
        ComponentDefinition { id: optTmpl;     Option {} },
        ComponentDefinition { id: optNoneTmpl; Option { text: "None"; value: -1; selected: true } }
    ]
}
