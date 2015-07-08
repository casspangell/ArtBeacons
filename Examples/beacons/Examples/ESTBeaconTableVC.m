//
//  ESTBeaconTableVC.m
//  DistanceDemo
//
//  Created by Cass Pangell
//  7/7/15
//

#import "ESTBeaconTableVC.h"
#import "ESTViewController.h"

@interface ESTBeaconTableVC () <ESTBeaconManagerDelegate, ESTUtilityManagerDelegate> {
    int count;
    double mdiameter;
    double lWidth;
}
@end

@implementation ESTBeaconTableVC

- (id)initWithScanType:(ESTScanType)scanType completion:(void (^)(id))completion
{
    self = [super init];
    if (self)
    {
        self.scanType = scanType;
        self.completion = [completion copy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    self.utilityManager = [[ESTUtilityManager alloc] init];
    self.utilityManager.delegate = self;
    
    self.beaconDict = [NSMutableDictionary new];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    /* 
     * Creates sample region object (you can additionaly pass major / minor values).
     *
     * We specify it using only the ESTIMOTE_PROXIMITY_UUID because we want to discover all
     * hardware beacons with Estimote's proximty UUID.
     */
    self.region = [[CLBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                      identifier:@"EstimoteSampleRegion"];

    /*
     * Starts looking for Estimote beacons.
     * All callbacks will be delivered to beaconManager delegate.
     */
    if (self.scanType == ESTScanTypeBeacon)
    {
        [self startRangingBeacons];
    }
    else
    {
        [self.utilityManager startEstimoteBeaconDiscovery];
    }
}

-(void)startRangingBeacons
{
    if ([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        [self.beaconManager requestAlwaysAuthorization];
        [self.beaconManager startRangingBeaconsInRegion:self.region];
    }
    else if([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
    {
        [self.beaconManager startRangingBeaconsInRegion:self.region];
    }
    else if([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Access Denied"
                                                        message:@"You have denied access to location services. Change this in app settings."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        
        [alert show];
    }
    else if([ESTBeaconManager authorizationStatus] == kCLAuthorizationStatusRestricted)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Not Available"
                                                        message:@"You have no access to location services."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        
        [alert show];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    /*
     *Stops ranging after exiting the view.
     */
    [self.beaconManager stopRangingBeaconsInRegion:self.region];
    [self.utilityManager stopEstimoteBeaconDiscovery];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ESTBeaconManager delegate

- (void)beaconManager:(id)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:@"Ranging error"
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    [errorView show];
}

- (void)beaconManager:(id)manager monitoringDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:@"Monitoring error"
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    [errorView show];
}

- (void)beaconManager:(id)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    self.beaconsArray = beacons;
    NSArray *colors = [self getColors];
    
    for (int i=0; i<[self.beaconsArray count]; i++) {
        CLBeacon *beacon = [self.beaconsArray objectAtIndex:i];
        
        if (![self.beaconDict objectForKey:beacon.major]) {
            [self.beaconDict setObject:beacon forKey:[colors objectAtIndex:i]];
        }
        
    }
    
    [self updateBeacons];
}

- (void)utilityManager:(ESTUtilityManager *)manager didDiscoverBeacons:(NSArray *)beacons
{
    self.beaconsArray = beacons;

}

#pragma mark - Display Beacons

- (void)updateBeacons {
    
    CLBeacon __block *beacon = [CLBeacon new];
    
    int __block counter = 0;
    [self.beaconDict enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
        counter ++;
        beacon = obj;
        
        [self setDiameter:70.0];
        
        double locationX = ((self.view.frame.size.width/2)-(mdiameter/2));
        double locationY = ((self.view.frame.size.height))*beacon.accuracy;
        
        self.drawing = [[Bubble alloc] initWithFrame:CGRectMake(locationX, locationY, mdiameter, mdiameter) andDiameter:mdiameter andLineWidth:lWidth andColor:key];
        
        [self.view addSubview:self.drawing];
        
        self.drawing.alpha = 0;
        [UIView animateWithDuration:4 animations:^(void) {
            self.drawing.alpha = 1;
        }];
        
        [UIView animateWithDuration:beacon.accuracy*40 animations:^(void) {
            self.drawing.transform = CGAffineTransformMakeScale(4.5, 4.5);
            
        }];
        
        [UIView animateWithDuration:beacon.accuracy*40.0 animations:^(void) {
            self.drawing.alpha = 0;
        }];
        
    }];
    
}

-(void)setDiameter:(double)dmeter{
    mdiameter = dmeter;
}

-(double)getDiameter{
    return mdiameter;
}

-(NSArray*)getColors {
    NSMutableArray *colors = [NSMutableArray new];
    
    float INCREMENT = 0.1;
    for (float hue = 0.0; hue < 1.0; hue += INCREMENT) {
        UIColor *color = [UIColor colorWithHue:hue
                                    saturation:1.0
                                    brightness:1.0
                                         alpha:1.0];
        [colors addObject:color];
        
    }
    
    return colors;
}


@end
