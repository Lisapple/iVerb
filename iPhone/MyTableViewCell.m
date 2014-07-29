//
//  UITableViewCell+addition.m
//  iVerb
//
//  Created by Max on 10/16/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import "MyTableViewCell.h"


@implementation MyTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		
		self.textLabel.textColor = [UIColor darkGrayColor];
		self.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	return self;
}

/*
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	[UIView animateWithDuration:(animated)? 0.35: 0.
					 animations:^{
						 self.backgroundColor = (selected)? [UIColor colorWithWhite:0.9 alpha:1.]: [UIColor whiteColor];
					 }];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	[super setHighlighted:highlighted animated:animated];
	
	[UIView animateWithDuration:(animated)? 0.35: 0.
					 animations:^{
						 self.backgroundColor = (highlighted)? [UIColor colorWithWhite:0.9 alpha:1.]: [UIColor whiteColor];
					 }];
}
*/

@end
