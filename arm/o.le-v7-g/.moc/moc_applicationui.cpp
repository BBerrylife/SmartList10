/****************************************************************************
** Meta object code from reading C++ file 'applicationui.hpp'
**
** Created by: The Qt Meta Object Compiler version 63 (Qt 4.8.6)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/applicationui.hpp"
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'applicationui.hpp' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 63
#error "This file was generated using the moc from 4.8.6. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_ApplicationUI[] = {

 // content:
       6,       // revision
       0,       // classname
       0,    0, // classinfo
      28,   14, // methods
      12,  154, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       4,       // signalCount

 // signals: signature, parameters, type, tag, flags
      15,   14,   14,   14, 0x05,
      38,   30,   14,   14, 0x05,
      70,   14,   14,   14, 0x05,
      93,   14,   14,   14, 0x05,

 // slots: signature, parameters, type, tag, flags
     126,  115,   14,   14, 0x0a,
     155,   14,   14,   14, 0x0a,
     195,  169,   14,   14, 0x0a,
     241,  237,   14,   14, 0x0a,
     266,   14,   14,   14, 0x0a,
     279,   14,   14,   14, 0x0a,
     299,  294,   14,   14, 0x0a,
     318,  294,   14,   14, 0x0a,
     364,  345,   14,   14, 0x0a,
     407,   14,   14,   14, 0x0a,
     427,  294,   14,   14, 0x0a,
     452,   14,   14,   14, 0x08,
     478,   14,   14,   14, 0x08,
     494,   14,   14,   14, 0x08,
     509,   14,   14,   14, 0x08,
     522,   14,   14,   14, 0x08,
     537,   14,   14,   14, 0x08,
     566,  562,   14,   14, 0x08,
     615,  562,   14,   14, 0x08,
     665,  562,   14,   14, 0x08,
     717,  562,   14,   14, 0x08,
     766,   14,   14,   14, 0x08,
     777,   14,   14,   14, 0x08,
     790,   14,   14,   14, 0x08,

 // properties: name, type, flags
     814,  806, 0x0a495001,
     832,  828, 0x02495001,
     842,  828, 0x02495001,
     853,  828, 0x02495001,
     900,  870, 0x00095409,
     920,  915, 0x01095103,
     934,  915, 0x01495103,
     953,  915, 0x01495103,
     971,  828, 0x02095103,
     998,  992, ((uint)QMetaType::QReal << 24) | 0x00495103,
    1008,  992, ((uint)QMetaType::QReal << 24) | 0x00495103,
    1030,  915, 0x01495103,

 // properties: notify_signal_id
       0,
       0,
       0,
       0,
       0,
       0,
       2,
       2,
       0,
       2,
       2,
       2,

       0        // eod
};

static const char qt_meta_stringdata_ApplicationUI[] = {
    "ApplicationUI\0\0coverChanged()\0targets\0"
    "shareTargetsReady(QVariantList)\0"
    "coverSettingsChanged()\0muteActionTriggered()\0"
    "to,subject\0invokeEmail(QString,QString)\0"
    "minimizeApp()\0listName,done,total,items\0"
    "updateCover(QString,int,int,QVariantList)\0"
    "idx\0setCoverSelectedIdx(int)\0navigateUp()\0"
    "navigateDown()\0text\0shareText(QString)\0"
    "queryShareTargets(QString)\0"
    "target,action,text\0"
    "invokeShareTarget(QString,QString,QString)\0"
    "triggerMuteAction()\0copyToClipboard(QString)\0"
    "onSystemLanguageChanged()\0onThumbnailed()\0"
    "onFullscreen()\0onVolumeUp()\0onVolumeDown()\0"
    "onQueryTargetsFinished()\0key\0"
    "onMode0VolUpLong(bb::multimedia::MediaKey::Type)\0"
    "onMode1VolUpShort(bb::multimedia::MediaKey::Type)\0"
    "onMode1VolDownShort(bb::multimedia::MediaKey::Type)\0"
    "onMode1MuteShort(bb::multimedia::MediaKey::Type)\0"
    "onTiltUp()\0onTiltDown()\0recreateCover()\0"
    "QString\0coverListName\0int\0coverDone\0"
    "coverTotal\0coverSelectedIdx\0"
    "bb::cascades::ArrayDataModel*\0"
    "coverDataModel\0bool\0volumeUpCheck\0"
    "showSmartFrameInfo\0useHeadersInLists\0"
    "smartFrameScrollMode\0qreal\0itemScale\0"
    "smartFrameScrollSpeed\0useSmartFrame\0"
};

void ApplicationUI::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        Q_ASSERT(staticMetaObject.cast(_o));
        ApplicationUI *_t = static_cast<ApplicationUI *>(_o);
        switch (_id) {
        case 0: _t->coverChanged(); break;
        case 1: _t->shareTargetsReady((*reinterpret_cast< const QVariantList(*)>(_a[1]))); break;
        case 2: _t->coverSettingsChanged(); break;
        case 3: _t->muteActionTriggered(); break;
        case 4: _t->invokeEmail((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< const QString(*)>(_a[2]))); break;
        case 5: _t->minimizeApp(); break;
        case 6: _t->updateCover((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2])),(*reinterpret_cast< int(*)>(_a[3])),(*reinterpret_cast< const QVariantList(*)>(_a[4]))); break;
        case 7: _t->setCoverSelectedIdx((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 8: _t->navigateUp(); break;
        case 9: _t->navigateDown(); break;
        case 10: _t->shareText((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 11: _t->queryShareTargets((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 12: _t->invokeShareTarget((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< const QString(*)>(_a[2])),(*reinterpret_cast< const QString(*)>(_a[3]))); break;
        case 13: _t->triggerMuteAction(); break;
        case 14: _t->copyToClipboard((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 15: _t->onSystemLanguageChanged(); break;
        case 16: _t->onThumbnailed(); break;
        case 17: _t->onFullscreen(); break;
        case 18: _t->onVolumeUp(); break;
        case 19: _t->onVolumeDown(); break;
        case 20: _t->onQueryTargetsFinished(); break;
        case 21: _t->onMode0VolUpLong((*reinterpret_cast< bb::multimedia::MediaKey::Type(*)>(_a[1]))); break;
        case 22: _t->onMode1VolUpShort((*reinterpret_cast< bb::multimedia::MediaKey::Type(*)>(_a[1]))); break;
        case 23: _t->onMode1VolDownShort((*reinterpret_cast< bb::multimedia::MediaKey::Type(*)>(_a[1]))); break;
        case 24: _t->onMode1MuteShort((*reinterpret_cast< bb::multimedia::MediaKey::Type(*)>(_a[1]))); break;
        case 25: _t->onTiltUp(); break;
        case 26: _t->onTiltDown(); break;
        case 27: _t->recreateCover(); break;
        default: ;
        }
    }
}

const QMetaObjectExtraData ApplicationUI::staticMetaObjectExtraData = {
    0,  qt_static_metacall 
};

const QMetaObject ApplicationUI::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_ApplicationUI,
      qt_meta_data_ApplicationUI, &staticMetaObjectExtraData }
};

#ifdef Q_NO_DATA_RELOCATION
const QMetaObject &ApplicationUI::getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

const QMetaObject *ApplicationUI::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->metaObject : &staticMetaObject;
}

void *ApplicationUI::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_ApplicationUI))
        return static_cast<void*>(const_cast< ApplicationUI*>(this));
    return QObject::qt_metacast(_clname);
}

int ApplicationUI::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 28)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 28;
    }
#ifndef QT_NO_PROPERTIES
      else if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QString*>(_v) = coverListName(); break;
        case 1: *reinterpret_cast< int*>(_v) = coverDone(); break;
        case 2: *reinterpret_cast< int*>(_v) = coverTotal(); break;
        case 3: *reinterpret_cast< int*>(_v) = coverSelectedIdx(); break;
        case 4: *reinterpret_cast< bb::cascades::ArrayDataModel**>(_v) = coverDataModel(); break;
        case 5: *reinterpret_cast< bool*>(_v) = volumeUpCheck(); break;
        case 6: *reinterpret_cast< bool*>(_v) = showSmartFrameInfo(); break;
        case 7: *reinterpret_cast< bool*>(_v) = useHeadersInLists(); break;
        case 8: *reinterpret_cast< int*>(_v) = smartFrameScrollMode(); break;
        case 9: *reinterpret_cast< qreal*>(_v) = itemScale(); break;
        case 10: *reinterpret_cast< qreal*>(_v) = smartFrameScrollSpeed(); break;
        case 11: *reinterpret_cast< bool*>(_v) = useSmartFrame(); break;
        }
        _id -= 12;
    } else if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 5: setVolumeUpCheck(*reinterpret_cast< bool*>(_v)); break;
        case 6: setShowSmartFrameInfo(*reinterpret_cast< bool*>(_v)); break;
        case 7: setUseHeadersInLists(*reinterpret_cast< bool*>(_v)); break;
        case 8: setSmartFrameScrollMode(*reinterpret_cast< int*>(_v)); break;
        case 9: setItemScale(*reinterpret_cast< qreal*>(_v)); break;
        case 10: setSmartFrameScrollSpeed(*reinterpret_cast< qreal*>(_v)); break;
        case 11: setUseSmartFrame(*reinterpret_cast< bool*>(_v)); break;
        }
        _id -= 12;
    } else if (_c == QMetaObject::ResetProperty) {
        _id -= 12;
    } else if (_c == QMetaObject::QueryPropertyDesignable) {
        _id -= 12;
    } else if (_c == QMetaObject::QueryPropertyScriptable) {
        _id -= 12;
    } else if (_c == QMetaObject::QueryPropertyStored) {
        _id -= 12;
    } else if (_c == QMetaObject::QueryPropertyEditable) {
        _id -= 12;
    } else if (_c == QMetaObject::QueryPropertyUser) {
        _id -= 12;
    }
#endif // QT_NO_PROPERTIES
    return _id;
}

// SIGNAL 0
void ApplicationUI::coverChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void ApplicationUI::shareTargetsReady(const QVariantList & _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void ApplicationUI::coverSettingsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, 0);
}

// SIGNAL 3
void ApplicationUI::muteActionTriggered()
{
    QMetaObject::activate(this, &staticMetaObject, 3, 0);
}
QT_END_MOC_NAMESPACE
