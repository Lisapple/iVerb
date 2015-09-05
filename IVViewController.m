//
//  IVViewController.m
//  iVerb
//
//  Created by Maxime on 7/28/14.
//
//

#import "IVViewController.h"

@interface IVViewController ()

@end

@implementation IVViewController

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
    
    super.title = title;
}

@end
