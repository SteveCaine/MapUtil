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
//	iOS itself determines whether 'view' or 'renderer' is called based on which protocol methods the overlay objects implement
//	so we don't need runtime checks there to see which iOS version is currently running
//
//	this code has been updated to work with the new iSO 8 logic for granting access to the user's location
//	while still being compatible with running in iOS 7
//
//	Created by Steve Caine on 07/15/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014 Steve Caine.
//

#define CONFIG_trackUserLocation	0	// NOT YET IMPLEMENTED

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
#define str_errorLoadingMap			@"Error loading map"

#define str_accessDeniedError		@"Access Denied. Please go to\nSettings -> Privacy -> Location\nto allow access to Location Services."
#define str_simulateLocationError	@"Did you forget to select a location\nin the Options panel\nof Xcode's Scheme Editor?"

// ----------------------------------------------------------------------
//#pragma mark -
// ----------------------------------------------------------------------

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UIAlertViewDelegate>

@property (	 weak, nonatomic) IBOutlet	MKMapView			*mapView;
@property (  weak, nonatomic) IBOutlet	UIButton			*btnDemo1;
@property (  weak, nonatomic) IBOutlet	UIButton			*btnDemo2;
@property (  weak, nonatomic) IBOutlet	UIButton			*btnClear;

@property (strong, nonatomic)			CLLocationManager	*locationManager;
@property (strong, nonatomic)			MapAnnotation		*userAnnotation;
@property (assign, nonatomic)		CLAuthorizationStatus	lastStatus;

@property (strong, nonatomic)			NSMutableArray		*dismissableAlerts;
@property (assign, nonatomic)			NSInteger			alertsPending;
@property (assign, nonatomic)			NSUInteger			alertsShown;

@property (assign, nonatomic)			MKCoordinateRegion	initialRegion;
@property (assign, nonatomic)			BOOL				userOverlaysPresent;

- (IBAction)doDemo1;

- (IBAction)doDemo2;

- (IBAction)doClear:(id)sender;

@end

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

@implementation ViewController

// ----------------------------------------------------------------------
#pragma mark - actions
// ----------------------------------------------------------------------

- (IBAction)doDemo1 {
	MyLog(@"\nTapped button 'Demo 1'");
	if ([self localAccess]) {
		// tests using MapUtil 
		[MapUtil testMapView:self.mapView];
		self.btnClear.enabled = YES;
	}
	else // should not happen; button should be disabled
		[self showAlertWithTitle:str_cantGetUserLocation message:str_accessDeniedError dismissable:NO];
}

// ----------------------------------------------------------------------

- (IBAction)doDemo2 {
	MyLog(@"\nTapped button 'Demo 2'");
	if ([self localAccess]) {
		// tests using MapDemo 
		[MapDemo demoInMapView:self.mapView withLocation:self.locationManager.location];
		self.userOverlaysPresent = YES;
		self.btnDemo2.enabled = NO;
		self.btnClear.enabled = YES;
	}
	else // should not happen; button should be disabled
		[self showAlertWithTitle:str_cantGetUserLocation message:str_accessDeniedError dismissable:NO];
}

// ----------------------------------------------------------------------

- (IBAction)doClear:(id)sender {
	MyLog(@"\nTapped button 'Clear' - Map has %i annotations and %i overlays.",
		  [self.mapView.annotations count], [self.mapView.overlays count]);
	
//	MyLog(@"=> annotations = %@", [self.mapView annotations]);
//	MyLog(@"=>	  overlays = %@", [self.mapView overlays]);
	
	// always keep our "You Are Here!" annotation (unless access to Location Services has been disabled)
	NSMutableArray *toRemove = [NSMutableArray arrayWithArray:self.mapView.annotations];
	if ([self localAccess])
		[toRemove removeObject:self.userAnnotation];
	else
		self.userAnnotation = nil; // it's about to be removed
	
	[self.mapView removeAnnotations:toRemove];
	[self.mapView removeOverlays:self.mapView.overlays];
	self.userOverlaysPresent = NO;
	
//	MyLog(@"<= annotations = %@", [self.mapView annotations]);
//	MyLog(@"<=	  overlays = %@", [self.mapView overlays]);
	
	self.btnClear.enabled = NO;
	
	if ([self localAccess])
		self.btnDemo2.enabled = YES;
	else
		self.btnDemo1.enabled = self.btnDemo2.enabled = self.btnClear.enabled = NO;
}

// ----------------------------------------------------------------------
#pragma mark - globals
// ----------------------------------------------------------------------

// ----------------------------------------------------------------------
#pragma mark - locals
// ----------------------------------------------------------------------

- (BOOL)globalAccess {
	return [CLLocationManager locationServicesEnabled];
}

// ----------------------------------------------------------------------

- (BOOL)localAccess {
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
	return (
#ifdef __IPHONE_8_0
			status == kCLAuthorizationStatusAuthorizedAlways ||
			status == kCLAuthorizationStatusAuthorizedWhenInUse
#else
			status == kCLAuthorizationStatusAuthorized
#endif
			);
}

// ----------------------------------------------------------------------

- (void)openCallout:(id<MKAnnotation>)annotation {
	[self.mapView selectAnnotation:annotation animated:YES];
}

// ----------------------------------------------------------------------

- (void)addUserAnnotation:(CLLocation *)location {
	MyLog(@"%s current = %@", __FUNCTION__, self.userAnnotation);
#if CONFIG_trackUserLocation
	if (self.userAnnotation) {
		[self.mapView removeAnnotation:self.userAnnotation];
		self.userAnnotation = nil;
	}
#endif
	if (self.userAnnotation == nil) {
		// put annotation on user location
		self.userAnnotation = [MapUserPoint userWithLocation:location title:@"You Are Here!"];
		[self.mapView addAnnotation:self.userAnnotation];
		[self openCallout:self.userAnnotation];
	}
}

// ----------------------------------------------------------------------

- (void)postAlert:(UIAlertView *)alert {
	static NSUInteger times;
	// only show alert if app is active, else defer (so if access changes to authorized, we can cancel alert)
	UIApplication *app = [UIApplication sharedApplication];
	MyLog(@"%s %p (app is '%@') %i", __FUNCTION__, alert, str_AppState(app.applicationState), times++);
	if (app != nil && app.applicationState == UIApplicationStateActive)
		[alert show];
	else
		[self performSelector:@selector(postAlert:) withObject:alert afterDelay:0.5];
}

// ----------------------------------------------------------------------

- (void)dismissAlerts {
	MyLog(@"%s (%i)", __FUNCTION__, [self.dismissableAlerts count]);
	if ([self.dismissableAlerts count]) {
		for (UIAlertView *alert in self.dismissableAlerts) {
			MyLog(@" dismiss & cut %p", alert);
			[alert dismissWithClickedButtonIndex:0 animated:NO];
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postAlert:) object:alert];
		}
		[self.dismissableAlerts removeAllObjects];
	}
}

// ----------------------------------------------------------------------

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message dismissable:(BOOL)dismissable {
#ifdef DEBUG
	NSString *prefix = (dismissable ? @"POST" : @"SHOW");
	MyLog(@"%@ ALERT: '%@' - '%@'", prefix,
		  [title   stringByReplacingOccurrencesOfString:@"\n" withString:@" "],
		  [message stringByReplacingOccurrencesOfString:@"\n" withString:@" "]);
	title = [title stringByAppendingString:[NSString stringWithFormat:@" (%i)", (int) ++self.alertsShown]];
#endif
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	// 'dismissable' alerts are shown after a delay IF app is in foreground AND we haven't canceled it while in background
	if (dismissable) {
		[self.dismissableAlerts addObject:alert];
		++self.alertsPending; // we only care about the ones that *can* be dismissed
		[self performSelector:@selector(postAlert:) withObject:alert afterDelay:1.0];
	}
	else // all other alerts are shown immediately
		[alert show];
}

// ----------------------------------------------------------------------

- (void)startTrackingLocation {
	MyLog(@"\n%s", __FUNCTION__);
#ifdef __IPHONE_8_0
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
	if (status == kCLAuthorizationStatusNotDetermined) {
		if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
			[self.locationManager requestWhenInUseAuthorization];
		else // compiled for iOS 8 but running on earlier iOS
			[self.locationManager startUpdatingLocation];
	}
	else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
			 status == kCLAuthorizationStatusAuthorizedAlways) {
		[self.locationManager startUpdatingLocation];
	}
#else
	[self.locationManager startUpdatingLocation];
#endif
}

// ----------------------------------------------------------------------
#pragma mark - application state
// ----------------------------------------------------------------------

- (void)notice_applicationDidBecomeActive {
	MyLog(@"\n%s", __FUNCTION__);
	if ([self globalAccess] == NO || [self localAccess] == NO)
		// only show if no previous alerts are pending
		if (self.alertsPending <= 0)
			[self showAlertWithTitle:str_cantGetUserLocation message:str_accessDeniedError dismissable:YES];
}

- (void)notice_applicationWillResignActive {
	MyLog(@"\n%s", __FUNCTION__);
}

- (void)notice_applicationDidEnterBackground {
	MyLog(@"\n%s", __FUNCTION__);
}

- (void)notice_applicationWillEnterForeground {
	MyLog(@"\n%s", __FUNCTION__);
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
	
	// initial map is centered over North America; we return here if access is revoked
	CLLocationCoordinate2D center = { 40, -95 };
	MKCoordinateSpan		 span = { 60,  40 };
	self.initialRegion = MKCoordinateRegionMake(center, span);

	// NOTE: this where most apps would call 
	//		[CLLocationManager locationServicesEnabled]
	// and only proceed if the answer is YES (else user has said NO app should access their location)
	// but since the entire purpose of this app is to use locations,
	// we'll keep asking every time this app becomes active, until access is allowed
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;

	self.lastStatus = kCLAuthorizationStatusNotDetermined;
	
	self.dismissableAlerts = [NSMutableArray array];

	// track changes in app state
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self selector:@selector(notice_applicationDidBecomeActive)
											name:UIApplicationDidBecomeActiveNotification object:nil];
	
	[nc addObserver:self selector:@selector(notice_applicationWillResignActive)
											name:UIApplicationWillResignActiveNotification object:nil];
	
	[nc addObserver:self selector:@selector(notice_applicationDidEnterBackground)
											name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	[nc addObserver:self selector:@selector(notice_applicationWillEnterForeground)
											name:UIApplicationWillEnterForegroundNotification object:nil];
	
	self.btnDemo1.enabled = self.btnDemo2.enabled = self.btnClear.enabled = NO;
}

// ----------------------------------------------------------------------

- (void)viewDidAppear:(BOOL)animated {
	MyLog(@"\n%s", __FUNCTION__);
	[super viewDidAppear:animated];
	[self startTrackingLocation];
}

// ----------------------------------------------------------------------

- (void)viewWillAppear:(BOOL)animated {MyLog(@"\n%s", __FUNCTION__);[super viewWillAppear:animated];}
//- (void)viewDidAppear:(BOOL)animated {MyLog(@"\n%s", __FUNCTION__);[super viewDidAppear:animated];}
- (void)viewWillDisappear:(BOOL)animated {MyLog(@"\n%s", __FUNCTION__);[super viewWillDisappear:animated];}
- (void)viewDidDisappear:(BOOL)animated {MyLog(@"\n%s", __FUNCTION__);[super viewDidDisappear:animated];}

// ----------------------------------------------------------------------

- (void)didReceiveMemoryWarning {
	MyLog(@"\n%s", __FUNCTION__);
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

// ----------------------------------------------------------------------

- (void)dealloc {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self]; // all notifications
}

// ----------------------------------------------------------------------
#pragma mark - CLLocationManagerDelegate
// ----------------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations {

	CLLocation *newLocation = [locations lastObject]; // objects in order received
	NSTimeInterval age = -[newLocation.timestamp timeIntervalSinceNow];
	
	MyLog(@"%s with %i location(s) as of %5.3f seconds ago", __FUNCTION__, [locations count], age);
	
	// ignore updates older than one minute (may be stale, cached data)
	if ([newLocation.timestamp timeIntervalSinceReferenceDate] < [NSDate timeIntervalSinceReferenceDate] - 60)
		return;

//	MyLog(@" location = %@", newLocation);
	MyLog(@" location = %@ at %5.3f seconds ago", [MapUtil locationString:newLocation], age);
	
#if !CONFIG_trackUserLocation
	MyLog(@" call stopUpdatingLocation");
	[manager stopUpdatingLocation];
#endif
	
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);	// 2km x 2km
//	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 200, 200);	// 200m x 200m
	[self.mapView setRegion:region animated:YES];
	
	self.btnDemo1.enabled = YES;
	self.btnDemo2.enabled = !self.userOverlaysPresent;
	self.btnClear.enabled = ([self.mapView.annotations count] > 1 &&
							 [self.mapView.overlays    count] > 0);
	
	// put annotation on user location
	[self performSelector:@selector(addUserAnnotation:) withObject:newLocation afterDelay:2.0];
}

// ----------------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"%s %@", __FUNCTION__, [error localizedDescription]);
	d_CLError(error.code, @" err = ");
	if (error.code == kCLErrorDenied) {
		// only show if no previous alerts are pending
		if (self.alertsPending <= 0)
			[self showAlertWithTitle:str_cantGetUserLocation message:str_accessDeniedError dismissable:YES];
	}
#ifdef DEBUG
	else if (error.code == kCLErrorLocationUnknown &&
			[[[UIDevice currentDevice] model] rangeOfString:@"Simulator"].location != NSNotFound) {
		[self showAlertWithTitle:str_cantGetUserLocation message:str_simulateLocationError dismissable:NO];
	}
#endif
	else
		[self showAlertWithTitle:str_cantGetUserLocation message:[error localizedDescription] dismissable:NO];
}

// ----------------------------------------------------------------------

- (void)	 locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	MyLog(@"%s '%@' (was '%@')", __FUNCTION__, str_CLAuthorizationStatus(status), str_CLAuthorizationStatus(self.lastStatus));
	
	switch (status) {
		case kCLAuthorizationStatusDenied:
			// if access is being revoked, clear whatever we have
			if ([self.mapView.annotations count] || [self.mapView.overlays count]) {
				[self doClear:nil];
				[self.mapView setRegion:self.initialRegion];
			}
			// only show if no previous alerts are pending
			if (self.alertsPending <= 0)
				[self showAlertWithTitle:str_cantGetUserLocation message:str_accessDeniedError dismissable:YES];
			break;

		case kCLAuthorizationStatusNotDetermined:
#ifdef __IPHONE_8_0
			if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
				MyLog(@" requesting access");
				[self.locationManager requestWhenInUseAuthorization];
			}
			else { // compiled for iOS 8 but running on earlier iOS
				NSLog(@" start tracking location");
//				[self.locationManager startUpdatingLocation];
				[self startTrackingLocation];
			}
#else
			[self startTrackingLocation];
#endif
			break;

#ifdef __IPHONE_8_0
		case kCLAuthorizationStatusAuthorizedAlways:
		case kCLAuthorizationStatusAuthorizedWhenInUse:
#else
		case kCLAuthorizationStatusAuthorized:
#endif
			// cancel any 'access denied' alerts
			[self dismissAlerts];
			NSLog(@"Got authorization, start tracking location");
			[self startTrackingLocation];
			break;
		default:
			MyLog(@" ?status? = %@", str_CLAuthorizationStatus(status));
			break;
	}
	self.lastStatus = status;
}

// ----------------------------------------------------------------------
#pragma mark - MKMapViewDelegate
// ----------------------------------------------------------------------

- (void)mapViewDidFailLoadingMap:(MKMapView *)aMapView withError:(NSError *)error {
	NSLog(@"%s %@", __FUNCTION__, [error localizedDescription]);
	
	// TODO: keep this? from older version
	[self showAlertWithTitle:str_errorLoadingMap message:[error localizedDescription] dismissable:NO];
}

// ----------------------------------------------------------------------

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation {
	MKAnnotationView *result = nil;
	
	// OUR CUSTOM ANNOTATIONS
	if ([annotation isKindOfClass:[MapAnnotation class]])
		result = [(MapAnnotation*)annotation annotationView];
	else if ([annotation isKindOfClass:[MKUserLocation class]])
		result = nil;
	else
		// STANDARD ANNOTATIONS
		result = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
	
//	MyLog(@"%s returns %@", __FUNCTION__, result);
	return result;
}

// ----------------------------------------------------------------------

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

// ----------------------------------------------------------------------

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

// ----------------------------------------------------------------------
#pragma mark - UIAlertViewDelegate
// ----------------------------------------------------------------------

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	MyLog(@"%s %i", __FUNCTION__, buttonIndex);
//	MyLog(@"%s (%i) %i", __FUNCTION__, self.alertsPending, buttonIndex);
	if ([self.dismissableAlerts containsObject:alertView]) {
		MyLog(@" => %@", self.dismissableAlerts);
		[self.dismissableAlerts removeObject:alertView];
		--self.alertsPending;
		MyLog(@" <= %@", self.dismissableAlerts);
	}
}

@end
