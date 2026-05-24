import bb.cascades 1.4
import QtQuick 1.0

Sheet {
    id: aboutSheetRoot

    Page {
        titleBar: TitleBar {
            title: "About"
            acceptAction: ActionItem {
                title: "Close"
                onTriggered: { aboutSheetRoot.close() }
            }
        }

        ScrollView {
            Container {
                horizontalAlignment: HorizontalAlignment.Fill
                leftPadding: 50; rightPadding: 50; topPadding: 50; bottomPadding: 80

                Container {
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    horizontalAlignment: HorizontalAlignment.Fill

                    Container {
                        layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                        verticalAlignment: VerticalAlignment.Center
                        Label { text: "SmartList10"; textStyle.base: SystemDefaults.TextStyles.BigText }
                        Label { text: "Version 1.0.1.0"; textStyle.color: Color.Gray; topMargin: 4 }
                        Container {
                            layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                            Label { text: "Developed by BerryLife© 2026"; textStyle.color: Color.Gray; topMargin: 4 }
                        }
                    }

                    ImageView {
                        imageSource: "asset:///images/berrylife.png"
                        scalingMethod: ScalingMethod.AspectFit
                        preferredWidth:  160
                        preferredHeight: 160
                        verticalAlignment: VerticalAlignment.Center
                        horizontalAlignment: HorizontalAlignment.Right
                    }
                }

                Divider { topMargin: 30; bottomMargin: 20 }

                Label {
                    text: "SmartDetection: enter multiple items at once, separated by commas, semicolons or newlines.\n\nSmartCopy: paste from clipboard, items are split automatically.\n\nSingle: add items one by one."
                    multiline: true; textStyle.color: Color.Gray
                }

                Divider { topMargin: 20; bottomMargin: 20 }

                Label { text: "Follow us"; textStyle.base: SystemDefaults.TextStyles.BigText }
                Button {
                    text: "Facebook"
                    horizontalAlignment: HorizontalAlignment.Fill; topMargin: 10
                    onClicked: { Qt.openUrlExternally("https://facebook.com/BBerrylife") }
                }
                Button {
                    text: "Reddit"
                    horizontalAlignment: HorizontalAlignment.Fill; topMargin: 4
                    onClicked: { Qt.openUrlExternally("https://www.reddit.com/user/Jim_Bowen87/") }
                }
                Button {
                    text: "Website"
                    horizontalAlignment: HorizontalAlignment.Fill; topMargin: 4
                    onClicked: { Qt.openUrlExternally("https://BBerryLife.github.io") }
                }
            }
        }
    }
}
