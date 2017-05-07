//
//	MapOverlays.m
//	MapUtil
//
//	see description in header file
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
#pragma mark   MapOverlayPathStyle
// ----------------------------------------------------------------------

@implementation MapOverlayPathStyle

+ (MapOverlayPathStyle *)styleWithLineWidth:(CGFloat)width
								strokeColor:(UIColor *)stroke
								  fillColor:(UIColor *)fill {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth   = width;
	result.strokeColor = stroke;
	result.fillColor   = fill;
	return result;
}

+ (MapOverlayPathStyle *)styleWithLineWidth:(CGFloat)width
									  color:(UIColor *)color
									  alpha:(CGFloat)alpha {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth   = width;
	result.strokeColor = color;
	result.fillColor   = [color colorWithAlphaComponent:alpha];
	return result;
}

// for polylines with solid fill
+ (MapOverlayPathStyle *)styleWithLineWidth:(CGFloat)width
									  color:(UIColor *)color {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth   = width;
	result.strokeColor = color;
	result.fillColor   = color;
	return result;
}

+ (MapOverlayPathStyle *)randomStyle {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	
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
#pragma mark - MapAnnotation
// ----------------------------------------------------------------------

@implementation MapAnnotation

+ (MapAnnotation *)pointWithCoordinate:(CLLocationCoordinate2D)coord {
	MapAnnotation *result = [[MapAnnotation alloc] initWithCoordinate:coord];
	return result;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord {
//	MyLog(@"%s { %f, %f } (lat/lon)", __FUNCTION__, coord.latitude, coord.longitude);
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
	NSString *class = NSStringFromClass(self.class);
	NSString *result = [NSString stringWithFormat:@"<%@: %p> - '%@'", class, self, self.title];
//	NSString *result = [NSString stringWithFormat:@"<%@: %p> - '%@' ('%@')", class, self, self.title, self.subtitle];
	return result;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlay - ABSTRACT BASE CLASS
// ----------------------------------------------------------------------

@implementation MapOverlay
- (id) initWithStyle:(MapOverlayPathStyle *)style {
	self = [super init];
	if (self) {
		_style = style;
	}
	return self;
}
- (CLLocationCoordinate2D) coordinate {
	NSAssert(false, @"Abstract class 'MapOverlay' should never be instantiated.");
	CLLocationCoordinate2D result = {0,0};
	return result;
}
- (MKMapRect) boundingMapRect {
	NSAssert(false, @"Abstract class 'MapOverlay' should never be instantiated.");
	MKMapRect result = {{0,0},{0,0}};
	return result;
}
// deprecated in iOS 7
- (MKOverlayPathView *)overlayView {
	MKOverlayPathView *result = nil;
	NSAssert(false, @"Abstract class 'MapOverlay' should never be instantiated.");
	return result;
}
#ifdef __IPHONE_7_0
- (MKOverlayRenderer *)overlayRenderer {
	MKOverlayRenderer *result = nil;
	NSAssert(false, @"Abstract class 'MapOverlay' should never be instantiated.");
	return result;
}
#endif
@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayCircle
// ----------------------------------------------------------------------

@implementation MapOverlayCircle

+ (MapOverlayCircle *)circleWithCenterCoordinate:(CLLocationCoordinate2D)center radius:(CLLocationDistance)radius style:(MapOverlayPathStyle *)style {
	MapOverlayCircle *result = [[MapOverlayCircle alloc] initWithCenterCoordinate:center radius:radius style:style];
	return result;
}

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)center radius:(CLLocationDistance)radius style:(MapOverlayPathStyle *)style {
//	MyLog(@"%s { %f, %f }, %f (lat/lon,radius)", __FUNCTION__, center.latitude, center.longitude, radius);
	self = [super initWithStyle:style];
	if (self) {
		_circle = [MKCircle circleWithCenterCoordinate:center radius:radius];
	}
	return self;
}

- (id)initWithCircle:(MKCircle *)circle style:(MapOverlayPathStyle *)style {
	self = [super initWithStyle:style];
	if (self) {
		_circle = circle;
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

#ifndef __IPHONE_7_0 // deprecated in iOS 7
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
#endif

#ifdef __IPHONE_7_0
- (MKOverlayRenderer *)overlayRenderer {
	if (self.renderer == nil) {
		self.renderer = [[MKCircleRenderer alloc] initWithCircle:self.circle];
		if (self.style) {
			self.renderer.lineWidth	  = self.style.lineWidth;
			self.renderer.strokeColor = self.style.strokeColor;
			self.renderer.fillColor	  = self.style.fillColor;
		}
		else
			NSLog(@"style == nil in %s", __FUNCTION__);
	}
	return self.renderer;
}
#endif

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolygon
// ----------------------------------------------------------------------

@implementation MapOverlayPolygon

// class method - simple polygon
+ (MapOverlayPolygon *)polygonWithCoords:(NSArray *)values style:(MapOverlayPathStyle *)style {
	MapOverlayPolygon *result = [[MapOverlayPolygon alloc] initWithCoords:values style:style];
	return result;
}

+ (MapOverlayPolygon *)polygonWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count style:(MapOverlayPathStyle *)style {
	MapOverlayPolygon *result = [[MapOverlayPolygon alloc] initWithCoordinates:coords count:count style:style];
	return result;
}

// class method - polygon with holes
+ (MapOverlayPolygon *)polygonWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count interiorPolygons:(NSArray *)interiorPolygons style:(MapOverlayPathStyle *)style {
	MapOverlayPolygon *result = [[MapOverlayPolygon alloc] initWithCoordinates:coords count:count interiorPolygons:interiorPolygons style:style];
	return result;
}

-  (id)initWithCoords:(NSArray *)values style:(MapOverlayPathStyle *)style {
//	MyLog(@"%s with %lu coords (NSArray)", __FUNCTION__, values.count);
	self = [super initWithStyle:style];
	if (self) {
		CLLocationCoordinate2D *coords = NULL;
		NSUInteger count = coordsFromNSValues(&coords, values);
		if (count) {
			_polygon = [MKPolygon polygonWithCoordinates:coords count:count];
			free(coords);
		}
	}
	return self;
}

// init method - simple polygon
- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count style:(MapOverlayPathStyle *)style {
//	MyLog(@"%s with %lu coords (buffer)", __FUNCTION__, count);
	self = [super initWithStyle:style];
	if (self) {
		_polygon = [MKPolygon polygonWithCoordinates:coords count:count];
	}
	return self;
}

// init method - polygon with holes
- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count interiorPolygons:(NSArray *)interiorPolygons style:(MapOverlayPathStyle *)style {
//	MyLog(@"%s with %lu coords (buffer) and %lu holes", __FUNCTION__, count, interiorPolygons.count);
	self = [super initWithStyle:style];
	if (self) {
		_polygon = [MKPolygon polygonWithCoordinates:coords count:count interiorPolygons:interiorPolygons];
	}
	return self;
}

// init with real MKPolygon
-(id)initWithPolygon:(MKPolygon *)polygon style:(MapOverlayPathStyle *)style {
	self = [super initWithStyle:style];
	if (self) {
		_polygon = polygon;
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

#ifndef __IPHONE_7_0 // deprecated in iOS 7
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
#endif

#ifdef __IPHONE_7_0
- (MKOverlayRenderer *)overlayRenderer {
	if (self.renderer == nil) {
		self.renderer = [[MKPolygonRenderer alloc] initWithPolygon:self.polygon];
		if (self.style) {
			self.renderer.lineWidth	  = self.style.lineWidth;
			self.renderer.strokeColor = self.style.strokeColor;
			self.renderer.fillColor	  = self.style.fillColor;
		}
		else
			NSLog(@"style == nil in %s", __FUNCTION__);
	}
	return self.renderer;
}
#endif

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolyline
// ----------------------------------------------------------------------

@implementation MapOverlayPolyline

// class methods
+ (MapOverlayPolyline *)polylineWithCoords:(NSArray *)values style:(MapOverlayPathStyle *)style {
	MapOverlayPolyline *result = [[MapOverlayPolyline alloc] initWithCoords:values style:style];
	return result;
}

+ (MapOverlayPolyline *)polylineWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count style:(MapOverlayPathStyle *)style {
	MapOverlayPolyline *result = [[MapOverlayPolyline alloc] initWithCoordinates:coords count:count style:style];
	return result;
}

+ (MapOverlayPolyline *)polylinePolyline:(MKPolyline *)polyline style:(MapOverlayPathStyle *)style {
	MapOverlayPolyline *result = [[MapOverlayPolyline alloc] initWithPolyline:polyline style:style];
	return result;
}

// init methods
-  (id)initWithCoords:(NSArray *)values style:(MapOverlayPathStyle *)style {
//	MyLog(@"%s with %lu coords (NSArray)", __FUNCTION__, values.count);
	self = [super initWithStyle:style];
	if (self) {
		CLLocationCoordinate2D *coords = NULL;
		NSUInteger count = coordsFromNSValues(&coords, values);
		if (count) {
			_polyline = [MKPolyline polylineWithCoordinates:coords count:count];
			free(coords);
		}
	}
	return self;
}

- (id)initWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count style:(MapOverlayPathStyle *)style {
//	MyLog(@"%s with %lu coords (buffer)", __FUNCTION__, count);
	self = [super initWithStyle:style];
	if (self) {
		_polyline = [MKPolyline polylineWithCoordinates:coords count:count];
	}
	return self;
}

// init with real MKPolyline
- (id)initWithPolyline:(MKPolyline *)line style:(MapOverlayPathStyle *)style {
	self = [super initWithStyle:style];
	if (self) {
		_polyline = line;
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

#ifndef __IPHONE_7_0 // deprecated in iOS 7
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
#endif

#ifdef __IPHONE_7_0
- (MKOverlayRenderer *)overlayRenderer {
	if (self.renderer == nil) {
		self.renderer = [[MKPolylineRenderer alloc] initWithPolyline:self.polyline];
		if (self.style) {
			self.renderer.lineWidth	  = self.style.lineWidth;
			self.renderer.strokeColor = self.style.strokeColor;
			self.renderer.fillColor	  = self.style.fillColor;
		}
		else
			NSLog(@"style == nil in %s", __FUNCTION__);
	}
	return self.renderer;
}
#endif

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayRegion
// ----------------------------------------------------------------------

@implementation MapOverlayRegion

+ (MapOverlayRegion *)regionWithMKRegion:(MKCoordinateRegion)region style:(MapOverlayPathStyle *)style {
	MapOverlayRegion *result = [[MapOverlayRegion alloc] initWithMKRegion:region style:style];
	return result;
}

- (id)initWithMKRegion:(MKCoordinateRegion)region style:(MapOverlayPathStyle *)style {
//	MyLog(@"%s with %@", __FUNCTION__, str_MKCoordinateRegion(region));
	CLLocationCoordinate2D *corners = regionCornersAsBuffer(region);
	self = [super initWithCoordinates:corners count:4 interiorPolygons:nil style:style];
	free(corners);
	if (self) {
//		MyLog(@"NEW <%@ %p>", NSStringFromClass(self.class), self);
	}
	return self;
}

- (void) dealloc {
//	MyLog(@"BYE <%@ %p>", NSStringFromClass(self.class), self);
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

#ifndef __IPHONE_7_0 // deprecated in iOS 7
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
#endif

#ifdef __IPHONE_7_0
- (MKOverlayRenderer *)overlayRenderer {
	if (self.renderer == nil) {
		self.renderer = [[MKPolygonRenderer alloc] initWithPolygon:self.polygon];
		if (self.style) {
			self.renderer.lineWidth	  = self.style.lineWidth;
			self.renderer.strokeColor = self.style.strokeColor;
			self.renderer.fillColor	  = self.style.fillColor;
		}
		else
			NSLog(@"style == nil in %s", __FUNCTION__);
	}
	return self.renderer;
}
#endif

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlays
// ----------------------------------------------------------------------

@implementation MapOverlays

+ (void) testMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region {
	
}

@end
