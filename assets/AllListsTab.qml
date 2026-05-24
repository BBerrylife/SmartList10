import bb.cascades 1.4
import QtQuick 1.0

Tab {
    id: tabAllRoot
    property int catId: -1
    title: "All"
    imageSource: "asset:///images/home.png"
    description: "All lists you made"

    property variant listDataModel      // allListModel từ ModelManager
    property variant itemPageDef        // ComponentDefinition của ItemPage
    property variant addListSheetRef    // Sheet addList để mở

    signal rebuildListModelRequested(int catId)

    onTriggered: {
        rebuildListModelRequested(-1)
    }

    NavigationPane {
        id: mainNav
        onPopTransitionEnded: { page.destroy() }

        Page {
            id: allPage
            onCreationCompleted: {
                logic.listDeleted.connect(function(deletedId) {
                    if (mainNav.top !== null && mainNav.top !== undefined
                            && mainNav.top.lid !== undefined
                            && mainNav.top.lid === deletedId) {
                        mainNav.pop()
                    }
                })
            }

            titleBar: TitleBar { title: "SmartList10: All Lists" }

            actions: [
                ActionItem {
                    title: "Add a new list"
                    imageSource: "asset:///images/plus.png"
                    ActionBar.placement: ActionBarPlacement.OnBar
                    onTriggered: {
                        tabAllRoot.addListSheetRef.editListId  = -1
                        tabAllRoot.addListSheetRef.selCatId    = -1
                        tabAllRoot.addListSheetRef.selSmartMode = -1
                        tabAllRoot.addListSheetRef.open()
                    }
                },
                ActionItem {
                    title: "Select More"
                    imageSource: "asset:///images/selectmore.png"
                    ActionBar.placement: ActionBarPlacement.InOverflow
                    onTriggered: { mainListView.multiSelectHandler.active = true }
                }
            ]

            Container {
                layout: StackLayout {}
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment:   VerticalAlignment.Fill

                ListView {
                    id: mainListView
                    dataModel: tabAllRoot.listDataModel
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }

                    function itemType(data, indexPath) {
                        return (indexPath.length === 1) ? "header" : "item"
                    }

                    multiSelectAction: MultiSelectActionItem {}
                    multiSelectHandler.actions: [
                        DeleteActionItem {
                            title: "Delete Selected"
                            onTriggered: {
                                var selection = mainListView.selectionList()
                                for (var i = selection.length - 1; i >= 0; i = i - 1) {
                                    var item = mainListView.dataModel.data(selection[i])
                                    if (item.isHeader !== true) logic.deleteList(item.id)
                                }
                                mainListView.clearSelection()
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
                                id: mainRow
                                highlightAppearance: HighlightAppearance.Full
                                dividerVisible: true
                                contextActions: [
                                    ActionSet {
                                        title: ListItemData.listName
                                        ActionItem {
                                            title: "Edit"
                                            imageSource: "asset:///images/listedit.png"
                                            onTriggered: { mainRow.ListItem.view.doEditList(ListItemData.id) }
                                        }
                                        ActionItem {
                                            title: "Share"
                                            imageSource: "asset:///images/share.png"
                                            onTriggered: { mainRow.ListItem.view.doShareList(ListItemData.id) }
                                        }
                                        DeleteActionItem {
                                            title: "Delete"
                                            onTriggered: { mainRow.ListItem.view.doConfirmDeleteList(ListItemData.id) }
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
                        var p = tabAllRoot.itemPageDef.createObject()
                        p.lid   = item.id
                        p.lname = item.listName
                        mainNav.push(p)
                    }

                    function doDeleteList(lid)        { logic.deleteList(lid) }
                    function doConfirmDeleteList(lid)  { logic.confirmDeleteList(lid) }
                    function doEditList(lid)           { tabAllRoot.addListSheetRef.editListId = lid; tabAllRoot.addListSheetRef.open() }
                    function doShareList(lid)          { logic.shareList(lid) }
                }
            }
        }
    }

    property alias navPane: mainNav
}
