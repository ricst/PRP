//
//  NSObject+NSStringExtentions.h
//  PRP
//
//  Created by Steinberger Richard on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// From: http://stackoverflow.com/questions/3293499/detecting-if-an-nsstring-contains

#import <Foundation/Foundation.h>

@interface NSString (NSStringExtentions)

- (BOOL) containsString:(NSString *) string;
- (BOOL) containsString:(NSString *) string
                options:(NSStringCompareOptions) options;

@end
