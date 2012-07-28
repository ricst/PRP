//
//  PRPThirdViewController.h
//  PRP
//
//  Created by Richard Steinberger on 7/28/12.
//
//

#import <UIKit/UIKit.h>

@interface PRPThirdViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *myTextView;

@property (strong, nonatomic) NSString *textFileContents;

- (id)initWithNibName:(NSString *)nibNameOrNil andTextFile:(NSString *)textFile bundle:(NSBundle *)nibBundleOrNil;



@end
