//
//  HistoryMapViewController.m
//  Gram
//
//  Created by Yoshimura Kenya on 2012/08/22.
//  Copyright (c) 2012年 Yoshimura Kenya. All rights reserved.
//

#import "HistoryMapViewController.h"
#import "BarCodeViewController.h"
#import "ReaderViewController.h"
#import "UITabBarWithAdController.h"
#import "GramContext.h"
#import "GramAnnotation.h"

@interface HistoryMapViewController ()
{
    UIBarButtonItem *item;
    CLLocationManager *locationManager;
    CGRect frame;
}

@end

@implementation HistoryMapViewController
@synthesize mapView;

- (void)viewWillAppear:(BOOL)animated
{
    //UITabBarWithAdController *tabBar = (UITabBarWithAdController *)self.tabBarController;
    //tabBar.delegate = self;
    //frame = [mapView frame];
    
    self.title = @"履歴";
    self.navigationItem.rightBarButtonItem = item;
    mapView.delegate = self;
    mapView.frame = CGRectMake(0, 0, 320, 460 - 44 - 49);
    
    if ([[GramContext get]->history count] > 0)
    {
        for (NSDictionary *data in [GramContext get]->history)
        {
            CLLocation *location = [NSKeyedUnarchiver unarchiveObjectWithData:[data objectForKey:@"location"]];
            if (location != nil)
            {
                NSString *subTitle = nil;
                if ([[data objectForKey:@"type"] isEqualToString:@"decode"])
                {
                    subTitle = @"読取";
                }
                else
                {
                    subTitle = @"作成";
                }
                
                NSDate *date = [data objectForKey:@"date"];
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                df.dateFormat  = @"yyyy/MM/dd HH:mm";
                GramAnnotation *placeMark = [[GramAnnotation alloc]
                                             initWithCoordinate:location.coordinate
                                             andTitle:[NSString stringWithFormat:@"%@", [df stringFromDate:date]]
                                             andSubTitle:subTitle
                                             withData:data];
                
                [mapView addAnnotation:placeMark];
            }
        }
        
        NSDictionary *data = [[GramContext get]->history objectAtIndex:0];
        mapView.mapType = MKMapTypeStandard;
        MKCoordinateRegion region = mapView.region;
        CLLocation *location = [NSKeyedUnarchiver unarchiveObjectWithData:[data objectForKey:@"location"]];
        region.center.latitude = location.coordinate.latitude;
        region.center.longitude = location.coordinate.longitude;
        region.span.latitudeDelta = 0.005;
        region.span.longitudeDelta = 0.005;
        [mapView setRegion:region animated:NO];
    }
    /*
    [UIView beginAnimations:@"ad" context:nil];
    if (tabBar.bannerIsVisible)
    {
        [self.mapView setFrame:CGRectMake(frame.origin.x,
                                            frame.origin.y,
                                            frame.size.width,
                                            frame.size.height - 93 -  49)];
    }
    else
    {
        [self.mapView setFrame:CGRectMake(frame.origin.x,
                                            frame.origin.y,
                                            frame.size.width,
                                            frame.size.height - 93)];
    }
    [UIView commitAnimations];
     */
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.viewControllers = [NSArray arrayWithObject:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    item = self.navigationItem.rightBarButtonItem;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    //UITabBarWithAdController *tabBar = (UITabBarWithAdController *)self.tabBarController;
    //if (tabBar.delegate == self)
    //{
    //    tabBar.delegate = nil;
    //}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (MKAnnotationView *)mapView:(MKMapView *)view viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[view dequeueReusableAnnotationViewWithIdentifier:@"view"];
    if (!annotationView)
    {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"view"];
        annotationView.canShowCallout = YES;
        GramAnnotation *gramAnnotation = annotationView.annotation;
        
        if ([[gramAnnotation.dictionary objectForKey:@"type"] isEqualToString:@"decode"])
        {
            annotationView.pinColor = MKPinAnnotationColorRed;
        }
        else
        {
            annotationView.pinColor = MKPinAnnotationColorGreen;
        }
        
        //annotationView.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    else
    {
        annotationView.annotation = annotation;
        //[(UIImageView *)annotationView.leftCalloutAccessoryView setImage:nil];
    }
    
    return annotationView;
}

- (void) mapView:(MKMapView*)view annotationView:(MKAnnotationView*)annotationView calloutAccessoryControlTapped:(UIControl*)control
{
    GramAnnotation *gramAnnotation = annotationView.annotation;
    
    if ([[gramAnnotation.dictionary objectForKey:@"type"] isEqualToString:@"decode"])
    {
        [GramContext get]->decodeFromHistory = gramAnnotation.dictionary;
        [self performSegueWithIdentifier:@"detailSegue" sender:self];
    }
    else
    {
        [GramContext get]->encodeFromHistory = gramAnnotation.dictionary;
        [self performSegueWithIdentifier:@"generateSegue" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *current = @"history";
    
    if ([segue.identifier isEqualToString:@"detailSegue"])
    {
        NSLog(@"tether: %@ detailSegue", current);
        
        ReaderViewController *view = segue.destinationViewController;
        view.phase = current;
    }
    else if ([segue.identifier isEqualToString:@"generateSegue"])
    {
        NSLog(@"tether: %@ generateSegue", current);
        
        BarCodeViewController *view = segue.destinationViewController;
        view.phase = current;
    }
}

- (IBAction)tapChangeMode:(id)sender
{
    [self performSegueWithIdentifier:@"changeSegue" sender:self];
}

#pragma  mark - custom delegate

- (void)bannerIsInvisible
{
    NSLog(@"delegate bannerIsInvisible");
    [UIView beginAnimations:@"ad" context:nil];
    [self.mapView setFrame:CGRectMake(frame.origin.x,
                                        frame.origin.y,
                                        frame.size.width,
                                        frame.size.height - 93)];
    [UIView commitAnimations];
}

- (void)bannerIsVisible
{
    NSLog(@"delegate bannerIsVisible");
    [UIView beginAnimations:@"ad" context:nil];
    [self.mapView setFrame:CGRectMake(frame.origin.x,
                                        frame.origin.y,
                                        frame.size.width,
                                        frame.size.height - 93 - 49)];
    [UIView commitAnimations];
}

@end