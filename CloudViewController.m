//
//  CloudViewController.m
//  iVerb
//
//  Created by Max on 05/02/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CloudViewController.h"

#import "ResultViewController.h"

#import "Playlist.h"

#import "CloudView.h"

#import "UIBarButtonItem+addition.h"

@implementation CloudViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString * nibName = (TARGET_IS_IPAD())? @"CloudViewController_Pad" : @"CloudViewController_Phone";
    if ((self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]])) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	self.title = @"Cloud";
	
	self.navigationController.delegate = self;
	
	if (TARGET_IS_IPAD()) {
		/* Add a "Done" button on iPad */
		self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonItemWithTitle:@"Done" target:self action:@selector(doneAction:)];
	}
	
	NSSet * verbsSet = [Playlist allVerbsPlaylist].verbs;
	
	float * sizes = (float *)malloc(3 * sizeof(float));
	sizes[0] = 24., sizes[1] = 18., sizes[2] = 14.;
	
	__block float x = 0.;
	__block int index = 0;
	
	__block float * oldYs = (float *)malloc(3 * sizeof(float));
	oldYs[0] = oldYs[1] = oldYs[2] = 0.;
	
	__block const float height = self.view.frame.size.height - 44. - 29.; // Remove the navigation bar height (44px) and the size of the label at bottom (29px max)
	
	__unsafe_unretained NSArray * colors = [NSArray arrayWithObjects:[UIColor darkGrayColor], [UIColor grayColor], [UIColor lightGrayColor], nil];
	[verbsSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
		
		NSString * infinitif = ((Verb *)obj).infinitif;
		
		UIFont * font = [UIFont boldSystemFontOfSize:sizes[(index % 3)]];
		CGSize size = [infinitif sizeWithFont:font];
		size.width += 8.;
		
		float y = (int)((rand() / (float)RAND_MAX) * height) + 44.;
		while (ABS(y - oldYs[0]) < 60. || 
			   ABS(y - oldYs[1]) < 60. ||
			   ABS(y - oldYs[2]) < 60.) {
			y = (int)((rand() / (float)RAND_MAX) * height) + 44.;
		}
		
		/* Rotate older "y" values */
		oldYs[2] = oldYs[1];
		oldYs[1] = oldYs[0];
		oldYs[0] = y;
		
		CGRect frame = CGRectMake(x, y, size.width, size.height);
		CloudLabel * label = [[CloudLabel alloc] initWithFrame:frame];
		label.origin = frame.origin;
		
		label.verb = (Verb *)obj;
		
		label.backgroundColor = self.view.backgroundColor;
		
		label.textColor = [colors objectAtIndex:(index % 3)];
		label.textAlignment = UITextAlignmentCenter;
		label.font = font;
		label.text = infinitif;
		
		[self.view addSubview:label];
		
		x += (int)(size.width / 2.);
		
		index++;
	}];
	
	free(oldYs);
	
	((CloudView *)self.view).totalWidth = x - self.view.frame.size.width;
	
	dispatch_queue_t queue = dispatch_get_main_queue();
	dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue); //run event handler on the default global queue
	dispatch_time_t now = dispatch_walltime(DISPATCH_TIME_NOW, 0);
	dispatch_source_set_timer(timer, now, 33.333 * USEC_PER_SEC, 5000ull);// Fire timer one time a second, with 5 ms delay, "in case the system wants to align it with other events to minimize power consumption"
	dispatch_source_set_event_handler(timer, ^{
		[(CloudView *)self.view update];
	});
	dispatch_resume(timer);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(labelDidSelected:)
												 name:@"CloudLabelDidSelectedNotification"
											   object:nil];
}

- (void)labelDidSelected:(NSNotification *)notification
{
	Verb * verb = (Verb *)notification.object;
	
	if (TARGET_IS_IPAD()) {
		
		/* Dismiss the view */
		[self dismissModalViewControllerAnimated:YES];
		
		/* Send a notification to select the verb on webView */
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchTableViewDidSelectCellNotification"
															object:verb];
	} else {
		/* Push the result view controller with the selected verb */
		ResultViewController * resultViewController = [[ResultViewController alloc] init];
		resultViewController.verb = verb;
		[self.navigationController pushViewController:resultViewController animated:YES];
	}
}

/* Action to close the view controller on iPad */
- (IBAction)doneAction:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UINavigationController Delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)aViewController animated:(BOOL)animated
{
	self.navigationItem.backBarButtonItem = [UIBarButtonItem backBarButtonItemWithTitle:@"Back"
																				  style:UIBarButtonItemStyleDefault];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (NSUInteger)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationPortrait;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.navigationController.delegate = nil;
	
}

@end
