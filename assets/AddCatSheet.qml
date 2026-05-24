import bb.cascades 1.4
import QtQuick 1.0

Sheet {
    id: addCatSheetRoot

    property variant logicRef       // AppLogic instance
    property variant prevTabRef     // Tab trước đó để restore khi Cancel

    signal newCatCreated(int catId)

    Page {
        titleBar: TitleBar {
            title: "Add a new Category"
            dismissAction: ActionItem {
                title: "Cancel"
                onTriggered: {
                    addCatSheetRoot.close()
                    if (addCatSheetRoot.prevTabRef !== null)
                        root.activeTab = addCatSheetRoot.prevTabRef
                }
            }
            acceptAction: ActionItem {
                title: "Save"
                onTriggered: {
                    var n = newCatName.text.trim()
                    if (n !== "") {
                        var newCatId = logicRef.createCategory(n)
                        newCatName.text = ""
                        addCatSheetRoot.close()
                        addCatSheetRoot.newCatCreated(newCatId)
                    }
                }
            }
        }

        Container {
            leftPadding: 30; rightPadding: 30; topPadding: 40
            Label { text: "Category name" }
            TextField {
                id: newCatName
                hintText: "e.g. Finance, College..."
                topMargin: 6; preferredHeight: 80
            }
        }
    }
}
