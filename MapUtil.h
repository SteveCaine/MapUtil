//
//	MapUtil.h
//	MapUtil
//
//	Created by Steve Caine on 05/21/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#define CONFIG_useSuperclassCtors 1

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


// ----------------------------------------------------------------------
#pragma mark   UTILITIES
// ----------------------------------------------------------------------

// just what it says
float randomFloatInRange(float a, float b);

// BOOL CLLocationCoordinate2DIsValid(CLLocationCoordinate2D coord); - is already in MapKit
BOOL MKCoordinateSpanIsValid(MKCoordinateSpan span);
BOOL MKCoordinateRegionIsValid(MKCoordinateRegion region);

// ----------------------------------------------------------------------

// extract map coords stored in array as NSValues
// and store in buffer created with malloc()
// caller must call free() on any non-nil buffer returned
// (this just skips invalid coord values, paranoid callers can check return value against [inValues count])
NSUInteger coordsFromNSValues(CLLocationCoordinate2D **outCoords, NSArray* inValues);

// extract map points stored in array as NSValues
// and store in buffer created with malloc()
// caller must call free() on any non-nil buffer returned
// (this just skips invalid point values, paranoid callers can check return value against [inValues count])
NSUInteger pointsFromNSValues(MKMapPoint **outPoints, NSArray* inValues);

// calc four corners of a region and return in buffer created with malloc()
// caller must call free() on any non-nil buffer returned
// returns -NULL- if region is invalid
CLLocationCoordinate2D* regionCornersAsBuffer(MKCoordinateRegion region);

// calc four corners of a region and return as NSValues
// returns -nil- if region is invalid
NSArray *regionCornersAsNSValues(MKCoordinateRegion region);

// ----------------------------------------------------------------------

MKCoordinateRegion scaledRegion(MKCoordinateRegion region, CGFloat scale);

MKCoordinateRegion regionForCoords(NSArray *values);
MKCoordinateRegion regionForScaledCoords(NSArray *values, CGFloat scale);

MKPolyline *polylineForCoords(NSArray *values);

MKPolygon *polygonForRegion(MKCoordinateRegion *region);
MKPolygon *polygonForCoords(NSArray *values);
MKPolygon *polygonForCoordsWithHoles(NSArray *values, NSArray *interiorMKPolygons);

// ----------------------------------------------------------------------
#pragma mark - TEST
// ----------------------------------------------------------------------

NSArray *randomCoordsInRegion(MKCoordinateRegion region, NSUInteger count);

// ----------------------------------------------------------------------
#pragma mark - MapUtil
// ----------------------------------------------------------------------

@class MapAnnotationPoint;
@class MapOverlayCircle;
@class MapOverlayPolygon;
@class MapOverlayPolyline;
@class MapOverlayRegion;

@interface MapUtil : NSObject

+ (MapAnnotationPoint *)mapView:(MKMapView *)mapView addAnnotationForCoordinate:(CLLocationCoordinate2D)coord;

+ (NSArray *)mapView:(MKMapView *)mapView addAnnotationsForCoords:(NSArray *)values;

+ (NSArray *)mapView:(MKMapView *)mapView addAnnotationsInRegion:(MKCoordinateRegion)region count:(NSUInteger) count;

+ (MapOverlayCircle *)mapView:(MKMapView *)mapView addCircleOverlayForCenter:(CLLocationCoordinate2D)center
					   radius:(CLLocationDistance)radius;

+ (MapOverlayPolygon *)mapView:(MKMapView *)mapView addPolygonOverlayForCoords:(NSArray *)values;

+ (MapOverlayPolyline *)mapView:(MKMapView *)mapView addPolylineOverlayForCoords:(NSArray *)values;

+ (MapOverlayRegion *)mapView:(MKMapView *)mapView addRegionOverlayForRegion:(MKCoordinateRegion)region
					   scaled:(CGFloat)scale;

// ----------------------------------------------------------------------

+ (void)testMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region;

// ----------------------------------------------------------------------
// MKMapViewDelegate methods

+ (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation;

+ (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay;

// ----------------------------------------------------------------------

@end
