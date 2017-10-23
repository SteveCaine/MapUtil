//
//	ViewController.m
//	MapDemo
//
//	iPad presentation of MapUtil's custom map annotation and overlay classes
//	either used directly - 'Demo 1'
//	   or via subclasses - 'Demo 2'
//	that hide the base classes' implementation details
//
//	Created by Steve Caine on 07/15/14.
//	Updated by Steve Caine on 07/20/17 to remove support for iOS versions prior to 8.x
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014-2017 Steve Caine.
//

#define CONFIG_keepUpdatingLocation			1

#define CONFIG_includeOurLocation			0	// show user location with our custom annotation
#define CONFIG_includeUserLocation			1	// show standard iOS user location annotation

#define CONFIG_requestLocationAccess_Always	1 // else request 'in-use' access

// NOT YET IMPLEMENTED - MapUserTrail (which would track changing location)

// ----------------------------------------------------------------------

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

// ----------------------------------------------------------------------
#if TARGET_IPHONE_SIMULATOR
static BOOL const DeviceIsSimulator = YES;
#else
static BOOL const DeviceIsSimulator = NO;
#endif
// ----------------------------------------------------------------------

static NSString * const ERR_cantGetUserLocation	=	@"Can’t Get User Location";
static NSString * const ERR_errorLoadingMap		=	@"Error loading map";

static NSString * const ERR_accessDeniedError =
	@"Access Denied. Please go to\nSettings -> Privacy -> Location\nto allow access to Location Services.";
static NSString * const ERR_simulateLocationError =
	@"Did you forget to select a location\nin the Options panel\nof Xcode's Scheme Editor?";

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
@property (assign, nonatomic)			MKUserLocation		*userLocation;
@property (assign, nonatomic)		CLAuthorizationStatus	lastStatus;

@property (strong, nonatomic)			NSMutableArray		*dismissableAlerts;
@property (assign, nonatomic)			NSInteger			alertsPending;
@property (assign, nonatomic)			NSUInteger			alertsShown;

@property (assign, nonatomic)			MKCoordinateRegion	initialRegion;
@property (assign, nonatomic)			BOOL				userOverlaysPresent;
@property (assign, nonatomic)			BOOL				isTrackingLocation;

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
		[self showAlertWithTitle:ERR_cantGetUserLocation message:ERR_accessDeniedError dismissable:NO];
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
		[self showAlertWithTitle:ERR_cantGetUserLocation message:ERR_accessDeniedError dismissable:NO];
}

// ----------------------------------------------------------------------

- (IBAction)doClear:(id)sender {
	MyLog(@"\nTapped button 'Clear' - Map has %lu annotations and %lu overlays.",
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
// return lat/lon like this: "37.332331 N, 122.031219 W" (Apple Inc.'s location in iOS Simulator)
- (NSString *)locationString:(CLLocation *)location {
	NSString *result = nil;
	if (location) {
		CLLocationCoordinate2D c = location.coordinate;
		NSString *str_latitude  = [NSString stringWithFormat:@"%3f %s", fabs(c.latitude),  (c.latitude  > 0 ? "N" : "S")];
		NSString *str_longitude = [NSString stringWithFormat:@"%4f %s", fabs(c.longitude), (c.longitude > 0 ? "E" : "W")];
		result = [NSString stringWithFormat:@"%@, %@", str_latitude, str_longitude];
	}
	return result;
}

// ----------------------------------------------------------------------

- (void)openCallout:(id<MKAnnotation>)annotation {
	[self.mapView selectAnnotation:annotation animated:YES];
}

// ----------------------------------------------------------------------

- (void)addUserAnnotation:(CLLocation *)location {
	MyLog(@"%s current = %@", __FUNCTION__, self.userAnnotation);
#if CONFIG_keepUpdatingLocation
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
	UIApplication *app = UIApplication.sharedApplication;
	MyLog(@"%s %p (app is '%@') %lu", __FUNCTION__, alert, str_AppState(app.applicationState), times++);
	if (app != nil && app.applicationState == UIApplicationStateActive)
		[alert show];
	else
		[self performSelector:@selector(postAlert:) withObject:alert afterDelay:0.5];
}

// ----------------------------------------------------------------------

- (void)dismissAlerts {
	MyLog(@"%s (%lu)", __FUNCTION__, [self.dismissableAlerts count]);
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
	title = [title stringByAppendingString:[NSString stringWithFormat:@" (%lu)", ++self.alertsShown]];
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
	
	self.isTrackingLocation = YES;
	CLAuthorizationStatus status = CLLocationManager.authorizationStatus;
	
	if (status == kCLAuthorizationStatusNotDetermined) {
#if CONFIG_requestLocationAccess_Always
		[self.locationManager requestAlwaysAuthorization];
#else
		[self.locationManager requestWhenInUseAuthorization];
#endif
	}
	else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
			 status == kCLAuthorizationStatusAuthorizedAlways) {
		[self.locationManager startUpdatingLocation];
	}
}

// ----------------------------------------------------------------------
#pragma mark - application state
// ----------------------------------------------------------------------

- (void)notice_applicationDidBecomeActive {
	MyLog(@"\n%s", __FUNCTION__);
	if ([self globalAccess] == NO || [self localAccess] == NO)
		// only show if no previous alerts are pending
		if (self.alertsPending <= 0)
			[self showAlertWithTitle:ERR_cantGetUserLocation message:ERR_accessDeniedError dismissable:YES];
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
	
	self.lastStatus = CLLocationManager.authorizationStatus;
	
	self.dismissableAlerts = @[].mutableCopy;

	// track changes in app state
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	
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
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc removeObserver:self]; // all notifications
}

// ----------------------------------------------------------------------
#pragma mark - CLLocationManagerDelegate
// ----------------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations {

	CLLocation *newLocation = locations.lastObject; // objects in order received
	NSTimeInterval age = -[newLocation.timestamp timeIntervalSinceNow];
	
	MyLog(@"%s with %lu location(s) as of %5.3f seconds ago", __FUNCTION__, locations.count, age);
	
	// ignore updates older than one minute (may be stale, cached data)
	if ([newLocation.timestamp timeIntervalSinceReferenceDate] < [NSDate timeIntervalSinceReferenceDate] - 60)
		return;

//	MyLog(@" location = %@", newLocation);
	MyLog(@" location = %@ at %5.3f seconds ago", [MapUtil locationString:newLocation], age);
	
#if !CONFIG_keepUpdatingLocation
	MyLog(@" call stopUpdatingLocation");
	[manager stopUpdatingLocation];
#endif
	
	// first location received? zoom in and initialize our controls
	if (self.userLocation == nil) {
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);	// 2km x 2km
//		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 200, 200);	// 200m x 200m
		[self.mapView setRegion:region animated:YES];
#if CONFIG_includeUserLocation
		self.mapView.showsUserLocation = YES;
#endif
		self.btnDemo1.enabled = YES;
		self.btnDemo2.enabled = !self.userOverlaysPresent;
		self.btnClear.enabled = ([self.mapView.annotations count] > 1 &&
								 [self.mapView.overlays    count] > 0);
#if CONFIG_includeOurLocation
		// put OUR annotation on user location
		[self performSelector:@selector(addUserAnnotation:) withObject:newLocation afterDelay:2.0];
#endif
	}
	else {
#if CONFIG_includeUserLocation
		// update subtitle on iOS user location annotation
		self.userLocation.subtitle = [self locationString:self.userLocation.location];
#endif
	}
	MyLog(@" span = %f, %f", self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta);
}

// ----------------------------------------------------------------------

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"%s %@", __FUNCTION__, error.localizedDescription);
	d_CLError(error.code, @" err = ");
	MyLog(@" app is '%@', status is '%@'", str_curAppState(), str_curCLAuthorizationStatus());
	
	if (error.code == kCLErrorDenied) {
		// only show if no previous alerts are pending
		if (self.alertsPending <= 0)
			[self showAlertWithTitle:ERR_cantGetUserLocation message:ERR_accessDeniedError dismissable:YES];
	}
#ifdef DEBUG
	else if (error.code == kCLErrorLocationUnknown && DeviceIsSimulator) {
		[self showAlertWithTitle:ERR_cantGetUserLocation message:ERR_simulateLocationError dismissable:NO];
	}
#endif
	else
		[self showAlertWithTitle:ERR_cantGetUserLocation message:error.localizedDescription dismissable:NO];
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
				[self showAlertWithTitle:ERR_cantGetUserLocation message:ERR_accessDeniedError dismissable:YES];
			break;

		case kCLAuthorizationStatusNotDetermined:
			break;

		case kCLAuthorizationStatusAuthorizedAlways:
		case kCLAuthorizationStatusAuthorizedWhenInUse:
			// cancel any 'access denied' alerts
			[self dismissAlerts];
			MyLog(@"Got authorization, start tracking location");
//			[self startTrackingLocation];
			[self.locationManager startUpdatingLocation];
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
	NSLog(@"%s %@", __FUNCTION__, error.localizedDescription);
	
	// TODO: keep this? from older version
	[self showAlertWithTitle:ERR_errorLoadingMap message:error.localizedDescription dismissable:NO];
}

// ----------------------------------------------------------------------

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation {
	MKAnnotationView *result = nil;
	
	// OUR CUSTOM ANNOTATIONS
	if ([annotation isKindOfClass:MapAnnotation.class])
		result = [(MapAnnotation*)annotation annotationView];
	
	// STANDARD iOS USER LOCATION ANNOTATION
	else if ([annotation isKindOfClass:MKUserLocation.class]) {
		result = nil; // iOS will provide the view object ...

#if CONFIG_includeUserLocation
		// ... but we can modify text of annotation
		MKUserLocation *dot = (MKUserLocation *)annotation;
		dot.title = @"You Are Here!";
		dot.subtitle = [self locationString:dot.location];
		
		// if it's not already open, do so once things have settled down
		if (self.userLocation == nil) {
			self.userLocation = dot;
#if !CONFIG_includeOurLocation
			// but prefer selecting OUR annotation to the iOS annotation
			[self performSelector:@selector(openCallout:) withObject:self.userLocation afterDelay:0.5];
#endif
		}
#endif
	}
	else
		// STANDARD ANNOTATIONS
		result = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
	
//	MyLog(@"%s returns %@", __FUNCTION__, result);
	return result;
}

// ----------------------------------------------------------------------

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
	MKOverlayRenderer *result = nil;

	// OUR CUSTOM OVERLAYS
	if ([overlay isKindOfClass:MapOverlay.class])
		result = [(MapOverlay *)overlay overlayRenderer];
	
	// STANDARD OVERLAYS
	else if ([overlay isKindOfClass:MKCircle.class])
		result = [[MKCircleRenderer alloc] initWithOverlay:overlay];
	
	else if ([overlay isKindOfClass:MKPolygon.class])
		result = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
	
	else if ([overlay isKindOfClass:MKPolyline.class])
		result = [[MKPolylineRenderer alloc] initWithOverlay:overlay];

//	MyLog(@"%s returns %@", __FUNCTION__, result);
	
	NSAssert(result != nil, @"Should never return nil. (says Apple)");
	// per Mark Knopper comment in stackoverflow thread
	//	http://stackoverflow.com/questions/30750560/swift-2-mkmapviewdelegate-rendererforoverlay-optionality
	
	return result;
}

// ----------------------------------------------------------------------
#pragma mark - UIAlertViewDelegate
// ----------------------------------------------------------------------

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	MyLog(@"%s %lu", __FUNCTION__, buttonIndex);
//	MyLog(@"%s (%lu) %lu", __FUNCTION__, self.alertsPending, buttonIndex);
	if ([self.dismissableAlerts containsObject:alertView]) {
		MyLog(@" => %@", self.dismissableAlerts);
		[self.dismissableAlerts removeObject:alertView];
		--self.alertsPending;
		MyLog(@" <= %@", self.dismissableAlerts);
	}
}

@end
