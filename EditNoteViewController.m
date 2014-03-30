//
//  EditNoteViewController.m
//  iVerb
//
//  Created by Maxime Leroy on 4/2/13.
//
//

#import "EditNoteViewController.h"

#import "UIBarButtonItem+addition.h"

@interface EditNoteViewController ()

- (IBAction)cancelAction:(id)sender;
- (IBAction)doneAction:(id)sender;

@end

@implementation EditNoteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString * nibName = (TARGET_IS_IPAD())? @"EditNoteViewController_Pad" : @"EditNoteViewController_Phone";
    if ((self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]])) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDefault target:self action:@selector(cancelAction:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDefault target:self action:@selector(doneAction:)];
	
	self.title = [NSString stringWithFormat:@"To %@", _verb.infinitif];
	
	_textView.text = _verb.note;
	[_textView becomeFirstResponder];
}

- (void)setVerb:(Verb *)verb
{
	_verb = verb;
	
	self.title = _verb.infinitif;
	_textView.text = _verb.note;
}

- (IBAction)cancelAction:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)doneAction:(id)sender
{
	NSString * note = _textView.text;
	NSString * key = [NSString stringWithFormat:@"note_%@", _verb.infinitif];
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if ([note stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0)
		[userDefaults setObject:_textView.text forKey:key];
	else
		[userDefaults removeObjectForKey:key];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResultDidReloadNotification" object:nil];
	
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (NSUInteger)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
