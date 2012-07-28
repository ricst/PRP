//
//  TEXPAppDelegate.m
//  TabExperiment1
//
//  Created by Steinberger Richard on 6/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// test now in dev1.1

#import "TEXPAppDelegate.h"
#import "TEXPFirstViewController.h"
#import "TEXPSecondViewController.h"

#import "ParseJSON.h"
#import "SQLiteMgr.h"
#import "rhs_header_utils.h"

// 0 => enable debug logging. 1=> Disable debug logging
#define MyLog if(0); else NSLog

/*
  JSON dictionary keys:
 
    dataURL = the URL to the online SQLite3 PRP data file
    sql3_src_file_base = Basename of installed SQL3 PRP data file
    sql3_src_file_ext = Extension of installed SQL3 PRP data file
    syncMaxSecs = Max seconds we wait during a synch download
    tablename = the SQLite3 db tablename
 
 */

#define JSON_CFG_FILE_BASE @"PRP"
#define JSON_CFG_FILE_EXT @"json"

#define PRP_DOWNLOAD_FILENAME @"prpData.sql3"
#define PRP_FOLDER_NAME @"PRP_Folder"

#define SQL3_SRC_FILE_BASE "prp1_ref"
#define SQL3_SRC_FILE_EXT "sql3"

#define SQLITE_QUERY @"SELECT * FROM %@ ORDER BY name_sort ASC;"

#define BEGIN_HTML_WRAPPER @"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"> <html> <head> <link rel=\"stylesheet\" type=\"text/css\" href=\"sample.css\" /> <meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=no\" /> <body bgcolor=\"#fffcd2\"> </head> <body> <br /> <br />"
#define END_HTML_WRAPPER @"</body> </html>"

@implementation TEXPAppDelegate

@synthesize xmlParser = _xmlParser;
@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (NSURL *)installedDBFileURL
{
    //Installed SQL3 file should be in main bundle area
    NSBundle *mainBun = [NSBundle mainBundle];
    NSURL *url = [mainBun URLForResource:@SQL3_SRC_FILE_BASE withExtension:@SQL3_SRC_FILE_EXT]; 
    if (!url) {
        NSAssert1(0, @"Error locating installed PRP SQL3 file", [url path]);
    }
    return url;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    // Load PRP data from SQLite3 file and convert each entry to a to PRPDataItem
    // Open, read and parse file into one string per PRPDataItem.  Break up each record into an array of
    // elements/objects, as defined in PRPDataItem.h
    
    // Installed data is the PRP SQL3 file that is installed with the App.  We try to get the network data instead.
    
    // Turn on network activity indicator until we finish this method
    UIApplication *myApp = [UIApplication sharedApplication];
    myApp.networkActivityIndicatorVisible = YES;
    
    // Could read in some #defines data here

    ParseJSON *myJSONdata = [[ParseJSON alloc] init];
    [myJSONdata parseJsonCfgFile:JSON_CFG_FILE_BASE withExtension:JSON_CFG_FILE_EXT];
      
    BOOL shouldUseInstalledPRPData = NO;
    NSError *docError = nil;
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSURL *docsurl = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&docError];
    if (!docsurl) {
        shouldUseInstalledPRPData = YES;
        NSLog(@"Could not create a docs directory '%@'\nError: %@", docsurl, [docError localizedDescription]);
    }
    NSURL *prpFolderURL = [docsurl URLByAppendingPathComponent:PRP_FOLDER_NAME];
    docError = nil;
    BOOL folderCreateSuccess = [fm createDirectoryAtURL:prpFolderURL withIntermediateDirectories:YES attributes:nil error:&docError];
    if (!folderCreateSuccess) {
        shouldUseInstalledPRPData = YES;
        NSLog(@"Could not create a docs folder '%@'\nError: %@", prpFolderURL, [docError localizedDescription]);
    }
  
    NSURL *prpDataURL;
    if (!shouldUseInstalledPRPData) {
        // OK, let's try to download a current PRP data file and set ptr to it, if successful
        // We may find we fail here and must still use installed data.
        
        prpDataURL = [prpFolderURL URLByAppendingPathComponent:PRP_DOWNLOAD_FILENAME];
        
        // remove any old version before we download to this location.
        [fm removeItemAtURL:prpDataURL error:nil];
        
        // We expect a URL that contains a SQLite3 PRP file, probably on dropbox.com
        NSString *dataURL = [myJSONdata.deserializedDictionary objectForKey:@"dataURL"];
        NSURL *url = [NSURL URLWithString:dataURL];
        
        NSTimeInterval nst =  [(NSNumber *) [myJSONdata.deserializedDictionary objectForKey:@"syncMaxSecs"] doubleValue];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:nst];
        NSURLResponse *response = nil;
        NSError *error = nil;
        
        NSLog(@"Starting synchronous connection to: %@", url);
        NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        
        if ([data length] > 0 && error == nil) {
            // Need to trap Dropbox's download of error message file if actual file not present
            char test[100];
            [data getBytes:test length:100]; // look at about the first 100 bytes
            test[99] = '\0';                 // create null-terminated C string
            NSString *testStr = [NSString stringWithCString:test encoding:NSASCIIStringEncoding];
            NSRange nr = [testStr rangeOfString:@"html"];  //Dropbox error file is in html format
            if (nr.location != NSNotFound) {               // a match
                shouldUseInstalledPRPData = YES;
                MyLog(@"Dropbox error file downloaded: Not actual SQLite data!");
            } else {
                // Looks like good data, so write it out
                NSError *writeError = nil;
                BOOL writeOK = [data writeToURL:prpDataURL options:NSDataWritingAtomic error:&writeError];
                if (!writeOK) {
                    MyLog(@"Error writing file '%@'\nError: %@", prpDataURL, [writeError localizedDescription]);
                    shouldUseInstalledPRPData = YES;
                } else {
                    MyLog(@"Bytes downloaded: %lu to file %@", (unsigned long)[data length], [prpDataURL path]);
                }
            }
        } else if ([data length] == 0 && error == nil) {
            shouldUseInstalledPRPData = YES;
            MyLog(@"Nothing was downloaded.");
        } else if (error != nil) {
            // On any error, we should use the PRP data file that comes installed with the App.
            // Set that up here.
            shouldUseInstalledPRPData = YES;
            MyLog(@"Down error = %@", error);
        } else {
            MyLog(@"Should never get here.");
        }
        
        if (!shouldUseInstalledPRPData) { // If we successfully got good data
            MyLog(@"Finished download process with apparent success at: %@", [prpDataURL path]);
        }
    }
    
    // For whatever reason, we can't use network data, so use the installed file instead
    // prpDataURL points to either the just created network data file, or the installed file
    if (shouldUseInstalledPRPData)
        prpDataURL = [self installedDBFileURL];
    
    NSString *tablename = [myJSONdata.deserializedDictionary objectForKey:@"tablename"];
    SQLiteMgr *dbManager = [[SQLiteMgr alloc] initDatabaseWithURL:prpDataURL andTablename:tablename];
    NSError *err = [dbManager openDatabase];
    if (err) {
        NSAssert1(0, @"Could not open db: '%@'", prpDataURL);
    }

    NSString *sqlQuery = [NSString stringWithFormat:SQLITE_QUERY, tablename];
    
    // allPRPDataRows has the results of the query.  Can use later for search, if necessary
    NSArray *allPRPDataRows = [dbManager getRowsForQuery:sqlQuery];
    MyLog(@"Rows in PRP DB file: %i", [allPRPDataRows count]);
    
    // Prepare starings for display in a UIWebView
    NSString *webDisplayString = @"";
    NSString *mediaDisplayString = @"";
    NSString *blogDisplayString = @"";
    NSString *orgDisplayString = @"";
    NSString *forumDisplayString = @"";
    
    NSString *displayString;
    
    // Loop through each row of the PRP Data.  Build up display string for every category (web, mag, ...)
    NSString *str;
    for (NSArray *dataRecord in allPRPDataRows) {
                
        NSDictionary *dataDict = (NSDictionary *) dataRecord;
        str = @"";  
        
        // Format the Name, Description and URL(s)
        NSString *nameString = [dataDict objectForKey:@"name"];
        NSString *descString = [dataDict objectForKey:@"desc"];
        NSString *urlString = [dataDict objectForKey:@"url"];
        NSString *urlItunesString = [dataDict objectForKey:@"url_itunes"];
        NSString *urlAndroidString = [dataDict objectForKey:@"url_android"];
        
        // Name and description must be present.  URLs are optional. Length check to ignore blank entries.
        displayString = [str stringByAppendingFormat:@"<p><strong>%@ </strong> <br />%@ <br />", nameString, descString, nil];
 
        //Must check for both Null string and string long enough to be valid (i.e., not blank) - arbitrarily set to anything over 8
        for (NSString *uString in [NSArray arrayWithObjects:urlString, urlItunesString, urlAndroidString, nil]) {
            if ( ((NSNull *)uString != [NSNull null]) && ([uString length] > 8) ) 
                displayString = [displayString stringByAppendingFormat:@"%@ <br />", uString, nil];
        }
        
        displayString = [displayString stringByAppendingFormat:@"</p>"];

        // Non-zero => true
        // if a web site item
        unsigned int web = [(NSNumber *)[dataDict objectForKey:@"web"] unsignedIntValue];
        unsigned int med = [(NSNumber *) [dataDict objectForKey:@"med"] unsignedIntValue];
        unsigned int blog = [(NSNumber *) [dataDict objectForKey:@"blog"] unsignedIntValue];
        unsigned int org = [(NSNumber *) [dataDict objectForKey:@"org"] unsignedIntValue];
        unsigned int forum = [(NSNumber *) [dataDict objectForKey:@"forum"] unsignedIntValue];
        
        // If a web item
        if (web) {  
            webDisplayString = [webDisplayString stringByAppendingString:displayString];
        }
        
        // If a media item
        if (med) {
            mediaDisplayString = [mediaDisplayString stringByAppendingString:displayString];
        }
        
        // If a blogger
        if (blog) {
            blogDisplayString = [blogDisplayString stringByAppendingString:displayString];
        }
        
        // If an organization
        if (org) {
            orgDisplayString = [orgDisplayString stringByAppendingString:displayString];
        }
        
        // If a discussion forum
        if (forum) {
            forumDisplayString = [forumDisplayString stringByAppendingString:displayString];
        }
    }
    
    // Close the HTML Format string
        
    webDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:webDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    mediaDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:mediaDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    blogDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:blogDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    orgDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:orgDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    forumDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:forumDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    
    // Array object order must follow CONFIGARRAY #defines
    NSArray *configArrayController1 = [NSArray arrayWithObjects:@"Web", @"Web Resources", @"first", nil];
    NSArray *configArrayController3 = [NSArray arrayWithObjects:@"Media", @"Media Resources", @"first", nil];  // <-- UPDATE IMAGE
    NSArray *configArrayController4 = [NSArray arrayWithObjects:@"Blog", @"Blog Resources", @"first", nil];
    
    
    UIViewController *viewController1 = [[TEXPFirstViewController alloc] initWithNibName:@"TEXPFirstViewController" andData:webDisplayString andConfigArray:configArrayController1 bundle:nil];
    UIViewController *viewController2 = [[TEXPSecondViewController alloc] initWithNibName:@"TEXPSecondViewController" bundle:nil];
    UIViewController *viewController3 = [[TEXPFirstViewController alloc] initWithNibName:@"TEXPFirstViewController" andData:mediaDisplayString andConfigArray:configArrayController3 bundle:nil];
    UIViewController *viewController4 = [[TEXPFirstViewController alloc] initWithNibName:@"TEXPFirstViewController" andData:blogDisplayString andConfigArray:configArrayController4 bundle:nil];
    
    
    self.tabBarController = [[UITabBarController alloc] init];

    // Make the AppDelegate also the TabBarController delegate
    self.tabBarController.delegate = self;
    
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:viewController1, viewController2, viewController3, viewController4, nil];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    myApp.networkActivityIndicatorVisible = NO;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    //NFLog;

    // REALLY SHITTY CODE - Fix!
    // If ViewController is managing a WebView, reload that view to initial state
    // Just use the viewController parameter <-----
    UIViewController *v;
    int ivc = 1;
    for (v in self.tabBarController.viewControllers) {
        if (ivc == 1) {
            [(TEXPFirstViewController *) v loadInitialView];
        } else if (ivc == 3)
            [(TEXPFirstViewController *) v loadInitialView];
        else if (ivc == 4)
            [(TEXPFirstViewController *) v loadInitialView];
        ivc++;
    }
}


/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
