//
//  ConfirmationButton.m
//  iVerb
//
//  Created by Max on 07/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ConfirmationButton.h"

#define kMargin 6.

@implementation ConfirmationButton

@synthesize title = _title;

- (id)initWithCell:(UITableViewCell *)cell
{
	CGSize buttonSize = CGSizeMake(16., 35.);
	CGRect frame = CGRectMake(cell.frame.size.width - buttonSize.width - 8. /* 8px margin on right */, (int)((cell.frame.size.height - buttonSize.height) / 2.), buttonSize.width, buttonSize.height);
	if ((self = [super initWithFrame:frame])) {
		//self.frame = frame;
		[self setBackgroundImage:[[UIImage imageNamed:@"confirmation-button"] stretchableImageWithLeftCapWidth:8. topCapHeight:0.]
						forState:UIControlStateNormal];
		
		self.titleLabel.textAlignment = NSTextAlignmentCenter;
		self.titleLabel.font = [UIFont boldSystemFontOfSize:14.];
		self.titleLabel.textColor = [UIColor whiteColor];
		//self.titleLabel.shadowColor = [UIColor blackColor];//[UIColor colorWithWhite:0. alpha:0.333];
		//self.titleLabel.shadowOffset = CGSizeMake(0., -1.);
		
		tableViewCell = cell;
	}
	return self;
}

- (void)setTitle:(NSString *)title
{
	_title = [title copy];
	
	[self setTitle:_title
		  forState:UIControlStateNormal];
	
	/* Update the frame of the button */
	CGRect frame = self.frame;
	CGFloat oldWidth = frame.size.width;
	CGSize size = [_title sizeWithFont:self.titleLabel.font];
	frame.size.width = size.width + (2 * kMargin);
	frame.origin.x = tableViewCell.frame.size.width - frame.size.width - oldWidth;
	self.frame = frame;
}

@end
