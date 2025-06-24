#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "ActionEventSink.h"
#import "Converters.h"
#import "FlutterEngineManager.h"
#import "FlutterLocalNotificationsPlugin.h"

FOUNDATION_EXPORT double flutter_local_notifications_plusVersionNumber;
FOUNDATION_EXPORT const unsigned char flutter_local_notifications_plusVersionString[];

