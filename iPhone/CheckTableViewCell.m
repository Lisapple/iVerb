//
//  SongTableViewCell.m
//  Closer
//
//  Created by Max on 3/9/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CheckTableViewCell.h"


@implementation CheckTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.accessoryView = nil;
	}
	return self;
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)aType
{
	if (aType == UITableViewCellAccessoryCheckmark) {
		
	} else if (aType == UITableViewCellAccessoryNone) {
		self.accessoryView = nil;
	}
	
	[super setAccessoryType:aType];
}

- (void)setAccessoryViewSelected:(BOOL)selected animated:(BOOL)animated
{
	float delay = (animated)? 0.3: 0.;
	
	if (self.selectionStyle != UITableViewCellSelectionStyleNone) {// No color change with UITableViewCellSelectionStyleNone
		if (selected) {
			self.textLabel.textColor = [UIColor whiteColor];
		} else {
			if (!textLabelColor)
				textLabelColor = [self.textLabel.textColor copy];
			
			[self.textLabel performSelector:@selector(setTextColor:)
								 withObject:textLabelColor
								 afterDelay:delay];
		}
	}
	
	if (self.accessoryType == UITableViewCellAccessoryNone) {
		
		if (selected) {
			UIImageView * accessoryImageView = nil;
			accessoryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check"]];
			self.accessoryView = accessoryImageView;
		} else {
			self.accessoryView = nil;
		}
		
	} else if (self.accessoryType == UITableViewCellAccessoryCheckmark) {
		/* When we using performSelector:withObject:afterDelay:, this use the current run loop to call the selector even if no delay have been set. In this case, iOS set the accessoryView with a "check" image before we set the accessoryView with nothing (to remove the "check" image). With performSelector:withObject:afterDelay: and the run loop, the system could set the "check" image after we set it with nothing.
		 So, to prevent this overflow effect, just call setAccessoryView: directly if no delay have been set. */
		if (delay) {
			[self performSelector:@selector(setAccessoryView:)
					   withObject:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check"]]
					   afterDelay:delay];
		} else {
			UIImageView * imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check"]];
			self.accessoryView = imageView;
		}
	}
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	[super setHighlighted:highlighted animated:animated];
	
	if (highlighted)
		[self setAccessoryViewSelected:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	if (!selected)
		[self setAccessoryViewSelected:selected animated:animated];
}

- (void)dealloc
{
	self.accessoryView = nil;
	
	/*
	[textLabelColor release];
	
	if (![self.textLabel observationInfo])
		[self.textLabel removeObserver:self forKeyPath:@"textColor"];
	*/
	
}


@end
