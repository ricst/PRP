//
//  PRPReachabilityStatus.h
//  PRP
//
//  Created by Richard Steinberger on 8/5/12.
//
//

#import <Foundation/Foundation.h>

#define REACHABLE YES
#define NOT_REACHABLE NO

// Simple class designed to help objects know when Internet reachability is not present, and how long it's been since
// the last alert to the App user has been.
// reachabilityStatus: intended to be set by one object and read by multiple objects that need to test reachability
// August, 2012: Reachable => Internet reachable.  

@interface PRPReachabilityStatus : NSObject

@property BOOL reachabilityStatus;  // YES => last reported to be reachable
@property (nonatomic, strong) NSDate *lastAlertUpdate;  // To be updated whenever an object issues an alert

- (void)updateAlertTime;

@end
