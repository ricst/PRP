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
#import "PRPThirdViewController.h"

#import "PRPReachabilityStatus.h"
#import "NSObject+NSStringExtentions.h"

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

#define SQLITE_QUERY @"SELECT * FROM %@ ORDER BY name_sort COLLATE NOCASE ASC;"

/* #define BEGIN_HTML_WRAPPER @"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"> <html> <head> <link rel=\"stylesheet\" type=\"text/css\" href=\"sample.css\" /> <meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=no\" /> <body bgcolor=\"#fffcd2\"> </head> <body> <br /> <br />"
 */

/* #define BEGIN_HTML_WRAPPER @"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"> <html> <head> <link rel=\"stylesheet\" type=\"text/css\" href=\"sample.css\" /> <meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=no\" /> <body bgcolor=\"#fffcd2\"> </head> <body> <div style=\"font-size:26px\" \"text-align:center\">Progressive Resource Portal</div>"
*/

/* #define BEGIN_HTML_WRAPPER @"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"> <html> <head> <link rel=\"stylesheet\" type=\"text/css\" href=\"sample.css\" > <meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=no\" >  <style type=\"text/css\" rel=\"stylesheet\"> .resetcss {margin: 0; padding: 0; border: 0; } </style> </head> <body bgcolor=\"#fffcd2\"> <p style=\"font-size:26px; text-align:center; margin: 0.25em auto\">Progressive Resource Portal</p>" */

#define BEGIN_HTML_WRAPPER @"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"> <html> <head> <meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"> <meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=no\"> <title>PRP</title>  <style type=\"text/css\"> .resetcss {margin: 0; padding: 0; border: 0; } </style> </head> <body bgcolor=\"#fffcd2\"> <p style=\"font-size:26px; text-align:center; margin: 0.25em auto\" class=\"resetcss\">Progressive Resource Portal</p>"

#define END_HTML_WRAPPER @"</body> </html>"
 
// Check for Internet Reachability at periodic intervals of this many seconds
// Except for testing, we want no less than 60.0
#define TIME_INTERVAL_FOR_INTERNET_CHECK 60.0
// Timeout for Internet access (must have valid connection & data within this many seconds, or else NOT REACHABLE)
#define INTERNET_CHECK_TIMEOUT 5.0f

//Global variables 
//PRPReachabilityStatus *internetState;

@implementation TEXPAppDelegate

@synthesize xmlParser = _xmlParser;
@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

@synthesize myTimer = _myTimer;

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
    
    //internetState = [[PRPReachabilityStatus alloc] init];
    PRPReachabilityStatus *internetState = [PRPReachabilityStatus sharedStatus];
    
    //check for Internet reachability periodically
    self.myTimer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL_FOR_INTERNET_CHECK target:self selector:@selector(checkInternetConnection) userInfo:nil repeats:YES];
    
    // Could read in some #defines data here

    ParseJSON *myJSONdata = [[ParseJSON alloc] init];
    [myJSONdata parseJsonCfgFile:JSON_CFG_FILE_BASE withExtension:JSON_CFG_FILE_EXT];
      
    BOOL shouldUseInstalledPRPData = NO;
    NSError *docError = nil;
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSURL *docsurl = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&docError];
    if (!docsurl) {
        shouldUseInstalledPRPData = YES;
        MyLog(@"Could not create a docs directory '%@'\nError: %@", docsurl, [docError localizedDescription]);
    }
    NSURL *prpFolderURL = [docsurl URLByAppendingPathComponent:PRP_FOLDER_NAME];
    docError = nil;
    BOOL folderCreateSuccess = [fm createDirectoryAtURL:prpFolderURL withIntermediateDirectories:YES attributes:nil error:&docError];
    if (!folderCreateSuccess) {
        shouldUseInstalledPRPData = YES;
        MyLog(@"Could not create a docs folder '%@'\nError: %@", prpFolderURL, [docError localizedDescription]);
    }
        
    NSURL *prpDataURL;
    if (!shouldUseInstalledPRPData) {
        // OK, let's try to download a current PRP data file and set ptr to it, if successful
        // We may find we fail here and must still use installed data.
        
        prpDataURL = [prpFolderURL URLByAppendingPathComponent:PRP_DOWNLOAD_FILENAME];
        
        // remove any old version before we download to this location.
        [fm removeItemAtURL:prpDataURL error:nil];
        
        // We expect a URL that contains a SQLite3 PRP file, on dropbox.com in RHS's Public folder
        NSString *dataURL = [myJSONdata.deserializedDictionary objectForKey:@"dataURL"];
        NSURL *url = [NSURL URLWithString:dataURL];
        
        NSTimeInterval nst =  [(NSNumber *) [myJSONdata.deserializedDictionary objectForKey:@"syncMaxSecs"] doubleValue];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:nst];
        NSURLResponse *response = nil;
        NSError *error = nil;
    
        // Initialize reachability to NOT REACHABLE.  Update state as we learn more...
        // If we successfully download the PRP SQL3 data from the internet (Dropbox), we set internet reachability to REACHABLE
        internetState.reachabilityStatus = NOT_REACHABLE;
        
        // Try to download the SQL3 PRP data file
        MyLog(@"Starting synchronous connection to: %@", url);
        NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        
        if ([data length] > 0 && error == nil) {
            // Need to trap Dropbox's download of error message file if actual file not present
            char test[100];
            [data getBytes:test length:100]; // look at about the first 100 bytes
            test[99] = '\0';                 // create null-terminated C string
            NSString *testStr = [NSString stringWithCString:test encoding:NSASCIIStringEncoding];
            NSRange nr = [testStr rangeOfString:@"html"];  //Dropbox error file is in html format [SQL3 db file would not have this]
            if (nr.location != NSNotFound) {               // a match - found "html"
                shouldUseInstalledPRPData = YES;
                MyLog(@"Dropbox error file downloaded: Not actual SQLite data!");
            } else {
                // Looks like good data from the PRP file, so write it out and update reachable state
                internetState.reachabilityStatus = REACHABLE;
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
    NSString *otherDisplayString = @"";
    
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
        displayString = [str stringByAppendingFormat:@"<p><strong>%@ </strong> <br>%@ <br>", nameString, descString, nil];
 
        //Must check for both Null string and string long enough to be valid (i.e., not blank) - arbitrarily set to anything over 8
        for (NSString *uString in [NSArray arrayWithObjects:urlString, urlItunesString, urlAndroidString, nil]) {
            if ( ((NSNull *)uString != [NSNull null]) && ([uString length] > 8) ) 
                displayString = [displayString stringByAppendingFormat:@"%@ <br>", uString, nil];
        }
        
        displayString = [displayString stringByAppendingFormat:@"</p>"];

        // Non-zero => true
        // if a web site item
        unsigned int web = [(NSNumber *)[dataDict objectForKey:@"web"] unsignedIntValue];
        unsigned int med = [(NSNumber *) [dataDict objectForKey:@"med"] unsignedIntValue];
        unsigned int blog = [(NSNumber *) [dataDict objectForKey:@"blog"] unsignedIntValue];
        unsigned int org = [(NSNumber *) [dataDict objectForKey:@"org"] unsignedIntValue];
        unsigned int other = [(NSNumber *) [dataDict objectForKey:@"other"] unsignedIntValue];
        
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
        
        // If other (as yet, undefined, undisplayed)
        if (other) {
            otherDisplayString = [otherDisplayString stringByAppendingString:displayString];
        }
    }
    
    // Close the HTML Format string
        
    webDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:webDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    mediaDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:mediaDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    blogDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:blogDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    orgDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:orgDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    otherDisplayString = [[BEGIN_HTML_WRAPPER stringByAppendingString:otherDisplayString] stringByAppendingString:END_HTML_WRAPPER];
    
    // Array object order must follow CONFIGARRAY #defines
    NSArray *configArrayController1 = [NSArray arrayWithObjects:@"Web", @"Web Resources", @"first", internetState, nil];
    NSArray *configArrayController2 = [NSArray arrayWithObjects:@"Media", @"Media Resources", @"first", internetState, nil];  //
    NSArray *configArrayController3 = [NSArray arrayWithObjects:@"Blog", @"Blog Resources", @"first", internetState, nil];
    NSArray *configArrayController4 = [NSArray arrayWithObjects:@"Org", @"Org Resources", @"first", internetState, nil];
    //NSArray *configArrayController6 = [NSArray arrayWithObjects:@"Other", @"Other Resources", @"first", nil];
    
    NSString *readmeFileBasename = [myJSONdata.deserializedDictionary objectForKey:@"readme_file_base"];
    NSString *readmeFileExt = [myJSONdata.deserializedDictionary objectForKey:@"readme_file_ext"];
    
     NSString *readmeFilePath = [[NSBundle mainBundle] pathForResource:readmeFileBasename ofType:readmeFileExt];
     if (!readmeFilePath) {
         NSAssert1(0, @"Error locating README text file", readmeFilePath);
        }
    // NSString *contents = [NSString stringWithContentsOfFile:readmeFilePath encoding:NSUTF8StringEncoding error:nil];
    
    UIViewController *viewController1 = [[TEXPFirstViewController alloc] initWithNibName:@"TEXPFirstViewController" andData:webDisplayString andConfigArray:configArrayController1 bundle:nil];
    UIViewController *viewController2 = [[TEXPFirstViewController alloc] initWithNibName:@"TEXPFirstViewController" andData:mediaDisplayString andConfigArray:configArrayController2 bundle:nil];
    UIViewController *viewController3 = [[TEXPFirstViewController alloc] initWithNibName:@"TEXPFirstViewController" andData:blogDisplayString andConfigArray:configArrayController3 bundle:nil];
    UIViewController *viewController4 = [[TEXPFirstViewController alloc] initWithNibName:@"TEXPFirstViewController" andData:orgDisplayString andConfigArray:configArrayController4 bundle:nil];
    
    // View Controller for the Readme file
    
    UIViewController *viewController5 = [[PRPThirdViewController alloc] initWithNibName:@"PRPThirdViewController" andTextFile:readmeFilePath bundle:nil];
    
    
    self.tabBarController = [[UITabBarController alloc] init];

    // Make the AppDelegate also the TabBarController delegate
    self.tabBarController.delegate = self;
    
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:viewController1, viewController2, viewController3, viewController4, viewController5, nil];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    myApp.networkActivityIndicatorVisible = NO;
    
    
    return YES;
}

// Reachability was not working properly.  Let's just check for www.apple.com
// Async download will set results
- (void) checkInternetConnection {
    
    MyLog(@"checkInternetConnection: checking reachability to www.apple.com.....");
    NSURL *url = [NSURL URLWithString:@"http://www.apple.com"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:INTERNET_CHECK_TIMEOUT];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) 
    {
        BOOL reach;
        if ([data length] > 0 && error == nil) {
            //MyLog(@"checkInternetStatus: Got received: %u bytes", [data length]);
            char test[500];
            [data getBytes:test length:500]; // look at about the first 500 bytes
            test[499] = '\0';                 // create null-terminated C string
            NSString *testStr = [NSString stringWithCString:test encoding:NSASCIIStringEncoding];
            if ([testStr containsString:@"Apple Inc."]) {
                // Got to Apple web site => Internet access OK
                MyLog(@"Got %u bytes from www.apple.com.", [data length]);
                reach = REACHABLE;
            } else {
                MyLog(@"Oops: downloaded string didn't contain 'Apple Inc.'");
            }
        } else if ([data length] == 0 && error == nil){
            // Internet access probably NOT OK
            MyLog(@"Nothing downloaded from www.Apple.com");
        } else if (error != nil) {
            // Internet access NOT OK
            MyLog(@"Error on download from www.apple.com: %@", error);
        } else {
            MyLog(@"checkInternetConnectivity: should never get here");
        }
        
        if (reach == REACHABLE) {
            //[internetState setReachabilityStatus:REACHABLE];
            [[PRPReachabilityStatus sharedStatus] setReachabilityStatus:REACHABLE];
            MyLog(@"checkInternetConnection: Internet is REACHABLE. *****\n\n");
        } else {
            //[internetState setReachabilityStatus:NOT_REACHABLE];
            [[PRPReachabilityStatus sharedStatus] setReachabilityStatus:NOT_REACHABLE];
            MyLog(@"checkInternetConnection: Internet is NOT REACHABLE *****\n\n");
        }
    }];
    
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
    // We don't need this logic, so just do nothing (;) for now:
    // ***************
        if ([viewController.nibName isEqualToString:@"TEXPFirstViewController"])
            ;//  [(TEXPFirstViewController *) viewController loadInitialView];
}


/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
