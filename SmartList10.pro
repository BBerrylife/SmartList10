APP_NAME = SmartList10

QT += core declarative sql

CONFIG += qt warn_on cascades10

CONFIG += mobility

MOBILITY += sensors

include(config.pri)

LIBS += -lbbdata -lbbsystem -lbb

LIBS += -lbbmultimedia