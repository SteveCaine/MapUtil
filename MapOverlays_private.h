//
//	MapOverlays_private.h
//	MapUtil
//
//	here we put those parts of the MapOverlay classes' interfaces
//	that should be hidden from general use but visible to subclasses
//
//	polygon and polyline overlays can get their coordinates
//	as either an NSArray of NSValues
//	or a C-style buffer created with malloc()
//	(on which they call free())
//
//	it would be possible (but less useful)
//	to write code that creates polygon and polyline overlays
//	from collections of MKMapPoints
//
//	Created by Steve Caine on 05/29/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#import "MapOverlays.h"

// ----------------------------------------------------------------------
#pragma mark   MapAnnotation
// ----------------------------------------------------------------------

@interface MapAnnotation ()

@property (copy,   nonatomic, readwrite) NSString *title;
@property (copy,   nonatomic, readwrite) NSString *subtitle;

@property (strong, nonatomic) MKPointAnnotation *point;
@property (strong, nonatomic) MKAnnotationView	*view;

+ (MapAnnotation *)pointWithCoordinate:(CLLocationCoordinate2D)coord;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord;

- (id)initWithPoint:(MKPointAnnotation *)point;

@end


// ----------------------------------------------------------------------
#pragma mark - MapOverlay
// ----------------------------------------------------------------------

@interface MapOverlay ()

@property (strong, nonatomic) MapOverlayPathStyle	*style;
@property (strong, nonatomic) MKOverlayPathView		*view; // deprecated in iOS 7
#ifdef __IPHONE_7_0
@property (strong, nonatomic) MKOverlayPathRenderer	*renderer;
#endif

- (id)initWithStyle:(MapOverlayPathStyle *)style;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayCircle
// ----------------------------------------------------------------------

@interface MapOverlayCircle ()

@property (strong, nonatomic) MKCircle *circle;

+ (MapOverlayCircle *)circleWithCenterCoordinate:(CLLocationCoordinate2D)center
										  radius:(CLLocationDistance)radius
										   style:(MapOverlayPathStyle *)style;

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)center
						radius:(CLLocationDistance)radius
						 style:(MapOverlayPathStyle *)style;

- (id)initWithCircle:(MKCircle *)circle
			   style:(MapOverlayPathStyle *)style;

@end


// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolygon
// ----------------------------------------------------------------------

@interface MapOverlayPolygon ()

@property (strong, nonatomic) MKPolygon *polygon;

+ (MapOverlayPolygon *)polygonWithCoords:(NSArray *)values
								   style:(MapOverlayPathStyle *)style;

+ (MapOverlayPolygon *)polygonWithCoordinates:(CLLocationCoordinate2D *)coords
										count:(NSUInteger)count
										style:(MapOverlayPathStyle *)style;

- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords
					count:(NSUInteger)count
					style:(MapOverlayPathStyle *)style;

- (id)initWithPolygon:(MKPolygon *)polygon
				style:(MapOverlayPathStyle *)style;

@end


// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolyline
// ----------------------------------------------------------------------

@interface MapOverlayPolyline ()

@property (strong, nonatomic) MKPolyline *polyline;

+ (MapOverlayPolyline *)polylineWithCoords:(NSArray *)values
									 style:(MapOverlayPathStyle *)style;

+ (MapOverlayPolyline *)polylineWithCoordinates:(CLLocationCoordinate2D *)coords
										  count:(NSUInteger)count
										  style:(MapOverlayPathStyle *)style;

- (id)initWithCoords:(NSArray *)values
			   style:(MapOverlayPathStyle *)style;

- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords
					count:(NSUInteger)count
					style:(MapOverlayPathStyle *)style;

- (id)initWithPolyline:(MKPolyline *)line
				 style:(MapOverlayPathStyle *)style;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayRegion
// ----------------------------------------------------------------------

@interface MapOverlayRegion ()

+ (MapOverlayRegion *)regionWithMKRegion:(MKCoordinateRegion)region
								   style:(MapOverlayPathStyle *)style;

- (id)initWithMKRegion:(MKCoordinateRegion)region
				 style:(MapOverlayPathStyle *)style;

@end

// ----------------------------------------------------------------------
