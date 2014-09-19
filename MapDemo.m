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
	MapOverlayPathStyle *result = [MapOverlayPathStyle styleWithLineWidth:2.0 color:[UIColor redColor] alpha:0.50];
	return result;
}

// TODO: still need to implement MapUserTrail overlay class
//static MapOverlayPathStyle *trailStyle() { // polyline
//	MapOverlayPathStyle *result = [MapOverlayPathStyle styleWithLineWidth:2.0 color:[UIColor blueColor]];
//	return result;
//}

static MapOverlayPathStyle *regionStyle() { // polygon
	MapOverlayPathStyle *result = [MapOverlayPathStyle styleWithLineWidth:2.0 color:[UIColor greenColor] alpha:0.25];
//	MapOverlayPathStyle *result = [MapOverlayPathStyle styleWithLineWidth:8.0 strokeColor:[UIColor redColor] fillColor:nil];
	return result;
}

// ----------------------------------------------------------------------
#pragma mark - MapUserPoint
// ----------------------------------------------------------------------

@implementation MapUserPoint

+ (MapUserPoint *)userWithLocation:(CLLocation *)location title:(NSString *)title {
	MapUserPoint *result = [[MapUserPoint alloc] initWithLocation:location];
	result.title = title;
	return result;
}

- (id)initWithLocation:(CLLocation *)location {
	self = [super initWithCoordinate:location.coordinate];
	if (self) {
//		self.title = [[UIDevice currentDevice] model];
		CLLocationCoordinate2D c = location.coordinate;
		NSString *str_latitude  = [NSString stringWithFormat:@"%3f %s", fabs(c.latitude),  (c.latitude  > 0 ? "N" : "S")];
		NSString *str_longitude = [NSString stringWithFormat:@"%4f %s", fabs(c.longitude), (c.longitude > 0 ? "E" : "W")];
//		self.subtitle = [NSString stringWithFormat:@"{ %@, %@ }", str_latitude, str_longitude];
		self.subtitle = [NSString stringWithFormat:@"%@, %@", str_latitude, str_longitude];
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
	// TODO: finish implementing this class to track user's changing location
	// via CLLocationManagerDelegate callbacks
	MapUserTrail *result = nil; //[[MapUserTrail alloc] initWithLocationManager:manager];
	return result;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	if (self.locations == nil)
		self.locations = [NSMutableArray arrayWithCapacity:[locations count]];
	[self.locations addObjectsFromArray:locations];
	// TODO: and then ...?
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

+ (void)demoInMapView:(MKMapView *)mapView withLocation:(CLLocation *)location {
	if (mapView != nil && location != nil) {
		MKCoordinateRegion region = mapView.region;
		[self demoInMapView:mapView withLocation:location region:region];
	}
}

+ (void)demoInMapView:(MKMapView *)mapView withLocation:(CLLocation *)location region:(MKCoordinateRegion)region {
	if (mapView != nil && location != nil) {
		
//		MyLog(@"=> annotations = %@", [mapView annotations]);
//		MyLog(@"=>	  overlays = %@", [mapView overlays]);

		// moved this code to app's ViewController
//		MapUserPoint *user = [MapUserPoint userWithLocation:location title:@"You Are Here!"];
//		[mapView addAnnotation:user];
		
		MapUserVicinity *vicinity = [MapUserVicinity vicinityWithLocation:location];
		[mapView addOverlay:vicinity];
		
		//MapUserTrail *TK*
		
		MKCoordinateRegion region_scaled = scaledRegion(region, 0.95);
		MapRegionOverlay *o1 = [[MapRegionOverlay alloc] initWithMKRegion:region_scaled style:regionStyle()];
		[mapView addOverlay:o1];
		
		// annotate the corners of our (shrunken) region
		NSUInteger index = 0;
		NSString *titles[] = {@"NW",@"NE",@"SE",@"SW"};
		
		NSArray *corners = regionCornersAsNSValues(region_scaled);
		for (NSValue *corner in corners) {
			CLLocationCoordinate2D coord = [corner MKCoordinateValue];
			MapAnnotation *pt = [MapAnnotation pointWithCoordinate:coord];
			pt.title = titles[index++];
			pt.subtitle = [NSString stringWithFormat:@"{ %f, %f } (lat/lon)", coord.latitude, coord.longitude];
			pt.reuseID = @"RegionCorner";
			pt.image = [UIImage imageNamed:regionImage];
			[mapView addAnnotation:pt];
		}
		
//		MyLog(@"<= annotations = %@", [mapView annotations]);
//		MyLog(@"<=	  overlays = %@", [mapView overlays]);
	}
}

@end
