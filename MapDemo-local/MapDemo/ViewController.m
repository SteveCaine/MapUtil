//
//	ViewController.m
//	MapDemo
//
//	iPad presentation of our custom map annotation and overlay classes
//	either used directly - 'Demo 1'
//	or via subclasses - 'Demo 2'
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

#if CONFIG_use_MapUtil
#	import "MapUtil.h"
#	import "MapOverlays_private.h"
#endif

#if CONFIG_use_MapDemo
#	import "MapDemo.h"
#endif

#import "Debug_iOS.h"
#import "Debug_MapKit.h"

#define str_selectLocationError	@"Did you forget to select a location\nin the Options panel\nof Xcode's Scheme Editor?"

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (	 weak, nonatomic) IBOutlet	MKMapView			*mapView;
@property (strong, nonatomic)			CLLocationManager	*manager;

- (IBAction)btnGo;
- (void)openCallout:(id<MKAnnotation>)annotation;

@end

#pragma mark -

@implementation ViewController

//#pragma mark - globals

#pragma mark - locals

- (IBAction)btnGo {
	if (self.manager == nil)
		self.manager = [[CLLocationManager alloc] init];
	
	self.manager.delegate = self;
	self.manager.desiredAccuracy = kCLLocationAccuracyBest;
	[self.manager startUpdatingLocation];
}

- (void)openCallout:(id<MKAnnotation>)annotation {
	[self.mapView selectAnnotation:annotation animated:YES];
}

#pragma mark - view lifetime

- (void)viewDidLoad {
//	MyLog(@"\n%s", __FUNCTION__);
	MyLog(@"\n%s for %@\n", __FUNCTION__, str_iOS_version());
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.mapView.mapType = MKMapTypeStandard;
//	self.mapView.mapType = MKMapTypeSatellite;
//	self.mapView.mapType = MKMapTypeHybrid;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManagerDelegate

// Deprecated in iOS 6.0
- (void)locationManager:(CLLocationManager *)aManager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
	// ignore updates older than one minute (may be stale, cached data)
	if ([newLocation.timestamp timeIntervalSince1970] < [NSDate timeIntervalSinceReferenceDate] - 60)
		return;
	MyLog(@"%s to %@", __FUNCTION__, newLocation);
#ifdef DEBUG
	if (0 && oldLocation != nil) {
		NSDate *when = (oldLocation ? oldLocation.timestamp : nil);
		NSTimeInterval then = (when ? [when timeIntervalSinceNow] : 0);
		NSString *str = (then ? [NSString stringWithFormat:@" (%+.2f sec)", -then] : @"");
		CLLocationDistance moved = [newLocation distanceFromLocation:oldLocation];
		MyLog(@"%s moved %.1f meters as of %.2f seconds ago%@", __FUNCTION__, moved, -[newLocation.timestamp timeIntervalSinceNow], str);
	}
#endif
	
	[aManager stopUpdatingLocation];
	
	MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
	
	MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion]; // unnecessary?
	
	[self.mapView setRegion:adjustedRegion animated:YES];
	
	// PUT TEST CODE HERE
	d_MKCoordinateRegion(adjustedRegion,	  @" adj region = ");
	d_MKCoordinateRegion(self.mapView.region, @" map region = ");
	
#if CONFIG_use_MapUtil
	// MapUtil tests
	[MapUtil testMapView:self.mapView withRegion:adjustedRegion];
	// one more annotation, this one right on top of our location
	MapAnnotation *youAreHere = [MapUtil mapView:self.mapView addAnnotationForCoordinate:newLocation.coordinate];
	youAreHere.title = @"You Are Here!";
	youAreHere.subtitle = @"This is here ... for certain!";
	youAreHere.image = [UIImage imageNamed:@"red-16x16.png"];
	youAreHere.reuseID = @"YourLocationAnnotation"; // optional
	[self performSelector:@selector(openCallout:) withObject:youAreHere afterDelay:0.5];
#else
	// MapDemo tests
	[MapDemo demoInMapView:self.mapView withLocation:newLocation region:adjustedRegion];
#endif
}

- (void)locationManager:(CLLocationManager *)aManager didFailWithError:(NSError *)error {
	NSLog(@"%s %@", __FUNCTION__, error);
	
	NSString *title = @"Error getting location";
	NSString *message = (error.code == kCLErrorDenied ? @"Access Denied" : @"Unknown Error");
	
#ifdef DEBUG
	if (error.code != kCLErrorDenied) {
		NSString *model = [[UIDevice currentDevice] model];
		if ([model rangeOfString:@"Simulator"].location != NSNotFound) {
			message = str_selectLocationError;
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

#pragma mark - MKMapViewDelegate

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
