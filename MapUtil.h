//
//	MapUtil.h
//	MapUtil
//
//	utility code and demo code for working with CLLocation and MapKit
//	including use of my map annotation and overlay classes
//	in files "MapOverlays.[h/m]" and "MapOverlays_private.h"
//
//	Created by Steve Caine on 05/21/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014-2017 Steve Caine.
//

#define CONFIG_useSuperclassCtors 1

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "MapBounds.h"

// ----------------------------------------------------------------------
#pragma mark   UTILITIES
// ----------------------------------------------------------------------

// just what it says
float randomFloatInRange(float a, float b);

// ----------------------------------------------------------------------

CLLocationCoordinate2D	MapBoundsCenter(MapBounds bounds);
MKCoordinateSpan		MapBoundsSpan(	MapBounds bounds);
MKCoordinateRegion		MapBoundsRegion(MapBounds bounds);

MapBounds MapBoundsForMKCoordinateRegion(MKCoordinateRegion region);

// ----------------------------------------------------------------------
// BOOL CLLocationCoordinate2DIsValid(CLLocationCoordinate2D coord); - is already in MapKit
BOOL MKCoordinateSpanIsValid(MKCoordinateSpan span);
BOOL MKCoordinateRegionIsValid(MKCoordinateRegion region);

// ----------------------------------------------------------------------

// extract lat/lon pairs from array of NSValues (each encoding a single CLLocation2D)
// and return an NSData with a flat array of the raw CLLocation2D coords
// (this just skips invalid NSValues, paranoid callers can check return value against values.count)
NSData *dataWithCoordsFromNSValues(NSArray *values);

// extract lat/lon pairs from array of NSArrays (each a lat/lon pair of NSNumber* doubles)
// and return an NSData with an array of the raw CLLocation2D coords
// (this just skips invalid NSValues, paranoid callers can check return value against values.count)
NSData *dataWithCoordsFromNSArray(NSArray *array);

// returns (nil, 0) if data empty or length/sizeof(coord) has leftover bytes
const CLLocationCoordinate2D *coordsFromNSData(NSData *data, NSUInteger *outLen);

// ----------------------------------------------------------------------

// extract map points stored in array as NSValues
// and return an NSData with a flat array of the raw MKMapPoint points
// (this just skips invalid NSValues values, paranoid callers can check return value against [inValues count])
//NSUInteger pointsFromNSValues(MKMapPoint **outPoints, NSArray* inValues);
NSData *dataWithMapPointsFromNSValues(NSArray *values);

// returns (nil, 0) if data empty or length/sizeof(point) has leftover bytes
const MKMapPoint *mapPointsFromNSData(NSData *data, NSUInteger *outLen);

// ----------------------------------------------------------------------

// calc four corners of a region and return an NSData with a flat array of the coords
// returns -nil- if region is invalid
NSData *dataWithRegionCorners(MKCoordinateRegion region);

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

@class MapAnnotation;
@class MapOverlayCircle;
@class MapOverlayPolygon;
@class MapOverlayPolyline;
@class MapRegionOverlay;

@interface MapUtil : NSObject

+ (NSString *)locationString:(CLLocation *)location;

+ (MapAnnotation *)mapView:(MKMapView *)mapView addAnnotationForCoordinate:(CLLocationCoordinate2D)coord;

+ (NSArray *)mapView:(MKMapView *)mapView addAnnotationsForCoords:(NSArray *)values;

+ (NSArray *)mapView:(MKMapView *)mapView addAnnotationsInRegion:(MKCoordinateRegion)region count:(NSUInteger) count;

+ (MapOverlayCircle *)mapView:(MKMapView *)mapView addCircleOverlayForCenter:(CLLocationCoordinate2D)center
					   radius:(CLLocationDistance)radius;

+ (MapOverlayPolygon *)mapView:(MKMapView *)mapView addPolygonOverlayForCoords:(NSArray *)values;

+ (MapOverlayPolyline *)mapView:(MKMapView *)mapView addPolylineOverlayForCoords:(NSArray *)values;

+ (MapRegionOverlay *)mapView:(MKMapView *)mapView addPolygonOverlayForRegion:(MKCoordinateRegion)region
					   scaled:(CGFloat)scale;

// ----------------------------------------------------------------------

+ (void)testMapView:(MKMapView *)mapView;

+ (void)testMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region;

// ----------------------------------------------------------------------

@end
