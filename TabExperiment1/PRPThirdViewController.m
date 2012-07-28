//
//  PRPThirdViewController.m
//  PRP
//
//  Created by Richard Steinberger on 7/28/12.
//
//
// Intended to display the README file

#import "PRPThirdViewController.h"

@interface PRPThirdViewController ()

@end

@implementation PRPThirdViewController

@synthesize myTextView = _myTextView;
@synthesize textFileContents = _textFileContents;

// Init method when a text file (to be displayed) is supplied
- (id)initWithNibName:(NSString *)nibNameOrNil andTextFile:(NSString *)textFile bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSError *err;
        self.textFileContents = [NSString stringWithContentsOfFile:textFile encoding:NSUTF8StringEncoding error:&err];
        if (!self.textFileContents) {
            NSAssert1(0, @"Could not access contents of README file %@", textFile);
        }
        
        self.title = NSLocalizedString(@"Readme", @"Readme");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.myTextView.text = self.textFileContents;
}

- (void)viewDidUnload
{
    [self setMyTextView:nil];
    [self setMyTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
