import bb.cascades 1.4
import bb.system 1.0
import QtQuick 1.0

Sheet {
    id: aboutSheetRoot

    NavigationPane {
        id: aboutNav

        property variant activeChangelogPage: null
        property string pendingManifestAction: ""
        property string pendingDownloadUrl: ""
        property string pendingDownloadVersion: ""

        function isVersionNewer(a, b) {
            var pa = a.split('.');
            var pb = b.split('.');
            var n = Math.max(pa.length, pb.length);
            for (var i = 0; i < n; i++) {
                var va = parseInt(pa[i] || "0", 10);
                var vb = parseInt(pb[i] || "0", 10);
                if (isNaN(va)) va = 0;
                if (isNaN(vb)) vb = 0;
                if (va !== vb) return va > vb;
            }
            return false;
        }

        function buildChangelogRows(versions) {
            var tags = ["NEW:", "IMPROVE:", "FIX:", "REMOVED:"];
            var rows = [];
            for (var i = 0; i < versions.length; i++) {
                var v = versions[i] || {};
                var ver = v.version || "";
                var items = v.items || [];
                rows.push({ rowType: "header", version: ver, isFirstHeader: (i === 0) });
                for (var j = 0; j < items.length; j++) {
                    var raw = items[j];
                    var tag = "";
                    var rest = raw;
                    for (var t = 0; t < tags.length; t++) {
                        if (raw.indexOf(tags[t]) === 0) {
                            tag = tags[t];
                            rest = raw.substring(tags[t].length);
                            break;
                        }
                    }
                    rest = rest.split("**").join("");
                    rows.push({ rowType: "item", tag: tag, text: rest });
                }
            }
            return rows;
        }

        function onManifestLoaded(manifest) {
            var action = aboutNav.pendingManifestAction;
            aboutNav.pendingManifestAction = "";
            manifestTimeoutTimer.stop();

            if (action === "update") {
                updateBtn.enabled = true;
                var latest = manifest.latestVersion || "";
                var downloadUrl = manifest.downloadUrl || "";
                if (latest.length === 0) {
                    updateResultToast.body = "Update info unavailable right now. Try again later.";
                    updateResultToast.show();
                    return;
                }
                var current = app.appVersion();
                if (!aboutNav.isVersionNewer(latest, current)) {
                    updateResultToast.body = "You're already on the latest version (" + current + ").";
                    updateResultToast.show();
                } else {
                    aboutNav.pendingDownloadUrl = downloadUrl;
                    aboutNav.pendingDownloadVersion = latest;
                    updateConfirmDialog.title = "New Update Available";
                    updateConfirmDialog.body = "New version " + latest + " detected. Would you like to download it?";
                    updateConfirmDialog.show();
                }
            } else if (action === "changelog") {
                var versions = manifest.changelog || [];
                if (aboutNav.activeChangelogPage) {
                    aboutNav.activeChangelogPage.setRows(aboutNav.buildChangelogRows(versions));
                }
            }
        }

        function onManifestFailed(message) {
            var action = aboutNav.pendingManifestAction;
            aboutNav.pendingManifestAction = "";
            manifestTimeoutTimer.stop();

            if (action === "update") {
                updateBtn.enabled = true;
                updateResultToast.body = message;
                updateResultToast.show();
            } else if (action === "changelog") {
                if (aboutNav.activeChangelogPage) {
                    aboutNav.activeChangelogPage.setRows([{ rowType: "item", tag: "", text: message }]);
                }
            }
        }

        Page {
            titleBar: TitleBar {
                title: "About"
                acceptAction: ActionItem {
                    title: "Close"
                    onTriggered: { aboutSheetRoot.close() }
                }
            }

            actions: [
                ActionItem {
                    title: "Facebook"
                    imageSource: "asset:///images/AboutSheet/ic_facebook.png"
                    ActionBar.placement: ActionBarPlacement.OnBar
                    onTriggered: { Qt.openUrlExternally("https://www.facebook.com/BBerrylife") }
                },
                ActionItem {
                    title: "Donate"
                    imageSource: "asset:///images/AboutSheet/ic_scan_barcode.png"
                    ActionBar.placement: ActionBarPlacement.Signature
                    onTriggered: {
                        var donatePage = donatePageDef.createObject();
                        aboutNav.push(donatePage);
                    }
                },
                ActionItem {
                    title: "Website"
                    imageSource: "asset:///images/AboutSheet/ic_sb_network.png"
                    ActionBar.placement: ActionBarPlacement.OnBar
                    onTriggered: { Qt.openUrlExternally("https://BBerryLife.github.io") }
                }
            ]

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
                            Label { text: "Version: " + app.appVersion(); textStyle.color: Color.Gray; topMargin: 4 }
                            Label { text: "Developed by BerryLife\u00a9 2026"; textStyle.color: Color.Gray; topMargin: 4 }
                        }

                        ImageView {
                            imageSource: "asset:///images/AboutSheet/berrylife.png"
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
                        multiline: true
                        textStyle.color: Color.Gray
                        horizontalAlignment: HorizontalAlignment.Center
                        textStyle.textAlign: TextAlign.Center
                    }

                    Container {
                        topMargin: 30
                        horizontalAlignment: HorizontalAlignment.Fill
                        layout: StackLayout { orientation: LayoutOrientation.LeftToRight }

                        Button {
                            id: updateBtn
                            text: "Update"
                            layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                            rightMargin: ui.du(0.8)
                            onClicked: {
                                updateBtn.enabled = false;
                                updateCheckingToast.show();
                                aboutNav.pendingManifestAction = "update";
                                manifestTimeoutTimer.restart();
                                manifestFetcher.url = manifestFetcher.manifestUrl + "?t=" + new Date().getTime();
                            }
                        }

                        Button {
                            id: changeListBtn
                            text: "Change List"
                            layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                            leftMargin: ui.du(0.8)
                            onClicked: {
                                var changelogPage = changelogPageDef.createObject();
                                aboutNav.activeChangelogPage = changelogPage;
                                aboutNav.push(changelogPage);
                                aboutNav.pendingManifestAction = "changelog";
                                manifestTimeoutTimer.restart();
                                manifestFetcher.url = manifestFetcher.manifestUrl + "?t=" + new Date().getTime();
                            }
                        }
                    }

                    // Hidden WebView used to fetch the version manifest via the BB10
                    // browser's TLS stack (Qt4/QNetworkAccessManager fails the TLS
                    // handshake against modern CDNs; the WebView stack is kept current
                    // by OS updates). Same pattern as Zalo10.
                    WebView {
                        id: manifestFetcher
                        visible: false
                        enabled: false
                        preferredWidth: 1
                        preferredHeight: 1

                        property string manifestUrl: "https://cdn.jsdelivr.net/gh/BBerryLife/BBerryLife.github.io@main/Data/SmartList10-version.json"

                        onLoadingChanged: {
                            if (loadRequest.status === WebLoadStatus.Succeeded) {
                                manifestFetcher.evaluateJavaScript("document.body.textContent || document.body.innerText || ''");
                            } else if (loadRequest.status === WebLoadStatus.Failed) {
                                if (aboutNav.pendingManifestAction.length === 0) return;
                                aboutNav.onManifestFailed("Could not load update info. Check your internet connection and try again.");
                            }
                        }

                        onJavaScriptResult: {
                            if (aboutNav.pendingManifestAction.length === 0) return;
                            try {
                                var manifest = JSON.parse(result);
                                aboutNav.onManifestLoaded(manifest);
                            } catch (e) {
                                var preview = (typeof result === "undefined") ? "<undefined>" : String(result).substring(0, 200);
                                aboutNav.onManifestFailed("Parse failed: " + e + " || got: " + preview);
                            }
                        }
                    }
                }
            }
        }

        attachedObjects: [
            Timer {
                id: manifestTimeoutTimer
                interval: 15000
                repeat: false
                onTriggered: {
                    if (aboutNav.pendingManifestAction.length > 0) {
                        aboutNav.onManifestFailed("Request timed out. Check your internet connection and try again.");
                    }
                }
            },
            ComponentDefinition {
                id: donatePageDef
                Page {
                    titleBar: TitleBar { title: "Donate & Support" }
                    ScrollView {
                        Container {
                            horizontalAlignment: HorizontalAlignment.Fill
                            leftPadding: 30; rightPadding: 30; topPadding: 50; bottomPadding: 50

                            Label {
                                text: "If you find the app useful and are feeling generous, you can donate 10,000 VND to help fund BB10/BBOS device testing and support the developer."
                                multiline: true
                                horizontalAlignment: HorizontalAlignment.Center
                                textStyle { base: SystemDefaults.TextStyles.BodyText; textAlign: TextAlign.Center; lineHeight: 1.3 }
                            }

                            Container {
                                topMargin: 50
                                horizontalAlignment: HorizontalAlignment.Center
                                preferredWidth: ui.du(40)
                                preferredHeight: ui.du(40)
                                background: Color.White
                                leftPadding: 10; rightPadding: 10; topPadding: 10; bottomPadding: 10
                                ImageView {
                                    imageSource: "asset:///images/AboutSheet/barcode.png"
                                    scalingMethod: ScalingMethod.AspectFit
                                    horizontalAlignment: HorizontalAlignment.Fill
                                    verticalAlignment: VerticalAlignment.Fill
                                }
                            }

                            Label {
                                topMargin: 30
                                text: "Thank you for your support!"
                                horizontalAlignment: HorizontalAlignment.Center
                                textStyle { color: Color.DarkGray; fontWeight: FontWeight.Bold }
                            }
                        }
                    }
                }
            },
            ComponentDefinition {
                id: changelogPageDef
                source: "asset:///ChangelogPage.qml"
            },
            SystemToast { id: updateCheckingToast; body: "Checking for updates\u2026" },
            SystemToast { id: updateResultToast; body: "" },
            SystemDialog {
                id: updateConfirmDialog
                title: "New Update Available"
                body: ""
                confirmButton.label: "Update"
                cancelButton.label: "Cancel"
                onFinished: {
                    if (value === SystemUiResult.ConfirmButtonSelection) {
                        Qt.openUrlExternally(aboutNav.pendingDownloadUrl);
                        updateResultToast.body = "Opening download in Browser. Check your Downloads folder when done.";
                        updateResultToast.show();
                    }
                }
            }
        ]
    }
}
