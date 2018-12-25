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

#import "AILoadingView.h"
#import "CLGCDTimerManager.h"
#import "CLPlayerMaskView.h"
#import "CLPlayerView.h"
#import "CLSlider.h"
#import "UINavigationController+CLPlayerRotation.h"
#import "UITabBarController+CLPlayerRotation.h"
#import "UIViewController+CLPlayerRotation.h"

FOUNDATION_EXPORT double CLPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char CLPlayerVersionString[];

