//
//  TEXPFirstViewController.m
//  TabExperiment1
//
//  Created by Steinberger Richard on 6/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "rhs_header_utils.h"
#import "TEXPFirstViewController.h"

//#import "PRPData.h"

@interface TEXPFirstViewController ()

@end

@implementation TEXPFirstViewController

@synthesize myToolbar = _myToolbar;
@synthesize dataAsHTML = _dataAsHTML;
@synthesize activity = _activity;
@synthesize isOnTopPage = _isOnTopPage;
@synthesize currentURL = _currentURL;
@synthesize myContentOffset = _myContentOffset;

@synthesize webView1 = _webView1;

// Top Toolbar and buttons added to UIWebView, as explained here: http://www.youtube.com/watch?v=lzJVDjBCtLk 

// An init method that allows passing in data and config details
- (id)initWithNibName: (NSString *)nibNameOrNil andData: (id)theData andConfigArray: (NSArray *)configArray bundle: (NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.dataAsHTML = theData;
        self.myContentOffset = CGPointZero;
        self.isOnTopPage = YES;

        self.title = NSLocalizedString([configArray objectAtIndex:CONFIGARRAY_NSLOC_KEY_INDEX], [configArray objectAtIndex:CONFIGARRAY_NSLOC_COMMENT_INDEX]);
        self.tabBarItem.image = [UIImage imageNamed:[configArray objectAtIndex:CONFIGARRAY_IMAGENAME_INDEX]];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"All", @"All Resources");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}

#define testType 3
- (void)loadInitialView
{
    // Just a test: See if we can load a sample HTML file
    if (testType == 1) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"someHTML" ofType:@"html"];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [self.webView1 loadRequest:[NSURLRequest requestWithURL:fileURL]];
    } else if (testType == 3) {
        self.myToolbar.hidden = YES;
        
        self.webView1.scrollView.contentOffset = self.myContentOffset;
        //NSLog(@"loadInitialView: contentOffset set to (%f, %f)", self.myContentOffset.x, self.myContentOffset.y);

        [self.webView1 loadHTMLString:self.dataAsHTML baseURL:nil];
        self.isOnTopPage = YES;
        
        // Allow for UIWebViewDelegate
        self.webView1.delegate = self;
        
    }
}

//hide or show myToolbar
- (void)hideShowToolbarView
{
    //NSLog(@"Gesture recognizer triggered: hideShowToolbarView hit");
    if (self.myToolbar.hidden == NO) {
        self.myToolbar.hidden = YES;
    } else {
        self.myToolbar.hidden = NO;
    }
}

// Added overload method
- (void)viewWillAppear:(BOOL)animated
{
    self.myToolbar.hidden = YES;
    [super viewWillAppear:animated];
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //self.myToolbar.hidden = YES;
    [self loadInitialView];

    UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideShowToolbarView)];
    gest.numberOfTapsRequired = 1;
    gest.numberOfTouchesRequired = 2;
    gest.delegate = self;
    [self.webView1 addGestureRecognizer:gest];
}

- (void)viewDidUnload
{
    [self setWebView1:nil];
    [self setMyToolbar:nil];
    [self setMyToolbar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark gestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark UIWebView delegate

// Methods to start/stop activity indicator
- (void)webViewDidStartLoad:(UIWebView *)wv
{
    [self.activity startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv
{
    [self.activity stopAnimating];
    if (self.isOnTopPage) {
        self.webView1.scrollView.contentOffset = self.myContentOffset;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.activity stopAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //Get most recently clicked URL
    
    NSURL *url = [request URL];
    
    // If we don't have an http or https URL (e.g., we have a link to the App Store), the see if the device can open the URL
    // Code from: http://goo.gl/eNHrk  If "Fame Load Interrupted" appears, this link has additional code
    if (![url.scheme isEqual:@"http"] && ![url.scheme isEqual:@"https"]) {
        if ([[UIApplication sharedApplication]canOpenURL:url]) {
            [[UIApplication sharedApplication]openURL:url];
            return NO;
        }
    }
    
    // approach to get top page content string  
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        //NSLog(@"Request URL: %@", [url absoluteString]);
        self.currentURL = [url absoluteString];
    }
    
    if (self.isOnTopPage && (navigationType == UIWebViewNavigationTypeLinkClicked)) {
        self.isOnTopPage = NO; //clicked any link; now not on top page
                               // self.myContentOffset = self.webView1.scrollView.contentOffset;
        self.myContentOffset = webView.scrollView.contentOffset;
        //NSLog(@"webView:should contentOffset set to (%f, %f)", webView.scrollView.contentOffset.x, webView.scrollView.contentOffset.y);
    }
    return YES;
}

// ********************************** //

- (IBAction)mail:(id)sender 
{
    //NSLog(@"Mail button tapped");
    
    // If we cannot send email, popup an alert view message and return
    if (![MFMailComposeViewController canSendMail]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"No Email Capability" message:@"This device cannot send email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
        return;
    }
    
    // Use the  presentViewController:animated:completion:  method to set up MFMailComposerViewController to send the page URL (or content, if top page)
    [self displayMailComposerSheet];
}

#pragma mark Mail Processing

- (void)displayMailComposerSheet
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    [picker setSubject:@"Progressive Resource Portal"];
    
    // Fill out the email body text
    NSString *emailBody;
    
    // If on Top page, send entire page; otherwise, just send the URL
    if (self.isOnTopPage) {
        emailBody = self.dataAsHTML;
    } else {
        emailBody = self.currentURL;
    }

    [picker setMessageBody:emailBody isHTML:YES];
    [self presentModalViewController:picker animated:YES];

}

// Use delegate to dismiss mail composition view controller
- (void)mailComposeController:(MFMailComposeViewController*)controller 
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    // At some point, maybe confirm sending or cancel of email
    
    [self dismissModalViewControllerAnimated:YES];
}

@end
