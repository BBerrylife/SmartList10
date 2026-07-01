import bb.cascades 1.4
import bb.system 1.0
import QtQuick 1.0

TabbedPane {
    id: root
    showTabsOnActionBar: false
    sidebarState: SidebarState.VisibleCompact

    property variant _prevTab:       null
    property variant _dynTabHandles: []

    // Called by C++ via QMetaObject::invokeMethod on thumbnail
    function prepareCoverData() { logic.prepareCoverData() }

    Menu.definition: MenuDefinition {
        settingsAction: SettingsActionItem {
            title: "Settings"
            imageSource: "asset:///images/settings.png"
            onTriggered: { settingsSheet.open() }
        }
        actions: [
            ActionItem {
                title: "About"
                imageSource: "asset:///images/about.png"
                onTriggered: { aboutSheet.open() }
            },
            ActionItem {
                title: "Feedback"
                imageSource: "asset:///images/email.png"
                onTriggered: { app.invokeEmail("Berrylife2025@gmail.com", "SmartList10 Feedback") }
            }
        ]
    }

    onCreationCompleted: {
        root._prevTab = tabAll
        app.muteActionTriggered.connect(logic.handleMute)
        app.shareTargetsReady.connect(function(targets) {
            dimFadeOut.play()
            sharePicker.openWithTargets(targets)
        })
        logic.appHandle = app
        logic.storage   = storage
        logic.loadAll()
    }

    onActiveTabChanged: {
        if (activeTab !== tabAddCat && activeTab !== null && activeTab !== undefined)
            root._prevTab = activeTab
        if (activeTab === tabAll) {
            logic.activeCatId = -1
            models.rebuildListModel(-1, logic.lists, -1)
        } else if (activeTab === tabAddCat) {
            // handled by onTriggered
        } else if (activeTab && typeof activeTab.catId !== "undefined" && activeTab.catId !== null) {
            logic.activeCatId = activeTab.catId
            models.rebuildListModel(activeTab.catId, logic.lists, activeTab.catId)
        }
    }

    function rebuildCatTabs() {
        var old = _dynTabHandles
        for (var i = 0; i < old.length; i = i + 1) root.remove(old[i])
        _dynTabHandles = []
        var handles = []
        for (var j = 0; j < logic.categories.length; j = j + 1) {
            var t = catTabDef.createObject()
            t.catId = logic.categories[j].id
            t.title = logic.categories[j].name
            root.insert(j + 1, t)
            handles.push(t)
        }
        _dynTabHandles = handles
    }

    AllListsTab {
        id: tabAll
        listDataModel:   models.allListModel
        itemPageDef:     itemPageDef
        addListSheetRef: addListSheet
    }

    Tab {
        id: tabAddCat
        property int catId: -1
        title: "Add a new category"
        imageSource: "asset:///images/newcategory.png"
        onTriggered: { addCatSheet.open(); addCatRedirectTimer.start() }
    }

    attachedObjects: [
        AppStorage   { id: storage },
        AppLogic     { id: logic },
        ModelManager { id: models },

        Connections {
            target: logic

            onUseHeadersInListsChanged:   { app.useHeadersInLists    = logic.useHeadersInLists }
            onUseSmartFrameChanged:       { app.useSmartFrame        = logic.useSmartFrame }
            onShowSmartFrameInfoChanged:  { app.showSmartFrameInfo   = logic.showSmartFrameInfo }
            onVolumeUpCheckChanged:       { app.volumeUpCheck        = logic.volumeUpCheck }
            onSmartFrameScrollModeChanged:{ app.smartFrameScrollMode = logic.smartFrameScrollMode }
            onItemScaleChanged:           { app.itemScale            = logic.itemScale }

            onCategoriesChanged: {
                models.rebuildCatModel(logic.categories)
                rebuildCatTabs()
            }
            onListModelRebuildNeeded: {
                models.rebuildListModel(catId, logic.lists, logic.activeCatId)
            }
            onItemModelRebuildNeeded: {
                models.rebuildItemModel(listId, logic.lists, logic.findListIdx)
            }
            onCoverUpdateNeeded:          { logic.buildCoverItems(listId) }
            onDeleteToastRequested:       { deleteToast.body = message; deleteToast.show() }
            onConfirmDeleteListRequested: { deleteListDialog.show() }
            onConfirmDeleteCatRequested:  { deleteCatDialog.show() }
            onSwitchToAllTabRequested:    { root.activeTab = tabAll }
            onShareDialogRequested:       { sharePicker.pendingShareText = text; dimDialog.open() }

            // Update page title after rename without rebuilding nav stack
            onListsChanged: {
                var name = logic.lastListName
                var lid  = logic.lastListId
                if (tabAll.navPane.top && tabAll.navPane.top.lid === lid)
                    tabAll.navPane.top.lname = name
                for (var ri = 0; ri < root._dynTabHandles.length; ri = ri + 1) {
                    var dh = root._dynTabHandles[ri]
                    if (dh.navPane && dh.navPane.top && dh.navPane.top.lid === lid) {
                        dh.navPane.top.lname = name; break
                    }
                }
            }
        },

        // Redirect away from the "Add category" tab slot after opening the sheet
        Timer {
            id: addCatRedirectTimer
            interval: 50; repeat: false
            onTriggered: {
                root.activeTab = (root._prevTab && root._prevTab !== tabAddCat)
                                 ? root._prevTab : tabAll
            }
        },

        SystemToast {
            id: deleteToast
            body: ""
            position: SystemUiPosition.MiddleCenter
        },
        SystemDialog {
            id: deleteCatDialog
            title: "Delete Category"
            body: "This category and all its lists will be permanently deleted. Continue?"
            confirmButton.label: "Delete"
            cancelButton.label:  "Cancel"
            onFinished: {
                if (result === SystemUiResult.ConfirmButtonSelection)
                    logic._doDeleteCategory(logic._pendingDeleteCatId)
                logic._pendingDeleteCatId = -1
            }
        },
        SystemDialog {
            id: deleteListDialog
            title: "Delete List"
            body: "This list and all its items will be permanently deleted. Continue?"
            confirmButton.label: "Delete"
            cancelButton.label:  "Cancel"
            onFinished: {
                if (result === SystemUiResult.ConfirmButtonSelection)
                    logic.deleteList(logic._pendingDeleteListId)
                logic._pendingDeleteListId = -1
            }
        },

        // Dim overlay shown while querying share targets
        Dialog {
            id: dimDialog
            Container {
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment:   VerticalAlignment.Fill
                background: Color.create(0, 0, 0, 0.5)
                opacity: 0.0
                animations: [
                    FadeTransition {
                        id: dimFadeIn
                        duration: 150; toOpacity: 1.0
                        onEnded: { app.queryShareTargets(logic._pendingShareText) }
                    },
                    FadeTransition {
                        id: dimFadeOut
                        duration: 150; toOpacity: 0.0
                        onEnded: { dimDialog.close() }
                    }
                ]
            }
            onOpened: { dimFadeIn.play() }
        },

        SettingsSheet { id: settingsSheet; logicRef: logic },
        AboutSheet    { id: aboutSheet },
        AddListSheet  { id: addListSheet; logicRef: logic; catDataModel: models.catModel },
        AddCatSheet {
            id: addCatSheet
            logicRef:   logic
            prevTabRef: root._prevTab
            onNewCatCreated: {
                for (var ti = 0; ti < root._dynTabHandles.length; ti = ti + 1) {
                    if (root._dynTabHandles[ti].catId === catId) {
                        root.activeTab = root._dynTabHandles[ti]; break
                    }
                }
            }
        },
        AddItemSheet     { id: addItemSheet; logicRef: logic },
        SharePickerSheet { id: sharePicker },

        CatTabDef {
            id: catTabDef
            catListDataModel: models.catListModel
            itemPageDefRef:   itemPageDef
            addListSheetRef:  addListSheet
        },
        ItemPageDef {
            id: itemPageDef
            itemDataModel:   models.itemModel
            addItemSheetRef: addItemSheet
            addListSheetRef: addListSheet
        }
    ]
}
