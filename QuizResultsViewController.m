//
//  QuizResultsViewController.m
//  iVerb
//
//  Created by Max on 22/01/16.
//
//

#import "QuizResultsViewController.h"
#import "QuizResultsView.h"
#import "QuizResult.h"

@interface QuizResultCell ()

@property (nonatomic, strong) UILabel * dateLabel, * resultLabel;

@end

@implementation QuizResultCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		_dateLabel = [[UILabel alloc] init];
		_dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:_dateLabel];
		[self.contentView addConstraints:@[ [NSLayoutConstraint constraintWithItem:_dateLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
																			toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:15],
											[NSLayoutConstraint constraintWithItem:_dateLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
																			toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1 constant:0] ]];
		
		_resultLabel = [[UILabel alloc] init];
		_resultLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:_resultLabel];
		[self.contentView addConstraints:@[ [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
																			toItem:_resultLabel attribute:NSLayoutAttributeRight multiplier:1 constant:15],
											[NSLayoutConstraint constraintWithItem:_resultLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
																			toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1 constant:0] ]];
		self.tintColor = [UIColor darkGrayColor];
	}
	return self;
}

- (void)setResult:(QuizResult *)result
{
	_result = result;
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	formatter.dateStyle = NSDateFormatterMediumStyle;
	formatter.timeStyle = NSDateFormatterShortStyle;
	_dateLabel.text = [formatter stringFromDate:_result.date];
	
	NSInteger rightResponses = _result.rightResponses.integerValue;
	NSInteger wrongResponses = _result.wrongResponses.integerValue;
	_resultLabel.text = [NSString stringWithFormat:@"%ld / %ld", (long)rightResponses, (long)rightResponses + wrongResponses];
}

- (void)setTintColor:(UIColor *)tintColor
{
	_tintColor = tintColor;
	_dateLabel.textColor = tintColor;
	_resultLabel.textColor = tintColor;
}

@end


@interface QuizResultsViewController ()

@property (nonatomic, strong) NSArray <QuizResult *> * results;

@end

@implementation QuizResultsViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Quiz Results";
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self action:@selector(cancelAction:)];
	self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.];
	
	self.tableView.showsVerticalScrollIndicator = NO;
	[self.tableView registerClass:QuizResultCell.class forCellReuseIdentifier:@"QuizResultCellID"];
	
	if (!TARGET_IS_IPAD()) // Disallow the landscape mode of the application
		[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	
	NSSortDescriptor * descriptor = [NSSortDescriptor sortDescriptorWithKey:SelectorName(date) ascending:NO];
	_results = [_playlist.quizResults sortedArrayUsingDescriptors:@[ descriptor ]];
	
	if (_results.count >= 2) {
		MArray(Value) points = [[NSMutableArray alloc] initWithCapacity:_results.count];
		for (QuizResult * result in _results) {
			// x : date (1 for older on left, 0 for today on right), y : percent of success (0% on bottom, 100% on top)
			const CGFloat totalDuration = [_results.lastObject.date timeIntervalSinceDate:_results.firstObject.date];
			CGFloat dateProgression = 1 - ([result.date timeIntervalSinceDate:_results.firstObject.date] / totalDuration);
			CGFloat percentSuccess = result.rightResponses.doubleValue / (result.rightResponses.doubleValue + result.wrongResponses.doubleValue);
			[points addObject:[NSValue valueWithCGPoint:CGPointMake(dateProgression, percentSuccess)]];
		}
		
		QuizResultsView * view = [[QuizResultsView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 300)];
		view.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
		view.backgroundColor = [UIColor whiteColor];
		view.points = points;
		
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		[formatter setLocalizedDateFormatFromTemplate:@"MMMyyyy"];
		view.leftText = [formatter stringFromDate:_results.lastObject.date];
		view.rightText = [formatter stringFromDate:_results.firstObject.date];
		
		self.tableView.tableHeaderView = view;
	}
	else if (_results.count == 0) {
		UILabel * placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
		placeholder.translatesAutoresizingMaskIntoConstraints = NO;
		placeholder.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
		placeholder.text = @"No quiz results";
		placeholder.textColor = [UIColor grayColor];
		[self.view addSubview:placeholder];
		[self.view addConstraints:
		 @[ [NSLayoutConstraint constraintWithItem:placeholder attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
											toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
			[NSLayoutConstraint constraintWithItem:placeholder attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
											toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:-64] ]];
	}
}

- (IBAction)cancelAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
	
	if (!TARGET_IS_IPAD()) // Re-allow the landscape mode of the application
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

#pragma mark - Table view delegate & datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	QuizResultCell * cell = (QuizResultCell *)[tableView dequeueReusableCellWithIdentifier:@"QuizResultCellID" forIndexPath:indexPath];
	QuizResult * result = _results[indexPath.row];
	cell.result = result;
	
	const CGFloat totalDuration = [_results.lastObject.date timeIntervalSinceDate:_results.firstObject.date];
	CGFloat dateProgression = 1 - ([result.date timeIntervalSinceDate:_results.firstObject.date] / totalDuration);
#define LERP(A, X, B) (A + (MAX(0,MIN(X,1)) * (B - A)))
	cell.tintColor = [UIColor colorWithWhite:LERP(0.85, dateProgression, 0.333) alpha:1]; // White from 85% (oldest) to 33% (newest)
#undef LERP
	
	return cell;
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

@end
