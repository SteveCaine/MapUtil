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
#pragma mark   MapAnnotationPoint
// ----------------------------------------------------------------------

@interface MapAnnotationPoint ()

@property (copy, nonatomic, readwrite) NSString *title;
@property (copy, nonatomic, readwrite) NSString *subtitle;
@property (strong, nonatomic) MKPointAnnotation *point;
@property (strong, nonatomic) MKAnnotationView	*view;

+ (MapAnnotationPoint *)pointWithCoordinate:(CLLocationCoordinate2D)coord;
- (id)initWithCoordinate:(CLLocationCoordinate2D)coord;
- (id)initWithPoint:(MKPointAnnotation *)point;

@end


// ----------------------------------------------------------------------
#pragma mark - MapOverlayCircle
// ----------------------------------------------------------------------

@interface MapOverlayCircle ()

@property (strong, nonatomic) MapOverlayStyle *style;
@property (strong, nonatomic) MKCircle		  *circle;
@property (strong, nonatomic) MKCircleView	  *view;

+ (MapOverlayCircle *)circleWithCenterCoordinate:(CLLocationCoordinate2D)center
										  radius:(CLLocationDistance)radius
										   style:(MapOverlayStyle *)style;
- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)center
						radius:(CLLocationDistance)radius
						 style:(MapOverlayStyle *)style;
- (id)initWithCircle:(MKCircle *)circle
			   style:(MapOverlayStyle *)style;

@end


// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolygon
// ----------------------------------------------------------------------

@interface MapOverlayPolygon ()

@property (strong, nonatomic) MapOverlayStyle *style;
@property (strong, nonatomic) MKPolygon		  *polygon;
@property (strong, nonatomic) MKPolygonView	  *view;

+ (MapOverlayPolygon *)polygonWithCoords:(NSArray *)values
								   style:(MapOverlayStyle *)style;
+ (MapOverlayPolygon *)polygonWithCoordinates:(CLLocationCoordinate2D *)coords
										count:(NSUInteger)count
										style:(MapOverlayStyle *)style;
- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords
					count:(NSUInteger)count
					style:(MapOverlayStyle *)style;
- (id)initWithPolygon:(MKPolygon *)polygon
				style:(MapOverlayStyle *)style;

@end


// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolyline
// ----------------------------------------------------------------------

@interface MapOverlayPolyline ()

@property (strong, nonatomic) MapOverlayStyle *style;
@property (strong, nonatomic) MKPolyline	  *polyline;
@property (strong, nonatomic) MKPolylineView  *view;

+ (MapOverlayPolyline *)polylineWithCoords:(NSArray *)values
									 style:(MapOverlayStyle *)style;
+ (MapOverlayPolyline *)polylineWithCoordinates:(CLLocationCoordinate2D *)coords
										  count:(NSUInteger)count
										  style:(MapOverlayStyle *)style;
- (id)initWithCoords:(NSArray *)values
			   style:(MapOverlayStyle *)style;
- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords
					count:(NSUInteger)count
					style:(MapOverlayStyle *)style;
- (id)initWithPolyline:(MKPolyline *)line
				 style:(MapOverlayStyle *)style;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayRegion
// ----------------------------------------------------------------------

@interface MapOverlayRegion ()

@property (strong, nonatomic) MapOverlayStyle *style;
@property (strong, nonatomic) MKPolygon		  *polygon;
@property (strong, nonatomic) MKPolygonView	  *view;

+ (MapOverlayRegion *)regionWithMKRegion:(MKCoordinateRegion)region
								   style:(MapOverlayStyle *)style;
- (id)initWithMKRegion:(MKCoordinateRegion)region
				 style:(MapOverlayStyle *)style;

@end

// ----------------------------------------------------------------------
