#ifndef ORIENTATIONSENSOR_HPP
#define ORIENTATIONSENSOR_HPP

#include <QObject>
#include <QtSensors/QAccelerometer>
#include <QtSensors/QAccelerometerFilter>
#include <QDateTime>

#include <QtSensors/QSensor>

QTM_USE_NAMESPACE

class OrientationSensor : public QObject, public QAccelerometerFilter
{
    Q_OBJECT
public:
    explicit OrientationSensor(QObject *parent = 0);
    virtual ~OrientationSensor();

    void start();
    void stop();

    void setScrollSpeed(qreal speed) { m_scrollSpeed = speed; }

Q_SIGNALS:
    void tiltUp();
    void tiltDown();

protected:
    bool filter(QAccelerometerReading *reading);

private:
    QAccelerometer m_sensor;
    qint64 m_lastTiltTime;
    qreal m_scrollSpeed;
    bool m_armed;
};

#endif
