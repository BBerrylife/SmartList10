import bb.cascades 1.4
import QtQuick 1.0

QtObject {
    id: mmRoot

    property alias allListModel: _allListModel
    property alias catListModel: _catListModel
    property alias itemModel:    _itemModel
    property alias catModel:     _catModel

    property variant _allListModel: GroupDataModel {
        id: _allListModel
        sortingKeys: ["listName"]
        grouping: ItemGrouping.ByFirstChar
    }
    property variant _catListModel: GroupDataModel {
        id: _catListModel
        sortingKeys: ["listName"]
        grouping: ItemGrouping.ByFirstChar
    }
    property variant _itemModel: ArrayDataModel { id: _itemModel }
    property variant _catModel:  ArrayDataModel { id: _catModel }

    function rebuildListModel(catId, lists, activeCatId) {
        function _filtered(filterCatId) {
            var result = []
            for (var i = 0; i < lists.length; i = i + 1) {
                var l = lists[i]
                if (filterCatId !== -1 && l.categoryId !== filterCatId) continue
                var done = 0
                var items = l.items || []
                for (var j = 0; j < items.length; j = j + 1) {
                    if (items[j] && items[j].checked) done = done + 1
                }
                result.push({
                    "id":         l.id,
                    "listName":   l.name || ("List " + l.id),
                    "categoryId": l.categoryId,
                    "doneCount":  done,
                    "items":      items
                })
            }
            return result
        }

        _allListModel.clear()
        _allListModel.insertList(_filtered(-1))

        var targetCat = (catId !== undefined && catId !== -1) ? catId
                      : ((activeCatId !== undefined && activeCatId !== -1) ? activeCatId : -1)
        _catListModel.clear()
        if (targetCat !== -1) _catListModel.insertList(_filtered(targetCat))
    }

    function rebuildItemModel(listId, lists, findListIdx) {
        _itemModel.clear()
        var li = findListIdx(listId)
        if (li < 0) return
        var its = lists[li].items
        for (var i = 0; i < its.length; i = i + 1) {
            _itemModel.append({
                "id":      its[i].id,
                "name":    its[i].name,
                "note":    its[i].note || "",
                "checked": its[i].checked
            })
        }
    }

    function rebuildCatModel(categories) {
        _catModel.clear()
        for (var i = 0; i < categories.length; i = i + 1) {
            _catModel.append({ "id": categories[i].id, "name": categories[i].name, "isCustom": true })
        }
    }
}
