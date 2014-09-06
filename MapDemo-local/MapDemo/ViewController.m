//
//	ViewController.m
//	MapDemo
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

#import "MapUtil.h"
// SPC 07-09-14 just for this first demo
// later demo will hide 'private' parts of base classes
// and work through subclasses
#import "MapOverlays_private.h"

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
	MyLog(@"\n%s for %s\n", __FUNCTION__, (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? "iOS 7" : "iOS 6"));
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

- (void)locationManager:(CLLocationManager *)aManager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
	// ignore updates older than one minute (may be stale, cached data)
	if ([newLocation.timestamp timeIntervalSince1970] < [NSDate timeIntervalSinceReferenceDate] - 60)
		return;
	
	MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
	
	MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
	
	[self.mapView setRegion:adjustedRegion animated:YES];
	
	// PUT TEST CODE HERE
	[MapUtil testMapView:self.mapView withRegion:adjustedRegion];
	
	aManager.delegate = nil;
	[aManager stopUpdatingLocation];

	MapAnnotationPoint *youAreHere = [MapUtil mapView:self.mapView addAnnotationForCoordinate:newLocation.coordinate];
	youAreHere.title = @"You Are Here!";
	youAreHere.subtitle = @"This is here ... for certain!";
	youAreHere.image = [UIImage imageNamed:@"red-16x16.png"];
	youAreHere.reuseID = @"YourLocationAnnotation"; // optional
	[self performSelector:@selector(openCallout:) withObject:youAreHere afterDelay:0.5];
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

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation {
	MKAnnotationView *result = [MapUtil mapView:self.mapView viewForAnnotation:annotation];
//	MyLog(@"%s returns %@", __FUNCTION__, result);
	return result;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	MKOverlayView *result = [MapUtil mapView:mapView viewForOverlay:overlay];
//	MyLog(@"%s returns %@", __FUNCTION__, result);
	return result;
}

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

@end
