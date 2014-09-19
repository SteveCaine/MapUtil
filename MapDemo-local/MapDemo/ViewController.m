//
//	ViewController.m
//	MapDemo
//
//	iPad presentation of MapUtil's custom map annotation and overlay classes
//	either used directly - 'Demo 1'
//	   or via subclasses - 'Demo 2'
//	that hide the base classes' implementation details
//
//	there are two ways that our custom overlay classes can be presented on the screen
//	1 - MKOverlayView		iOS 4.0 and later, deprecated in iOS 7.0
//	2 - MKOverlayRenderer	iOS 7.0 and later
//	via the MKMapViewDelegate protocol's viewForOverlay and rendererForOverlay methods
//
//	this code supports iOS 6 and later, so it provides methods to return both
//	where the latter is presented only if compiled in SDKs 7.0 and above
//
//	iOS itself determines which is called based on which protocol methods the overlay objects implement
//	so we don't need runtime checks to see which iOS version is currently running
//
//	Created by Steve Caine on 07/15/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2011-2014 Steve Caine.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "ViewController.h"

// for 'Demo 1'
#import "MapUtil.h"

// for 'Demo 2'
#import "MapDemo.h"

#import "Debug_iOS.h"
#import "Debug_MapKit.h"

#define str_accessDeniedEror		@"Access Denied. Go to\nSettings -> Privacy -> Location\nto allow access to Location Services."
#define str_simulateLocationError	@"Did you forget to select a location\nin the Options panel\nof Xcode's Scheme Editor?"

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (	 weak, nonatomic) IBOutlet	MKMapView			*mapView;
@property (  weak, nonatomic) IBOutlet	UIButton			*btnDemo1;
@property (  weak, nonatomic) IBOutlet	UIButton			*btnDemo2;
@property (  weak, nonatomic) IBOutlet	UIButton			*btnClear;
@property (strong, nonatomic)			CLLocationManager	*locationManager;
@property (strong, nonatomic)			MapAnnotation		*userAnnotation;
@property (assign, nonatomic)			BOOL				userOverlaysPresent;

- (IBAction)doDemo1;

- (IBAction)doDemo2;

- (IBAction)doClear;

//- (void)openCallout:(id<MKAnnotation>)annotation;

@end

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

@implementation ViewController

//#pragma mark - globals

// ----------------------------------------------------------------------
#pragma mark - locals
// ----------------------------------------------------------------------

// NOTE: we use status >= for our buttons as iOS 8 adds
// 'kCLAuthorizationStatusAuthorizedWhenInUse' just after this enum

- (IBAction)doDemo1 {
	MyLog(@"\nTapped button 'Demo 1'");
	if ([CLLocationManager authorizationStatus] >= kCLAuthorizationStatusAuthorized) {
		// MapUtil tests
		[MapUtil testMapView:self.mapView];
		self.btnClear.enabled = YES;
	}
	
}

- (IBAction)doDemo2 {
	MyLog(@"\nTapped button 'Demo 2'");
	if ([CLLocationManager authorizationStatus] >= kCLAuthorizationStatusAuthorized) {
		// MapDemo tests
		[MapDemo demoInMapView:self.mapView withLocation:self.locationManager.location];
		self.userOverlaysPresent = YES;
		self.btnDemo2.enabled = NO;
		self.btnClear.enabled = YES;
	}
}

- (IBAction)doClear {
	MyLog(@"\nTapped button 'Clear' - Map has %i annotations and %i overlays.",
		  [self.mapView.annotations count], [self.mapView.overlays count]);
	
//	MyLog(@"=> annotations = %@", [self.mapView annotations]);
//	MyLog(@"=>	  overlays = %@", [self.mapView overlays]);
	
	// always keep our "You Are Here!" annotation
	NSMutableArray *toRemove = [NSMutableArray arrayWithArray:self.mapView.annotations];
	[toRemove removeObject:self.userAnnotation];
	
	[self.mapView removeAnnotations:toRemove];
	[self.mapView removeOverlays:self.mapView.overlays];
	self.userOverlaysPresent = NO;
	
//	MyLog(@"<= annotations = %@", [self.mapView annotations]);
//	MyLog(@"<=	  overlays = %@", [self.mapView overlays]);
	
	self.btnClear.enabled = NO;
	
	if ([CLLocationManager authorizationStatus] >= kCLAuthorizationStatusAuthorized) {
		self.btnDemo2.enabled = YES;
	}
}

- (void)addUserAnnotation:(CLLocation *)location {
	// for any location updates (IF -didUpdateToLocation:- is changed to NOT stop updating
	if (self.userAnnotation) {
		[self.mapView removeAnnotation:self.userAnnotation];
		self.userAnnotation = nil;
	}
	if (self.userAnnotation == nil) {
		// put annotation on user location
		self.userAnnotation = [MapUserPoint userWithLocation:location title:@"You Are Here!"];
		[self.mapView addAnnotation:self.userAnnotation];
		[self openCallout:self.userAnnotation];
	}
}

- (void)openCallout:(id<MKAnnotation>)annotation {
	[self.mapView selectAnnotation:annotation animated:YES];
}

// ----------------------------------------------------------------------
#pragma mark - view lifetime
// ----------------------------------------------------------------------

- (void)viewDidLoad {
//	MyLog(@"\n%s", __FUNCTION__);
	MyLog(@"\n%s for %@\n", __FUNCTION__, str_iOS_version());
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.mapView.mapType = MKMapTypeStandard;
//	self.mapView.mapType = MKMapTypeSatellite;
//	self.mapView.mapType = MKMapTypeHybrid;

	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	[self.locationManager startUpdatingLocation];
	
	self.btnDemo1.enabled = self.btnClear.enabled = self.btnDemo2.enabled = NO;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

// ----------------------------------------------------------------------
#pragma mark - CLLocationManagerDelegate
// ----------------------------------------------------------------------

// Deprecated in iOS 6.0
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
	// ignore updates older than one minute (may be stale, cached data)
	if ([newLocation.timestamp timeIntervalSince1970] < [NSDate timeIntervalSinceReferenceDate] - 60)
		return;
	
	MyLog(@"%s to { %f, %f } %f meters (latitude/longitude/accuracy)", __FUNCTION__,
		  newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy);
#ifdef DEBUG
	if (0 && oldLocation != nil) {
		NSDate *when = (oldLocation ? oldLocation.timestamp : nil);
		NSTimeInterval then = (when ? [when timeIntervalSinceNow] : 0);
		NSString *str = (then ? [NSString stringWithFormat:@" (%+.2f sec)", -then] : @"");
		CLLocationDistance moved = [newLocation distanceFromLocation:oldLocation];
		MyLog(@"%s moved %.1f meters as of %.2f seconds ago%@", __FUNCTION__, moved, -[newLocation.timestamp timeIntervalSinceNow], str);
	}
#endif
	
	[manager stopUpdatingLocation];
	
	MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
	
	MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion]; // unnecessary?
	
	[self.mapView setRegion:adjustedRegion animated:YES];
	
//	d_MKCoordinateRegion(adjustedRegion,	  @" adj region = ");
//	d_MKCoordinateRegion(self.mapView.region, @" map region = ");
	
	self.btnDemo1.enabled = YES;
	self.btnDemo2.enabled = !self.userOverlaysPresent;
	self.btnClear.enabled = ([self.mapView.annotations count] > 1 &&
							 [self.mapView.overlays    count] > 0);
	
	// put annotation on user location
	[self performSelector:@selector(addUserAnnotation:) withObject:newLocation afterDelay:2.0];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"%s %@", __FUNCTION__, error);
	
	NSString *title = @"Error getting location";
	NSString *message = @"Unknown Error";
	if (error.code == kCLErrorDenied) {
		message = str_accessDeniedEror;
	}
#ifdef DEBUG
	else {
		NSString *model = [[UIDevice currentDevice] model];
		if ([model rangeOfString:@"Simulator"].location != NSNotFound) {
			message = str_simulateLocationError;
			NSLog(message);
		}
	}
#endif
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

// ----------------------------------------------------------------------
#pragma mark - MKMapViewDelegate
// ----------------------------------------------------------------------

- (void)mapViewDidFailLoadingMap:(MKMapView *)aMapView withError:(NSError *)error {
	NSLog(@"%s %@", __FUNCTION__, error);
	
	NSString *title = @"Error loading map";
	NSString *message = [error localizedDescription];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation {
	MKAnnotationView *result = nil;
	
	// OUR CUSTOM ANNOTATIONS
	if ([annotation isKindOfClass:[MapAnnotation class]])
		result = [(MapAnnotation*)annotation annotationView];
	else
		// STANDARD ANNOTATIONS
		result = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
	
//	MyLog(@"%s returns %@", __FUNCTION__, result);
	return result;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	MKOverlayView *result = nil;
	
	// OUR CUSTOM OVERLAYS
	if ([overlay isKindOfClass:[MapOverlay class]])
		result = [(MapOverlay *)overlay overlayView];
	
	// STANDARD OVERLAYS
	else if ([overlay isKindOfClass:[MKCircle class]])
		result = [[MKCircleView alloc] initWithOverlay:overlay];
	
	else if ([overlay isKindOfClass:[MKPolygon class]])
		result = [[MKPolygonView alloc] initWithOverlay:overlay];
	
	else if ([overlay isKindOfClass:[MKPolyline class]])
		result = [[MKPolylineView alloc] initWithOverlay:overlay];

//	MyLog(@"%s returns %@", __FUNCTION__, result);
	return result;
}

#ifdef __IPHONE_7_0
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
	MKOverlayRenderer *result = nil;

	// OUR CUSTOM OVERLAYS
	if ([overlay isKindOfClass:[MapOverlay class]])
		result = [(MapOverlay *)overlay overlayRenderer];
	
	// STANDARD OVERLAYS
	else if ([overlay isKindOfClass:[MKCircle class]])
		result = [[MKCircleRenderer alloc] initWithOverlay:overlay];
	
	else if ([overlay isKindOfClass:[MKPolygon class]])
		result = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
	
	else if ([overlay isKindOfClass:[MKPolyline class]])
		result = [[MKPolylineRenderer alloc] initWithOverlay:overlay];

//	MyLog(@"%s returns %@", __FUNCTION__, result);
	return result;
}
#endif

@end
