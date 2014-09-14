//
//  MapDemo.h
//  MapDemo
//
//	examples of using MapAnnotation and MapOverlay base classes
//	to create custom subclasses specific to a given app
//
//  Created by Steve Caine on 09/12/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#import <Foundation/Foundation.h>

#import "MapOverlays.h"

// ----------------------------------------------------------------------
#pragma mark - MapUserPoint - point with user's latitude/longitude
// ----------------------------------------------------------------------

@interface MapUserPoint : MapAnnotation

+ (MapUserPoint *)userWithLocation:(CLLocation *)location title:(NSString *)title;

//- (id)initWithLocation:(CLLocation *)location;

@end

// ----------------------------------------------------------------------
#pragma mark - MapUserVicinity - circle  with user's latitude/longitude/accuracy
// ----------------------------------------------------------------------

@interface MapUserVicinity : MapOverlayCircle

+ (MapUserVicinity *)vicinityWithLocation:(CLLocation *)location;

//- (id)initWithLocation:(CLLocation *)location;

@end

// ----------------------------------------------------------------------
#pragma mark - MapUserTrail - polyline following user's changing location
// ----------------------------------------------------------------------

@interface MapUserTrail : MapOverlayPolyline <CLLocationManagerDelegate>

//+ (MapUserTrail *)trailWithLocationManager:(CLLocationManager *)manager;

//- (id)initWithLocationManager:(CLLocationManager *)manager;

@end

// ----------------------------------------------------------------------
#pragma mark - MapRegionOverlay - polygon framing an MKRegion
// ----------------------------------------------------------------------

@interface MapRegionOverlay : MapOverlayPolygon

+ (MapRegionOverlay *)regionWithMKRegion:(MKCoordinateRegion)region
								   style:(MapOverlayPathStyle *)style;

//- (id)initWithMKRegion:(MKCoordinateRegion)region
//				 style:(MapOverlayPathStyle *)style;

@end

// ----------------------------------------------------------------------
#pragma mark - MapDemo
// ----------------------------------------------------------------------

@interface MapDemo : NSObject

+ (void)demoInMapView:(MKMapView *)mapView withLocation:(CLLocation *)location;

+ (void)demoInMapView:(MKMapView *)mapView withLocation:(CLLocation *)location region:(MKCoordinateRegion)region;

@end
