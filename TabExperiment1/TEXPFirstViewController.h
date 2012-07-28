//
//  TEXPFirstViewController.h
//  TabExperiment1
//
//  Created by Steinberger Richard on 6/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

// configArray offsets for initWithNibName:andData:andConfigArray:bundle
#define CONFIGARRAY_NSLOC_KEY_INDEX 0
#define CONFIGARRAY_NSLOC_COMMENT_INDEX 1
#define CONFIGARRAY_IMAGENAME_INDEX 2

@interface TEXPFirstViewController : UIViewController <UIGestureRecognizerDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate>

// could probably make these IBOutlets private
@property (weak, nonatomic) IBOutlet UIToolbar *myToolbar;
@property (weak, nonatomic) IBOutlet UIWebView *webView1;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;

- (IBAction)mail:(id)sender;
- (IBAction)reloadButton:(id)sender;
- (IBAction)goBackButton:(id)sender;
- (IBAction)goForwardButton:(id)sender;
- (IBAction)stopLoadingButton:(id)sender;

@property (nonatomic, copy) NSString *dataAsHTML;
@property (nonatomic) BOOL isOnTopPage;
@property (nonatomic, copy) NSString *currentURL;
@property (nonatomic) CGPoint myContentOffset;

- (void)displayMailComposerSheet;
- (void)loadInitialView;
- (id)initWithNibName: (NSString *)nibNameOrNil andData: (id)theData andConfigArray: (NSArray *)configArray bundle: (NSBundle *)nibBundleorNil;

@end
