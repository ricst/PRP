//
//  NSObject+NSStringExtentions.m
//  PRP
//
//  Created by Steinberger Richard on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSObject+NSStringExtentions.h"

@implementation NSString (NSStringExtentions)

- (BOOL) containsString:(NSString *) string
                options:(NSStringCompareOptions) options {
    NSRange rng = [self rangeOfString:string options:options];
    return rng.location != NSNotFound;
}

- (BOOL) containsString:(NSString *) string {
    return [self containsString:string options:0];
}


@end
