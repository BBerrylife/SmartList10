#ifndef FILEIO_H
#define FILEIO_H

#include <QObject>
#include <QString>
#include <QFile>
#include <QIODevice>
#include <QTextStream>

class FileIO : public QObject {
    Q_OBJECT

public:
    explicit FileIO(QObject *parent = 0) : QObject(parent) {}

    Q_INVOKABLE QString read(const QString &path) {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return QString();
        QTextStream in(&file);
        in.setCodec("UTF-8");
        QString content = in.readAll();
        file.close();
        return content;
    }

    Q_INVOKABLE bool write(const QString &path, const QString &content) {
        QFile file(path);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
            return false;
        QTextStream out(&file);
        out.setCodec("UTF-8");
        out << content;
        file.close();
        return true;
    }
};

#endif
