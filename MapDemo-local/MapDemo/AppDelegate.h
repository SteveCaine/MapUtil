//
//	AppDelegate.h
//	MapDemo
//
//	Created by Steve Caine on 07/15/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2011-2014 Steve Caine.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (UIApplicationState)currentState;

+ (UIViewController *)currentViewController;

@end
