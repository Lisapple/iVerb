//
//  UIBarButtonItem+addition.h
//  test_tintTabBar
//
//  Created by Max on 8/3/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#define UIBarButtonItemStyleDefault 4

@interface UIBarButtonItem (addition)

- (void)setCustomStyle:(UIBarButtonItemStyle)style;

+ (UIBarButtonItem *)barButtonItemWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (UIBarButtonItem *)backBarButtonItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style;

@end
