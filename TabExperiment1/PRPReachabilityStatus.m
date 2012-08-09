//
//  PRPReachabilityStatus.m
//  PRP
//
//  Created by Richard Steinberger on 8/5/12.
//
//

#import "PRPReachabilityStatus.h"

// 0 => enable debug logging. 1=> Disable debug logging
#define MyLog if(0); else NSLog

@implementation PRPReachabilityStatus

@synthesize reachabilityStatus = _reachabilityStatus;
@synthesize lastAlertUpdate = _lastAlertUpdate;

- (PRPReachabilityStatus *) init {
    self = [super init];

    // Class specific stuff below
    if (self != nil) {
        self.lastAlertUpdate = [[NSDate date] initWithTimeIntervalSinceNow:(NSTimeInterval) (-10*60.0)]; //init to 10 minutes ago
        
        MyLog(@"Setting lastAlertUpdate to %@\n", self.lastAlertUpdate);
    }
    
    return self;
}

// Setter & Getter overrides - for debugging.

- (void) setReachabilityStatus:(BOOL) state {
    _reachabilityStatus = state;
    
    MyLog(@"PRPReachabilityStatus object setter: reachabilityStatus = %@\n", _reachabilityStatus ? @"REACHABLE" : @"NOT REACHABLE");
}

- (BOOL) reachabilityStatus {
    MyLog(@"PRPReachabilityStatus object getter: reachabilityStatus = %@\n", _reachabilityStatus ? @"REACHABLE" : @"NOT REACHABLE");
    
    return _reachabilityStatus;
}

// If an alert is issued, object should also call this method to reset the time of the most recent alert
// so each object monitoring reachability doesn't issue an alert too close in time to the last alert.
// It is assumed that only lack of reachability would lead to the issuing of an alert.
- (void) updateAlertTimeToNow {
    self.lastAlertUpdate = [NSDate date];
}

@end
