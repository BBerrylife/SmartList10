import bb.cascades 1.4
import QtQuick 1.0

SceneCover {
    id: rootCover
    
    property int viewportStart: 0
    
    property int maxRows: 4
    
    onCreationCompleted: {
        app.coverChanged.connect(function() {
                highlightTimer.start()
        })
    }
    
    attachedObjects: [
        ArrayDataModel {
            id: localViewModel
        },
        Timer {
            id: highlightTimer
            interval: 10
            repeat: false
            onTriggered: {
                var allItems = []
                var targetModelIdx = -1
                var rank = 0
                
                for (var i = 0; i < coverModel.size(); i = i + 1) {
                    var item = coverModel.data([i])
                    if (item) {
                        allItems.push({
                                "modelIdx": i,
                                "name": item.name,
                                "isHeader": item.isHeader === true,
                                "checked": item.checked === true
                        })
                    
                    if (item.isHeader !== true) {
                        if (rank === app.coverSelectedIdx) {
                            targetModelIdx = i
                        }
                        rank = rank + 1
                    }
                    }
                }
                
                if (allItems.length === 0) {
                    localViewModel.clear()
                    coverList.highlightIdx = -1
                    return
                }
                
                var vStart = rootCover.viewportStart
                
                if (vStart > allItems.length - rootCover.maxRows) {
                    vStart = allItems.length - rootCover.maxRows
                }
                if (vStart < 0) {
                    vStart = 0
                }
                
                // Thuật toán kiểm tra biên để di chuyển khung nhìn ảo
                if (targetModelIdx < vStart) {
                    // Nếu tilt vượt quá biên trên -> Cuộn khung nhìn lên
                    vStart = targetModelIdx
                } else if (targetModelIdx >= vStart + rootCover.maxRows) {
                    // Nếu tilt vượt quá biên dưới -> Cuộn khung nhìn xuống
                    vStart = targetModelIdx - rootCover.maxRows + 1
                }
                
                rootCover.viewportStart = vStart
                
                var visibleItems = []
                var count = Math.min(rootCover.maxRows, allItems.length - vStart)
                for (var j = 0; j < count; j = j + 1) {
                    visibleItems.push(allItems[vStart + j])
                }
                
                localViewModel.clear()
                localViewModel.append(visibleItems)
                
                coverList.highlightIdx = targetModelIdx - vStart
            }
        }
    ]
    
    content: Container {
        layout: DockLayout {}
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment:   VerticalAlignment.Fill
        background: app.useSmartFrame ? Color.White : Color.create("#70cbff")
        
        Container {
            visible: !app.useSmartFrame
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment:   VerticalAlignment.Center
            ImageView {
                imageSource: "asset:///images/berrylife.png"
                scalingMethod: ScalingMethod.AspectFit
                preferredWidth: 200; preferredHeight: 200
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment:   VerticalAlignment.Center
            }
        }
        
        Container {
            visible: app.useSmartFrame
            layout: StackLayout {}
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment:   VerticalAlignment.Fill
            
            Container {
                id: infoHeader
                property bool ruleHeader: (app.useHeadersInLists && app.coverTotal > 8)
                visible: app.showSmartFrameInfo || ruleHeader
                
                layout: DockLayout {}
                horizontalAlignment: HorizontalAlignment.Fill
                topPadding: 14; bottomPadding: 14
                leftPadding: 20; rightPadding: 20
                background: Color.create("#3daee9")
                
                Container {
                    visible: infoHeader.ruleHeader
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center
                    layout: DockLayout {}
                    Label {
                        text: app.coverListName !== "" ? app.coverListName : "SmartList10"
                        textStyle.color: Color.White
                        textStyle.fontWeight: FontWeight.Bold
                        textStyle.base: SystemDefaults.TextStyles.BodyText
                        horizontalAlignment: HorizontalAlignment.Left
                        verticalAlignment: VerticalAlignment.Center
                    }
                    Label {
                        visible: app.showSmartFrameInfo
                        text: app.coverDone + "/" + app.coverTotal
                        textStyle.color: Color.White
                        textStyle.base: SystemDefaults.TextStyles.BodyText
                        horizontalAlignment: HorizontalAlignment.Right
                        verticalAlignment: VerticalAlignment.Center
                    }
                }
                
                Container {
                    visible: !infoHeader.ruleHeader && app.showSmartFrameInfo
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    leftPadding: 4; rightPadding: 4
                    
                    Label {
                        text: app.coverDone + "/" + app.coverTotal
                        textStyle.color: Color.White
                        textStyle.base: SystemDefaults.TextStyles.BodyText
                        verticalAlignment: VerticalAlignment.Center
                    }
                    Container {
                        verticalAlignment: VerticalAlignment.Center
                        preferredHeight: 22
                        leftMargin: 20; rightMargin: 10
                        background: Color.create("#30000000")
                        layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }
                        layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                        
                        Container {
                            background: Color.White
                            preferredHeight: 22
                            layoutProperties: StackLayoutProperties {
                                spaceQuota: (app.coverDone > 0) ? app.coverDone : 0.001
                            }
                        }
                        Container {
                            background: Color.Transparent
                            preferredHeight: 22
                            layoutProperties: StackLayoutProperties {
                                spaceQuota: ((app.coverTotal - app.coverDone) > 0) ? (app.coverTotal - app.coverDone) : 0.001
                            }
                        }
                    }
                }
            }
            
            ListView {
                id: coverList
                dataModel: localViewModel 
                horizontalAlignment: HorizontalAlignment.Fill
                scrollIndicatorMode: ScrollIndicatorMode.None
                bottomPadding: 150 * appItemScale
                
                property int  highlightIdx: -1
                property real appItemScale: app.itemScale > 0 ? app.itemScale : 1.0
                
                function itemType(data, indexPath) {
                    return (data && data.isHeader === true) ? "header" : "item"
                }
                
                listItemComponents: [
                    ListItemComponent {
                        type: "header"
                        Container {
                            background: Color.create("#e8e8e8")
                            horizontalAlignment: HorizontalAlignment.Fill
                            leftPadding: 20; topPadding: 6; bottomPadding: 6
                            Label {
                                text: ListItemData.name
                                verticalAlignment: VerticalAlignment.Center
                                textStyle {
                                    color: Color.create("#888888")
                                    fontSize: FontSize.XSmall
                                    fontWeight: FontWeight.Bold
                                }
                            }
                        }
                    },
                    ListItemComponent {
                        type: "item"
                        Container {
                            id: itemRoot
                            horizontalAlignment: HorizontalAlignment.Fill
                            background: (itemRoot.ListItem.indexPath[0] === itemRoot.ListItem.view.highlightIdx) ? Color.create("#cce5ff") : Color.Transparent
                            
                            Container {
                                horizontalAlignment: HorizontalAlignment.Fill
                                verticalAlignment: VerticalAlignment.Center
                                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                                leftPadding: 20; rightPadding: 10
                                topPadding:    10 * itemRoot.ListItem.view.appItemScale
                                bottomPadding: 10 * itemRoot.ListItem.view.appItemScale
                                
                                Label {
                                    text: ListItemData.name
                                    textStyle.base: SystemDefaults.TextStyles.BodyText
                                    textStyle.fontSize: FontSize.PercentageValue
                                    textStyle.fontSizeValue: 100 * itemRoot.ListItem.view.appItemScale
                                    textStyle.color: ListItemData.checked ? Color.create("#aaaaaa") : Color.Black
                                    verticalAlignment: VerticalAlignment.Center
                                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                                    multiline: false
                                }
                                CheckBox {
                                    checked: ListItemData.checked
                                    verticalAlignment: VerticalAlignment.Center
                                    scaleX: itemRoot.ListItem.view.appItemScale
                                    scaleY: itemRoot.ListItem.view.appItemScale
                                }
                            }
                            Divider { topMargin: 0; bottomMargin: 0 }
                        }
                    }
                ]
            }
        }
    }
}