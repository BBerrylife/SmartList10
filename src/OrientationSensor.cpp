#include "OrientationSensor.hpp"
#include <QDebug>

OrientationSensor::OrientationSensor(QObject *parent)
    : QObject(parent), m_lastTiltTime(0), m_scrollSpeed(1.0), m_armed(false)
{
    if (!m_sensor.connectToBackend()) {
        qWarning() << "OrientationSensor: Cannot connect to accelerometer backend!";
    }
    m_sensor.setAlwaysOn(true);
    m_sensor.addFilter(this);
}

OrientationSensor::~OrientationSensor() {}

void OrientationSensor::start() {
    m_armed = false;
    m_lastTiltTime = QDateTime::currentMSecsSinceEpoch() + 1200;
    m_sensor.start();
}

void OrientationSensor::stop() {
    m_armed = false;
    m_sensor.stop();
}

bool OrientationSensor::filter(QAccelerometerReading *reading)
{
    qint64 now = QDateTime::currentMSecsSinceEpoch();

    if (now < m_lastTiltTime) return false;

    if (!m_armed) {
        m_armed = true;
        m_lastTiltTime = now;
        return false;
    }

    qreal y = reading->y();
    qreal z = reading->z();

    // Ngay trong quá trình bạn đang đặt máy xuống bàn, tránh hiện tượng trôi 1-2 items.
    if (qAbs(z) > 6.0) {
        return false;
    }

    // Tăng chỉ số cooldown từ 500 lên 600 giảm nhẹ tốc độ cuộn tổng thể
    qreal spd = (m_scrollSpeed > 0.01) ? m_scrollSpeed : 1.0;
    int cooldown = static_cast<int>(600 / spd);

    if (y < -8.5) {
        m_lastTiltTime = now + cooldown;
        emit tiltUp();
        return true;
    }
    else if (y > -3.0) {
        m_lastTiltTime = now + cooldown;
        emit tiltDown();
        return true;
    }

    return false;
}
