// idk
    function rebuildListModel(catId) {
        listModel.clear()
        var filtered = []
        
        for (var i = 0; i < lists.length; i = i + 1) {
            var l = lists[i]
            if (catId === -1 || l.categoryId === catId) {
                var done = 0
                var itemArray = l.items || []
                for (var j = 0; j < itemArray.length; j = j + 1) {
                    if (itemArray[j] && itemArray[j].checked) {
                        done = done + 1
                    }
                }
                
                var itemCopy = {
                    "id": l.id,
                    "name": l.name || "",
                    "listName": l.listName || l.name || "",
                    "categoryId": l.categoryId,
                    "doneCount": done,
                    "items": itemArray,
                    "isHeader": false
                }
                filtered.push(itemCopy)
            }
        }

        filtered.sort(function(a, b) {
            var nameA = a.listName.toString().toLowerCase().trim();
            var nameB = b.listName.toString().toLowerCase().trim();
            if (nameA < nameB) return -1;
            if (nameA > nameB) return 1;
            return 0;
        });

        var lastLetter = "";
        for (var k = 0; k < filtered.length; k = k + 1) {
            var currentList = filtered[k]
            if (currentList.listName.length > 0) {
                var firstChar = currentList.listName.charAt(0).toUpperCase();
                var groupChar = (firstChar >= "0" && firstChar <= "9") ? "#" : firstChar;
                
                if (groupChar !== lastLetter) {
                    listModel.append({ "isHeader": true, "name": groupChar, "listName": groupChar })
                    lastLetter = groupChar
                }
            }
            listModel.append(currentList)
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
        var useH = (root.useHeadersInLists === true && its.length > 8)
        var lastLetter = ""

        for (var i = 0; i < its.length; i = i + 1) {
            if (its[i].checked) done = done + 1
            if (useH) {
                var itemName = (its[i].name !== undefined && its[i].name !== null) ? (its[i].name + "") : ""
                var firstChar = itemName.charAt(0).toUpperCase()
                var groupChar = (firstChar >= "0" && firstChar <= "9") ? "#" : firstChar
                if (groupChar !== lastLetter) {
                    items.push({ "id": -1, "name": groupChar, "checked": false, "isHeader": true })
                    lastLetter = groupChar
                }
            }
            items.push({ "id": its[i].id, "name": its[i].name, "checked": its[i].checked, "isHeader": false })
        }
        app.updateCover(lists[li].name, done, its.length, items)
    }