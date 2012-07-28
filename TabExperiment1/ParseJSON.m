//
//  ParseJSON.m
//  PRP
//
//  Created by Steinberger Richard on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ParseJSON.h"

// 0 => enable debug logging. 1=> Disable debug logging
#define MyLog if(0); else NSLog

@implementation ParseJSON

@synthesize deserializedDictionary = _deserializedDictionary;
@synthesize deserializedArray = _deserializedArray;

- (id)init {
    self = [super init];
    // Custom init code goes here
    return self;
}

- (void) parseJsonCfgFile:(NSString *)base withExtension:(NSString *)ext {

    NSURL *jsonURL = [[NSBundle mainBundle] URLForResource:base withExtension:ext];
    NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
    if (!jsonData) {
        NSAssert1(0, @"Could not read JSON data from: %@", [jsonURL path]);
    }
    NSError *jsonError = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&jsonError];
    
    if (jsonObject != nil && jsonError == nil) {
        MyLog(@"JSON Object deserialized...");
        if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            self.deserializedDictionary = (NSDictionary *)jsonObject;
            MyLog(@"Deserialized JSON dictionary: %@", self.deserializedDictionary);
        } 
        else if ([jsonObject isKindOfClass:[NSArray class]]) {
            self.deserializedArray = (NSArray *)jsonObject;
            MyLog(@"Deserialized JSON Array: %@", self.deserializedArray);
        }
        else {
            //Some other object, but JSON only should have dictionaroes and/or arrays
            NSAssert(0, @"JSON data type error");
        }
    } else {
        NSAssert1(0, @"ParseJSON no daat or error: %@", [jsonError localizedDescription]);
    }
    
}

@end
