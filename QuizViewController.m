//
//  QuizViewController.m
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import "QuizViewController.h"
#import "ResultViewController.h"

@interface QuizViewController ()

- (void)start;

- (void)pushView:(UIView *)view animated:(BOOL)animated;

- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated;

@end

@implementation QuizViewController

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
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelAction:)];
	
	// @TODO: add a "Details" button on result to show a list with good and bad responses
	
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

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[_resultTableView deselectRowAtIndexPath:_resultTableView.indexPathForSelectedRow
									animated:YES];
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
	[responses addObject:@""];
	[responsesCorrect addObject:@NO];
	
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
	
	responses = [[NSMutableArray alloc] initWithCapacity:allVerbs.count];
	responsesCorrect = [[NSMutableArray alloc] initWithCapacity:allVerbs.count];
	forms = [[NSMutableArray alloc] initWithCapacity:allVerbs.count];
	
	currentIndex = 0;
	srand((unsigned int)time(NULL));
	VerbForm form = (rand() % 2)? VerbFormPastSimple : VerbFormPastParticiple;
	[self pushVerb:allVerbs.firstObject form:form animated:animated];
}

- (void)pushView:(UIView *)view animated:(BOOL)animated
{
	/* "Pop" the previous pushed view (if exists) */
	if (previousPushedView && previousPushedView != view) {
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
	if (view.hidden) view.hidden = NO;
	else [self.view addSubview:view];
	
	[UIView animateWithDuration:(animated)? 0.25 : 0.
					 animations:^{
						 CGRect frame = view.frame;
						 frame.origin.x = 0.;
						 view.frame = frame;
					 }
					 completion:^(BOOL finished) {
						 if (previousPushedView != view)
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
		
		srand((unsigned int)time(NULL));
		VerbForm form = (rand() % 2)? VerbFormPastSimple : VerbFormPastParticiple;
		[self pushVerb:verb form:form animated:YES];
		
	} else {// Else, show results
		[self pushResultAnimated:YES];
	}
}

- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated
{
	[forms addObject:@(form)];
	
	self.title = [NSString stringWithFormat:@"%ld of %ld", (long)currentIndex + 1, (long)allVerbs.count];
	
	_infinitifLabel.text = [@"To " stringByAppendingString:verb.infinitif];
	_formLabel.text = (form == VerbFormPastSimple)? @"Past Simple Form:" : @"Past Participle Form:";
	
	currentResponse = (form == VerbFormPastSimple)? (verb.past) : (verb.pastParticiple);
	
	/* Update the label with the number of remaining letters */
	_remainingCount.text = [NSString stringWithFormat:@"%ld remaining letters", (long)currentResponse.length];
	
	CGSize size = [currentResponse sizeWithAttributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:24.] }];
 	
	/* Fit "_backgroundFieldImageView" from "size.width" + 50px + 2 x 8px */
	CGRect frame = _backgroundFieldImageView.frame;
	frame.size.width = size.width + 50. + 2 * 8.;
	frame.origin.x = ceilf((self.view.frame.size.width - frame.size.width) / 2.);
	_backgroundFieldImageView.frame = frame;
	
	/* Fit "_textField" from "size.width" + 50px */
	frame = _textField.frame;
	frame.size.width = size.width + 50.;
	frame.origin.x = ceilf((self.view.frame.size.width - frame.size.width) / 2.);
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
	
	self.title = [NSString stringWithFormat:@"%ld on %ld", (long)goodResponseCount, (long)allVerbs.count];
	
	UIBarButtonItem * startItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
																				target:self
																				action:@selector(start)];
	[self.navigationItem setLeftBarButtonItem:startItem animated:YES];
	
	UIBarButtonItem * doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			   target:self
																			   action:@selector(doneAction:)];
	[self.navigationItem setRightBarButtonItem:doneItem animated:YES];
	
	_resultTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_resultTableView.frame = self.view.bounds;
	[self pushView:_resultTableView animated:animated];
	[_resultTableView reloadData];
	_resultTableView.contentInset = UIEdgeInsetsMake(64., 0., 0., 0.);
}

#pragma mark Response Management

- (void)pushResponse:(ResponseState)response animated:(BOOL)animated
{
	_responseImageView.image = [UIImage imageNamed:(response == ResponseStateTrue) ? @"true" : @"false"];
	_responseLabel.text = currentResponse;
	
	_responseView.frame = self.view.bounds;
	[self pushView:_responseView animated:animated];
	
	double delayInSeconds = ((animated)? 0.25 : 0.) + 1.;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)),
				   dispatch_get_main_queue(), ^{ [self pushNewVerbAction:nil]; });
}

#pragma mark - UITableView Delegate and DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return allVerbs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"CellID"];
	
	if (!cell)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellID"];
	
	NSString * response = responses[indexPath.row];
	Verb * verb = allVerbs[indexPath.row];
	NSString * verbString = ([forms[indexPath.row] intValue] == VerbFormPastSimple) ? (verb.past) : (verb.pastParticiple);
	if (response.length > 0) {
		BOOL correct = [responsesCorrect[indexPath.row] boolValue];
		if (correct)
			cell.textLabel.text = [NSString stringWithFormat:@"%@", response];
		else
			cell.textLabel.text = [NSString stringWithFormat:@"%@ (not %@)", verbString, response];
		
		cell.imageView.image = [UIImage imageNamed:(correct) ? @"true-small" : @"false-small"];
		
	} else {
		cell.textLabel.text = [NSString stringWithFormat:@"%@ (skipped)", verbString];
		cell.textLabel.textColor = [UIColor lightGrayColor];
		cell.imageView.image = nil;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Verb * verb = allVerbs[indexPath.row];
	if (TARGET_IS_IPAD()) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SearchTableViewDidSelectCellNotification object:verb];
		[self dismissViewControllerAnimated:YES completion:NULL];
		
	} else {
		ResultViewController * resultViewController = [[ResultViewController alloc] init];
		resultViewController.verb = verb;
		[self.navigationController pushViewController:resultViewController animated:YES];
	}
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField.text.length == currentResponse.length) {
		BOOL goodResponse = [textField.text isEqualToString:currentResponse];
		if (goodResponse) {
			goodResponseCount++;
			[self pushResponse:ResponseStateTrue animated:YES];
		} else {
			badResponseCount++;
			[self pushResponse:ResponseStateFalse animated:YES];
		}
		
		[responses addObject:textField.text];
		[responsesCorrect addObject:@(goodResponse)];
		
		return YES;
	} else {
		_remainingCount.textColor = [UIColor redColor];
	}
	
	return NO;
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
	NSInteger rem = currentResponse.length - _textField.text.length;
	_remainingCount.text = [NSString stringWithFormat:@"%ld remaining letters", (long)rem];
	_remainingCount.textColor = (rem < 0) ? [UIColor redColor] : [UIColor grayColor];
}

#pragma mark - UINavigationController Delegate

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationPortrait;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.navigationController.delegate = nil;
	
}

@end
