//
//  UIBarButtonItem+addition.m
//  test_tintTabBar
//
//  Created by Max on 8/3/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import "UIBarButtonItem+addition.h"

@implementation UIBarButtonItem (addition)

- (id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action
{
	if (self = [super init]) {
		self.target = target;
		self.action = action;
		
		self.enabled = YES;
		
		if (style == UIBarButtonItemStyleDefault) {
			CGFloat scale = [UIScreen mainScreen].scale;
			
			CGSize size = [title sizeWithFont:[UIFont boldSystemFontOfSize:13.]];
			UIGraphicsBeginImageContextWithOptions(size, NO, scale);
			
			CGRect rect = CGRectMake(0., 0., 200., 16);// 16 is the height for this font and 200 is the max width
			UILabel * titleLabel = [[UILabel alloc] initWithFrame:rect];
			titleLabel.backgroundColor = [UIColor clearColor];
			titleLabel.text = title;
			titleLabel.font = [UIFont boldSystemFontOfSize:13.];
			titleLabel.textColor = [UIColor darkGrayColor];
			titleLabel.shadowColor = [UIColor whiteColor];
			titleLabel.shadowOffset = CGSizeMake(0., 1.);
			
			[titleLabel.layer renderInContext:UIGraphicsGetCurrentContext()];
			
			UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			self.image = image;
		} else {
			self.title = title;
			self.style = style;
		}		
	}
	
	return self;
}

- (void)setCustomStyle:(UIBarButtonItemStyle)style
{
	if (style == UIBarButtonItemStyleDefault) {
		
		self.style = UIBarButtonItemStylePlain;
		
		CGFloat scale = [UIScreen mainScreen].scale;
		
		CGSize size = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:13.]];
		UIGraphicsBeginImageContextWithOptions(size, NO, scale);
		
		CGRect rect = CGRectMake(0., 0., 100., 16);// 16 is the height for this font and 200 is the max width
		UILabel * titleLabel = [[UILabel alloc] initWithFrame:rect];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.text = self.title;
		titleLabel.font = [UIFont boldSystemFontOfSize:13.];
		titleLabel.textColor = [UIColor darkGrayColor];
		titleLabel.shadowColor = [UIColor whiteColor];
		titleLabel.shadowOffset = CGSizeMake(0., 1.);
		
		[titleLabel.layer renderInContext:UIGraphicsGetCurrentContext()];
		
		UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		self.image = image;
	}
}

+ (UIBarButtonItem *)barButtonItemWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
	UIBarButtonItem * button = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleDefault target:target action:action];
	return button;
}

+ (UIBarButtonItem *)backBarButtonItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style
{
	UIBarButtonItem * button = [[UIBarButtonItem alloc] initWithTitle:title style:style target:nil action:nil];
	return button;
}

@end
