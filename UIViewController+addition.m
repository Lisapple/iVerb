//
//  UIViewController+addition.m
//  test_tintTabBar
//
//  Created by Max on 8/3/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

//#import "UIViewController+addition.h"


@implementation UIViewController (addition)

- (void)setTitle:(NSString *)title
{
	UIFont * font = [UIFont boldSystemFontOfSize:20.];
	CGSize size = [title sizeWithAttributes:@{ NSFontAttributeName : font }];
	
	CGRect rect = CGRectMake(0., 0., size.width, 40.);
	UILabel * titleLabel = [[UILabel alloc] initWithFrame:rect];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.text = title;
	titleLabel.font = font;
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.textColor = [UIColor darkGrayColor];
	
	self.navigationItem.titleView = titleLabel;
    self.navigationItem.title = title;
}

@end
