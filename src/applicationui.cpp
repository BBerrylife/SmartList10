#include "applicationui.hpp"

#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>
#include <bb/cascades/AbstractPane>
#include <bb/cascades/LocaleHandler>
#include <bb/cascades/SceneCover>
#include <bb/cascades/ArrayDataModel>
#include <bb/system/InvokeManager>
#include <bb/system/InvokeRequest>
#include <bb/system/InvokeQueryTargetsRequest>
#include <bb/system/InvokeQueryTargetsReply>
#include <bb/system/InvokeAction>
#include <bb/system/InvokeTarget>
#include <bb/multimedia/MediaKeyWatcher>
#include <bb/multimedia/MediaKey>

#include <QEvent>
#include <QtGui/QKeyEvent>
#include <QVariantList>
#include <QVariantMap>
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QTimer>

using namespace bb::cascades;
using namespace bb::system;
using namespace bb::multimedia;

ApplicationUI::ApplicationUI(OrientationSensor *sensor) :
    QObject(),
    m_pRoot(0),
    m_pCoverQml(0),
    m_pCurrentCover(0),
    m_isThumbnailed(false),
    m_coverRecreateScheduled(false),
    m_coverDone(0),
    m_coverTotal(0),
    m_coverSelectedIdx(0),
    m_volumeUpCheck(false),
    m_showSmartFrameInfo(false),
    m_useHeadersInLists(false),
    m_smartFrameScrollMode(0),
    m_mediaKeysConnected(false),
    m_itemScale(1.0),
    m_smartFrameScrollSpeed(1.0),
    m_useSmartFrame(true),
    m_volUpWatcher(0),
    m_volDownWatcher(0),
    m_muteWatcher(0),
    m_pOrientSensor(sensor)
{
    m_pInvokeManager = new InvokeManager(this);
    m_pTranslator    = new QTranslator(this);
    m_pLocaleHandler = new LocaleHandler(this);
    m_coverModel     = new ArrayDataModel(this);

    bool res = QObject::connect(m_pLocaleHandler, SIGNAL(systemLanguageChanged()),
                                this, SLOT(onSystemLanguageChanged()));
    Q_ASSERT(res); Q_UNUSED(res);
    onSystemLanguageChanged();

    QObject::connect(Application::instance(), SIGNAL(thumbnail()),
                     this, SLOT(onThumbnailed()));
    QObject::connect(Application::instance(), SIGNAL(fullscreen()),
                     this, SLOT(onFullscreen()));

    m_volUpWatcher   = new MediaKeyWatcher(MediaKey::VolumeUp,   this);
    m_volDownWatcher = new MediaKeyWatcher(MediaKey::VolumeDown, this);
    m_muteWatcher    = new MediaKeyWatcher(MediaKey::PlayPause,  this);

    if (m_pOrientSensor) {
        QObject::connect(m_pOrientSensor, SIGNAL(tiltUp()), this, SLOT(onTiltUp()));
        QObject::connect(m_pOrientSensor, SIGNAL(tiltDown()), this, SLOT(onTiltDown()));
    }

    QmlDocument *qml = QmlDocument::create("asset:///main.qml").parent(this);
    qml->setContextProperty("app", this);
    m_pRoot = qml->createRootObject<AbstractPane>();
    Application::instance()->setScene(m_pRoot);

    m_pCoverQml = QmlDocument::create("asset:///cover.qml").parent(this);
    m_pCoverQml->setContextProperty("app", this);
    m_pCoverQml->setContextProperty("coverModel", m_coverModel);
    SceneCover *cover = m_pCoverQml->createRootObject<SceneCover>();
    if (cover) {
        m_pCurrentCover = cover;
        Application::instance()->setCover(cover);
    }

    Application::instance()->installEventFilter(this);
    connectMediaKeyWatchers();
}

ApplicationUI::~ApplicationUI() {}

void ApplicationUI::onTiltUp()
{
    if (!m_isThumbnailed) return;
    navigateUp();
}

void ApplicationUI::onTiltDown()
{
    if (!m_isThumbnailed) return;
    navigateDown();
}

void ApplicationUI::setSmartFrameScrollSpeed(qreal v)
{
    m_smartFrameScrollSpeed = v;
    if (m_pOrientSensor) m_pOrientSensor->setScrollSpeed(v);
}

void ApplicationUI::navigateUp()
{
    if (m_isThumbnailed) setCoverSelectedIdx(m_coverSelectedIdx - 1);
}

void ApplicationUI::navigateDown()
{
    if (m_isThumbnailed) setCoverSelectedIdx(m_coverSelectedIdx + 1);
}

void ApplicationUI::recreateCover()
{

}

void ApplicationUI::minimizeApp()
{
    Application::instance()->minimize();
}

void ApplicationUI::onThumbnailed()
{
    m_isThumbnailed = true;
    m_coverRecreateScheduled = false;
    if (m_pOrientSensor && m_smartFrameScrollMode == 0) {
        m_pOrientSensor->start();
    }
    if (m_pRoot) {
        QMetaObject::invokeMethod(m_pRoot, "prepareCoverData", Qt::QueuedConnection);
    }
}

void ApplicationUI::onFullscreen()
{
    m_isThumbnailed = false;
    if (m_pOrientSensor) m_pOrientSensor->stop();
}

void ApplicationUI::updateCover(const QString &listName, int done, int total, const QVariantList &items)
{
    m_coverListName    = listName;
    m_coverDone        = done;
    m_coverTotal       = total;

    m_coverModel->clear();
    if (!items.isEmpty()) {
        m_coverModel->append(items);
    }

    int itemCount = 0;
    for (int i = 0; i < m_coverModel->size(); i++) {
        QVariantMap row = m_coverModel->value(i).toMap();
        if (!row.value("isHeader", false).toBool()) itemCount++;
    }

    if (m_coverSelectedIdx < 0) {
        m_coverSelectedIdx = 0;
    }
    if (itemCount > 0 && m_coverSelectedIdx >= itemCount) {
        m_coverSelectedIdx = itemCount - 1;
    } else if (itemCount == 0) {
        m_coverSelectedIdx = 0;
    }

    emit coverChanged();
}

void ApplicationUI::setCoverSelectedIdx(int idx)
{
    int itemCount = 0;
    for (int i = 0; i < m_coverModel->size(); i++) {
        QVariantMap row = m_coverModel->value(i).toMap();
        if (!row.value("isHeader", false).toBool()) itemCount++;
    }
    if (idx < 0) idx = 0;
    if (itemCount > 0 && idx >= itemCount) idx = itemCount - 1;

    if (m_coverSelectedIdx != idx) {
        m_coverSelectedIdx = idx;
        emit coverChanged();
    }
}

void ApplicationUI::onVolumeUp()
{
    if (m_isThumbnailed) setCoverSelectedIdx(m_coverSelectedIdx - 1);
}

void ApplicationUI::onVolumeDown()
{
    if (m_isThumbnailed) setCoverSelectedIdx(m_coverSelectedIdx + 1);
}

void ApplicationUI::triggerMuteAction()
{
    if (!m_isThumbnailed) return;
    emit muteActionTriggered();
}

void ApplicationUI::setSmartFrameScrollMode(int v)
{
    if (m_smartFrameScrollMode == v) return;
    m_smartFrameScrollMode = v;
    if (m_pOrientSensor) {
        if (v != 0) {
            m_pOrientSensor->stop();
        } else if (m_isThumbnailed) {
            m_pOrientSensor->start();
        }
    }
    disconnectMediaKeyWatchers();
    connectMediaKeyWatchers();
}

void ApplicationUI::connectMediaKeyWatchers()
{
    if (m_mediaKeysConnected) return;
    m_mediaKeysConnected = true;

    if (m_smartFrameScrollMode == 0) {
        QObject::connect(m_volUpWatcher,
            SIGNAL(longPress(bb::multimedia::MediaKey::Type)),
            this, SLOT(onMode0VolUpLong(bb::multimedia::MediaKey::Type)));
    } else {
        QObject::connect(m_volUpWatcher,
            SIGNAL(shortPress(bb::multimedia::MediaKey::Type)),
            this, SLOT(onMode1VolUpShort(bb::multimedia::MediaKey::Type)));
        QObject::connect(m_volDownWatcher,
            SIGNAL(shortPress(bb::multimedia::MediaKey::Type)),
            this, SLOT(onMode1VolDownShort(bb::multimedia::MediaKey::Type)));
        QObject::connect(m_muteWatcher,
            SIGNAL(shortPress(bb::multimedia::MediaKey::Type)),
            this, SLOT(onMode1MuteShort(bb::multimedia::MediaKey::Type)));
    }
}

void ApplicationUI::disconnectMediaKeyWatchers()
{
    if (!m_mediaKeysConnected) return;
    m_mediaKeysConnected = false;
    if (m_volUpWatcher)   m_volUpWatcher->disconnect(this);
    if (m_volDownWatcher) m_volDownWatcher->disconnect(this);
    if (m_muteWatcher)    m_muteWatcher->disconnect(this);
}

void ApplicationUI::onMode0VolUpLong(bb::multimedia::MediaKey::Type)
{
    triggerMuteAction();
}

void ApplicationUI::onMode1MuteShort(bb::multimedia::MediaKey::Type)
{
    triggerMuteAction();
}

void ApplicationUI::onMode1VolUpShort(bb::multimedia::MediaKey::Type)
{
    if (m_isThumbnailed) setCoverSelectedIdx(m_coverSelectedIdx - 1);
}

void ApplicationUI::onMode1VolDownShort(bb::multimedia::MediaKey::Type)
{
    if (m_isThumbnailed) setCoverSelectedIdx(m_coverSelectedIdx + 1);
}

bool ApplicationUI::eventFilter(QObject *obj, QEvent *event)
{
    Q_UNUSED(obj);
    if (m_smartFrameScrollMode != 1) return false;
    if (!m_isThumbnailed) return false;

    if (event->type() == QEvent::KeyPress) {
        QKeyEvent *key = static_cast<QKeyEvent*>(event);
        int k = key->key();
        bool isMute = (k == Qt::Key_VolumeMute          ||
                       k == Qt::Key_MediaTogglePlayPause ||
                       k == Qt::Key_MediaPlay            ||
                       k == Qt::Key_MediaPause           ||
                       k == 0x01000072                   ||
                       k == 0x01010002                   ||
                       k == 173 || k == 177 || k == 179 || k == 180);
        if (isMute) { triggerMuteAction(); return true; }
    }
    return false;
}

void ApplicationUI::invokeEmail(const QString &to, const QString &subject)
{
    InvokeRequest req;
    req.setTarget("sys.pim.uib.email.hybridcomposer");
    req.setAction("bb.action.COMPOSE");
    req.setMimeType("message/rfc822");
    req.setUri(QString("mailto:%1?subject=%2").arg(to).arg(subject));
    m_pInvokeManager->invoke(req);
}

void ApplicationUI::queryShareTargets(const QString &text)
{
    Q_UNUSED(text);
    InvokeQueryTargetsRequest req;
    req.setAction("bb.action.SHARE");
    req.setMimeType("text/plain");
    InvokeQueryTargetsReply *reply = m_pInvokeManager->queryTargets(req);
    connect(reply, SIGNAL(finished()), this, SLOT(onQueryTargetsFinished()));
}

void ApplicationUI::onQueryTargetsFinished()
{
    InvokeQueryTargetsReply *reply = qobject_cast<InvokeQueryTargetsReply*>(sender());
    if (!reply) return;
    QString tmpDir = QDir::homePath() + "/tmp/icons/";
    QDir().mkpath(tmpDir);

    QStringList nativePfx;
    nativePfx << "sys." << "com.rim.";

    QVariantList bbmMain, bbmGroup, bbmChannel;
    QVariantList textList, emailList, meetingList, connList, rememberList, otherNatList, thirdList;

    QList<InvokeAction> actions = reply->actions();
    for (int a = 0; a < actions.size(); a++) {
        QList<InvokeTarget> tgts = actions.at(a).targets();
        for (int t = 0; t < tgts.size(); t++) {
            QVariantMap m;
            m["label"]  = tgts.at(t).label();
            m["target"] = tgts.at(t).name();
            m["action"] = actions.at(a).name();

            QString src = tgts.at(t).icon().toLocalFile();
            if (!src.isEmpty() && QFile::exists(src)) {
                QString dst = tmpDir + tgts.at(t).name().replace("/","_") + ".png";
                if (!QFile::exists(dst)) QFile::copy(src, dst);
                m["icon"] = "file://" + dst;
            } else m["icon"] = "";

            bool isNat = false;
            QString targetName = tgts.at(t).name().toLower();

            for (int p = 0; p < nativePfx.size(); p++) {
                if (targetName.startsWith(nativePfx.at(p))) { isNat = true; break; }
            }
            m["isNative"] = isNat;

            if (isNat) {
                if (targetName.contains("bbgroups") || (targetName.contains("bbm") && targetName.contains("group"))) {
                    bbmGroup.append(m);
                    qDebug() << "BBM_GROUP:" << targetName;
                } else if (targetName.contains("channel") || targetName.contains("channels")) {
                    bbmChannel.append(m);
                    qDebug() << "BBM_CHANNEL:" << targetName;
                } else if (targetName.contains("bbm")) {
                    bbmMain.append(m);
                    qDebug() << "BBM_MAIN:" << targetName;
                }
                else if (targetName.contains("text") || targetName.contains("sms") || targetName.contains("mms")) { textList.append(m); }
                else if (targetName.contains("email")) { emailList.append(m); }
                else if (targetName.contains("meeting") || targetName.contains("calendar")) { meetingList.append(m); }
                else if (targetName.contains("bluetooth") || targetName.contains("nfc")) { connList.append(m); }
                else if (targetName.contains("remember")) { rememberList.append(m); }
                else { otherNatList.append(m); }
            } else {
                thirdList.append(m);
            }
        }
    }
    reply->deleteLater();

    QVariantList result;
    QList<QVariantList*> listsToAppend;
    listsToAppend << &bbmMain << &bbmGroup << &bbmChannel << &textList << &emailList
                  << &meetingList << &connList << &rememberList << &otherNatList << &thirdList;

    for (int i = 0; i < listsToAppend.size(); i++) {
        for(int j = 0; j < listsToAppend[i]->size(); j++) {
            result.append(listsToAppend[i]->at(j));
        }
    }

    for (int r = 0; r < result.size(); r++) {
        QVariantMap rm = result.at(r).toMap();
        qDebug() << "SHARE_ORDER[" << r << "]" << rm.value("target").toString() << rm.value("label").toString();
    }
    emit shareTargetsReady(result);
}

void ApplicationUI::invokeShareTarget(const QString &target, const QString &action, const QString &text)
{
    InvokeRequest req;
    req.setTarget(target);
    req.setAction(action.isEmpty() ? "bb.action.SHARE" : action);
    req.setMimeType("text/plain");
    req.setData(text.toUtf8());
    m_pInvokeManager->invoke(req);
}

void ApplicationUI::shareText(const QString &text)
{
    InvokeRequest req;
    req.setAction("bb.action.SHARE");
    req.setMimeType("text/plain");
    req.setData(text.toUtf8());
    m_pInvokeManager->invoke(req);
}

void ApplicationUI::onSystemLanguageChanged()
{
    QCoreApplication::instance()->removeTranslator(m_pTranslator);
    QString locale_string = QLocale().name();
    QString file_name = QString("SmartList10_%1").arg(locale_string);
    if (m_pTranslator->load(file_name, "app/native/qm"))
        QCoreApplication::instance()->installTranslator(m_pTranslator);
}
