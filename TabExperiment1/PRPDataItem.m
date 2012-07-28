//
//  PRPDataItem.m
//  TabExperiment1
//
//  Created by Steinberger Richard on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PRPDataItem.h"
#import "rhs_header_utils.h"

@implementation PRPDataItem

@synthesize nameString = _nameString;
@synthesize nameSortString = _nameSortString;
@synthesize web = _web;
@synthesize med = _med;
@synthesize org = _org;
@synthesize blog = _blog;
@synthesize forum = _forum;
@synthesize descString = _descString;
@synthesize urlString = _urlString;
@synthesize urlItunesString = _urlItunesString;
@synthesize urlAndroidString = _urlAndroidString;

// Initialize a single PRPDataItem Object: Deep copy
- (id)initPRPDataItemFromRecord:(NSArray *) prpItemsArray
{
    self = [super init];
    if (!self)
        return self;
    
    self->_nameString = [(NSString *) [prpItemsArray objectAtIndex:PRPITEM_NAME_INDEX] copy];
    self->_nameSortString = [(NSString *) [prpItemsArray objectAtIndex:PRPITEM_NAME_SORT_INDEX] copy];
    self->_web = [[prpItemsArray objectAtIndex:PRPITEM_WEB_INDEX] copy];
    self->_med = [[prpItemsArray objectAtIndex:PRPITEM_MED_INDEX] copy];
    self->_org = [[prpItemsArray objectAtIndex:PRPITEM_ORG_INDEX] copy];
    self->_blog = [[prpItemsArray objectAtIndex:PRPITEM_BLOG_INDEX] copy];
    self->_forum = [[prpItemsArray objectAtIndex:PRPITEM_FORUM_INDEX] copy];
    self->_descString = [(NSString *) [prpItemsArray objectAtIndex:PRPITEM_DESC_INDEX] copy];
    self->_urlString = [(NSString *) [prpItemsArray objectAtIndex:PRPITEM_URL_INDEX] copy];
    self->_urlItunesString = [(NSString *) [prpItemsArray objectAtIndex:PRPITEM_URL_ITUNES_INDEX] copy];
    self->_urlAndroidString = [(NSString *) [prpItemsArray objectAtIndex:PRPITEM_URL_ANDROID_INDEX] copy];
       
    return self;  
}

@end
