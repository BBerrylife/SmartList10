import QtQuick 1.0

QtObject {
    id: logicRoot

    property variant storage
    property variant appHandle

    property int nextCatId:   100
    property int nextListId:  100
    property int nextItemId:  1000

    property variant categories:  []
    property variant lists:       []
    property int activeCatId:     -1
    property int lastListId:      -1
    property string lastListName: ""

    property bool useHeadersInLists:  false
    property bool useSmartFrame:      true
    property bool showSmartFrameInfo: false
    property bool volumeUpCheck:      false
    property int  smartFrameScrollMode:   0
    property real smartFrameScrollSpeed: 1.0
    property bool useLargeItems:  false
    property real itemScale:      1.0
    property bool darkTheme:      false

    signal listDeleted(int deletedId)
    signal categoriesChanged()
    signal listsChanged()
    signal coverUpdateNeeded(int listId)
    signal listModelRebuildNeeded(int catId)
    signal itemModelRebuildNeeded(int listId)
    signal itemToggled(int listId, int itemId, bool isChecked)
    signal deleteToastRequested(string message)
    signal confirmDeleteListRequested()
    signal confirmDeleteCatRequested()
    signal shareDialogRequested(string text)
    signal switchToAllTabRequested()

    property int    _pendingDeleteCatId:  -1
    property int    _pendingDeleteListId: -1
    property string _pendingShareText:    ""

    function findListIdx(id) {
        for (var i = 0; i < lists.length; i = i + 1) {
            if (lists[i].id === id) return i
        }
        return -1
    }

    function dataSnapshot() {
        return {
            nextCatId:  nextCatId,
            nextListId: nextListId,
            nextItemId: nextItemId,
            categories: categories,
            lists:      lists,
            lastListId: lastListId,
            settings: {
                useHeadersInLists:     useHeadersInLists,
                useSmartFrame:         useSmartFrame,
                showSmartFrameInfo:    showSmartFrameInfo,
                volumeUpCheck:         volumeUpCheck,
                smartFrameScrollMode:  smartFrameScrollMode,
                smartFrameScrollSpeed: smartFrameScrollSpeed,
                useLargeItems:         useLargeItems,
                itemScale:             itemScale,
                darkTheme:             darkTheme
            }
        }
    }

    function _save() { storage.saveAll(dataSnapshot()) }

    function loadAll() {
        storage.loadAll(function(o) {
            if (!o) {
                categoriesChanged()
                listModelRebuildNeeded(-1)
                return
            }
            nextCatId  = o.nextCatId  || 100
            nextListId = o.nextListId || 100
            nextItemId = o.nextItemId || 1000
            categories = o.categories || []
            lastListId = (o.lastListId !== undefined) ? o.lastListId : -1

            var raw = o.lists || []
            for (var i = 0; i < raw.length; i = i + 1) {
                if (typeof raw[i].name !== "string" || raw[i].name === "")
                    raw[i].name = "List " + raw[i].id
                if (raw[i].items) {
                    for (var j = 0; j < raw[i].items.length; j = j + 1) {
                        raw[i].items[j].checked =
                            (raw[i].items[j].checked === true || raw[i].items[j].checked === "true")
                    }
                }
            }
            lists = raw

            if (o.settings) {
                var s = o.settings
                useHeadersInLists    = s.useHeadersInLists    || false
                useSmartFrame        = (s.useSmartFrame        !== undefined) ? s.useSmartFrame        : true
                showSmartFrameInfo   = (s.showSmartFrameInfo   !== undefined) ? s.showSmartFrameInfo   : false
                volumeUpCheck        = s.volumeUpCheck        || false
                smartFrameScrollMode = (s.smartFrameScrollMode !== undefined) ? s.smartFrameScrollMode : 0
                smartFrameScrollSpeed= s.smartFrameScrollSpeed || 1.0
                useLargeItems        = s.useLargeItems        || false
                itemScale            = (s.itemScale            !== undefined) ? s.itemScale            : 1.0
                darkTheme            = s.darkTheme            || false
            }

            categoriesChanged()
            listModelRebuildNeeded(-1)

            if (lastListId >= 0) {
                var li = findListIdx(lastListId)
                if (li >= 0) {
                    lastListName = lists[li].name
                    coverUpdateNeeded(lastListId)
                }
            }
        })
    }

    // Called by C++ via QMetaObject::invokeMethod on thumbnail
    function prepareCoverData() {
        if (lastListId !== -1 && findListIdx(lastListId) >= 0) {
            coverUpdateNeeded(lastListId)
        } else if (lists.length > 0) {
            var fb = lists[lists.length - 1]
            lastListId   = fb.id
            lastListName = fb.name
            coverUpdateNeeded(fb.id)
        } else {
            appHandle.updateCover("SmartList10", 0, 0, [])
        }
    }

    function buildCoverItems(listId) {
        var li = findListIdx(listId)
        if (li < 0) { appHandle.updateCover("", 0, 0, []); return }
        var its = lists[li].items
        var done = 0
        var items = []
        for (var i = 0; i < its.length; i = i + 1) {
            if (its[i].checked) done = done + 1
            items.push({ "id": its[i].id, "name": its[i].name, "checked": its[i].checked, "isHeader": false })
        }
        appHandle.updateCover(lists[li].name, done, its.length, items)
    }

    function handleMute() {
        var idx = appHandle.coverSelectedIdx
        var model = appHandle.coverDataModel
        var rank = 0
        for (var ci = 0; ci < model.size(); ci = ci + 1) {
            var cv = model.value(ci)
            if (cv && cv.isHeader !== true) {
                if (rank === idx) { toggleItem(lastListId, cv.id, !cv.checked); return }
                rank = rank + 1
            }
        }
    }

    function createCategory(name) {
        var n = name.trim()
        if (n === "") return -1
        var tc = categories
        tc.push({ "id": nextCatId, "name": n })
        categories = tc
        nextCatId = nextCatId + 1
        categoriesChanged()
        _save()
        return nextCatId - 1
    }

    function deleteCategory(catId) {
        _pendingDeleteCatId = catId
        confirmDeleteCatRequested()
    }

    function _doDeleteCategory(catId) {
        var catName = ""
        for (var j = 0; j < categories.length; j = j + 1) {
            if (categories[j].id === catId) { catName = categories[j].name; break }
        }
        var keptLists = []
        for (var i = 0; i < lists.length; i = i + 1) {
            if (lists[i].categoryId !== catId) {
                keptLists.push(lists[i])
            } else if (lists[i].id === lastListId) {
                lastListId = -1; lastListName = ""
            }
        }
        lists = keptLists
        var keptCats = []
        for (var k = 0; k < categories.length; k = k + 1) {
            if (categories[k].id !== catId) keptCats.push(categories[k])
        }
        categories = keptCats
        categoriesChanged()
        listModelRebuildNeeded(-1)
        switchToAllTabRequested()
        _save()
        deleteToastRequested("\"" + catName + "\" successfully deleted.")
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
        appHandle.setCoverSelectedIdx(0)
        buildCoverItems(newList.id)
        listModelRebuildNeeded(activeCatId)
        _save()
    }

    function deleteList(listId) {
        var deletedName = ""
        var kept = []
        for (var i = 0; i < lists.length; i = i + 1) {
            if (lists[i].id !== listId) { kept.push(lists[i]) }
            else { deletedName = lists[i].name }
        }
        lists = kept
        if (lastListId === listId) {
            if (lists.length > 0) {
                var fb = lists[lists.length - 1]
                lastListId = fb.id; lastListName = fb.name
                appHandle.setCoverSelectedIdx(0)
                buildCoverItems(fb.id)
            } else {
                lastListId = -1; lastListName = ""
                appHandle.updateCover("SmartList10", 0, 0, [])
            }
        }
        listModelRebuildNeeded(activeCatId)
        _save()
        _pendingDeleteListId = listId
        listDeleted(listId)
        deleteToastRequested("\"" + deletedName + "\" successfully deleted.")
    }

    function confirmDeleteList(listId) {
        _pendingDeleteListId = listId
        confirmDeleteListRequested()
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
            buildCoverItems(listId)
        }
        listModelRebuildNeeded(activeCatId)
        _save()
        return name.trim()
    }

    function shareList(listId) {
        var li = findListIdx(listId)
        if (li < 0) return
        var lst = lists[li]
        var text = lst.name + "\n"
        for (var i = 0; i < lst.items.length; i = i + 1) {
            var it = lst.items[i]
            text += (i + 1) + ". " + it.name + (it.checked ? " - Completed" : "") + "\n"
        }
        _pendingShareText = text.trim()
        shareDialogRequested(_pendingShareText)
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
        itemModelRebuildNeeded(listId)
        listModelRebuildNeeded(activeCatId)
        if (listId === lastListId) buildCoverItems(listId)
        _save()
    }

    function addItemsBatch(listId, text) {
        var li = findListIdx(listId)
        if (li < 0) return
        var parts = text.split(/[\n,;]+/)
        var tb = lists
        for (var i = 0; i < parts.length; i = i + 1) {
            var s = parts[i].trim()
            if (s) {
                tb[li].items.push({ "id": nextItemId, "name": s, "note": "", "checked": false })
                nextItemId = nextItemId + 1
            }
        }
        lists = tb
        itemModelRebuildNeeded(listId)
        listModelRebuildNeeded(activeCatId)
        if (listId === lastListId) buildCoverItems(listId)
        _save()
    }

    function toggleItem(listId, itemId, isChecked) {
        var li = findListIdx(listId)
        if (li < 0) return
        var tt = lists
        for (var i = 0; i < tt[li].items.length; i = i + 1) {
            if (tt[li].items[i].id === itemId) { tt[li].items[i].checked = isChecked; break }
        }
        lists = tt
        lastListId   = listId
        lastListName = lists[li].name
        itemToggled(listId, itemId, isChecked)
        listModelRebuildNeeded(activeCatId)
        buildCoverItems(listId)
        _save()
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
        itemModelRebuildNeeded(listId)
        if (listId === lastListId) buildCoverItems(listId)
        _save()
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
        itemModelRebuildNeeded(listId)
        listModelRebuildNeeded(activeCatId)
        if (listId === lastListId) buildCoverItems(listId)
        _save()
    }
}
