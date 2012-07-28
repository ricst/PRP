//
//  TEXPAppDelegate.h
//  TabExperiment1
//
//  Created by Steinberger Richard on 6/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface TEXPAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
{
      
}

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end
