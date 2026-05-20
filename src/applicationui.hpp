#ifndef ApplicationUI_HPP_
#define ApplicationUI_HPP_

#include <QObject>
#include <QString>
#include <QVariantList>
#include <bb/cascades/ArrayDataModel>
#include <bb/cascades/QmlDocument>
#include <bb/system/InvokeManager>
#include <bb/multimedia/MediaKeyWatcher>
#include <bb/multimedia/MediaKey>
#include "OrientationSensor.hpp"

namespace bb { namespace cascades { class LocaleHandler; class AbstractPane; class SceneCover; } }
class QTranslator;

class ApplicationUI : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString coverListName READ coverListName NOTIFY coverChanged)
    Q_PROPERTY(int coverDone READ coverDone NOTIFY coverChanged)
    Q_PROPERTY(int coverTotal READ coverTotal NOTIFY coverChanged)
    Q_PROPERTY(int coverSelectedIdx READ coverSelectedIdx NOTIFY coverChanged)
    Q_PROPERTY(bb::cascades::ArrayDataModel* coverDataModel READ coverDataModel CONSTANT)
    Q_PROPERTY(bool volumeUpCheck READ volumeUpCheck WRITE setVolumeUpCheck)
    Q_PROPERTY(bool showSmartFrameInfo READ showSmartFrameInfo WRITE setShowSmartFrameInfo NOTIFY coverSettingsChanged)
    Q_PROPERTY(bool useHeadersInLists READ useHeadersInLists WRITE setUseHeadersInLists NOTIFY coverSettingsChanged)
    Q_PROPERTY(int smartFrameScrollMode READ smartFrameScrollMode WRITE setSmartFrameScrollMode)
    Q_PROPERTY(qreal itemScale READ itemScale WRITE setItemScale NOTIFY coverSettingsChanged)
    Q_PROPERTY(qreal smartFrameScrollSpeed READ smartFrameScrollSpeed WRITE setSmartFrameScrollSpeed NOTIFY coverSettingsChanged)
    Q_PROPERTY(bool useSmartFrame READ useSmartFrame WRITE setUseSmartFrame NOTIFY coverSettingsChanged)

public:
    explicit ApplicationUI(OrientationSensor *sensor = 0);
    virtual ~ApplicationUI();

    QString coverListName() const { return m_coverListName; }
    int coverDone() const { return m_coverDone; }
    int coverTotal() const { return m_coverTotal; }
    int coverSelectedIdx() const { return m_coverSelectedIdx; }
    bb::cascades::ArrayDataModel* coverDataModel() { return m_coverModel; }

    bool volumeUpCheck() const { return m_volumeUpCheck; }
    void setVolumeUpCheck(bool v) { m_volumeUpCheck = v; }

    bool showSmartFrameInfo() const { return m_showSmartFrameInfo; }
    void setShowSmartFrameInfo(bool v) { m_showSmartFrameInfo = v; emit coverSettingsChanged(); }

    bool useHeadersInLists() const { return m_useHeadersInLists; }
    void setUseHeadersInLists(bool v) { m_useHeadersInLists = v; emit coverSettingsChanged(); }

    int smartFrameScrollMode() const { return m_smartFrameScrollMode; }
    void setSmartFrameScrollMode(int v);

    qreal itemScale() const { return m_itemScale; }
    void setItemScale(qreal v) { m_itemScale = v; emit coverSettingsChanged(); }

    qreal smartFrameScrollSpeed() const { return m_smartFrameScrollSpeed; }
    void setSmartFrameScrollSpeed(qreal v);

    bool useSmartFrame() const { return m_useSmartFrame; }
    void setUseSmartFrame(bool v) { m_useSmartFrame = v; emit coverSettingsChanged(); }

public slots:
    void invokeEmail(const QString &to, const QString &subject);
    void minimizeApp();
    void updateCover(const QString &listName, int done, int total, const QVariantList &items);
    void setCoverSelectedIdx(int idx);
    void navigateUp();
    void navigateDown();
    void shareText(const QString &text);
    void queryShareTargets(const QString &text);
    void invokeShareTarget(const QString &target, const QString &action, const QString &text);
    void triggerMuteAction();

signals:
    void coverChanged();
    void shareTargetsReady(const QVariantList &targets);
    void coverSettingsChanged();
    void muteActionTriggered();

private slots:
    void onSystemLanguageChanged();
    void onThumbnailed();
    void onFullscreen();
    void onVolumeUp();
    void onVolumeDown();
    void onQueryTargetsFinished();
    void onMode0VolUpLong(bb::multimedia::MediaKey::Type key);
    void onMode1VolUpShort(bb::multimedia::MediaKey::Type key);
    void onMode1VolDownShort(bb::multimedia::MediaKey::Type key);
    void onMode1MuteShort(bb::multimedia::MediaKey::Type key);
    void onTiltUp();
    void onTiltDown();

private slots:
    void recreateCover();

private:
    bool eventFilter(QObject *obj, QEvent *event);
    void connectMediaKeyWatchers();
    void disconnectMediaKeyWatchers();

    QTranslator* m_pTranslator;
    bb::cascades::LocaleHandler* m_pLocaleHandler;
    bb::system::InvokeManager* m_pInvokeManager;
    bb::cascades::AbstractPane* m_pRoot;
    bb::cascades::ArrayDataModel* m_coverModel;
    bb::cascades::QmlDocument* m_pCoverQml;
    bb::cascades::SceneCover* m_pCurrentCover;
    bool m_isThumbnailed;
    bool m_coverRecreateScheduled;

    QString m_coverListName;
    int m_coverDone;
    int m_coverTotal;
    int m_coverSelectedIdx;
    bool m_volumeUpCheck;
    bool m_showSmartFrameInfo;
    bool m_useHeadersInLists;
    int m_smartFrameScrollMode;
    bool m_mediaKeysConnected;
    qreal m_itemScale;
    qreal m_smartFrameScrollSpeed;
    bool m_useSmartFrame;

    bb::multimedia::MediaKeyWatcher* m_volUpWatcher;
    bb::multimedia::MediaKeyWatcher* m_volDownWatcher;
    bb::multimedia::MediaKeyWatcher* m_muteWatcher;

    OrientationSensor* m_pOrientSensor;
};

#endif
