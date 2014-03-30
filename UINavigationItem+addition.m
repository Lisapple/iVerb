//
//  UINavigationItem+addition.m
//  test_tintTabBar
//
//  Created by Max on 8/3/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import "UINavigationItem+addition.h"


@implementation UINavigationItem (addition)

- (void)setTitle:(NSString *)title
{
	UIFont * font = [UIFont boldSystemFontOfSize:20.];
	CGSize size = [title sizeWithFont:font];
	
	CGRect rect = CGRectMake(0., 0., size.width, 40.);
	UILabel * titleLabel = [[UILabel alloc] initWithFrame:rect];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.text = title;
	titleLabel.font = font;
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.textColor = [UIColor darkGrayColor];
	titleLabel.shadowColor = [UIColor whiteColor];
	titleLabel.shadowOffset = CGSizeMake(0., 1.);
	
	self.titleView = titleLabel;
}

@end
