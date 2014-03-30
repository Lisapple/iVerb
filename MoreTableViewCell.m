//
//  MoreTableViewCell.m
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import "MoreTableViewCell.h"

@implementation _MoreTableViewCellButton

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	[[UIColor lightGrayColor] setFill];
	CGContextFillRect(context, CGRectMake(0., 0., 1., self.frame.size.height));
	
	[super drawRect:rect];
}

@end


@implementation MoreTableViewCell

@synthesize moreTarget = _moreTarget;
@synthesize moreAction = _moreAction;

@synthesize showsMoreButton = _showsMoreButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		
		moreButton = [_MoreTableViewCellButton buttonWithType:UIButtonTypeCustom];
		moreButton.frame = CGRectMake(self.frame.size.width - 58., 0., 50., self.frame.size.height);
		[moreButton setTitle:@"..." forState:UIControlStateNormal];
		[moreButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		moreButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.];
		
		[moreButton addTarget:self action:@selector(moreSelectedAction:) forControlEvents:UIControlEventTouchUpInside];
		
		[self addSubview:moreButton];
    }
    return self;
}

- (void)setShowsMoreButton:(BOOL)showsMoreButton
{
	moreButton.hidden = (!showsMoreButton);
}

- (IBAction)moreSelectedAction:(id)sender
{
	if (_moreAction && [_moreTarget respondsToSelector:_moreAction])
		[_moreTarget performSelector:_moreAction withObject:self];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
