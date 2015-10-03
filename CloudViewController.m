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

@interface CloudViewController ()
{
    CADisplayLink * _link;
}
@end

@implementation CloudViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString * nibName = (TARGET_IS_IPAD())? @"CloudViewController_Pad" : @"CloudViewController_Phone";
    if ((self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]])) {
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Cloud";
	self.view.clipsToBounds = YES;
	
	if (TARGET_IS_IPAD()) {
		/* Add a "Done" button on iPad */
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(doneAction:)];
	}
	
	NSSet * verbsSet = [Playlist allVerbsPlaylist].verbs;
	
	float * sizes = (float *)malloc(3 * sizeof(float)); // Use dynamic alloc to be used into a block
	sizes[0] = 24., sizes[1] = 18., sizes[2] = 14.;
	
	__block float x = 0.;
	__block int index = 0;
	
	__block float * oldYs = (float *)calloc(3, sizeof(float));
	
	const float height = ((TARGET_IS_IPAD()) ? self.view.frame.size.height : [UIScreen mainScreen].bounds.size.height) - (20. + 44.) - 29.; // Remove the navigation bar height (44px) and the size of the label at bottom (29px max)
	
	__unsafe_unretained NSArray * colors = @[[UIColor darkGrayColor], [UIColor grayColor], [UIColor lightGrayColor]];
	[verbsSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
		
		NSString * infinitif = ((Verb *)obj).infinitif;
		
		UIFont * font = [UIFont systemFontOfSize:sizes[(index % 3)]];
		CGSize size = [infinitif sizeWithAttributes:@{ NSFontAttributeName : font }];
		size.width += 8.;
		
		float y = (int)((rand() / (float)RAND_MAX) * height) + 20. + 44.;
		while (ABS(y - oldYs[0]) < 60. || 
			   ABS(y - oldYs[1]) < 60. ||
			   ABS(y - oldYs[2]) < 60.) {
			y = (int)((rand() / (float)RAND_MAX) * height) + 20. + 44.;
		}
		
		/* Switch older "y" values */
		oldYs[2] = oldYs[1];
		oldYs[1] = oldYs[0];
		oldYs[0] = y;
		
		CGRect frame = CGRectMake(x, y, size.width, size.height);
		CloudLabel * label = [[CloudLabel alloc] initWithFrame:frame];
		label.origin = frame.origin;
		
		label.verb = (Verb *)obj;
		
		label.backgroundColor = [UIColor clearColor];
		
		label.textColor = colors[(index % 3)];
		label.textAlignment = NSTextAlignmentCenter;
		label.font = font;
		label.text = infinitif;
		
		[self.view addSubview:label];
		
		x += (int)(size.width / 2.);
		
		index++;
	}];
	
	free(oldYs);
	
	((CloudView *)self.view).totalWidth = x - self.view.frame.size.width;
    
    _link = [CADisplayLink displayLinkWithTarget:self.view selector:@selector(update)];
    
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
		[self dismissViewControllerAnimated:YES completion:NULL];
		
		/* Send a notification to select the verb on webView */
		[[NSNotificationCenter defaultCenter] postNotificationName:SearchTableViewDidSelectCellNotification object:verb];
	} else {
		/* Push the result view controller with the selected verb */
		ResultViewController * resultViewController = [[ResultViewController alloc] init];
		resultViewController.verb = verb;
		[self.navigationController pushViewController:resultViewController animated:YES];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _link.paused = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _link.paused = YES;
    [_link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

/* Action to close the view controller on iPad */
- (IBAction)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

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
