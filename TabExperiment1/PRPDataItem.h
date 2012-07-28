//
//  PRPDataItem.h
//  TabExperiment1
//
//  Created by Steinberger Richard on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRPDataItem : NSObject

// PRPDataItem - The basic object

// itemName, cats, desc, url, urlItunes, urlAndroid
// All properties to be set in init()

// PRP Table schema: name, name_sort, [web, med, org, blog, forum] (<- all int), desc, url, url_itunes, url_android

#define PRPITEM_NAME_INDEX 0
#define PRPITEM_NAME_SORT_INDEX 1
#define PRPITEM_WEB_INDEX 2
#define PRPITEM_MED_INDEX 3
#define PRPITEM_ORG_INDEX 4
#define PRPITEM_BLOG_INDEX 5
#define PRPITEM_FORUM_INDEX 6
#define PRPITEM_DESC_INDEX 7
#define PRPITEM_URL_INDEX 8
#define PRPITEM_URL_ITUNES_INDEX 9
#define PRPITEM_URL_ANDROID_INDEX 10

@property (nonatomic, readonly) NSString *nameString;
@property (nonatomic, readonly) NSString *nameSortString;
@property (nonatomic, readonly) NSNumber *web;
@property (nonatomic, readonly) NSNumber *med;
@property (nonatomic, readonly) NSNumber *org;
@property (nonatomic, readonly) NSNumber *blog;
@property (nonatomic, readonly) NSNumber *forum;
@property (nonatomic, readonly) NSString *descString;
@property (nonatomic, readonly) NSString *urlString;
@property (nonatomic, readonly) NSString *urlItunesString;
@property (nonatomic, readonly) NSString *urlAndroidString;


- (id)initPRPDataItemFromRecord: (NSArray *) prpItemsArray;

@end
