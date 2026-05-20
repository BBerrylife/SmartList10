import bb.cascades 1.4
import bb.data 1.0
import bb.system 1.0
import QtQuick 1.0

TabbedPane {
    id: root
    showTabsOnActionBar: false
    sidebarState: SidebarState.VisibleCompact
    
    function prepareCoverData() {
        if (lastListId !== -1 && findListIdx(lastListId) >= 0) {
            rebuildCoverModel(lastListId)
        } else if (lists.length > 0) {
            var fb = lists[lists.length - 1]
            lastListId   = fb.id
            lastListName = fb.name
            rebuildCoverModel(fb.id)
        } else {
            app.updateCover("SmartList10", 0, 0, [])
        }
    }
    
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
                title: "Email"
                imageSource: "asset:///images/email.png"
                onTriggered: {
                    app.invokeEmail("Berrylife2025@gmail.com", "SmartList10 Feedback")
                }
            }
        ]
    }
    
    property int nextCatId: 100
    property int nextListId: 100
    property int nextItemId: 1000
    property variant _prevTab: null
    
    property variant categories: []
    property variant lists: []
    property int activeCatId: -1
    property int lastListId: -1
    property string lastListName: ""
    property variant _dynTabHandles: []
    
    property bool useHeadersInLists: false
    onUseHeadersInListsChanged: {
        app.useHeadersInLists = useHeadersInLists
        rebuildListModel(activeCatId)
    }
    property bool useSmartFrame: true
    onUseSmartFrameChanged: { app.useSmartFrame = useSmartFrame }
    
    property bool showSmartFrameInfo: false
    onShowSmartFrameInfoChanged: { app.showSmartFrameInfo = showSmartFrameInfo }
    
    property bool volumeUpCheck: false
    onVolumeUpCheckChanged: { app.volumeUpCheck = volumeUpCheck }
    
    property int smartFrameScrollMode: 0
    onSmartFrameScrollModeChanged: { app.smartFrameScrollMode = smartFrameScrollMode }
    
    property real smartFrameScrollSpeed: 1.0
    property bool useLargeItems: false
    property real itemScale: 1.0
    onItemScaleChanged: { app.itemScale = itemScale }
    property bool darkTheme: false
    property bool _navigating: false
    
    function handleVolumeUp() {
        app.setCoverSelectedIdx(app.coverSelectedIdx - 1)
    }
    
    function handleVolumeDown() {
        app.setCoverSelectedIdx(app.coverSelectedIdx + 1)
    }

    function handleMute() {
        var idx = app.coverSelectedIdx
        var model = app.coverDataModel
        var itemCount = 0
        for (var ci = 0; ci < model.size(); ci = ci + 1) {
            var cv = model.value(ci)
            if (cv && cv.isHeader !== true) {
                if (itemCount === idx) {
                    toggleItem(lastListId, cv.id, !cv.checked)
                    return
                }
                itemCount = itemCount + 1
            }
        }
    }
    
    function getDB() {
        return openDatabaseSync("SmartList10DB", "1.0", "SmartList10 Storage", 1000000)
    }
    
    function initDB() {
        var db = getDB()
        db.transaction(function(tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS appdata(key TEXT PRIMARY KEY, value TEXT)')
        })
    }
    
    function saveAll() {
        var data = JSON.stringify({
                nextCatId: nextCatId,
                nextListId: nextListId,
                nextItemId: nextItemId,
                categories: categories,
                lists: lists,
                lastListId: lastListId,
                settings: {
                    useHeadersInLists: useHeadersInLists,
                    useSmartFrame: useSmartFrame,
                    showSmartFrameInfo: showSmartFrameInfo,
                    volumeUpCheck: volumeUpCheck,
                    smartFrameScrollMode: smartFrameScrollMode,
                    smartFrameScrollSpeed: smartFrameScrollSpeed,
                    useLargeItems: useLargeItems,
                    itemScale: itemScale,
                    darkTheme: darkTheme
                }
        })
        var db = getDB()
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO appdata(key, value) VALUES(?, ?)', ["alldata", data])
            tx.executeSql('INSERT OR REPLACE INTO appdata(key, value) VALUES(?, ?)', ["darkTheme", darkTheme ? "1" : "0"])
        })
    }
    
    function loadAll() {
        initDB()
        var db = getDB()
        db.transaction(function(tx) {
                var rs = tx.executeSql('SELECT value FROM appdata WHERE key = ?', ["alldata"])
                if (rs.rows.length > 0) {
                    try {
                        var o = JSON.parse(rs.rows.item(0).value)
                        nextCatId  = o.nextCatId  || 100
                        nextListId = o.nextListId || 100
                        nextItemId = o.nextItemId || 1000
                        categories = o.categories || []
                        lastListId = o.lastListId !== undefined ? o.lastListId : -1
                        
                        var rawLists = o.lists || []
                        for (var fixI = 0; fixI < rawLists.length; fixI = fixI + 1) {
                            if (typeof rawLists[fixI].name !== "string" || rawLists[fixI].name === "") {
                                rawLists[fixI].name = "List " + rawLists[fixI].id
                            }
                            if (rawLists[fixI].items) {
                                for (var fixJ = 0; fixJ < rawLists[fixI].items.length; fixJ = fixJ + 1) {
                                    rawLists[fixI].items[fixJ].checked = (rawLists[fixI].items[fixJ].checked === true || rawLists[fixI].items[fixJ].checked === "true")
                                }
                            }
                        }
                        lists = rawLists
                        
                        if (o.settings) {
                            useHeadersInLists    = o.settings.useHeadersInLists    || false
                            useSmartFrame        = o.settings.useSmartFrame        !== undefined ? o.settings.useSmartFrame : true
                            showSmartFrameInfo   = o.settings.showSmartFrameInfo   !== undefined ? o.settings.showSmartFrameInfo : false
                            volumeUpCheck        = o.settings.volumeUpCheck        || false
                            smartFrameScrollMode = o.settings.smartFrameScrollMode !== undefined ? o.settings.smartFrameScrollMode : 0
                            smartFrameScrollSpeed= o.settings.smartFrameScrollSpeed|| 1.0
                            useLargeItems        = o.settings.useLargeItems        || false
                            itemScale            = o.settings.itemScale !== undefined ? o.settings.itemScale : 1.0
                            app.itemScale        = itemScale
                            darkTheme            = o.settings.darkTheme            || false
                        }
                    } catch(e) {}
                }
                rebuildCatModel()
                rebuildListModel(-1, rawLists)
                
                if (lastListId >= 0) {
                    rebuildCoverModel(lastListId)
                    var li2 = findListIdx(lastListId)
                    if (li2 >= 0) { lastListName = lists[li2].name }
                }
        })
    }
    
    function findListIdx(id) {
        for (var i = 0; i < lists.length; i = i + 1) {
            if (lists[i].id === id) return i
        }
        return -1
    }
    
    function rebuildCatModel() {
        catModel.clear()
        for (var i = 0; i < categories.length; i = i + 1) {
            catModel.append({ "id": categories[i].id, "name": categories[i].name, "isCustom": true })
        }
        rebuildCatTabs()
    }
    
    function rebuildCatTabs() {
        var old = _dynTabHandles
        for (var i = 0; i < old.length; i = i + 1) {
            root.remove(old[i])
        }
        _dynTabHandles = []
        
        var insertIdx = 1
        var newHandles = []
        for (var j = 0; j < categories.length; j = j + 1) {
            var newTab = catTabDef.createObject()
            newTab.catId = categories[j].id
            newTab.title = categories[j].name
            root.insert(insertIdx, newTab)
            newHandles.push(newTab)
            insertIdx = insertIdx + 1
        }
        _dynTabHandles = newHandles
    }

    function rebuildListModel(catId, sourceList) {
        var src = (sourceList !== undefined && sourceList !== null) ? sourceList : lists

        // Hàm nội bộ: build mảng filtered + tính doneCount, trả về plain array
        function _buildFiltered(filterCatId) {
            var filtered = []
            for (var i = 0; i < src.length; i = i + 1) {
                var l = src[i]
                if (filterCatId === -1 || l.categoryId === filterCatId) {
                    var done = 0
                    var itemArray = l.items || []
                    for (var j = 0; j < itemArray.length; j = j + 1) {
                        if (itemArray[j] && itemArray[j].checked) done = done + 1
                    }
                    filtered.push({
                        "id": l.id,
                        "listName": l.name || ("List " + l.id),
                        "categoryId": l.categoryId,
                        "doneCount": done,
                        "items": itemArray
                    })
                }
            }
            return filtered
        }

        // All tab
        if (typeof allListModel !== 'undefined' && allListModel !== null) {
            allListModel.clear()
            allListModel.insertList(_buildFiltered(-1))
        }

        // Category tab
        var targetCatId = (catId !== undefined && catId !== -1) ? catId
                        : ((root.activeCatId !== undefined && root.activeCatId !== -1) ? root.activeCatId : -1)
        if (typeof catListModel !== 'undefined' && catListModel !== null) {
            catListModel.clear()
            if (targetCatId !== -1) {
                catListModel.insertList(_buildFiltered(targetCatId))
            }
        }
    }
    
    function rebuildItemModel(listId) {
        itemModel.clear()
        var li = findListIdx(listId)
        if (li < 0) return
        var its = lists[li].items
        for (var i = 0; i < its.length; i = i + 1) {
            itemModel.append({
                    "id": its[i].id,
                    "name": its[i].name,
                    "note": its[i].note || "",
                    "checked": its[i].checked
            })
        }
    }

    function rebuildCoverModel(listId) {
        var li = findListIdx(listId)
        if (li < 0) {
            app.updateCover("", 0, 0, [])
            return
        }
        var its = lists[li].items
        var done = 0
        var items = []
        for (var i = 0; i < its.length; i = i + 1) {
            if (its[i].checked) done = done + 1
            // Cover chỉ cần items — KHÔNG push headers dù useHeadersInLists=true.
            // Headers (sort A-Z) chỉ dành cho page All Lists và page Category, không cho Active Frame.
            items.push({ "id": its[i].id, "name": its[i].name, "checked": its[i].checked, "isHeader": false })
        }
        app.updateCover(lists[li].name, done, its.length, items)
    }
    
    function createCategory(name) {
        var n = name.trim()
        if (n === "") return -1
        var newId = nextCatId
        var tc = categories
        tc.push({ "id": newId, "name": n })
        categories = tc
        nextCatId = nextCatId + 1
        rebuildCatModel()
        saveAll()
        return newId
    }
    
    property int _pendingDeleteCatId: -1
    function deleteCategory(catId) {
        _pendingDeleteCatId = catId
        deleteCatDialog.show()
    }
    function _doDeleteCategory(catId) {
        var deletedCatName = ""
        for (var j0 = 0; j0 < categories.length; j0 = j0 + 1) {
            if (categories[j0].id === catId) { deletedCatName = categories[j0].name; break }
        }
        var kept = []
        for (var i = 0; i < lists.length; i = i + 1) {
            if (lists[i].categoryId !== catId) {
                kept.push(lists[i])
            } else {
                if (lists[i].id === lastListId) {
                    lastListId = -1
                    lastListName = ""
                }
            }
        }
        lists = kept
        var tc = []
        for (var j = 0; j < categories.length; j = j + 1) {
            if (categories[j].id !== catId) tc.push(categories[j])
        }
        categories = tc
        rebuildCatModel()
        rebuildListModel(-1)
        root.activeTab = tabAll
        saveAll()
        deleteToast.body = "\"" + deletedCatName + "\" successfully deleted."
        deleteToast.show()
    }
    
    function createList(name, catId, smartMode, smartText) {
        var n = name.trim()
        if (n === "") return
        var newList = { "id": nextListId, "name": n, "categoryId": catId, "items": [] }
        nextListId = nextListId + 1
        if ((smartMode === 0 || smartMode === 1) && smartText.trim() !== "") {
            var parts = smartText.split(/[\n,;]+/)
            for (var i = 0; i < parts.length; i = i + 1) {
                var s = parts[i].trim()
                if (s) {
                    newList.items.push({ "id": nextItemId, "name": s, "note": "", "checked": false })
                    nextItemId = nextItemId + 1
                }
            }
        }
        var tl = lists
        tl.push(newList)
        lists = tl
        lastListId   = newList.id
        lastListName = newList.name
        app.setCoverSelectedIdx(0)
        rebuildCoverModel(newList.id)
        rebuildListModel(activeCatId)
        saveAll()
    }
    
    function deleteList(listId) {
        var t = []
        var deletedName = ""
        for (var i = 0; i < lists.length; i = i + 1) {
            if (lists[i].id !== listId) {
                t.push(lists[i])
            } else {
                deletedName = lists[i].name
            }
        }
        lists = t
        if (lastListId === listId) {
            if (lists.length > 0) {
                var fb = lists[lists.length - 1]
                lastListId   = fb.id
                lastListName = fb.name
                app.setCoverSelectedIdx(0)
                rebuildCoverModel(fb.id)
            } else {
                lastListId   = -1
                lastListName = ""
                app.updateCover("SmartList10", 0, 0, [])
            }
        }
        rebuildListModel(activeCatId)
        saveAll()
        _popAfterDelete()
        deleteToast.body = "\"" + deletedName + "\" successfully deleted."
        deleteToast.show()
    }

    signal listDeleted(int deletedId)
    function _popAfterDelete() { root.listDeleted(root._pendingDeleteListId) }

    property int _pendingDeleteListId: -1
    function confirmDeleteList(listId) {
        _pendingDeleteListId = listId
        deleteListDialog.show()
    }

    property string _pendingShareText: ""
    function shareList(listId) {
        var li = findListIdx(listId)
        if (li < 0) return
        var lst = lists[li]
        var text = lst.name + "\n"
        for (var i = 0; i < lst.items.length; i = i + 1) {
            var item = lst.items[i]
            text += (i + 1) + ". " + item.name + (item.checked ? " - Completed" : "") + "\n"
        }
        _pendingShareText = text.trim()
        
        dimDialog.open()
    }
    
    function renameList(listId, name, catId) {
        var li = findListIdx(listId)
        if (li < 0) return
        var tr = lists
        tr[li].name = name.trim()
        tr[li].categoryId = catId
        lists = tr
        if (listId === lastListId) {
            lastListName = name.trim()
            rebuildCoverModel(listId)
        }
        rebuildListModel(activeCatId)
        saveAll()

        // BUG 4 FIX: update lname cho cả mainNav (tab All) lẫn dynNav (tab category)
        var trimmedName = name.trim();
        if (mainNav.top !== null && mainNav.top !== undefined
                && mainNav.top.lid !== undefined && mainNav.top.lid === listId) {
            mainNav.top.lname = trimmedName;
        }
        for (var ri = 0; ri < root._dynTabHandles.length; ri = ri + 1) {
            var dh = root._dynTabHandles[ri];
            if (dh.navPane && dh.navPane.top !== null && dh.navPane.top !== undefined
                    && dh.navPane.top.lid !== undefined && dh.navPane.top.lid === listId) {
                dh.navPane.top.lname = trimmedName;
                break;
            }
        }
    }
    
    function addItemSingle(listId, name, note) {
        var n = name.trim()
        if (n === "") return
        var li = findListIdx(listId)
        if (li < 0) return
        var ts = lists
        ts[li].items.push({ "id": nextItemId, "name": n, "note": note.trim(), "checked": false })
        lists = ts
        nextItemId = nextItemId + 1
        rebuildItemModel(listId)
        rebuildListModel(activeCatId)
        if (listId === lastListId) rebuildCoverModel(listId)
        saveAll()
    }
    
    function addItemsBatch(listId, text) {
        var parts = text.split(/[\n,;]+/)
        var li = findListIdx(listId)
        if (li < 0) return
        var tb = lists
        for (var i = 0; i < parts.length; i = i + 1) {
            var s = parts[i].trim()
            if (s) {
                tb[li].items.push({ "id": nextItemId, "name": s, "note": "", "checked": false })
                nextItemId = nextItemId + 1
            }
        }
        lists = tb
        rebuildItemModel(listId)
        rebuildListModel(activeCatId)
        if (listId === lastListId) rebuildCoverModel(listId)
        saveAll()
    }
    
    function toggleItem(listId, itemId, isChecked) {
        var li = findListIdx(listId)
        if (li < 0) return
        var tt = lists
        for (var i = 0; i < tt[li].items.length; i = i + 1) {
            if (tt[li].items[i].id === itemId) {
                tt[li].items[i].checked = isChecked
                break
            }
        }
        lists = tt
        lastListId   = listId
        lastListName = lists[li].name
        rebuildItemModel(listId)
        rebuildListModel(activeCatId)
        rebuildCoverModel(listId)
        saveAll()
    }
    
    function updateItem(listId, itemId, name, note) {
        var li = findListIdx(listId)
        if (li < 0) return
        var tu = lists
        for (var i = 0; i < tu[li].items.length; i = i + 1) {
            if (tu[li].items[i].id === itemId) {
                tu[li].items[i].name = name.trim()
                tu[li].items[i].note = note.trim()
                break
            }
        }
        lists = tu
        rebuildItemModel(listId)
        if (listId === lastListId) rebuildCoverModel(listId)
        saveAll()
    }
    
    function deleteItem(listId, itemId) {
        var li = findListIdx(listId)
        if (li < 0) return
        var kept = []
        for (var i = 0; i < lists[li].items.length; i = i + 1) {
            if (lists[li].items[i].id !== itemId) kept.push(lists[li].items[i])
        }
        var td = lists
        td[li].items = kept
        lists = td
        rebuildItemModel(listId)
        rebuildListModel(activeCatId)
        if (listId === lastListId) rebuildCoverModel(listId)
        saveAll()
    }
    
    attachedObjects: [
        Timer {
            id: addCatRedirectTimer
            interval: 50
            repeat: false
            onTriggered: {
                // BUG 4 FIX: 50ms đủ để BB10 finish transition rồi mới switch tab,
                // tránh blank page flash. Sheet đã mở rồi nên user không thấy khoảng trắng.
                var prev = (root._prevTab !== null && root._prevTab !== undefined && root._prevTab !== tabAddCat)
                           ? root._prevTab : tabAll
                root.activeTab = prev
            }
        },
        ArrayDataModel  { id: catModel },
        GroupDataModel  { id: allListModel; sortingKeys: ["listName"]; grouping: ItemGrouping.ByFirstChar },
        GroupDataModel  { id: catListModel; sortingKeys: ["listName"]; grouping: ItemGrouping.ByFirstChar },
        ArrayDataModel  { id: itemModel },

        SystemToast {
            id: deleteToast
            body: ""
            position: SystemUiPosition.BottomCenter
        },
        SystemDialog {
            id: deleteCatDialog
            title: "Delete Category"
            body: "This category and all its lists will be permanently deleted. Continue?"
            confirmButton.label: "Delete"
            cancelButton.label: "Cancel"
            onFinished: {
                if (result === SystemUiResult.ConfirmButtonSelection) {
                    root._doDeleteCategory(root._pendingDeleteCatId)
                }
                root._pendingDeleteCatId = -1
            }
        },
        SystemDialog {
            id: deleteListDialog
            title: "Delete List"
            body: "This list and all its items will be permanently deleted. Continue?"
            confirmButton.label: "Delete"
            cancelButton.label: "Cancel"
            onFinished: {
                if (result === SystemUiResult.ConfirmButtonSelection) {
                    root.deleteList(root._pendingDeleteListId)
                }
                root._pendingDeleteListId = -1
            }
        },

        Dialog {
            id: dimDialog
            Container {
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                background: Color.create(0, 0, 0, 0.5)
                opacity: 0.0
                animations: [
                    FadeTransition {
                        id: dimFadeIn
                        duration: 150
                        toOpacity: 1.0
                        onEnded: {
                            app.queryShareTargets(root._pendingShareText);
                        }
                    },
                    FadeTransition {
                        id: dimFadeOut
                        duration: 150
                        toOpacity: 0.0
                        onEnded: { dimDialog.close(); }
                    }
                ]
            }
            onOpened: {
                dimFadeIn.play();
            }
        },

        Sheet {
            id: sharePickerSheet
            property variant targets: []

            function openWithTargets(tgts) {
                targets = tgts
                open()
            }

            Page {
                titleBar: TitleBar {
                    title: "Share"
                    dismissAction: ActionItem {
                        title: "Cancel"
                        onTriggered: { sharePickerSheet.close() }
                    }
                }
                ListView {
                    dataModel: ArrayDataModel { id: shareTargetModel }
                    listItemComponents: [
                        ListItemComponent {
                            CustomListItem {
                                dividerVisible: true
                                Container {
                                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                                    verticalAlignment: VerticalAlignment.Center
                                    leftPadding: 0; rightPadding: 16
                                    topPadding: 2; bottomPadding: 2
                                    ImageView {
                                        id: shareIcon
                                        imageSource: ListItemData.icon
                                        scalingMethod: ScalingMethod.AspectFit
                                        verticalAlignment: VerticalAlignment.Center
                                        horizontalAlignment: HorizontalAlignment.Left
                                        minWidth: 80
                                        preferredWidth: 77
                                        preferredHeight: 77
                                        onCreationCompleted: {
                                            if (!ListItemData.isNative) {
                                                preferredWidth  = 65
                                                preferredHeight = 65
                                            }
                                        }
                                    }
                                    Label {
                                        text: ListItemData.label
                                        verticalAlignment: VerticalAlignment.Center
                                        layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                                        leftMargin: 7
                                        textStyle.base: SystemDefaults.TextStyles.TitleText
                                    }
                                }
                            }
                        }
                    ]
                    onTriggered: {
                        var item = dataModel.data(indexPath)
                        sharePickerSheet.close()
                        app.invokeShareTarget(item.target, item.action, root._pendingShareText)
                    }
                }
            }
            onTargetsChanged: {
                shareTargetModel.clear()
                // BUG 3 FIX: C++ đã sort đúng thứ tự (bbmMain→bbmGroup→bbmChannel→text→
                // email→meeting→conn→remember→otherNat→third). QML chỉ cần append thẳng,
                // không cần sort lại. Sort lại ở QML gộp tất cả non-BBM vào "rest" làm mất
                // thứ tự remember đứng sau bbmChannel từ C++.
                for (var oi = 0; oi < targets.length; oi = oi + 1) {
                    shareTargetModel.append(targets[oi])
                }
            }
        },
        
        ComponentDefinition {
            id: catTabDef
            Tab {
                id: dynTab
                property int catId: -1
                property variant navPane: dynNav
                title: ""
                description: title !== "" ? (title + " Lists") : "Lists"
                imageSource: "asset:///images/category.png"
                
                onTriggered: {
                    if (catId !== -1) {
                        root.activeCatId = catId
                        root.rebuildListModel(root.activeCatId)
                    }
                }
                
                NavigationPane {
                    id: dynNav
                    onPopTransitionEnded: { page.destroy() }
                    Page {
                        onCreationCompleted: {
                            root.listDeleted.connect(function(deletedId) {
                                if (dynNav.top !== null && dynNav.top !== undefined
                                        && dynNav.top.lid !== undefined
                                        && dynNav.top.lid === deletedId) {
                                    dynNav.pop()
                                }
                            })
                        }
                        id: dynPage
                        property int pageCatId: dynTab.catId
                        titleBar: TitleBar { title: dynTab.title !== "" ? dynTab.title : "Lists" }
                        
                        actions: [
                            ActionItem {
                                title: "Add a new list"
                                imageSource: "asset:///images/plus.png"
                                ActionBar.placement: ActionBarPlacement.OnBar
                                onTriggered: {
                                    addListSheet.editListId = -1
                                    addListSheet.selCatId   = dynPage.pageCatId
                                    addListSheet.selSmartMode = -1 
                                    addListSheet.open()
                                }
                            },
                            ActionItem {
                                title: "Delete Category"
                                imageSource: "asset:///images/delete.png"
                                ActionBar.placement: ActionBarPlacement.InOverflow
                                onTriggered: { root.deleteCategory(dynPage.pageCatId) }
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
                                dataModel: catListModel
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
                                                if (item.isHeader !== true) root.deleteList(item.id)
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
                                                        imageSource: "asset:///images/edit.png"
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
                                                leftPadding: 20; rightPadding: 20; topPadding: 20; bottomPadding: 20
                                                Label {
                                                    text: ListItemData.listName
                                                    textStyle.base: SystemDefaults.TextStyles.TitleText
                                                    multiline: false
                                                }
                                            }
                                        }
                                    }
                                ]
                                onTriggered: {
                                    if (indexPath.length === 1) return  // GroupDataModel header
                                    var item = dataModel.data(indexPath)
                                    if (item === null || item === undefined || item.id === undefined || typeof item.id !== "number") return
                                    if (root._navigating) return
                                    root._navigating = true
                                    root.lastListId   = item.id
                                    root.lastListName = item.listName
                                    
                                    app.setCoverSelectedIdx(0)
                                    root.rebuildCoverModel(item.id)
                                    
                                    var p = itemPageDef.createObject()
                                    p.lid   = item.id
                                    p.lname = item.listName
                                    dynNav.push(p)
                                    root._navigating = false
                                }
                                function doDeleteList(lid) { root.deleteList(lid) }
                                function doConfirmDeleteList(lid) { root.confirmDeleteList(lid) }
                                function doEditList(lid) { addListSheet.editListId = lid; addListSheet.open() }
                                function doShareList(lid) { root.shareList(lid) }
                            }
                        }
                    }
                }
            }
        },

        Sheet {
            id: settingsSheet
            Page {
                titleBar: TitleBar {
                    title: "Settings"
                    acceptAction: ActionItem {
                        title: "Close"
                        onTriggered: { saveAll(); settingsSheet.close() }
                    }
                }
                attachedObjects: [
                    SystemToast {
                        id: volKeyWarningToast
                        body: "WARNING: Using 'Volume key naviagtion' will disable the system volume controls while the SmartFrame is active."
                        position: SystemUiPosition.MiddleCenter
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
                                text: "Use headers in lists when these are bigger than 8"
                                layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                                verticalAlignment: VerticalAlignment.Center; multiline: true
                            }
                            ToggleButton { checked: root.useHeadersInLists; onCheckedChanged: { root.useHeadersInLists = checked } }
                        }
                        Container {
                            layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                            topMargin: 10
                            Label {
                                text: "Use SmartFrame when minimized"
                                layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                                verticalAlignment: VerticalAlignment.Center; multiline: true
                            }
                            ToggleButton { checked: root.useSmartFrame; onCheckedChanged: { root.useSmartFrame = checked } }
                        }
                        Container {
                            layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                            topMargin: 10
                            Label {
                                text: "Show SmartFrame info when app is minimized"
                                layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                                verticalAlignment: VerticalAlignment.Center; multiline: true
                            }
                            ToggleButton { checked: root.showSmartFrameInfo; onCheckedChanged: { root.showSmartFrameInfo = checked } }
                        }
                        Label {
                            text: "Choose a mode for the SmartFrame scrolling"
                            multiline: true; topMargin: 20
                        }
                        DropDown {
                            id: scrollModeDropDown
                            horizontalAlignment: HorizontalAlignment.Fill
                            Option { text: "Smooth scroll (default)"; value: 0; selected: root.smartFrameScrollMode === 0 }
                            Option { text: "Volume key navigation"; value: 1; selected: root.smartFrameScrollMode === 1 }
                            onSelectedValueChanged: {
                                if (selectedValue === 1 && root.smartFrameScrollMode !== 1) {
                                    root.smartFrameScrollMode = 1
                                    volKeyWarningToast.show()
                                } else {
                                    root.smartFrameScrollMode = selectedValue
                                }
                            }
                        }
                        Container {
                            visible: root.smartFrameScrollMode === 0
                            topMargin: 20
                            Label {
                                text: "Control the sensitivity of the scrolling speed in SmartFrame (slow to fast)"
                                multiline: true; textStyle.color: Color.Gray
                            }
                            // Tìm đến Container điều chỉnh tốc độ trong settingsSheet và thay thế:
                            Container {
                                topPadding: 20; bottomPadding: 20
                                horizontalAlignment: HorizontalAlignment.Fill
                                
                                Slider {
                                    id: speedSlider
                                    // Đặt từ 0.0 đến 2.0 để giá trị trung tâm 1.0 nằm chính giữa thanh kéo
                                    fromValue: 0.0
                                    toValue: 2.0
                                    value: app.smartFrameScrollSpeed
                                    horizontalAlignment: HorizontalAlignment.Fill
                                    
                                    onImmediateValueChanged: {
                                        app.smartFrameScrollSpeed = immediateValue
                                    }
                                }
                            }                        }
                        Container {
                            visible: root.smartFrameScrollMode === 0
                            topMargin: 10
                            Label {
                                text: "Change the size of list elements in the SmartFrame:"
                                multiline: true; textStyle.color: Color.Gray
                            }
                            Slider {
                                fromValue: 1.0; toValue: 1.25; value: root.itemScale
                                horizontalAlignment: HorizontalAlignment.Fill; topMargin: 10
                                onValueChanged: {
                                    root.itemScale = value
                                    root.useLargeItems = (value > 1.15)
                                }
                            }
                        }
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
                                id: darkThemeToggle
                                checked: root.darkTheme
                                onCheckedChanged: { root.darkTheme = checked }
                            }
                        }
                        Label {
                            text: "Theme change requires app restart to take effect."
                            multiline: true; textStyle.color: Color.Gray; topMargin: 10
                        }
                        Button {
                            text: "Restart App to Apply Theme"
                            horizontalAlignment: HorizontalAlignment.Fill; topMargin: 16
                            onClicked: { saveAll(); app.minimizeApp() }
                        }
                    }
                }
            }
        },

        Sheet {
            id: aboutSheet
            Page {
                titleBar: TitleBar {
                    title: "About"
                    acceptAction: ActionItem {
                        title: "Close"
                        onTriggered: { aboutSheet.close() }
                    }
                }
                ScrollView {
                    Container {
                        horizontalAlignment: HorizontalAlignment.Fill
                        leftPadding: 50; rightPadding: 50; topPadding: 80; bottomPadding: 80
                        Label { text: "SmartList10"; textStyle.base: SystemDefaults.TextStyles.BigText }
                        Label { text: "Version 1.0.0"; textStyle.color: Color.Gray; topMargin: 4 }
                        Label { text: "Developed by BerryLife 2026"; textStyle.color: Color.Gray; topMargin: 4 }
                        Divider { topMargin: 30; bottomMargin: 20 }
                        Label {
                            text: "SmartDetection: enter multiple items at once, separated by commas, semicolons or newlines.\n\nSmartCopy: paste from clipboard, items are split automatically.\n\nSingle: add items one by one."
                            multiline: true; textStyle.color: Color.Gray
                        }
                        Divider { topMargin: 20; bottomMargin: 20 }
                        Label { text: "Follow us"; textStyle.base: SystemDefaults.TextStyles.BigText }
                        Button {
                            text: "Facebook"; horizontalAlignment: HorizontalAlignment.Fill; topMargin: 10
                            onClicked: { Qt.openUrlExternally("https://facebook.com/BBerrylife") }
                        }
                        Button {
                            text: "Website"; horizontalAlignment: HorizontalAlignment.Fill; topMargin: 4
                            onClicked: { Qt.openUrlExternally("https://BBerryLife.github.io") }
                        }
                    }
                }
            }
        },

        Sheet {
            id: addListSheet
            property int editListId: -1
            property int selCatId: -1
            property int selSmartMode: 2
            
            onOpened: {
                lsName.text = ""
                lsSmartInput.text = ""
                
                selSmartMode = -1 
                lsSmartDD.setSelectedIndex(-1)
                
                var savedCatId = selCatId
                lsCatDD.removeAll()
                lsCatDD.add(optNoneTmpl.createObject())
                for (var k = 0; k < catModel.size(); k = k + 1) {
                    var opt = optTmpl.createObject()
                    opt.text  = catModel.value(k).name
                    opt.value = catModel.value(k).id
                    lsCatDD.add(opt)
                }
                selCatId = savedCatId
                
                if (editListId >= 0) {
                    var li = findListIdx(editListId)
                    if (li >= 0) {
                        lsName.text = lists[li].name
                        selCatId    = lists[li].categoryId
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
                    title: addListSheet.editListId < 0 ? "Add a new list" : "Edit List"
                    dismissAction: ActionItem {
                        title: "Cancel"
                        onTriggered: { addListSheet.close() }
                    }
                    acceptAction: ActionItem {
                        title: "Save"
                        onTriggered: {
                            if (lsName.text.trim() === "") return

                            try {
                                // Lấy catId an toàn, chống undefined
                                var targetCatId = -1
                                if (lsCatDD.selectedValue !== undefined && lsCatDD.selectedValue !== null) {
                                    targetCatId = parseInt(lsCatDD.selectedValue)
                                } else if (addListSheet.selCatId !== undefined && addListSheet.selCatId !== null) {
                                    targetCatId = parseInt(addListSheet.selCatId)
                                }
                                if (isNaN(targetCatId)) targetCatId = -1

                                var trimmed = lsName.text.trim()
                                if (addListSheet.editListId < 0) {
                                    var modeToUse = (addListSheet.selSmartMode === -1) ? 2 : addListSheet.selSmartMode
                                    createList(trimmed, targetCatId, modeToUse, lsSmartInput.text)
                                } else {
                                    renameList(addListSheet.editListId, trimmed, targetCatId)
                                }
                                addListSheet.close()
                            } catch (e) {
                                console.log("Lỗi Save List: " + e)
                                addListSheet.close()
                            }
                        }
                    }
                }
                
                ScrollView {
                    Container {
                        horizontalAlignment: HorizontalAlignment.Fill
                        
                        Label {
                            text: "Create a new list by filling out the forms below"
                            multiline: true
                            textStyle.color: Color.Gray
                            textStyle.base: SystemDefaults.TextStyles.SubtitleText
                            horizontalAlignment: HorizontalAlignment.Center
                            textStyle.textAlign: TextAlign.Center
                            topMargin: 60; bottomMargin: 1; leftMargin: 20; rightMargin: 20
                        }

                        Container {
                            horizontalAlignment: HorizontalAlignment.Fill
                            leftPadding: 20; rightPadding: 20; topPadding: 10; bottomPadding: 10
                            TextField {
                                id: lsName; hintText: "Enter the list name..."
                                horizontalAlignment: HorizontalAlignment.Fill
                            }
                        }
                        
                        Container {
                            horizontalAlignment: HorizontalAlignment.Fill
                            leftPadding: 20; rightPadding: 20; topPadding: 10; bottomPadding: 10
                            DropDown {
                                id: lsCatDD; title: "Category"; horizontalAlignment: HorizontalAlignment.Fill
                                onSelectedValueChanged: { 
                                    if (selectedValue !== undefined && selectedValue !== null) {
                                        addListSheet.selCatId = selectedValue 
                                    }
                                }
                            }
                        }
                        
                        Container {
                            visible: addListSheet.editListId < 0
                            horizontalAlignment: HorizontalAlignment.Fill
                            leftPadding: 20; rightPadding: 20; topPadding: 10; bottomPadding: 10
                            DropDown {
                                id: lsSmartDD; title: "SmartMode"; horizontalAlignment: HorizontalAlignment.Fill
                                onSelectedValueChanged: { 
                                    if (selectedValue !== undefined && selectedValue !== null) {
                                        addListSheet.selSmartMode = selectedValue 
                                    }
                                }
                                Option { text: "Single Entries"; value: 2 }
                                Option { text: "SmartDetection"; value: 0 }
                                Option { text: "SmartCopy"; value: 1 }
                            }
                        }
                        
                        Label {
                            visible: addListSheet.editListId < 0
                            text: {
                                if (addListSheet.selSmartMode === -1 || addListSheet.selSmartMode === 2) return "Items can be added after the list is created."
                                if (addListSheet.selSmartMode === 0) return "Type items below, separated by comma, semicolon or newline."
                                return "Paste clipboard text below — items will be split automatically."
                            }
                            multiline: true
                            textStyle.color: Color.Gray
                            horizontalAlignment: HorizontalAlignment.Center
                            textStyle.textAlign: TextAlign.Center
                            topMargin: 2; bottomMargin: 6; leftMargin: 20; rightMargin: 20
                        }
                        
                        Container {
                            visible: (addListSheet.selSmartMode === 0 || addListSheet.selSmartMode === 1) && addListSheet.editListId < 0
                            horizontalAlignment: HorizontalAlignment.Fill
                            topMargin: 4; leftPadding: 16; rightPadding: 16; bottomPadding: 16
                            TextArea {
                                id: lsSmartInput
                                hintText: addListSheet.selSmartMode === 0 ? "e.g. Milk, Eggs, Bread, Butter..." : "Paste clipboard text here..."
                                minHeight: 200; preferredHeight: 260
                                horizontalAlignment: HorizontalAlignment.Fill
                            }
                        }
                    }
                }
            }
            attachedObjects: [
                ComponentDefinition { id: optTmpl; Option {} },
                ComponentDefinition { id: optNoneTmpl; Option { text: "None"; value: -1; selected: true } }
            ]
        },

        Sheet {
            id: addCatSheet
            Page {
                titleBar: TitleBar {
                    title: "Add a new Category"
                    dismissAction: ActionItem {
                        title: "Cancel"
                        onTriggered: {
                            addCatSheet.close()
                            if (root._prevTab !== null) root.activeTab = root._prevTab
                        }
                    }
                    acceptAction: ActionItem {
                        title: "Save"
                        onTriggered: {
                            var n = newCatName.text.trim()
                            if (n !== "") {
                                var newCatId = createCategory(n)
                                newCatName.text = ""
                                addCatSheet.close()
                                for (var ti = 0; ti < root._dynTabHandles.length; ti = ti + 1) {
                                    if (root._dynTabHandles[ti].catId === newCatId) {
                                        root.activeTab = root._dynTabHandles[ti]
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
                Container {
                    leftPadding: 30; rightPadding: 30; topPadding: 40
                    Label { text: "Category name" }
                    TextField {
                        id: newCatName; hintText: "e.g. Finance, College..."
                        topMargin: 6; preferredHeight: 80
                    }
                }
            }
        },

        Sheet {
            id: addItemSheet
            property int targetListId: -1
            property int editItemId: -1
            property int smartMode: 2
            
            onOpened: {
                itName.text = ""; itNote.text = ""; itBatch.text = ""
                smartMode = 2; itemModeCtrl.setSelectedIndex(2)
                
                if (editItemId >= 0) {
                    var li = findListIdx(targetListId)
                    if (li >= 0) {
                        for (var i = 0; i < lists[li].items.length; i = i + 1) {
                            if (lists[li].items[i].id === editItemId) {
                                itName.text = lists[li].items[i].name
                                itNote.text = lists[li].items[i].note || ""
                                break
                            }
                        }
                    }
                }
            }
            
            Page {
                titleBar: TitleBar {
                    title: addItemSheet.editItemId < 0 ? "Add Items" : "Edit Item"
                    dismissAction: ActionItem { title: "Cancel"; onTriggered: { addItemSheet.close() } }
                    acceptAction: ActionItem {
                        title: "Save"
                        onTriggered: {
                            if (addItemSheet.editItemId >= 0) {
                                updateItem(addItemSheet.targetListId, addItemSheet.editItemId, itName.text, itNote.text)
                            } else if (addItemSheet.smartMode === 2) {
                                addItemSingle(addItemSheet.targetListId, itName.text, itNote.text)
                            } else {
                                addItemsBatch(addItemSheet.targetListId, itBatch.text)
                            }
                            addItemSheet.close()
                        }
                    }
                }
                
                Container {
                    layout: StackLayout {}
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill

                    ScrollView {
                        layoutProperties: StackLayoutProperties { spaceQuota: -1 }
                        horizontalAlignment: HorizontalAlignment.Fill
                        Container {
                            leftPadding: 16; rightPadding: 16; topPadding: 20; bottomPadding: 16
                            horizontalAlignment: HorizontalAlignment.Fill
                            SegmentedControl {
                                id: itemModeCtrl
                                visible: addItemSheet.editItemId < 0
                                onSelectedIndexChanged: { addItemSheet.smartMode = selectedIndex }
                                Option { text: "Detection"; value: 0 }
                                Option { text: "Copy"; value: 1 }
                                Option { text: "Single"; value: 2; selected: true }
                            }
                            Container {
                                visible: addItemSheet.smartMode === 2 || addItemSheet.editItemId >= 0
                                topMargin: 24
                                Label { text: "Item name" }
                                TextField { id: itName; hintText: "Enter item..."; preferredHeight: 80 }
                                Label { text: "Note (optional)"; topMargin: 24 }
                                TextArea { id: itNote; hintText: "Add a note..."; minHeight: 100; preferredHeight: 120 }
                            }
                            Label {
                                visible: (addItemSheet.smartMode === 0 || addItemSheet.smartMode === 1) && addItemSheet.editItemId < 0
                                text: addItemSheet.smartMode === 0
                                      ? "Type items separated by comma, semicolon or newline:"
                                      : "Paste clipboard text - items split automatically:"
                                multiline: true; textStyle.color: Color.Gray
                                topMargin: 24; bottomMargin: 10
                            }
                        }
                    }
                    Container {
                        visible: (addItemSheet.smartMode === 0 || addItemSheet.smartMode === 1) && addItemSheet.editItemId < 0
                        horizontalAlignment: HorizontalAlignment.Fill
                        verticalAlignment: VerticalAlignment.Fill
                        leftPadding: 16; rightPadding: 16; bottomPadding: 16
                        layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                        TextArea {
                            id: itBatch
                            hintText: addItemSheet.smartMode === 0 ? "e.g. Milk, Eggs, Bread, Butter..." : "Paste your clipboard text here..."
                            horizontalAlignment: HorizontalAlignment.Fill
                            verticalAlignment: VerticalAlignment.Fill
                            minHeight: 200
                        }
                    }
                }
            }
        },

        ComponentDefinition {
            id: itemPageDef
            Page {
                id: ipRoot
                property int lid: -1
                property string lname: ""
                
                onLidChanged: {
                    if (lid >= 0) {
                        rebuildItemModel(lid)
                        root.lastListId   = lid
                        rebuildCoverModel(lid)
                    }
                }
                
                titleBar: TitleBar { title: ipRoot.lname }
                
                actions: [
                    ActionItem {
                        title: "Add your items"
                        imageSource: "asset:///images/plus.png"
                        ActionBar.placement: ActionBarPlacement.OnBar
                        onTriggered: {
                            addItemSheet.targetListId = ipRoot.lid
                            addItemSheet.editItemId   = -1
                            addItemSheet.open()
                        }
                    },
                    ActionItem {
                        title: "Edit the list"
                        imageSource: "asset:///images/listedit.png"
                        ActionBar.placement: ActionBarPlacement.OnBar
                        onTriggered: { addListSheet.editListId = ipRoot.lid; addListSheet.open() }
                    },
                    ActionItem {
                        title: "Share List"
                        imageSource: "asset:///images/share.png"
                        ActionBar.placement: ActionBarPlacement.InOverflow
                        onTriggered: { root.shareList(ipRoot.lid) }
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
                        onTriggered: { root.confirmDeleteList(ipRoot.lid) }
                    }
                ]
                
                Container {
                    layout: StackLayout {}
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill
                    
                    ListView {
                        id: itemLV
                        dataModel: itemModel
                        layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }
                        multiSelectAction: MultiSelectActionItem {}
                        multiSelectHandler.actions: [
                            DeleteActionItem {
                                title: "Delete Selected"
                                onTriggered: {
                                    var selection = itemLV.selectionList()
                                    for (var i = selection.length - 1; i >= 0; i = i - 1) {
                                        var item = itemLV.dataModel.data(selection[i])
                                        deleteItem(ipRoot.lid, item.id)
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
                                            DeleteActionItem {
                                                title: "Delete"
                                                onTriggered: { ilRow.ListItem.view.doDelete(ListItemData.id) }
                                            }
                                        }
                                    ]
                                    Container {
                                        layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                                        leftPadding: 20; rightPadding: 20; topPadding: 16; bottomPadding: 16
                                        Container {
                                            layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                                            verticalAlignment: VerticalAlignment.Center
                                            Label {
                                                text: ListItemData.name
                                                textStyle.base: SystemDefaults.TextStyles.TitleText
                                                opacity: ListItemData.checked ? 0.35 : 1.0
                                            }
                                            Label {
                                                text: ListItemData.note
                                                visible: ListItemData.note !== ""
                                                textStyle.color: Color.Gray
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
                            addItemSheet.targetListId = ipRoot.lid
                            addItemSheet.editItemId   = it.id
                            addItemSheet.open()
                        }
                        function doToggle(itemId, isChecked) { toggleItem(ipRoot.lid, itemId, isChecked) }
                        function doDelete(itemId) { deleteItem(ipRoot.lid, itemId) }
                    }
                }
            }
        }
    ]
    
    onCreationCompleted: {
        root._prevTab = tabAll   // BUG 2 FIX: đảm bảo _prevTab không bao giờ null
        app.muteActionTriggered.connect(handleMute)
        loadAll()
        app.shareTargetsReady.connect(function(targets) {
            dimFadeOut.play()
            sharePickerSheet.openWithTargets(targets)
        })
    }
    
    onActiveTabChanged: {
        // BUG 2 FIX: Track tab trước ở đây — onActiveTabChanged fire SAU khi activeTab
        // đã đổi, nên ta lưu activeTab CŨ vào _prevTab trước khi nó bị ghi đè.
        // onTriggered của tabAddCat không thể đọc tab cũ vì BB10 đã đổi activeTab trước khi
        // onTriggered chạy → luôn đọc được tabAddCat thay vì tab cũ.
        if (activeTab !== tabAddCat && activeTab !== null && activeTab !== undefined) {
            root._prevTab = activeTab
        }

        if (activeTab === tabAll) {
            activeCatId = -1;
            rebuildListModel(-1);
        } else if (activeTab === tabAddCat) {
            // Không làm gì cả
        } else if (activeTab) {
            if (typeof activeTab.catId !== "undefined" && activeTab.catId !== null) {
                activeCatId = activeTab.catId;
                rebuildListModel(activeCatId);
            }
        }
    }
    
    Tab {
        id: tabAll
        property int catId: -1
        title: "All"
        imageSource: "asset:///images/home.png"
        description: "All lists you made"
        onTriggered: {
            activeCatId = -1
            rebuildListModel(-1)
        }
        
        NavigationPane {
            id: mainNav
            onPopTransitionEnded: { page.destroy() }
            Page {
                onCreationCompleted: {
                    root.listDeleted.connect(function(deletedId) {
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
                            addListSheet.editListId = -1
                            addListSheet.selCatId   = -1
                            addListSheet.selSmartMode = -1
                            addListSheet.open()
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
                    verticalAlignment: VerticalAlignment.Fill
                    ListView {
                        id: mainListView
                        dataModel: allListModel
                        layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }
                        function itemType(data, indexPath) {
                            // GroupDataModel: indexPath độ dài 1 là Header chữ cái, 2 là Item
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
                                        if (item.isHeader !== true) root.deleteList(item.id)
                                    }
                                    mainListView.clearSelection()
                                }
                            }
                        ]
                        listItemComponents: [
                            ListItemComponent {
                                type: "header"
                                Header {
                                    title: ListItemData.toString()
                                }
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
                                                imageSource: "asset:///images/edit.png"
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
                                        leftPadding: 20; rightPadding: 20; topPadding: 20; bottomPadding: 20
                                        Label {
                                            text: ListItemData.listName
                                            textStyle.base: SystemDefaults.TextStyles.TitleText
                                            multiline: false
                                        }
                                    }
                                }
                            }
                        ]
                        onTriggered: {
                            if (indexPath.length === 1) return  // GroupDataModel header
                            var item = dataModel.data(indexPath)
                            if (item === null || item === undefined || item.id === undefined || typeof item.id !== "number") return
                            if (root._navigating) return
                            root._navigating = true
                            root.lastListId   = item.id
                            root.lastListName = item.listName
                            
                            app.setCoverSelectedIdx(0)
                            root.rebuildCoverModel(item.id)
                            
                            var p = itemPageDef.createObject()
                            p.lid   = item.id
                            p.lname = item.listName
                            mainNav.push(p)
                            root._navigating = false
                        }
                        function doDeleteList(lid) { root.deleteList(lid) }
                        function doConfirmDeleteList(lid) { root.confirmDeleteList(lid) }
                        function doEditList(lid) { addListSheet.editListId = lid; addListSheet.open() }
                        function doShareList(lid) { root.shareList(lid) }
                    }
                }
            }
        }
    }
    Tab {
        id: tabAddCat
        property int catId: -1
        title: "Add a new category"
        imageSource: "asset:///images/newcategory.png"
        onTriggered: {
            // BUG 4 FIX: Mở sheet ngay lập tức trong onTriggered để phủ lên trước khi
            // BB10 render bất cứ thứ gì. Timer 50ms sau đó switch activeTab về prev —
            // đủ thời gian để BB10 hoàn tất transition mà không flash blank page.
            addCatSheet.open()
            addCatRedirectTimer.start()
        }
    }
}