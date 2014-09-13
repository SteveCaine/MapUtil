//
//	MapOverlays_private.h
//	MapUtil
//
//	Created by Steve Caine on 05/29/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#import "MapOverlays.h"

// here we put those parts of the MapOverlays classes' interfaces
// that should be hidden from general use
// but visible to subclasses of these classes

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

@property (strong, nonatomic) MapOverlayPathStyle		*style;
@property (strong, nonatomic) MKOverlayPathView		*view;
#if 0 //def __IPHONE_7_0
@property (strong, nonatomic) MKOverlayPathRenderer	*renderer;
#endif
- (id)initWithStyle:(MapOverlayPathStyle *)style;
@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayCircle
// ----------------------------------------------------------------------

@interface MapOverlayCircle ()
//@interface MapOverlayCircle : MapOverlay // MKCircle //

//@property (strong, nonatomic) MapOverlayPathStyle *style;
@property (strong, nonatomic) MKCircle		  *circle;
//@property (strong, nonatomic) MKCircleView	  *view;

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
//@interface MapOverlayPolygon : MapOverlay // MKPolygon //

//@property (strong, nonatomic) MapOverlayPathStyle *style;
@property (strong, nonatomic) MKPolygon		  *polygon;
//@property (strong, nonatomic) MKPolygonView	  *view;

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
//@interface MapOverlayPolyline : MapOverlay // MKPolyline //

//@property (strong, nonatomic) MapOverlayPathStyle	*style;
@property (strong, nonatomic) MKPolyline		*polyline;
//@property (strong, nonatomic) MKPolylineView	*view;

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
//@interface MapOverlayRegion : MapOverlay // MKPolygon //

//@property (strong, nonatomic) MapOverlayPathStyle *style;
@property (strong, nonatomic) MKPolygon		  *polygon;
@property (strong, nonatomic) MKPolygonView	  *view;

+ (MapOverlayRegion *)regionWithMKRegion:(MKCoordinateRegion)region
								   style:(MapOverlayPathStyle *)style;
- (id)initWithMKRegion:(MKCoordinateRegion)region
				 style:(MapOverlayPathStyle *)style;
@end

// ----------------------------------------------------------------------
