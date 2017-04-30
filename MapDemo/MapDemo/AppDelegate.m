//
//	AppDelegate.m
//	MapDemo
//
//	Created by Steve Caine on 07/15/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#import "AppDelegate.h"

#import "Debug_iOS.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef DEBUG
	MyLog(@"*** %@ ***", str_AppName());
	NSDate *now = NSDate.date;
	MyLog(@"launched at %@ on %@", str_logTime(now), str_logDate(now));
	MyLog(@"%@", str_device_OS_UDID());
//	MyLog(@"app path = '%@'", str_AppPath());
//	MyLog(@"doc path = '%@'", str_DocumentsPath());
	MyLog(@"\n%s", __FUNCTION__);
	
	if(getenv( "NSDebugEnabled"))
		MyLog(@"NSDebugEnabled == YES");
	if(getenv( "NSZombieEnabled"))
		MyLog(@"NSZombieEnabled == YES");
	if(getenv( "NSAutoreleaseFreedObjectCheckEnabled"))
		MyLog(@"NSAutoreleaseFreedObjectCheckEnabled == YES");
#endif
	// Override point for customization after application launch.
	return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
	MyLog(@"\n%s", __FUNCTION__);
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	MyLog(@"\n%s", __FUNCTION__);
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	MyLog(@"\n%s", __FUNCTION__);
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	MyLog(@"\n%s", __FUNCTION__);
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	MyLog(@"\n%s", __FUNCTION__);
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
