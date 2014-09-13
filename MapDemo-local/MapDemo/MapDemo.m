//
//  MapDemo.m
//  MapDemo
//
//  Created by Steve Caine on 09/12/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#import "MapDemo.h"

#import "MapOverlays_private.h"
#import "MapUtil.h"

#import "Debug_iOS.h"

// LOCAL
static NSString *userImage		= @"UserDot.png";
static NSString *vicinityImage	= @"VicinityDot.png";
static NSString *trailImage		= @"TrailDot";
static NSString *regionImage	= @"RegionDot.png";

static MapOverlayPathStyle *vicinityStyle() { // circle
	MapOverlayPathStyle *result = [MapOverlayPathStyle styleWithLineWidth:2.0 color:[UIColor greenColor] alpha:0.50];
	return result;
}

//static MapOverlayPathStyle *trailStyle() { // polyline
//	MapOverlayPathStyle *result = [MapOverlayPathStyle styleWithLineWidth:2.0 color:[UIColor blueColor]];
//	return result;
//}

static MapOverlayPathStyle *regionStyle() { // polygon
//	MapOverlayPathStyle *result = [MapOverlayPathStyle styleWithLineWidth:2.0 color:[UIColor greenColor] alpha:0.25];
	MapOverlayPathStyle *result = [MapOverlayPathStyle styleWithLineWidth:8.0 strokeColor:[UIColor redColor] fillColor:nil];
	return result;
}

// ----------------------------------------------------------------------
#pragma mark - MapUserPoint
// ----------------------------------------------------------------------

@implementation MapUserPoint

+ (MapUserPoint *)userWithLocation:(CLLocation *)location {
	MapUserPoint *result = [[MapUserPoint alloc] initWithLocation:location];
	return result;
}

- (id)initWithLocation:(CLLocation *)location {
	self = [super initWithCoordinate:location.coordinate];
	if (self) {
		self.title = [[UIDevice currentDevice] model];
		self.subtitle = [NSString stringWithFormat:@"{ %f, %f } (lat/lon)",
						 location.coordinate.latitude, location.coordinate.longitude];
		self.image = [UIImage imageNamed:@"UserDot.png"];
		self.reuseID = @"MapUserPoint";
	}
	return self;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapUserVicinity - circle  with user's latitude/longitude/accuracy
// ----------------------------------------------------------------------

@implementation MapUserVicinity

+ (MapUserVicinity *)vicinityWithLocation:(CLLocation *)location {
	MapUserVicinity *result = [[MapUserVicinity alloc] initWithLocation:location];
	return result;
}

- (id)initWithLocation:(CLLocation *)location {
	self = [super initWithCenterCoordinate:location.coordinate radius:location.horizontalAccuracy style:vicinityStyle()];
	if (self) {
	}
	return self;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapUserTrail - polyline following user's changing location
// ----------------------------------------------------------------------

@interface MapUserTrail ()
@property (strong, nonatomic) NSMutableArray *locations;
@end

@implementation MapUserTrail

+ (MapUserTrail *)trailWithLocationManager:(CLLocationManager *)manager {
	MapUserTrail *result = nil; //[[MapUserTrail alloc] initWithLocationManager:manager];
	return result;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	
	if (self.locations == nil)
		self.locations = [NSMutableArray arrayWithCapacity:[locations count]];
	
	else if ([locations count] == 1) {
		CLLocationCoordinate2D coord = [[locations firstObject] MKCoordinateValue];
		if (fabs(coord.latitude) < 0.1 && fabs(coord.longitude) < 0.1)
			[self.locations removeAllObjects];
	}
	[self.locations addObjectsFromArray:locations];
	// and then ...?
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapRegionOverlay - polygon framing an MKRegion
// ----------------------------------------------------------------------

@implementation MapRegionOverlay

+ (MapRegionOverlay *)regionWithMKRegion:(MKCoordinateRegion)region style:(MapOverlayPathStyle *)style {
	MapRegionOverlay *result = [[MapRegionOverlay alloc] initWithMKRegion:region style:style];
	return result;
}

- (id)initWithMKRegion:(MKCoordinateRegion)region style:(MapOverlayPathStyle *)style {
	CLLocationCoordinate2D *corners = regionCornersAsBuffer(region);
	self = [super initWithCoordinates:corners count:4 style:style];
	free(corners);
	if (self) {
	}
	return self;
}

@end

// ----------------------------------------------------------------------
#pragma mark - MapDemo
// ----------------------------------------------------------------------

@implementation MapDemo

+ (void)demoInMapView:(MKMapView *)mapView withLocation:(CLLocation *)location region:(MKCoordinateRegion)region {
	if (mapView != nil) {
		
		MyLog(@"=> annotations = %@", [mapView annotations]);
		MyLog(@"=>	  overlays = %@", [mapView overlays]);
		
		MapUserPoint *user = [MapUserPoint userWithLocation:location];
//		user.title = [[UIDevice currentDevice] model];
//		user.subtitle = [NSString stringWithFormat:@"{ %f, %f } (lat/lon)",
//						 location.coordinate.latitude, location.coordinate.longitude];
//		user.reuseID = @"UserPoint";
//		user.image = [UIImage imageNamed:userImage];
		[mapView addAnnotation:user];
		
		MapUserVicinity *vicinity = [MapUserVicinity vicinityWithLocation:location];
		[mapView addOverlay:vicinity];
		
		//MapUserTrail *TK*
		
//		MKCoordinateRegion region = mapView.region;
		MKCoordinateRegion r1 = scaledRegion(region, 0.50);
		MapRegionOverlay *o1 = [[MapRegionOverlay alloc] initWithMKRegion:r1 style:regionStyle()];
		[mapView addOverlay:o1];
		
		NSUInteger index = 0;
		NSString *titles[] = {@"NW",@"NE",@"SE",@"SW"};
		NSArray *corners = regionCornersAsNSValues(r1);
		for (NSValue *corner in corners) {
			CLLocationCoordinate2D coord = [corner MKCoordinateValue];
			MapAnnotation *pt = [MapAnnotation pointWithCoordinate:coord];
			pt.title = titles[index++];
			pt.subtitle = [NSString stringWithFormat:@"{ %f, %f } (lat/lon)", coord.latitude, coord.longitude];
			pt.reuseID = @"RegionCorner";
			pt.image = [UIImage imageNamed:regionImage];
			[mapView addAnnotation:pt];
		}
		MyLog(@"<= annotations = %@", [mapView annotations]);
		MyLog(@"<=	  overlays = %@", [mapView overlays]);
	}
}

@end
