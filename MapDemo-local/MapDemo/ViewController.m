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
//	where the latter is presented only if compiled in SDKs 7.0 and above and run in iOS 7 and above
//
//	iOS itself determines whether 'view' or 'renderer' is called based on which protocol methods 
//	the overlay objects implement, so we don't need runtime checks to see which iOS version is currently running
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

#import "AppDelegate.h"

// for 'Demo 1'
#import "MapUtil.h"

// for 'Demo 2'
#import "MapDemo.h"

#import "Debug_iOS.h"
#import "Debug_MapKit.h"

#define str_cantGetUserLocation		@"Can’t Get User Location"
#define str_errorGettingLocation	@"Error getting location"

#define str_accessDeniedEror		@"Access Denied. Please go to\nSettings -> Privacy -> Location\nto allow access to Location Services."
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
@property (assign, nonatomic)			NSUInteger			alertsShown;

- (IBAction)doDemo1;

- (IBAction)doDemo2;

- (IBAction)doClear;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

@end

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

@implementation ViewController

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
	
	// always keep our "You Are Here!" annotation (unless user has disabled Location Services)
	NSMutableArray *toRemove = [NSMutableArray arrayWithArray:self.mapView.annotations];
	if ([CLLocationManager authorizationStatus] >= kCLAuthorizationStatusAuthorized)
		[toRemove removeObject:self.userAnnotation];
	else
		self.userAnnotation = nil; // it's about to be removed
	
	[self.mapView removeAnnotations:toRemove];
	[self.mapView removeOverlays:self.mapView.overlays];
	self.userOverlaysPresent = NO;
	
//	MyLog(@"<= annotations = %@", [self.mapView annotations]);
//	MyLog(@"<=	  overlays = %@", [self.mapView overlays]);
	
	self.btnClear.enabled = NO;
	
	if ([CLLocationManager authorizationStatus] >= kCLAuthorizationStatusAuthorized)
		self.btnDemo2.enabled = YES;
	else
		self.btnDemo1.enabled = self.btnClear.enabled = self.btnDemo2.enabled = NO;
	}

- (void)openCallout:(id<MKAnnotation>)annotation {
	[self.mapView selectAnnotation:annotation animated:YES];
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

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
#ifdef DEBUG
	MyLog(@"ALERT: '%@' - '%@'",
		  [title   stringByReplacingOccurrencesOfString:@"\n" withString:@" "],
		  [message stringByReplacingOccurrencesOfString:@"\n" withString:@" "]);
#endif
	title = [title stringByAppendingString:[NSString stringWithFormat:@" (%i)", (int) ++self.alertsShown]];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

// ----------------------------------------------------------------------
#pragma mark - globals
// ----------------------------------------------------------------------

- (void)handle_applicationDidBecomeActive {
	MyLog(@"%s", __FUNCTION__);
	MyLog(@" app is '%@', status is '%@'", str_curAppState(), str_curCLAuthorizationStatus());
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
	if (status == kCLAuthorizationStatusDenied) {
		if ([self.mapView.annotations count] || [self.mapView.overlays count])
			[self doClear];
		// call every time we become active (since app is useless w/o access)
		[self showAlertWithTitle:str_cantGetUserLocation message:str_accessDeniedEror];
	}
	// are we coming back after user has changed status to active?
	else if (status >= kCLAuthorizationStatusAuthorized && self.userAnnotation == nil) {
		[self.locationManager startUpdatingLocation];
	}
}

// ----------------------------------------------------------------------
#pragma mark - view lifetime
// ----------------------------------------------------------------------

- (void)viewDidLoad {
//	MyLog(@"\n%s", __FUNCTION__);
	MyLog(@"\n%s for iOS %@\n", __FUNCTION__, str_iOS_version());
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
		// hard to believe iOS 6 doesn't do something like this by default
		UIColor *dimColor = [[self.btnDemo1 titleColorForState:UIControlStateNormal]  colorWithAlphaComponent:0.5];
		[self.btnDemo1 setTitleColor:dimColor forState:UIControlStateDisabled];
		[self.btnDemo2 setTitleColor:dimColor forState:UIControlStateDisabled];
		[self.btnClear setTitleColor:dimColor forState:UIControlStateDisabled];
	}
	
	// choose one
	self.mapView.mapType = MKMapTypeStandard;
//	self.mapView.mapType = MKMapTypeSatellite;
//	self.mapView.mapType = MKMapTypeHybrid;

	// normally we would call
	//		[CLLocationManager locationServicesEnabled]
	// here, and only ask once that user enable it;
	// but since the entire purpose of this app is to use locations,
	// we'll keep asking every time handle_applicationDidBecomeActive is called
	// until access is allowed
	
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
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

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations {
	MyLog(@"%s %@", __FUNCTION__, locations);
	MyLog(@" manager.location = %@", manager.location);
	
	CLLocation *newLocation = [locations lastObject]; // objects in order received
	
	[manager stopUpdatingLocation];
	
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000); // 2km x 2km
	[self.mapView setRegion:region animated:YES];
	
	self.btnDemo1.enabled = YES;
	self.btnDemo2.enabled = !self.userOverlaysPresent;
	self.btnClear.enabled = ([self.mapView.annotations count] > 1 &&
							 [self.mapView.overlays    count] > 0);
	
	// put annotation on user location
	[self performSelector:@selector(addUserAnnotation:) withObject:newLocation afterDelay:2.0];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"%s %@", __FUNCTION__, error);
	d_CLError(error.code, @" err = ");
	MyLog(@" app is '%@', status is '%@'", str_curAppState(), str_curCLAuthorizationStatus());
	
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
	[self showAlertWithTitle:title message:message];
}

- (void)	 locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	MyLog(@"%s '%@' - cur app state is '%@'", __FUNCTION__, str_CLAuthorizationStatus(status), str_curAppState());
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

// for iOS 6 and earlier
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

// for iOS 7 and later
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
