import bb.cascades 1.4
import bb.system 1.0
import QtQuick 1.0

ComponentDefinition {
    id: itemPageDefRoot

    property variant itemDataModel      // itemModel từ ModelManager
    property variant addItemSheetRef    // Sheet addItem
    property variant addListSheetRef    // Sheet addList (để edit list)

    Page {
        id: ipRoot
        property int lid: -1
        property string lname: ""

        onLidChanged: {
            if (lid >= 0) {
                models.rebuildItemModel(lid, logic.lists, logic.findListIdx)
                logic.lastListId = lid
                logic.buildCoverItems(lid)
            }
        }

        titleBar: TitleBar { title: ipRoot.lname }

        actions: [
            ActionItem {
                title: "Add your items"
                imageSource: "asset:///images/plus.png"
                ActionBar.placement: ActionBarPlacement.OnBar
                onTriggered: {
                    itemPageDefRoot.addItemSheetRef.targetListId = ipRoot.lid
                    itemPageDefRoot.addItemSheetRef.editItemId   = -1
                    itemPageDefRoot.addItemSheetRef.open()
                }
            },
            ActionItem {
                title: "Edit the list"
                imageSource: "asset:///images/listedit.png"
                ActionBar.placement: ActionBarPlacement.OnBar
                onTriggered: {
                    itemPageDefRoot.addListSheetRef.editListId = ipRoot.lid
                    itemPageDefRoot.addListSheetRef.open()
                }
            },
            ActionItem {
                title: "Share List"
                imageSource: "asset:///images/share.png"
                ActionBar.placement: ActionBarPlacement.InOverflow
                onTriggered: { logic.shareList(ipRoot.lid) }
            },
            ActionItem {
                title: "Select More"
                imageSource: "asset:///images/selectmore.png"
                ActionBar.placement: ActionBarPlacement.InOverflow
                onTriggered: { itemLV.multiSelectHandler.active = true }
            },
            DeleteActionItem {
                title: "Delete List"
                ActionBar.placement: ActionBarPlacement.InOverflow
                onTriggered: { logic.confirmDeleteList(ipRoot.lid) }
            }
        ]

        Container {
            layout: StackLayout {}
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment:   VerticalAlignment.Fill

            ListView {
                id: itemLV
                dataModel: itemPageDefRoot.itemDataModel
                layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }

                multiSelectAction: MultiSelectActionItem {}
                multiSelectHandler.actions: [
                    DeleteActionItem {
                        title: "Delete Selected"
                        onTriggered: {
                            var selection = itemLV.selectionList()
                            for (var i = selection.length - 1; i >= 0; i = i - 1) {
                                var item = itemLV.dataModel.data(selection[i])
                                logic.deleteItem(ipRoot.lid, item.id)
                            }
                            itemLV.clearSelection()
                        }
                    }
                ]

                listItemComponents: [
                    ListItemComponent {
                        CustomListItem {
                            id: ilRow
                            highlightAppearance: HighlightAppearance.Full
                            dividerVisible: true
                            contextActions: [
                                ActionSet {
                                    title: ListItemData.name
                                    ActionItem {
                                        title: "Copy"
                                        imageSource: "asset:///images/copy.png"
                                        onTriggered: { ilRow.ListItem.view.doCopy(ListItemData.name) }
                                    }
                                    DeleteActionItem {
                                        title: "Delete"
                                        onTriggered: { ilRow.ListItem.view.doDelete(ListItemData.id) }
                                    }
                                }
                            ]
                            Container {
                                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                                leftPadding: 20; rightPadding: 20
                                minHeight: 80
                                verticalAlignment: VerticalAlignment.Center
                                Container {
                                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                                    verticalAlignment: VerticalAlignment.Center
                                    Label {
                                        text: ListItemData.name
                                        textStyle.base: SystemDefaults.TextStyles.TitleText
                                        opacity: ListItemData.checked ? 0.35 : 1.0
                                        verticalAlignment: VerticalAlignment.Center
                                    }
                                    Label {
                                        text: ListItemData.note
                                        visible: ListItemData.note !== ""
                                        textStyle.color: Color.Gray
                                        verticalAlignment: VerticalAlignment.Center
                                    }
                                }
                                CheckBox {
                                    checked: ListItemData.checked
                                    verticalAlignment: VerticalAlignment.Center
                                    onCheckedChanged: {
                                        if (checked !== ListItemData.checked) {
                                            ilRow.ListItem.view.doToggle(ListItemData.id, checked)
                                        }
                                    }
                                }
                            }
                        }
                    }
                ]

                onTriggered: {
                    var it = dataModel.data(indexPath)
                    itemPageDefRoot.addItemSheetRef.targetListId = ipRoot.lid
                    itemPageDefRoot.addItemSheetRef.editItemId   = it.id
                    itemPageDefRoot.addItemSheetRef.open()
                }

                function doToggle(itemId, isChecked) { logic.toggleItem(ipRoot.lid, itemId, isChecked) }
                function doDelete(itemId)             { logic.deleteItem(ipRoot.lid, itemId) }
                function doCopy(text) {
                    app.copyToClipboard(text)
                    copyToast.show()
                }
            }
        }

        attachedObjects: [
            SystemToast {
                id: copyToast
                body: "Item copied to clipboard"
                position: SystemUiPosition.MiddleCenter
            }
        ]
    }
}
