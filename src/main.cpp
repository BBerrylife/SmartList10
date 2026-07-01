#include "applicationui.hpp"
#include "OrientationSensor.hpp"

#include <bb/cascades/Application>
#include <bb/cascades/ThemeSupport>
#include <bbndk.h>

#include <QLocale>
#include <QTranslator>
#include <Qt/qdeclarativedebug.h>

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QVariant>
#include <QDir>
#include <QFileInfo>

using namespace bb::cascades;

Q_DECL_EXPORT int main(int argc, char **argv)
{
    Application app(argc, argv);

#if BBNDK_VERSION_AT_LEAST(10,3,0)
    Application::instance()->themeSupport()->setVisualStyle(VisualStyle::Bright);
#endif

    {
        QString dbPath;
        QStringList dirsToSearch;
        dirsToSearch << QDir::homePath() + "/data/"
                     << QDir::homePath() + "/shared/misc/"
                     << QDir::homePath() + "/";

        QStringList visited;
        while (!dirsToSearch.isEmpty() && dbPath.isEmpty()) {
            QString currentDir = dirsToSearch.takeFirst();
            if (visited.contains(currentDir)) continue;
            visited << currentDir;

            QDir dir(currentDir);
            if (!dir.exists()) continue;

            QFileInfoList files = dir.entryInfoList(QDir::Files | QDir::NoSymLinks);
            foreach (const QFileInfo &fi, files) {
                if (fi.size() < 1024) continue;
                QString connName = QString("probe_%1").arg(fi.fileName());
                {
                    QSqlDatabase probe = QSqlDatabase::addDatabase("QSQLITE", connName);
                    probe.setDatabaseName(fi.absoluteFilePath());
                    if (probe.open()) {
                        QSqlQuery chk(probe);
                        chk.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='appdata'");
                        if (chk.exec() && chk.next()) {
                            dbPath = fi.absoluteFilePath();
                        }
                        probe.close();
                    }
                }
                QSqlDatabase::removeDatabase(connName);
                if (!dbPath.isEmpty()) break;
            }

            if (currentDir.count('/') - QDir::homePath().count('/') < 4) {
                QFileInfoList subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks);
                foreach (const QFileInfo &sd, subdirs) {
                    dirsToSearch << sd.absoluteFilePath() + "/";
                }
            }
        }

        if (!dbPath.isEmpty()) {
            {
                QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "themeconn");
                db.setDatabaseName(dbPath);
                if (db.open()) {
                    QSqlQuery q(db);
                    q.prepare("SELECT value FROM appdata WHERE key = 'darkTheme'");
                    if (q.exec() && q.next()) {
                        QString val = q.value(0).toString().trimmed();
                        if (val == "1") {
#if BBNDK_VERSION_AT_LEAST(10,3,0)
                            Application::instance()->themeSupport()->setVisualStyle(VisualStyle::Dark);
#endif
                        }
                    }
                    db.close();
                }
            }
            QSqlDatabase::removeDatabase("themeconn");
        }
    }

    OrientationSensor orientSensor;
    ApplicationUI appui(&orientSensor);

    return Application::exec();
}
