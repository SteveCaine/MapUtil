//
//	MapUtil.m
//	MapUtil
//
//	see description in header file
//
//	Created by Steve Caine on 05/21/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#import "MapUtil.h"

#import "MapOverlays.h"
#import "MapOverlays_private.h"

#import "Debug_iOS.h"
#import "Debug_MapKit.h"

// ----------------------------------------------------------------------
#pragma mark   static globals
// ----------------------------------------------------------------------
// some globals to define text & images for our test annotations and overlays

static int		 annotationIndex = 0;
static NSString *annotationImage;
static NSString *annotationPrefix;

// point
static NSString *pointImage = @"cyan-16x16.png";

// circle
static NSString *circleImage = @"red-16x16.png";
static MapOverlayPathStyle *circleStyle() {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth = 3;
	result.strokeColor =  [UIColor redColor];
	result.fillColor   = [[UIColor redColor] colorWithAlphaComponent:0.25];
	return result;
}

// polygon
static NSString *polygonImage = @"blue-16x16.png";
static MapOverlayPathStyle *polygonStyle() {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth = 4;
	result.strokeColor =  [UIColor blueColor];
	result.fillColor   = [[UIColor blueColor] colorWithAlphaComponent:0.25];
	return result;
}

// polyline
static NSString *polylineImage = @"green-16x16.png";
static MapOverlayPathStyle *polylineStyle() {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth = 3;
	result.strokeColor =  [UIColor greenColor];
	result.fillColor   = [[UIColor greenColor] colorWithAlphaComponent:0.25];
	return result;
}

// region
static NSString *regionImage = @"yellow-16x16.png";
static MapOverlayPathStyle *regionStyle() {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth = 3;
	result.strokeColor =  [UIColor yellowColor];
	result.fillColor   = [[UIColor yellowColor] colorWithAlphaComponent:0.25];
	return result;
}

// ----------------------------------------------------------------------
#pragma mark - UTILITIES
// ----------------------------------------------------------------------

// adapted from 'Recipe 7-6: Grouping Annotations Dynamically' code sample
// in "iOS 7 Development Recipes" book by Joseph Hoffman

float randomFloatInRange(float a, float b) {
	static BOOL did_init;
	if (did_init == NO) {
		did_init = YES;
		srand((unsigned)time(0));
	}
	float random = ((float) rand()) / (float) RAND_MAX;
	float diff = b - a;
	float r = random * diff;
	return a + r;
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

//CLLocationCoordinate2DIsValid(CLLocationCoordinate2D coord) - already provided in MapKit

BOOL MKCoordinateSpanIsValid(MKCoordinateSpan span) {
	if (span.latitudeDelta <=	0 || span.longitudeDelta <=	  0 ||
		span.latitudeDelta >= 180 || span.longitudeDelta >= 360)
		return NO;
	return YES;
}

BOOL MKCoordinateRegionIsValid(MKCoordinateRegion region) {
	if (!CLLocationCoordinate2DIsValid(region.center))
		return NO;
	else if (!MKCoordinateSpanIsValid(region.span))
		return NO;
	else {
		CLLocationDegrees halfLat = region.span.latitudeDelta/2;
		if (region.center.latitude + halfLat > +90 ||
			region.center.latitude - halfLat < -90)
			return NO;
		else {
			CLLocationDegrees halfLon = region.span.longitudeDelta/2;
			if (region.center.longitude + halfLon > +180 ||
				region.center.longitude - halfLon < -180)
				return NO;
		}
	}
	return YES;
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

// caller must call free() on any non-nil buffer returned

NSUInteger coordsFromNSValues(CLLocationCoordinate2D **outCoords, NSArray* inValues) {
	NSUInteger result = 0;
	
	NSUInteger count = [inValues count];
	if (count && outCoords) {
		size_t size = sizeof(CLLocationCoordinate2D) * count;
//		*outCoords = malloc(size);
		*outCoords = calloc(count, size);
		CLLocationCoordinate2D *c = *outCoords;
		
		for (NSValue *value in inValues) {
			if (strcmp([value objCType], @encode(CLLocationCoordinate2D)) == 0) {
				CLLocationCoordinate2D coord;
				[value getValue:&coord];
				*c++ = coord;
			}
		}
		result = c - *outCoords; // how many values *were* CLLocationCoordinate2Ds?
		
		if (result < count) {
			size_t new_size = sizeof(CLLocationCoordinate2D) * result;
			if (new_size)
				*outCoords = realloc(*outCoords, new_size);
			else {
				free(*outCoords);
				*outCoords = NULL;
			}
		}
	}
	return result;
}

// ----------------------------------------------------------------------
// caller must call free() on any non-nil buffer returned

NSUInteger pointsFromNSValues(MKMapPoint **outPoints, NSArray* inValues) {
	NSUInteger result = 0;
	
	NSUInteger count = [inValues count];
	if (count && outPoints) {
		size_t size = sizeof(MKMapPoint) * count;
//		*outPoints = malloc(size);
		*outPoints = calloc(count, size);
		MKMapPoint *p = *outPoints;
		
		for (NSValue *value in inValues) {
			if (strcmp([value objCType], @encode(MKMapPoint)) == 0) {
				MKMapPoint point;
				[value getValue:&point];
				*p++ = point;
			}
		}
		result = p - *outPoints; // how many values *were* MKMapPoints?
		
		if (result < count) {
			size_t new_size = sizeof(MKMapPoint) * result;
			if (new_size)
				*outPoints = realloc(*outPoints, sizeof(MKMapPoint) * result);
			else {
				free(*outPoints);
				*outPoints = NULL;
			}
		}
	}
	return result;
}

// ----------------------------------------------------------------------
// caller must call free() on any non-nil buffer returned

CLLocationCoordinate2D* regionCornersAsBuffer(MKCoordinateRegion region) {
	CLLocationCoordinate2D *result = NULL;
	if (MKCoordinateRegionIsValid(region)) {
		result = malloc(sizeof(CLLocationCoordinate2D) * 4);
		CLLocationCoordinate2D center = region.center;
		MKCoordinateSpan		 span = region.span;
		result[0] = CLLocationCoordinate2DMake(center.latitude	+ span.latitudeDelta  / 2,
											   center.longitude - span.longitudeDelta / 2); // top left
		result[1] = CLLocationCoordinate2DMake(center.latitude	+ span.latitudeDelta  / 2,
											   center.longitude + span.longitudeDelta / 2); // top right;
		result[2] = CLLocationCoordinate2DMake(center.latitude	- span.latitudeDelta  / 2,
											   center.longitude + span.longitudeDelta / 2); // bottom right;
		result[3] = CLLocationCoordinate2DMake(center.latitude	- span.latitudeDelta  / 2,
											   center.longitude - span.longitudeDelta / 2); // bottom left;
	}
	return result;
}

// ----------------------------------------------------------------------

NSArray *regionCornersAsNSValues(MKCoordinateRegion region) {
	NSMutableArray *result = nil;
	CLLocationCoordinate2D* coords = regionCornersAsBuffer(region);
	if (coords) {
		NSUInteger count = 4;
		result = [NSMutableArray arrayWithCapacity:count];
		for (NSUInteger i = 0; i < count; ++i) {
			NSValue *value = [NSValue valueWithMKCoordinate:coords[i]];
			[result addObject:value];
		}
		free(coords);
	}
	return result;
}
// ----------------------------------------------------------------------

MKCoordinateRegion scaledRegion(MKCoordinateRegion region, CGFloat scale) {
	MKCoordinateRegion result = region;
	if (scale > 0) {
		result.span.latitudeDelta  *= scale;
		result.span.longitudeDelta *= scale;
	}
	if (scale > 1) {
		if (!MKCoordinateRegionIsValid(result)) {
			// return invalid region to signal failure
			result = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0),
											MKCoordinateSpanMake(0, 0));
		}
	}
	return result;
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

// smallest region that encloses these points
MKCoordinateRegion regionForCoords(NSArray *values) {
	return regionForScaledCoords(values, 0); // '0' says "don't scale"
}

// same region but scaled larger/smaller
MKCoordinateRegion regionForScaledCoords(NSArray *values, CGFloat scale) {
	MKCoordinateRegion result = {0,0,0,0};
	
	if ([values count]) {
		CLLocationCoordinate2D *coords = NULL;
		NSUInteger count = coordsFromNSValues(&coords, values);
		
		if (count) {
			CLLocationDegrees minLat = +90, minLon = +180;
			CLLocationDegrees maxLat = -90, maxLon = -180;
			
			BOOL invalid = NO;
			for (NSUInteger index = 0; index < count; ++index) {
				CLLocationCoordinate2D coord = coords[index];
				if (CLLocationCoordinate2DIsValid(coord)) {
					minLat = MIN(minLat, coord.latitude);
					minLon = MIN(minLon, coord.longitude);
					maxLat = MAX(maxLat, coord.latitude);
					maxLon = MAX(maxLon, coord.longitude);
				}
				else
					invalid = YES;
			}
			free(coords);
			
			if (!invalid) {
				MKCoordinateSpan span = MKCoordinateSpanMake(maxLat - minLat, maxLon - minLon);
				
				CLLocationCoordinate2D center =
				CLLocationCoordinate2DMake(minLat + span.latitudeDelta/2,
										   minLon + span.longitudeDelta/2);
				
				if (scale > 0) {
					span.latitudeDelta	*= scale;
					span.longitudeDelta *= scale;
				}
				result = MKCoordinateRegionMake(center, span);
			}
		}
	}
	return result;
}

// ----------------------------------------------------------------------

MKPolyline *polylineForCoords(NSArray *values) {
	MKPolyline *result = nil;
	CLLocationCoordinate2D *coords = NULL;
	NSUInteger count = coordsFromNSValues(&coords, values);
	if (count) {
		result = [MKPolyline polylineWithCoordinates:coords count:count];
		free(coords);
	}
	return result;
}

// ----------------------------------------------------------------------

MKPolygon *polygonForCoords(NSArray *values) {
	MKPolygon *result = nil;
	CLLocationCoordinate2D *coords = NULL;
	NSUInteger count = coordsFromNSValues(&coords, values);
	if (count) {
		result = [MKPolygon polygonWithCoordinates:coords count:count];
		free(coords);
	}
	return result;
}

// ----------------------------------------------------------------------

MKPolygon *polygonForCoordsWithHoles(NSArray *values, NSArray *interiorPolygons) {
	MKPolygon *result = nil;
	CLLocationCoordinate2D *coords = NULL;
	NSUInteger count = coordsFromNSValues(&coords, values);
	if (count) {
		result = [MKPolygon polygonWithCoordinates:coords count:count interiorPolygons:interiorPolygons];
		free(coords);
	}
	return result;
}

// ----------------------------------------------------------------------
#pragma mark - TEST
// ----------------------------------------------------------------------

NSArray *randomCoordsInRegion(MKCoordinateRegion region, NSUInteger count) {
	NSMutableArray *result = nil;
	if (count > 0 && MKCoordinateRegionIsValid(region)) {
		
		CLLocationDegrees minLat = region.center.latitude - region.span.latitudeDelta/2;
		CLLocationDegrees maxLat = region.center.latitude + region.span.latitudeDelta/2;
		CLLocationDegrees minLon = region.center.longitude - region.span.longitudeDelta/2;
		CLLocationDegrees maxLon = region.center.longitude + region.span.longitudeDelta/2;
		
//		MyLog(@" box = { %f, %f, %f, %f } (tlbr)", maxLat, minLon, minLat, minLat);
		
		result = [NSMutableArray arrayWithCapacity:count];
		for (NSUInteger i = 0; i < count; ++i) {
			CLLocationDegrees latitude	= randomFloatInRange(minLat, maxLat);
			CLLocationDegrees longitude = randomFloatInRange(minLon, maxLon);
			
			CLLocationCoordinate2D coord =
			CLLocationCoordinate2DMake(latitude,
									   longitude);
//			MyLog(@"%2i: %@", i, str_CLLocationCoordinate2D(coord));
			NSValue *value = [NSValue valueWithMKCoordinate:coord];
			[result addObject:value];
		}
	}
	return result;
}

// ----------------------------------------------------------------------
#pragma mark - MapUtil
// ----------------------------------------------------------------------

@implementation MapUtil

+ (NSString *)locationString:(CLLocation *)location {
	CLLocationCoordinate2D c = location.coordinate;
	NSString *str_latitude  = [NSString stringWithFormat:@"%3f %s", fabs(c.latitude),  (c.latitude  > 0 ? "N" : "S")];
	NSString *str_longitude = [NSString stringWithFormat:@"%4f %s", fabs(c.longitude), (c.longitude > 0 ? "E" : "W")];
	return [NSString stringWithFormat:@"%@, %@", str_latitude, str_longitude];
}

+ (MapAnnotation *)mapView:(MKMapView *)mapView
	 addAnnotationForCoordinate:(CLLocationCoordinate2D)coord {
	MapAnnotation *result = nil;
	
	if (mapView != nil && CLLocationCoordinate2DIsValid(coord)) {
		NSString *imageFile = annotationImage;
		if (imageFile == nil)
			imageFile = pointImage;
		
		result = [MapAnnotation pointWithCoordinate:coord];
		if (annotationIndex == 0)
			result.title = [NSString stringWithFormat:@"%@ point #%i", annotationPrefix, annotationIndex];
		else
			result.title = [NSString stringWithFormat:@"%@ point #%i", annotationPrefix, annotationIndex];
		result.subtitle = @"This is here ... maybe";
		result.reuseID = @"PointAnnotation";
		result.image = [UIImage imageNamed:imageFile];
		
		++annotationIndex;
		
		[mapView addAnnotation:result];
	}
	return result;
}

+ (NSArray *)	mapView:(MKMapView *)mapView
addAnnotationsForCoords:(NSArray *)values {
	NSMutableArray *result = nil;
	
	if (mapView != nil && [values count]) {
		result = [NSMutableArray array];
		NSString *imageFile = annotationImage;
		if (imageFile == nil)
			imageFile = pointImage;
		
		int i = 0;
		// one way to extract CLLocationCoordinate2Ds from an array of NSValues
		for (NSValue *value in values) {
			CLLocationCoordinate2D coord = [value MKCoordinateValue];
			
			MapAnnotation *point = [MapAnnotation pointWithCoordinate:coord];
			if (i == 0)
				point.title = [NSString stringWithFormat:@"%@ point #%i", annotationPrefix, i];
			else
				point.title = [NSString stringWithFormat:@"%@ point #%i", annotationPrefix, i];
			++i;
			point.subtitle = @"This is here ... maybe";
			point.reuseID = @"CoordsAnnotation";
			point.image = [UIImage imageNamed:imageFile];
			
			[result addObject:point];
			[mapView addAnnotation:point];
		}
	}
	return result;
}

+ (NSArray *)  mapView:(MKMapView *)mapView
addAnnotationsInRegion:(MKCoordinateRegion)region
				 count:(NSUInteger) count {
	NSMutableArray *result = nil;
	if (mapView != nil && count) {
		result = [NSMutableArray array];
		NSArray *values = randomCoordsInRegion(region, count);
		// another way to extract CLLocationCoordinate2Ds from an array of NSValues
		CLLocationCoordinate2D *coords = NULL;
		NSUInteger count = coordsFromNSValues(&coords, values);
		if (count) {
			for (int index = 0; index < count; ++index) {
				CLLocationCoordinate2D coord = coords[index];
				
				MapAnnotation *point = [MapAnnotation pointWithCoordinate:coord];
				point.title = [NSString stringWithFormat:@"%@ point #%i", annotationPrefix, index];
				if (index)
					point.subtitle = @"You be here too, mon ...";
				else
					point.subtitle = @"You be here, mon ...";
				point.reuseID = @"RegionAnnotation";
				point.image = [UIImage imageNamed:regionImage];
				
				[result addObject:point];
				[mapView addAnnotation:point];
			}
			free(coords);
		}
	}
	return result;
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

+ (MapOverlayCircle *)mapView:(MKMapView *)mapView
	addCircleOverlayForCenter:(CLLocationCoordinate2D)center
					   radius:(CLLocationDistance) radius {
	MapOverlayCircle *result = nil;
	
	if (mapView != nil && CLLocationCoordinate2DIsValid(center)) { // TODO: check 'radius' param
		
#if CONFIG_useSuperclassCtors
		// either create with MKCircle
		MKCircle *circle = [MKCircle circleWithCenterCoordinate:center radius:radius];
		result = [[MapOverlayCircle alloc] initWithCircle:circle style:circleStyle()];
#else
		// or create with input params
		result = [MapOverlayCircle circleWithCenterCoordinate:center radius:radius style:style];
#endif
//		MyLog(@"=> overlays = %@", [mapView overlays]);
		[mapView addOverlay:result];
//		MyLog(@"<= overlays = %@", [mapView overlays]);
	}
	return result;
}

+ (MapOverlayPolygon *)mapView:(MKMapView *)mapView
	addPolygonOverlayForCoords:(NSArray *)values {
	MapOverlayPolygon *result = nil;
	
	if (mapView != nil && [values count]) {
		CLLocationCoordinate2D *coords = nil;
		NSUInteger count = coordsFromNSValues(&coords, values);
		if (count) {
			
#if CONFIG_useSuperclassCtors
			// either create with MKPolygon
			MKPolygon *poly = [MKPolygon polygonWithCoordinates:coords count:count];
			result = [[MapOverlayPolygon alloc] initWithPolygon:poly style:polygonStyle()];
#else
			// or create with input params
			result = [MapOverlayPolygon polygonWithCoordinates:coords count:count style:style];
#endif
			free(coords);
			[mapView addOverlay:result];
		}
	}
	return result;
}

+ (MapOverlayPolyline *)mapView:(MKMapView *)mapView
	addPolylineOverlayForCoords:(NSArray *)values {
	MapOverlayPolyline *result = nil;
	
	if (mapView != nil && [values count]) {
		CLLocationCoordinate2D *coords = nil;
		NSUInteger count = coordsFromNSValues(&coords, values);
		if (count) {
			
#if CONFIG_useSuperclassCtors
			// either create with MKPolyline
			MKPolyline *poly = [MKPolyline polylineWithCoordinates:coords count:count];
			result = [[MapOverlayPolyline alloc] initWithPolyline:poly style:polylineStyle()];
#else
			// or create with input params
			result = [MapOverlayPolyline polylineWithCoordinates:coords count:count style:style];
#endif
			free(coords);
			[mapView addOverlay:result];
		}
	}
	
	return result;
}

+ (MapOverlayRegion *)mapView:(MKMapView *)mapView addPolygonOverlayForRegion:(MKCoordinateRegion)region
					   scaled:(CGFloat)scale {
	MapOverlayRegion *result = nil;
	
	if (mapView != nil) {
		MKCoordinateRegion rgn = scaledRegion(region, scale); // scaledRegion() validates 'scale' param
		if (MKCoordinateRegionIsValid(region)) {
			
			result = [MapOverlayRegion regionWithMKRegion:rgn style:regionStyle()];
			[mapView addOverlay:result];
		}
	}
	return result;
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

+ (void)testMapView:(MKMapView *)mapView {
	if (mapView != nil) {
		MKCoordinateRegion region = mapView.region;
		[self testMapView:mapView withRegion:region];
	}
}

+ (void)testMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region {
	
	if (mapView != nil && MKCoordinateRegionIsValid(region)) {
		// log current annotations/overlays (disabled)
//		MyLog(@"=> annotations = %@", [mapView annotations]);
//		d_Annotations(mapView, @"=> annotations = ");
//		MyLog(@"=>	  overlays = %@", [mapView overlays]);
		
		// some random points for our poly overlays
		NSArray *coords1 = randomCoordsInRegion(region, 10);
		NSArray *coords2 = randomCoordsInRegion(region, 10);
		
		// set static globals for circle
		annotationIndex = 0;
		annotationImage = circleImage;
		annotationPrefix = @"circle";
		
		// circle
		CGFloat radius = 300; // in *meters*
		(void) [MapUtil mapView:mapView addCircleOverlayForCenter:region.center
						 radius:300];
		// add four annotations marking sides of circle
		MKCoordinateRegion circleRegion = MKCoordinateRegionMakeWithDistance(region.center, radius * 2, radius * 2);
		CLLocationCoordinate2D sides[] = {
			{ region.center.latitude + circleRegion.span.latitudeDelta/2, region.center.longitude },	// top-center
			{ region.center.latitude, region.center.longitude - circleRegion.span.longitudeDelta/2 },	// left-center
			{ region.center.latitude - circleRegion.span.latitudeDelta/2, region.center.longitude },	// bottom-center
			{ region.center.latitude, region.center.longitude + circleRegion.span.longitudeDelta/2 }	// right-center
		};
		for (NSUInteger i = 0; i < sizeof(sides)/sizeof(sides[0]); ++i) {
			(void) [MapUtil mapView:mapView addAnnotationForCoordinate:sides[i]];
		}
		
		
		// set static globals for polygon
		annotationIndex = 0;
		annotationImage = polygonImage;
		annotationPrefix = @"polygon";
		
		// polygon
		(void) [MapUtil mapView:mapView addPolygonOverlayForCoords:coords1];
		(void) [MapUtil mapView:mapView addAnnotationsForCoords:coords1];
		
		
		// set static globals for polyline
		annotationIndex = 0;
		annotationImage = polylineImage;
		annotationPrefix = @"polyline";
		
		// polyline
		(void) [MapUtil mapView:mapView addPolylineOverlayForCoords:coords2];
		(void) [MapUtil mapView:mapView addAnnotationsForCoords:coords2];
		
		
		// set static globals for region
		annotationIndex = 0;
		annotationImage = regionImage;
		annotationPrefix = @"region";
		
		// region
//		(void) [MapUtil mapView:mapView addAnnotationsInRegion:region count:5];
		MKCoordinateRegion region_75 = scaledRegion(region, 0.75);
		NSArray *values = regionCornersAsNSValues(region_75);
		[MapUtil mapView:mapView addAnnotationsForCoords:values];

		(void) [MapUtil mapView:mapView addPolygonOverlayForRegion:region scaled:0.75];
		
		// log updated annotations/overlays (disabled)
//		MyLog(@"<= annotations = %@", [mapView annotations]);
//		d_Annotations(mapView, @"<= annotations = ");
//		MyLog(@"<=	  overlays = %@", [mapView overlays]);
	}
}

// ----------------------------------------------------------------------

@end
