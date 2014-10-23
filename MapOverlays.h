//
//	MapOverlays.h
//	MapUtil
//
//	wrapper classes for MapKit annotations and overlays
//	to attach icons to annotations and styles to overlays
//
//	subclasses will hide most of these details
//
//	for MapAnnotation,
//		@property title, subtitle, coordinate
//	are declared in MKAnnotation
//
//	for MapOverlayCircle, MapOverlayPolygon, and MapOverlayPolyline
//		@property coordinate, boundingMapRect,
//		and optional methods intersectsMapRect: canReplaceMapContent
//	are declared in MKOverlay
//
//	for MapOverlayCircle
//		@property radius
//	is declared in MKCircle
//
//	NOTE: MapOverlayPathStyle implements just *some* of the properties
//	common to both MKOverlayPathView and MKOverlayPathRenderer,
//	remaining properties (lineCap, miterLimit, etc.) could be added as needed
//
//	Created by Steve Caine on 05/29/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

// ----------------------------------------------------------------------
#pragma mark   MapOverlayPathStyle
// ----------------------------------------------------------------------

@interface MapOverlayPathStyle : NSObject

@property (assign, nonatomic) CGFloat  lineWidth;
@property (strong, nonatomic) UIColor *strokeColor;
@property (strong, nonatomic) UIColor *fillColor;

+ (MapOverlayPathStyle *)styleWithLineWidth:(CGFloat)width
								strokeColor:(UIColor *)stroke
								  fillColor:(UIColor *)fill;

+ (MapOverlayPathStyle *)styleWithLineWidth:(CGFloat)width
									  color:(UIColor *)color
									  alpha:(CGFloat)alpha;
// for polylines with solid fill
+ (MapOverlayPathStyle *)styleWithLineWidth:(CGFloat)width
									  color:(UIColor *)color;

+ (MapOverlayPathStyle *)randomStyle;

@end

// ----------------------------------------------------------------------
#pragma mark - MapAnnotation
// ----------------------------------------------------------------------

@interface MapAnnotation : NSObject <MKAnnotation>

@property (copy,   nonatomic) NSString *reuseID; // can be left nil
@property (strong, nonatomic) UIImage  *image;	 // ditto

- (MKAnnotationView *)annotationView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlay - abstract base class
// ----------------------------------------------------------------------

@interface MapOverlay : NSObject <MKOverlay>

// deprecated in iOS 7
- (MKOverlayView *)overlayView;

#ifdef __IPHONE_7_0
- (MKOverlayRenderer *)overlayRenderer;
#endif

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayCircle
// ----------------------------------------------------------------------

@interface MapOverlayCircle : MapOverlay
@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolygon
// ----------------------------------------------------------------------

@interface MapOverlayPolygon : MapOverlay
@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolyline
// ----------------------------------------------------------------------

@interface MapOverlayPolyline : MapOverlay
@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayRegion - polygon framing an MKRegion - for demo
// ----------------------------------------------------------------------

@interface MapOverlayRegion : MapOverlayPolygon

+ (MapOverlayRegion *)regionWithMKRegion:(MKCoordinateRegion)region
								   style:(MapOverlayPathStyle *)style;

//- (id)initWithMKRegion:(MKCoordinateRegion)region
//				 style:(MapOverlayPathStyle *)style;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlays - demo code
// ----------------------------------------------------------------------

@interface MapOverlays : NSObject

+ (void) testMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region;

@end

// ----------------------------------------------------------------------
