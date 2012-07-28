//
//  ParseJSON.h
//  PRP
//
//  Created by Steinberger Richard on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ParseJSON : NSObject

@property (nonatomic, strong) NSDictionary *deserializedDictionary;
@property (nonatomic, strong) NSArray *deserializedArray;

- (void) parseJsonCfgFile:(NSString *)base withExtension:(NSString *)ext;

@end
