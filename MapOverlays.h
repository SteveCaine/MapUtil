//
//	MapOverlays.h
//	MapUtil
//
//	wrapper classes for MapKit annotations and overlays
//	to attach icons to annotations and styles to overlays
//
//	subclasses will hide most of these details
//
//	for MapAnnotationPoint,
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

+ (MapOverlayPathStyle *)randomStyle;

@end

// ----------------------------------------------------------------------
#pragma mark - MapAnnotationPoint
// ----------------------------------------------------------------------

@interface MapAnnotationPoint : NSObject <MKAnnotation> // MKPointAnnotation //

@property (copy,   nonatomic) NSString *reuseID; // can be left nil
@property (strong, nonatomic) UIImage  *image;	 // ditto

- (MKAnnotationView *)annotationView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlay
// ----------------------------------------------------------------------

@interface MapOverlay : NSObject <MKOverlay>

- (MKOverlayView *)overlayView;
#ifdef __IPHONE_7_0
- (MKOverlayRenderer *)overlayRenderer;
#endif

@end

#if 0
// ----------------------------------------------------------------------
#pragma mark - MapOverlayCircle
// ----------------------------------------------------------------------

@interface MapOverlayCircle : MapOverlay // MKCircle //

//- (MKOverlayPathView *)overlayView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolygon
// ----------------------------------------------------------------------

@interface MapOverlayPolygon : MapOverlay // MKPolygon //

//- (MKOverlayPathView *)overlayView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolyline
// ----------------------------------------------------------------------

@interface MapOverlayPolyline : MapOverlay // MKPolyline //

//- (MKOverlayPathView *)overlayView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayRegion
// ----------------------------------------------------------------------

@interface MapOverlayRegion : MapOverlay // MKPolygon //

//- (MKOverlayPathView *)overlayView;

@end
#endif

// ----------------------------------------------------------------------
#pragma mark - MapOverlays
// ----------------------------------------------------------------------

@interface MapOverlays : NSObject

+ (void) testMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region;

@end

// ----------------------------------------------------------------------
