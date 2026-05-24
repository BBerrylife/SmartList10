import QtQuick 1.0

QtObject {
    id: storageRoot

    function _getDB() {
        return openDatabaseSync("SmartList10DB", "1.0", "SmartList10 Storage", 1000000)
    }

    function _initDB() {
        var db = _getDB()
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS appdata(key TEXT PRIMARY KEY, value TEXT)')
        })
    }

    function saveAll(dataObj) {
        var db = _getDB()
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO appdata(key, value) VALUES(?, ?)',
                ["alldata", JSON.stringify(dataObj)])
            tx.executeSql('INSERT OR REPLACE INTO appdata(key, value) VALUES(?, ?)',
                ["darkTheme", dataObj.settings && dataObj.settings.darkTheme ? "1" : "0"])
        })
    }

    // callback(obj) — obj is null if no data exists yet
    function loadAll(callback) {
        _initDB()
        var db = _getDB()
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM appdata WHERE key = ?', ["alldata"])
            if (rs.rows.length > 0) {
                try { callback(JSON.parse(rs.rows.item(0).value)) }
                catch(e) { callback(null) }
            } else {
                callback(null)
            }
        })
    }
}
