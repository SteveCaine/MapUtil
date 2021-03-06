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
//	Copyright (c) 2014-2017 Steve Caine.
//

// NOTE: Apple docs say all -polyXxxWithCoordinates methods COPY the input buffer's bytes,
// so we trust them and cast away 'const' in each case

#import "MapUtil.h"

#import "MapOverlays.h"
#import "MapOverlays_private.h"

#import "Categories.h"

#import "Debug_iOS.h"
#import "Debug_MapKit.h"

// ----------------------------------------------------------------------
#pragma mark   static globals
// ----------------------------------------------------------------------
// some globals to define text & images for our test annotations and overlays

static NSUInteger annotationIndex = 0;
static NSString	 *annotationImage;
static NSString  *annotationPrefix;

// point
static NSString *pointImage = @"cyan-16x16.png";

// circle
static NSString *circleImage = @"red-16x16.png";
static MapOverlayPathStyle *circleStyle() {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth = 3;
	result.strokeColor =  UIColor.redColor;
	result.fillColor   = [UIColor.redColor colorWithAlphaComponent:0.25];
	return result;
}

// polygon
static NSString *polygonImage = @"blue-16x16.png";
static MapOverlayPathStyle *polygonStyle() {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth = 4;
	result.strokeColor =  UIColor.blueColor;
	result.fillColor   = [UIColor.blueColor colorWithAlphaComponent:0.25];
	return result;
}

// polyline
static NSString *polylineImage = @"green-16x16.png";
static MapOverlayPathStyle *polylineStyle() {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth = 3;
	result.strokeColor =  UIColor.greenColor;
	result.fillColor   = [UIColor.greenColor colorWithAlphaComponent:0.25];
	return result;
}

// region
static NSString *regionImage = @"yellow-16x16.png";
static MapOverlayPathStyle *regionStyle() {
	MapOverlayPathStyle *result = [[MapOverlayPathStyle alloc] init];
	result.lineWidth = 3;
	result.strokeColor =  UIColor.yellowColor;
	result.fillColor   = [UIColor.yellowColor colorWithAlphaComponent:0.25];
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
#pragma mark - MapBounds
// ----------------------------------------------------------------------
// disabled code in this block not (yet) used in this file (so gets "-Wunused-function" warning)
// ----------------------------------------------------------------------
// since longitude 'wraps' around at +/- 180 degrees (International Date Line)
// we 'normalize' all values to positive numbers before making comparisons
/*static CLLocationCoordinate2D normalizedCoordinate2D(CLLocationCoordinate2D coordinate) {
	CLLocationCoordinate2D result = coordinate;
	result.latitude  +=  90.0;
	result.longitude += 180.0;
	return result;
}*/
static CLLocationCoordinate2D denormalizedCoordinate2D(CLLocationCoordinate2D coordinate) {
	CLLocationCoordinate2D result = coordinate;
	result.latitude  -=  90.0;
	result.longitude -= 180.0;
	return result;
}
// ----------------------------------------------------------------------
static MapBounds normalizedMapBounds(MapBounds bounds) {
	MapBounds result = bounds;
	result.south +=  90.0;
	result.north +=  90.0;
	result.west += 180.0;
	result.east += 180.0;
//	MyLog(@"%s %@ => %@", __FUNCTION__, str_MapBounds(bounds), str_MapBounds(result));
	return result;
}
/*static MapBounds denormalizedMapBounds(MapBounds bounds) {
	MapBounds result = bounds;
	result.south -=  90.0;
	result.north -=  90.0;
	result.west -= 180.0;
	result.east -= 180.0;
//	MyLog(@"%s %@ => %@", __FUNCTION__, str_MapBounds(bounds), str_MapBounds(result));
	return result;
}*/
// ----------------------------------------------------------------------

CLLocationCoordinate2D MapBoundsCenter(MapBounds bounds) {
//	MyLog(@"%s bounds => %@", __FUNCTION__, str_MapBounds(bounds));
	MapBounds std_bounds = normalizedMapBounds(bounds);
	CLLocationCoordinate2D center = {
		std_bounds.south + ((std_bounds.north - std_bounds.south) / 2),
		std_bounds.west + ((std_bounds.east - std_bounds.west) / 2) };
	CLLocationCoordinate2D result = denormalizedCoordinate2D(center);
//	MyLog(@" %@ => %@", str_CLLocationCoordinate2D(center), str_CLLocationCoordinate2D(result));
	return result;
}
MKCoordinateSpan MapBoundsSpan(MapBounds bounds) {
//	MyLog(@"%s bounds => %@", __FUNCTION__, str_MapBounds(bounds));
	MapBounds std_bounds = normalizedMapBounds(bounds);
	MKCoordinateSpan result = {
		std_bounds.north - std_bounds.south,
		std_bounds.east - std_bounds.west};
//	MyLog(@" returns %@", str_MKCoordinateSpan(result));
	return result;
}
MKCoordinateRegion MapBoundsRegion(MapBounds bounds) {
//	MyLog(@"%s bounds => %@", __FUNCTION__, str_MapBounds(bounds));
	CLLocationCoordinate2D center = MapBoundsCenter(bounds);
	MKCoordinateSpan span = MapBoundsSpan(bounds);
	MKCoordinateRegion result = MKCoordinateRegionMake(center, span);
//	MyLog(@" returns %@", str_MKCoordinateRegion(result));
	return result;
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

// expected input is an array of NSValues, each encoding a single CLLocationCoordinate2D
NSData *dataWithCoordsFromNSValues(NSArray *values) {
	if (values.count) {
		NSMutableData *data = [NSMutableData data];
		
		for (id obj in values) {
			NSValue *value = [NSValue cast:obj];
			if (value && strcmp([value objCType], @encode(CLLocationCoordinate2D)) == 0) {
				CLLocationCoordinate2D coord;
				[value getValue:&coord];
				[data appendBytes:&coord length:sizeof(coord)];
			}
		}
		if (data.length)
			return data.copy;
	}
	return nil;
}

// expected input is an array of arrays, where each inner array is a single lat/lon pair as NSNumber* doubles
// i.e., @[ @[ @(41.723),@(-70.368) ], ... ]
NSData *dataWithCoordsFromNSArray(NSArray *array) {
	if (array.count) {
		NSMutableData *data = [NSMutableData data];
		
		for (id obj in array) {
			// only process expected lat/lon pairs
			NSArray *lat_lon = [NSArray cast:obj];
			if (lat_lon.count == 2) {
				
				NSNumber *lat = [NSNumber cast:lat_lon.firstObject];
				NSNumber *lon = [NSNumber cast:lat_lon.lastObject];
				
				if (lat && lon) {
					CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue);
					[data appendBytes:&coord length:sizeof(coord)];
				}
			}
		}
		if (data.length)
			return data.copy;
	}
	return nil;
}

// ASSUMED: -data- contains flat array of CLLocationCoordinate2D structs;
const CLLocationCoordinate2D *coordsFromNSData(NSData *data, NSUInteger *outLen) {
	if (outLen) *outLen = 0;
	if (data.length) {
		// our only attempt at validation - is length/size an integer?
		if (data.length % sizeof(CLLocationCoordinate2D) == 0) {
			if (outLen)
				*outLen = data.length / sizeof(CLLocationCoordinate2D);
			return (const CLLocationCoordinate2D *)data.bytes;
		}
	}
	return NULL;
}

// ----------------------------------------------------------------------

// expected input is an array of NSValues, each encoding a single MKMapPoint
NSData *dataWithMapPointsFromNSValues(NSArray *values) {
	if (values.count) {
		NSMutableData *data = [NSMutableData data];
		
		for (id obj in values) {
			NSValue *value = [NSValue cast:obj];
			if (value && strcmp([value objCType], @encode(MKMapPoint)) == 0) {
				MKMapPoint point;
				[value getValue:&point];
				[data appendBytes:&point length:sizeof(point)];
			}
		}
		return (data.length ? data.copy : nil);
	}
	return nil;
}

// ASSUMED: -data- contains flat array of MKMapPoint structs;
const MKMapPoint *mapPointsFromNSData(NSData *data, NSUInteger *outLen) {
	if (outLen) *outLen = 0;
	if (data.length) {
		// our only attempt at validation - is length/size an integer?
		if (data.length % sizeof(MKMapPoint) == 0) {
			if (outLen)
				*outLen = data.length / sizeof(MKMapPoint);
			return (const MKMapPoint *)data.bytes;
		}
	}
	return NULL;
}

// ----------------------------------------------------------------------

NSData *dataWithRegionCorners(MKCoordinateRegion region) {
	if (MKCoordinateRegionIsValid(region)) {
		NSMutableData *data = [NSMutableData data];
		
		CLLocationCoordinate2D center = region.center;
		MKCoordinateSpan		 span = region.span;
		
		CLLocationCoordinate2D coord;
		coord = CLLocationCoordinate2DMake(center.latitude	+ span.latitudeDelta  / 2,
										   center.longitude - span.longitudeDelta / 2); // top left
		[data appendBytes:&coord length:sizeof(coord)];
		
		coord = CLLocationCoordinate2DMake(center.latitude	+ span.latitudeDelta  / 2,
										   center.longitude + span.longitudeDelta / 2); // top right;
		[data appendBytes:&coord length:sizeof(coord)];
		
		coord = CLLocationCoordinate2DMake(center.latitude	- span.latitudeDelta  / 2,
										   center.longitude + span.longitudeDelta / 2); // bottom right;
		[data appendBytes:&coord length:sizeof(coord)];
		
		coord = CLLocationCoordinate2DMake(center.latitude	- span.latitudeDelta  / 2,
										   center.longitude - span.longitudeDelta / 2); // bottom left;
		[data appendBytes:&coord length:sizeof(coord)];
		
		return data.copy; // corners in clockwise order
	}
	return nil;
}

// ----------------------------------------------------------------------

NSArray *regionCornersAsNSValues(MKCoordinateRegion region) {
	NSMutableArray *result = @[].mutableCopy;
	
	NSData *data = dataWithRegionCorners(region);
	NSUInteger count;
	const CLLocationCoordinate2D *coords = coordsFromNSData(data, &count);
	const CLLocationCoordinate2D *end = coords + count;
	
	while (coords < end) {
		NSValue *value = [NSValue valueWithMKCoordinate:*coords++];
		[result addObject:value];
	}

	return (result.count ? result : nil);
}
// ----------------------------------------------------------------------

MKCoordinateRegion scaledRegion(MKCoordinateRegion region, CGFloat scale) {
	MKCoordinateRegion result = region;
	if (scale > 0.0) {
		result.span.latitudeDelta  *= scale;
		result.span.longitudeDelta *= scale;
	}
	if (scale > 1.0) {
		if (!MKCoordinateRegionIsValid(result)) {
			// return empty region to signal failure
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
	return regionForScaledCoords(values, 0.0); // '0' says "don't scale"
}

// same region but scaled larger/smaller
MKCoordinateRegion regionForScaledCoords(NSArray *values, CGFloat scale) {
	MKCoordinateRegion result = {{0,0},{0,0}};
	
	if (values.count) {
		// convert array to buffer
		NSData *data = dataWithCoordsFromNSValues(values);
		
		NSUInteger count;
		const CLLocationCoordinate2D *coords = coordsFromNSData(data, &count);
		const CLLocationCoordinate2D *end = coords + count;

		if (count) {
			// validate coordinates
			CLLocationDegrees minLat = +90, minLon = +180;
			CLLocationDegrees maxLat = -90, maxLon = -180;
			
			BOOL invalid = NO;
			while (coords < end && !invalid) {
				CLLocationCoordinate2D coord = *coords++;
				if (CLLocationCoordinate2DIsValid(coord)) {
					minLat = MIN(minLat, coord.latitude);
					minLon = MIN(minLon, coord.longitude);
					maxLat = MAX(maxLat, coord.latitude);
					maxLon = MAX(maxLon, coord.longitude);
				}
				else
					invalid = YES;
			}

			if (!invalid) {
				// create region
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
	
	NSData *data = dataWithCoordsFromNSValues(values);
	NSUInteger count;
	const CLLocationCoordinate2D *coords = coordsFromNSData(data, &count);
	if (count) {
		// cast away 'const' (see note above)
		result = [MKPolyline polylineWithCoordinates:(CLLocationCoordinate2D *)coords count:count];
	}
	return result;
}

// ----------------------------------------------------------------------

MKPolygon *polygonForCoords(NSArray *values) {
	MKPolygon *result = nil;

	NSData *data = dataWithCoordsFromNSValues(values);
	NSUInteger count;
	const CLLocationCoordinate2D *coords = coordsFromNSData(data, &count);
	if (count) {
		// cast away 'const' (see note above)
		result = [MKPolygon polygonWithCoordinates:(CLLocationCoordinate2D *)coords count:count];
	}
	return result;
}

// ----------------------------------------------------------------------

MKPolygon *polygonForCoordsWithHoles(NSArray *values, NSArray *interiorPolygons) {
	MKPolygon *result = nil;

	NSData *data = dataWithCoordsFromNSValues(values);
	NSUInteger count;
	const CLLocationCoordinate2D *coords = coordsFromNSData(data, &count);
	if (count) {
		// cast away 'const' (see note above)
		result = [MKPolygon polygonWithCoordinates:(CLLocationCoordinate2D *)coords
											 count:count
								  interiorPolygons:interiorPolygons];
		// 'interior' param, if not empty, is array of MKPolygons
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
			result.title = [NSString stringWithFormat:@"%@ point #%lu", annotationPrefix, annotationIndex];
		else
			result.title = [NSString stringWithFormat:@"%@ point #%lu", annotationPrefix, annotationIndex];
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
	
	if (mapView != nil && values.count) {
		result = [NSMutableArray array];
		NSString *imageFile = annotationImage;
		if (imageFile == nil)
			imageFile = pointImage;
		
		NSUInteger i = 0;
		// one way to extract CLLocationCoordinate2Ds from an array of NSValues
		for (NSValue *value in values) {
			CLLocationCoordinate2D coord = [value MKCoordinateValue];
			
			MapAnnotation *point = [MapAnnotation pointWithCoordinate:coord];
			if (i == 0)
				point.title = [NSString stringWithFormat:@"%@ point #%lu", annotationPrefix, i];
			else
				point.title = [NSString stringWithFormat:@"%@ point #%lu", annotationPrefix, i];
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
				 count:(NSUInteger)count {
	NSMutableArray *result = [NSMutableArray array];
	
	if (mapView && count) {
		NSArray *values = randomCoordsInRegion(region, count);
		
		NSData *data = dataWithCoordsFromNSValues(values);
		const CLLocationCoordinate2D *coords = coordsFromNSData(data, nil);
		
		if (coords) {
			NSUInteger index = 0;
			const CLLocationCoordinate2D *end = coords + values.count;
			
			while (coords < end) {
				CLLocationCoordinate2D coord = *coords++;
				
				MapAnnotation *point = [MapAnnotation pointWithCoordinate:coord];
				point.title = [NSString stringWithFormat:@"%@ point #%lu", annotationPrefix, index];
				if (index)
					point.subtitle = @"You be here too, mon ...";
				else
					point.subtitle = @"You be here, mon ...";
				point.reuseID = @"RegionAnnotation";
				point.image = [UIImage imageNamed:regionImage];
				
				[result addObject:point];
				[mapView addAnnotation:point];
			}
		}
	}
	return (result.count ? result.copy : nil);
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
//		MyLog(@"=> overlays = %@", mapView.overlays);
		[mapView addOverlay:result];
//		MyLog(@"<= overlays = %@", mapView.overlays);
	}
	return result;
}

+ (MapOverlayPolygon *)mapView:(MKMapView *)mapView
	addPolygonOverlayForCoords:(NSArray *)values {
	MapOverlayPolygon *result = nil;
	
	if (mapView && values.count) {
		NSData *data = dataWithCoordsFromNSValues(values);
		NSUInteger count;
		const CLLocationCoordinate2D *coords = coordsFromNSData(data, &count);
		if (count) {
			
			// both cast away 'const' (see note above)
#if CONFIG_useSuperclassCtors
			// either create with MKPolygon
			MKPolygon *poly = [MKPolygon polygonWithCoordinates:(CLLocationCoordinate2D *)coords count:count];
			result = [[MapOverlayPolygon alloc] initWithPolygon:poly style:polygonStyle()];
#else
			// or create with input params
			result = [MapOverlayPolygon polygonWithCoordinates:(CLLocationCoordinate2D *)coords count:count style:style];
#endif
			[mapView addOverlay:result];
		}
	}
	return result;
}

+ (MapOverlayPolyline *)mapView:(MKMapView *)mapView
	addPolylineOverlayForCoords:(NSArray *)values {
	MapOverlayPolyline *result = nil;
	
	if (mapView != nil && values.count) {
		NSData *data = dataWithCoordsFromNSValues(values);
		NSUInteger count;
		const CLLocationCoordinate2D *coords = coordsFromNSData(data, &count);
		if (count) {
			
			// both cast away 'const' (see note above)
#if CONFIG_useSuperclassCtors
			// either create with MKPolyline
			MKPolyline *poly = [MKPolyline polylineWithCoordinates:(CLLocationCoordinate2D *)coords count:count];
			result = [[MapOverlayPolyline alloc] initWithPolyline:poly style:polylineStyle()];
#else
			// or create with input params
			result = [MapOverlayPolyline polylineWithCoordinates:(CLLocationCoordinate2D *)coords count:count style:style];
#endif
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
//		MyLog(@"=> annotations = %@", mapView.annotations);
//		d_Annotations(mapView, @"=> annotations = ");
//		MyLog(@"=>	  overlays = %@", mapView.overlays);
		
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
//		MyLog(@"<= annotations = %@", mapView.annotations);
//		d_Annotations(mapView, @"<= annotations = ");
//		MyLog(@"<=	  overlays = %@", mapView.overlays);
	}
}

// ----------------------------------------------------------------------

@end
