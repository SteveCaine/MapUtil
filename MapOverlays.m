//
//	MapOverlays.m
//	MapUtil
//
//	wrapper classes for MapKit annotations and overlays
//	to attach icons to annotations and styles to overlays
//
//	subclasses will hide most of these details
//
//	Created by Steve Caine on 05/29/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#import "MapOverlays.h"
#import "MapOverlays_private.h"

#import "MapUtil.h"

#import "Debug_iOS.h"
#import "Debug_MapKit.h"

// ----------------------------------------------------------------------
#pragma mark   MapOverlayStyle
// ----------------------------------------------------------------------

@implementation MapOverlayStyle

+ (MapOverlayStyle *)randomStyle {
	MapOverlayStyle *result = [[MapOverlayStyle alloc] init];
	
	CGFloat r1 = randomFloatInRange(0, 1);
	CGFloat g1 = randomFloatInRange(0, 1);
	CGFloat b1 = randomFloatInRange(0, 1);
	
	CGFloat r2 = randomFloatInRange(0, 1);
	CGFloat g2 = randomFloatInRange(0, 1);
	CGFloat b2 = randomFloatInRange(0, 1);
	
	result.lineWidth   = randomFloatInRange(1, 4);
	result.strokeColor = [UIColor colorWithRed:r1 green:g1 blue:b1 alpha:1.0];
	result.fillColor   = [UIColor colorWithRed:r2 green:g2 blue:b2 alpha:0.5];
	
	return result;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapAnnotationPoint
// ----------------------------------------------------------------------

@implementation MapAnnotationPoint
+ (MapAnnotationPoint *)pointWithCoordinate:(CLLocationCoordinate2D)coord {
	MapAnnotationPoint *result = [[MapAnnotationPoint alloc] initWithCoordinate:coord];
	return result;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord {
	self = [super init];
	if (self) {
		_point = [[MKPointAnnotation alloc] init];
		_point.coordinate = coord;
	}
	return self;
}

- (id)initWithPoint:(MKPointAnnotation *)point {
	self = [super init];
	if (self) {
		_point = point;
		_point.coordinate = point.coordinate;
	}
	return self;
}

- (CLLocationCoordinate2D) coordinate {
	return self.point.coordinate;
}

- (MKAnnotationView *)annotationView {
	if (self.view == nil) {
		self.view = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:self.reuseID];
		if (self.image) {
			self.view.image = self.image;
		}
		self.view.enabled = YES;
		self.view.canShowCallout = YES;
	}
	return self.view;
}

- (NSString *)description {
	NSString *class = NSStringFromClass([self class]);
	NSString *result = [NSString stringWithFormat:@"<%@: %p> - '%@'", class, self, self.title];
//	NSString *result = [NSString stringWithFormat:@"<%@: %p> - '%@' ('%@')", class, self, self.title, self.subtitle];
	return result;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayCircle
// ----------------------------------------------------------------------

@implementation MapOverlayCircle

+ (MapOverlayCircle *)circleWithCenterCoordinate:(CLLocationCoordinate2D)center radius:(CLLocationDistance)radius style:(MapOverlayStyle *)style {
	MapOverlayCircle *result = [[MapOverlayCircle alloc] initWithCenterCoordinate:center radius:radius style:style];
	return result;
}

- (id) initWithCenterCoordinate:(CLLocationCoordinate2D)center radius:(CLLocationDistance)radius style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		_circle = [MKCircle circleWithCenterCoordinate:center radius:radius];
		_style = style;
	}
	return self;
}

- (id) initWithCircle:(MKCircle *)circle style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		_circle = circle;
		_style = style;
	}
	return self;
}

- (CLLocationCoordinate2D) coordinate {
	return self.circle.coordinate;
}

- (CLLocationDistance) radius {
	return self.circle.radius;
}

- (MKMapRect) boundingMapRect {
	return self.circle.boundingMapRect;
}

- (MKOverlayPathView *)overlayView {
	if (self.view == nil) {
		self.view = [[MKCircleView alloc] initWithOverlay:self];
		if (self.style) {
			self.view.lineWidth	  = self.style.lineWidth;
			self.view.strokeColor = self.style.strokeColor;
			self.view.fillColor	  = self.style.fillColor;
		}
		else
			NSLog(@"style == nil in %s", __FUNCTION__);
	}
	return self.view;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolygon
// ----------------------------------------------------------------------

@implementation MapOverlayPolygon

// class method - simple polygon
+ (MapOverlayPolygon *)polygonWithCoords:(NSArray *)values style:(MapOverlayStyle *)style {
	MapOverlayPolygon *result = [[MapOverlayPolygon alloc] initWithCoords:values style:style];
	return result;
}

+ (MapOverlayPolygon *)polygonWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count style:(MapOverlayStyle *)style {
	MapOverlayPolygon *result = [[MapOverlayPolygon alloc] initWithCoordinates:coords count:count style:style];
	return result;
}

// class method - polygon with holes
+ (MapOverlayPolygon *)polygonWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count interiorPolygons:(NSArray *)interiorPolygons style:(MapOverlayStyle *)style {
	MapOverlayPolygon *result = [[MapOverlayPolygon alloc] initWithCoordinates:coords count:count interiorPolygons:interiorPolygons style:style];
	return result;
}

-  (id)initWithCoords:(NSArray *)values style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		CLLocationCoordinate2D *coords = NULL;
		NSUInteger count = coordsFromNSValues(&coords, values);
		if (count) {
			_polygon = [MKPolygon polygonWithCoordinates:coords count:count];
			_style = style;
			free(coords);
		}
	}
	return self;
}

// init method - simple polygon
- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		_polygon = [MKPolygon polygonWithCoordinates:coords count:count];
		_style = style;
	}
	return self;
}

// init method - polygon with holes
- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count interiorPolygons:(NSArray *)interiorPolygons style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		_polygon = [MKPolygon polygonWithCoordinates:coords count:count interiorPolygons:interiorPolygons];
		_style = style;
	}
	return self;
}

// init with real MKPolygon
-(id)initWithPolygon:(MKPolygon *)polygon style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		_polygon = polygon;
		_style = style;
	}
	return self;
}

- (CLLocationCoordinate2D) coordinate {
	return self.polygon.coordinate;
}

- (MKMapRect) boundingMapRect {
	return self.polygon.boundingMapRect;
}

- (NSUInteger) pointCount {
	return self.polygon.pointCount;
}

- (MKMapPoint *)points {
	return self.polygon.points;
}

- (NSArray *)interiorPolygons {
	return self.polygon.interiorPolygons;
}

- (void)getCoordinates:(CLLocationCoordinate2D *)coords range:(NSRange)range {
	[self.polygon getCoordinates:coords range:range];
}

- (MKOverlayPathView *)overlayView {
	if (self.view == nil) {
		self.view = [[MKPolygonView alloc] initWithOverlay:self];
		if (self.style) {
			self.view.lineWidth	  = self.style.lineWidth;
			self.view.strokeColor = self.style.strokeColor;
			self.view.fillColor	  = self.style.fillColor;
		}
		else
			NSLog(@"style == nil in %s", __FUNCTION__);
	}
	return self.view;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolyline
// ----------------------------------------------------------------------

@implementation MapOverlayPolyline

// class methods
+ (MapOverlayPolyline *)polylineWithCoords:(NSArray *)values style:(MapOverlayStyle *)style {
	MapOverlayPolyline *result = [[MapOverlayPolyline alloc] initWithCoords:values style:style];
	return result;
}

+ (MapOverlayPolyline *)polylineWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count style:(MapOverlayStyle *)style {
	MapOverlayPolyline *result = [[MapOverlayPolyline alloc] initWithCoordinates:coords count:count style:style];
	return result;
}

+ (MapOverlayPolyline *)polylinePolyline:(MKPolyline *)polyline style:(MapOverlayStyle *)style {
	MapOverlayPolyline *result = [[MapOverlayPolyline alloc] initWithPolyline:polyline style:style];
	return result;
}

// init methods
-  (id)initWithCoords:(NSArray *)values style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		CLLocationCoordinate2D *coords = NULL;
		NSUInteger count = coordsFromNSValues(&coords, values);
		if (count) {
			_polyline = [MKPolyline polylineWithCoordinates:coords count:count];
			_style = style;
			free(coords);
		}
	}
	return self;
}

- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		_polyline = [MKPolyline polylineWithCoordinates:coords count:count];
		_style = style;
	}
	return self;
}

// init with real MKPolyline
- (id)initWithPolyline:(MKPolyline *)line style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
		_polyline = line;
		_style = style;
	}
	return self;
}

- (CLLocationCoordinate2D) coordinate {
	return self.polyline.coordinate;
}

- (MKMapRect) boundingMapRect {
	return self.polyline.boundingMapRect;
}

- (NSUInteger) pointCount {
	return self.polyline.pointCount;
}

- (MKMapPoint *)points {
	return self.polyline.points;
}

- (void)getCoordinates:(CLLocationCoordinate2D *)coords range:(NSRange)range {
	[self.polyline getCoordinates:coords range:range];
}

- (MKOverlayPathView *)overlayView {
	if (self.view == nil) {
		self.view = [[MKPolylineView alloc] initWithOverlay:self];
		if (self.style) {
			self.view.lineWidth	  = self.style.lineWidth;
			self.view.strokeColor = self.style.strokeColor;
			self.view.fillColor	  = self.style.fillColor;
		}
		else
			NSLog(@"style == nil in %s", __FUNCTION__);
	}
	return self.view;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayRegion
// ----------------------------------------------------------------------

@implementation MapOverlayRegion

+ (MapOverlayRegion *)regionWithMKRegion:(MKCoordinateRegion)region style:(MapOverlayStyle *)style {
	MapOverlayRegion *result = [[MapOverlayRegion alloc] initWithMKRegion:region style:style];
	return result;
}

- (id)initWithMKRegion:(MKCoordinateRegion)region style:(MapOverlayStyle *)style {
	self = [super init];
	if (self) {
//		MyLog(@"NEW <%@ %p>", NSStringFromClass([self class]), self);
		CLLocationCoordinate2D *corners = regionCornersAsBuffer(region);
		if (corners) {
			_polygon = [MKPolygon polygonWithCoordinates:corners count:4];
			_style = style;
			free(corners);
		}
	}
	return self;
}

- (void) dealloc {
//	MyLog(@"BYE <%@ %p>", NSStringFromClass([self class]), self);
}

- (CLLocationCoordinate2D) coordinate {
	return self.polygon.coordinate;
}

- (MKMapRect) boundingMapRect {
	return self.polygon.boundingMapRect;
}

- (NSUInteger) pointCount {
	return self.polygon.pointCount;
}

- (MKMapPoint *)points {
	return self.polygon.points;
}

- (void)getCoordinates:(CLLocationCoordinate2D *)coords range:(NSRange)range {
	[self.polygon getCoordinates:coords range:range];
}

- (NSArray *)interiorPolygons {
	return nil;
}

- (MKOverlayPathView *)overlayView {
	if (self.view == nil) {
		self.view = [[MKPolygonView alloc] initWithOverlay:self];
		if (self.style) {
			self.view.lineWidth	  = self.style.lineWidth;
			self.view.strokeColor = self.style.strokeColor;
			self.view.fillColor	  = self.style.fillColor;
		}
		else
			NSLog(@"style == nil in %s", __FUNCTION__);
	}
	return self.view;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlays
// ----------------------------------------------------------------------

@implementation MapOverlays

+ (void) testMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region {
	
}

@end
