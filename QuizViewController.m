//
//  QuizViewController.m
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import "QuizViewController.h"

//#import "UIBarButtonItem+addition.h"

@interface QuizViewController ()

- (void)start;

- (void)pushView:(UIView *)view animated:(BOOL)animated;

- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated;

@end

@implementation QuizViewController

@synthesize quizView = _quizView, responseView = _responseView, resultView = _resultView;

@synthesize infinitifLabel = _infinitifLabel, formLabel = _formLabel, remainingCount = _remainingCount;
@synthesize textField = _textField;
@synthesize backgroundFieldImageView = _backgroundFieldImageView;

@synthesize responseImageView = _responseImageView;
@synthesize responseLabel = _responseLabel;

@synthesize goodResponseCountLabel = _goodResponseCountLabel, badResponseCountLabel = _badResponseCountLabel;

@synthesize playlist = _playlist;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString * nibName = (TARGET_IS_IPAD())? @"QuizViewController_Pad" : @"QuizViewController_Phone";
    if ((self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]])) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	//self.navigationController.delegate = self;
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelAction:)];
	
	// @TODO: add a "Details" button on result to show a liste with good and bad responses
	
	self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.];
	
	allVerbs = self.playlist.verbs.allObjects;
	
	_textField.delegate = self;
	_backgroundFieldImageView.image = [[UIImage imageNamed:@"quiz-field"] stretchableImageWithLeftCapWidth:25. topCapHeight:0.];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textFieldDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:nil];
	
	[self start];
	
	if (!TARGET_IS_IPAD()) {
        /* Disallow the landscape mode of the application */
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	}
}

- (IBAction)cancelAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
	
	if (!TARGET_IS_IPAD()) {
        /* Re-allow the landscape mode of the application */
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	}
}

- (IBAction)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
	
	if (!TARGET_IS_IPAD()) {
        /* Re-allow the landscape mode of the application */
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	}
}

- (IBAction)skipAction:(id)sender
{
	[self pushNewVerbAction:sender];
}

- (void)start
{
	BOOL animated = (goodResponseCount > 0 || badResponseCount > 0);// Don't animate the first try
	
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                            target:self
                                                                                            action:@selector(cancelAction:)]
                                     animated:animated];
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Skip"
                                                                                style:UIBarButtonItemStylePlain
                                                                               target:self
                                                                               action:@selector(skipAction:)]
                                      animated:animated];
	
	goodResponseCount = 0, badResponseCount = 0;
	
	currentIndex = 0;
	Verb * verb = allVerbs[0];
	[self pushVerb:verb form:VerbFormPastSimple animated:animated];
}

- (void)pushView:(UIView *)view animated:(BOOL)animated
{
	/* "Pop" the previous pushed view (if exists) */
	if (previousPushedView) {
		CGRect frame = previousPushedView.frame;
		frame.origin.x = 0;
		previousPushedView.frame = frame;
		
		[UIView animateWithDuration:(animated)? 0.25 : 0.
						 animations:^{
							 CGRect frame = previousPushedView.frame;
							 frame.origin.x = -self.view.frame.size.width;
							 previousPushedView.frame = frame;
						 }];
	}
	
	/* Push the new view */
	CGRect frame = view.frame;
	frame.origin.x = self.view.frame.size.width;
	view.frame = frame;
	
	/* If "view" have been hidden, just re-show it, else add it to the main view */
	(view.hidden) ? (view.hidden = NO) : [self.view addSubview:view];
	
	[UIView animateWithDuration:(animated)? 0.25 : 0.
					 animations:^{
						 CGRect frame = view.frame;
						 frame.origin.x = 0.;
						 view.frame = frame;
					 }
					 completion:^(BOOL finished) {
						 //[previousPushedView removeFromSuperview];
						 previousPushedView.hidden = YES;
						 previousPushedView = view;
					 }];
}

#pragma mark Next Verb Management

- (IBAction)pushNewVerbAction:(id)sender
{
	currentIndex++;
	if (currentIndex < allVerbs.count) {// If we have verb to show, push the next verb
		Verb * verb = allVerbs[currentIndex];
		
		VerbForm form = (rand() % 2)? VerbFormPastSimple : VerbFormPastParticiple;
		[self pushVerb:verb form:form animated:YES];
		
	} else {// Else, show results
		[self pushResultAnimated:YES];
	}
}

- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated
{
	self.title = [NSString stringWithFormat:@"%ld / %ld", (unsigned long)currentIndex + 1, (unsigned long)allVerbs.count];
	
	_infinitifLabel.text = [@"To " stringByAppendingString:verb.infinitif];
	_formLabel.text = (form == VerbFormPastSimple)? @"Past Simple Form:" : @"Past Participle Form:";
	
	currentResponse = (form == VerbFormPastSimple)? (verb.past) : (verb.pastParticiple);
	
	/* Update the label with the number of remaining letters */
	_remainingCount.text = [NSString stringWithFormat:@"%lu remaining letters", (unsigned long)currentResponse.length];
	
	CGSize size = [currentResponse sizeWithAttributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:24.] }];
 	
	/* Fit "_backgroundFieldImageView" from "size.width" + 50px + 2 x 8px */
	CGRect frame = _backgroundFieldImageView.frame;
	frame.size.width = size.width + 50. + 2 * 8.;
	frame.origin.x = (int)((self.view.frame.size.width - frame.size.width) / 2.);
	_backgroundFieldImageView.frame = frame;
	
	/* Fit "_textField" from "size.width" + 50px */
	frame = _textField.frame;
	frame.size.width = size.width + 50.;
	frame.origin.x = (int)((self.view.frame.size.width - frame.size.width) / 2.);
	_textField.frame = frame;
	
	_textField.text = @"";
	[self pushView:_quizView animated:animated];
	
	double delayInSeconds = (animated)? 0.25 : 0.;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[_textField becomeFirstResponder];
	});
}

#pragma mark Result Management

- (void)pushResultAnimated:(BOOL)animated
{
    [_textField becomeFirstResponder];
	[_textField resignFirstResponder];
	
	currentResponse = nil;
	
	self.title = @"";
	
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(doneAction:)]
                                     animated:YES];
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Again" style:UIBarButtonItemStylePlain target:self action:@selector(start)] animated:YES];
	
	_goodResponseCountLabel.text = [NSString stringWithFormat:@"%ld", (long)goodResponseCount];
	_badResponseCountLabel.text = [NSString stringWithFormat:@"%ld", (long)badResponseCount];
	
	[self pushView:_resultView animated:animated];
}

#pragma mark Response Management

- (void)pushResponse:(ResponseState)response animated:(BOOL)animated
{
	if (response == ResponseStateTrue) {
		_responseImageView.image = [UIImage imageNamed:@"true"];
	} else {
		_responseImageView.image = [UIImage imageNamed:@"false"];
	}
	
	_responseLabel.text = currentResponse;
	
	[self pushView:_responseView animated:animated];
	
	double delayInSeconds = ((animated)? 0.25 : 0.) + 1.;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self pushNewVerbAction:nil];
	});
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([textField.text isEqualToString:currentResponse]) {
		goodResponseCount++;
		[self pushResponse:ResponseStateTrue animated:YES];
	} else {
		badResponseCount++;
		[self pushResponse:ResponseStateFalse animated:YES];
	}
	
	return (textField.text.length == currentResponse.length);
}

- (void)textFieldDidChange:(NSNotification *)notification
{
	static NSUInteger oldLenght = 0;
	
	NSUInteger location = [currentResponse rangeOfString:@"-"].location;
	if (location != NSNotFound) {
		if (oldLenght > _textField.text.length) {// If the old lenght is greated than the actual, the user is deleting
			
			/* Remove "-" if needed */
			if (_textField.text.length == (location + 1)) {
				_textField.text = [_textField.text stringByReplacingCharactersInRange:NSMakeRange(location - 1, 2) withString:@""];// Remove the two last caracters (as if we delete the last caracter with the "-")
			}
			
		} else {
			/* Add "-" if needed */
			if (_textField.text.length == location) {
				_textField.text = [_textField.text stringByAppendingString:@"-"];
			}
		}
	}
	
	oldLenght = _textField.text.length;
	
	/* Update the label with the number of remaining letters */
	_remainingCount.text = [NSString stringWithFormat:@"%ld remaining letters", (unsigned long)(currentResponse.length - _textField.text.length)];
}

#pragma mark - UINavigationController Delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)aViewController animated:(BOOL)animated
{
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

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.navigationController.delegate = nil;
	
}

@end