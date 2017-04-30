//
//  Categories.h
//  MapDemo
//
//	collection of various convenience categories
//
//  Created by Steve Caine on 08/20/15.
//
//	This code is distributed under the terms of the MIT license.
//
//  Copyright (c) 2015 Steve Caine.
//

#import <UIKit/UIKit.h>

// ----------------------------------------------------------------------

@interface NSObject (Cast)
+ (instancetype)cast:(id)object;
@end

// ----------------------------------------------------------------------
//	Thanks to 'Cliff Ribaudo' for his answer in the SO thread
//	http://stackoverflow.com/questions/12542472/why-iphone-5-doesnt-rotate-to-upsidedown

@interface UINavigationController (RotateAll)
@end

// ----------------------------------------------------------------------
