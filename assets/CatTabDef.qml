import bb.cascades 1.4
import QtQuick 1.0

ComponentDefinition {
    id: catTabDefRoot

    property variant catListDataModel   // catListModel từ ModelManager
    property variant itemPageDefRef     // ComponentDefinition của ItemPage
    property variant addListSheetRef    // Sheet addList

    Tab {
        id: dynTab
        property int catId: -1
        property alias navPane: dynNav
        title: ""
        description: title !== "" ? (title + " Lists") : "Lists"
        imageSource: "asset:///images/category.png"

        onTriggered: {
            if (catId !== -1) {
                logic.activeCatId = catId
                models.rebuildListModel(catId, logic.lists, catId)
            }
        }

        NavigationPane {
            id: dynNav
            onPopTransitionEnded: { page.destroy() }

            Page {
                id: dynPage
                property int pageCatId: dynTab.catId

                onCreationCompleted: {
                    logic.listDeleted.connect(function(deletedId) {
                        if (dynNav.top !== null && dynNav.top !== undefined
                                && dynNav.top.lid !== undefined
                                && dynNav.top.lid === deletedId) {
                            dynNav.pop()
                        }
                    })
                }

                titleBar: TitleBar { title: dynTab.title !== "" ? dynTab.title : "Lists" }

                actions: [
                    ActionItem {
                        title: "Add a new list"
                        imageSource: "asset:///images/plus.png"
                        ActionBar.placement: ActionBarPlacement.OnBar
                        onTriggered: {
                            catTabDefRoot.addListSheetRef.editListId  = -1
                            catTabDefRoot.addListSheetRef.selCatId    = dynPage.pageCatId
                            catTabDefRoot.addListSheetRef.selSmartMode = -1
                            catTabDefRoot.addListSheetRef.open()
                        }
                    },
                    ActionItem {
                        title: "Delete Category"
                        imageSource: "asset:///images/delete.png"
                        ActionBar.placement: ActionBarPlacement.InOverflow
                        onTriggered: { logic.deleteCategory(dynPage.pageCatId) }
                    },
                    ActionItem {
                        title: "Select More"
                        imageSource: "asset:///images/selectmore.png"
                        ActionBar.placement: ActionBarPlacement.InOverflow
                        onTriggered: { dynLV.multiSelectHandler.active = true }
                    }
                ]

                Container {
                    layout: StackLayout {}
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment:   VerticalAlignment.Fill

                    ListView {
                        id: dynLV
                        dataModel: catTabDefRoot.catListDataModel
                        layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }

                        function itemType(data, indexPath) {
                            return (indexPath.length === 1) ? "header" : "item"
                        }

                        multiSelectAction: MultiSelectActionItem {}
                        multiSelectHandler.actions: [
                            DeleteActionItem {
                                title: "Delete Selected"
                                onTriggered: {
                                    var selection = dynLV.selectionList()
                                    for (var i = selection.length - 1; i >= 0; i = i - 1) {
                                        var item = dynLV.dataModel.data(selection[i])
                                        if (item.isHeader !== true) logic.deleteList(item.id)
                                    }
                                    dynLV.clearSelection()
                                }
                            }
                        ]

                        listItemComponents: [
                            ListItemComponent {
                                type: "header"
                                Header { title: ListItemData.toString() }
                            },
                            ListItemComponent {
                                type: "item"
                                CustomListItem {
                                    id: dynRow
                                    highlightAppearance: HighlightAppearance.Full
                                    dividerVisible: true
                                    contextActions: [
                                        ActionSet {
                                            title: ListItemData.listName
                                            ActionItem {
                                                title: "Edit"
                                                imageSource: "asset:///images/listedit.png"
                                                onTriggered: { dynRow.ListItem.view.doEditList(ListItemData.id) }
                                            }
                                            ActionItem {
                                                title: "Share"
                                                imageSource: "asset:///images/share.png"
                                                onTriggered: { dynRow.ListItem.view.doShareList(ListItemData.id) }
                                            }
                                            DeleteActionItem {
                                                title: "Delete"
                                                onTriggered: { dynRow.ListItem.view.doConfirmDeleteList(ListItemData.id) }
                                            }
                                        }
                                    ]
                                    Container {
                                        layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                                        leftPadding: 20; rightPadding: 20
                                        topPadding: 16; bottomPadding: 16
                                        minHeight: 80
                                        verticalAlignment: VerticalAlignment.Center
                                        Label {
                                            text: ListItemData.listName
                                            textStyle.base: SystemDefaults.TextStyles.TitleText
                                            multiline: false
                                            verticalAlignment: VerticalAlignment.Center
                                            layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                                        }
                                    }
                                }
                            }
                        ]

                        onTriggered: {
                            if (indexPath.length === 1) return
                            var item = dataModel.data(indexPath)
                            if (item === null || item === undefined
                                    || item.id === undefined
                                    || typeof item.id !== "number") return
                            logic.lastListId   = item.id
                            logic.lastListName = item.listName
                            app.setCoverSelectedIdx(0)
                            logic.buildCoverItems(item.id)
                            var p = catTabDefRoot.itemPageDefRef.createObject()
                            p.lid   = item.id
                            p.lname = item.listName
                            dynNav.push(p)
                        }

                        function doDeleteList(lid)        { logic.deleteList(lid) }
                        function doConfirmDeleteList(lid)  { logic.confirmDeleteList(lid) }
                        function doEditList(lid)           { catTabDefRoot.addListSheetRef.editListId = lid; catTabDefRoot.addListSheetRef.open() }
                        function doShareList(lid)          { logic.shareList(lid) }
                    }
                }
            }
        }
    }
}
