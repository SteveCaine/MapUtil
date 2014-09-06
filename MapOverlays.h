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
#pragma mark   MapOverlayStyle
// ----------------------------------------------------------------------

@interface MapOverlayStyle : NSObject

@property (assign, nonatomic) CGFloat  lineWidth;
@property (strong, nonatomic) UIColor *strokeColor;
@property (strong, nonatomic) UIColor *fillColor;

+ (MapOverlayStyle *)randomStyle;

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
#pragma mark - MapOverlayCircle
// ----------------------------------------------------------------------

@interface MapOverlayCircle : NSObject <MKOverlay> // MKCircle //

- (MKOverlayPathView *)overlayView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolygon
// ----------------------------------------------------------------------

@interface MapOverlayPolygon : NSObject <MKOverlay> // MKPolygon //

- (MKOverlayPathView *)overlayView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayPolyline
// ----------------------------------------------------------------------

@interface MapOverlayPolyline : NSObject <MKOverlay> // MKPolyline //

- (MKOverlayPathView *)overlayView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlayRegion
// ----------------------------------------------------------------------

@interface MapOverlayRegion : NSObject <MKOverlay> // MKPolygon //

- (MKOverlayPathView *)overlayView;

@end

// ----------------------------------------------------------------------
#pragma mark - MapOverlays
// ----------------------------------------------------------------------

@interface MapOverlays : NSObject

+ (void) testMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region;

@end

// ----------------------------------------------------------------------
