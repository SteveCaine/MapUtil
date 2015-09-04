//
//  Categories.m
//  MapDemo
//
//  Created by Steve Caine on 08/20/15.
//
//	This code is distributed under the terms of the MIT license.
//
//  Copyright (c) 2015 Steve Caine.
//

#import "Categories.h"

// ----------------------------------------------------------------------

@implementation NSObject (Cast)

+ (instancetype)cast:(id)object {
	return [object isKindOfClass:self] ? object : nil;
}

@end

// ----------------------------------------------------------------------
//	Override default UINavigationController to allow upside-down rotation on iPhone.
//	Child VCs in a navigation controller's hierarchy can control their own rotation
//	by implementing -shouldAutorotate and -supportedInterfaceOrientations as appropriate.
//
//	Thanks to 'Cliff Ribaudo' for his answer in the SO thread
//	http://stackoverflow.com/questions/12542472/why-iphone-5-doesnt-rotate-to-upsidedown

@implementation UINavigationController (RotateAll)

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

@end

// ----------------------------------------------------------------------
