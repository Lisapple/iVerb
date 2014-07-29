//
//  ActionSheet.m
//  iVerb
//
//  Created by Maxime Leroy on 3/23/13.
//
//

#import "ActionSheet.h"

@implementation _ActionSheetButton

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	float x = .5, y = .5, width = rect.size.width - 1., height = rect.size.height - 1.;
	float radius = 0.;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, radius);
	CGContextAddArcToPoint(context, x, y, x + radius, y, radius);
	CGContextAddArcToPoint(context, x + width, y, x + width, radius, radius);
	CGContextAddArcToPoint(context, x + width, height + y, x + width - radius, height + y, radius);
	CGContextAddArcToPoint(context, x, height + y, x, height - radius, radius);
	CGContextClosePath(context);
	
    [(self.highlighted)? [UIColor colorWithWhite:0. alpha:0.07] : [UIColor clearColor] setFill];
	CGContextFillPath(context);
}

- (void)update
{
    self.titleLabel.font = [UIFont systemFontOfSize:21.];
    switch (_type) {
		case ActionSheetButtonTypeDelete:
			[self setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [self setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
			break;
		case ActionSheetButtonTypeCancel:
            self.titleLabel.font = [UIFont boldSystemFontOfSize:21.];
		default: // "ActionSheetButtonTypeDefault"
			[self setTitleColor:_titleColor forState:UIControlStateNormal];
            [self setTitleColor:_titleColor forState:UIControlStateHighlighted];
			break;
	}
}

- (void)setTitleColor:(UIColor *)titleColor
{
    _titleColor = titleColor;
    [self update];
}

- (void)setType:(ActionSheetButtonType)type
{
	_type = type;
	[self update];
}

- (void)setHighlighted:(BOOL)highlighted
{
	[self setNeedsDisplay];
	super.highlighted = highlighted;
}

@end


@interface ActionSheet ()
{
    NSString * _title;
    UILabel * _titleLabel;
    UIColor * _tintColor;
}
@end

@implementation ActionSheet

- (id)initWithTitle:(NSString *)title delegate:(id <ActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	UIScreen * mainScreen = [UIScreen mainScreen];
	CGRect frame = mainScreen.applicationFrame;
	if ((self = [super initWithFrame:frame])) {
		
        _title = title;
        
		self.delegate = delegate;
		
		self.backgroundColor = [UIColor clearColor];
        UIColor * tintColor = [UIApplication sharedApplication].keyWindow.tintColor;
		
		buttons = [[NSMutableArray alloc] initWithCapacity:5];
		
		NSMutableArray * titles = [[NSMutableArray alloc] initWithCapacity:3];
		if (otherButtonTitles) {
			[titles addObject:otherButtonTitles];
			
			va_list list;
			va_start(list, otherButtonTitles);
			NSString * string = nil;
			while ((string = va_arg(list, id))) {
				[titles addObject:string];
			}
			va_end(list);
		}
		
		CGFloat height = 7. /* Bottom margin */ + 44. /* Cancel button's height */ + 10. /* Margin between "Cancel" button and other buttons */ + (44. * titles.count) /* 44px height + 10px for each button */ + 10. /* 10px for top margin */;
		if (destructiveButtonTitle && destructiveButtonTitle.length > 0) height += 44.; /* Add 44px height + 10px for the top margin */
		
        CGSize titleSize = CGSizeZero;
		if (title.length > 0) {
            titleSize = [title boundingRectWithSize:CGSizeMake(306., INFINITY)
                                options:NSStringDrawingUsesLineFragmentOrigin
                             attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:13.] }
                                context:NULL].size;
            
			height += titleSize.height + 20.;
		}
		
		CGRect newFrame = self.frame;
		newFrame.origin.y = frame.size.height - height + 20.;
		newFrame.size.height = height;
		self.frame = newFrame;
		
		
		CGFloat y = 20. + 20. + 10.; // 20px from status bar offset + 20px bottom margin + 10px (=> ???)
		
		if (cancelButtonTitle && cancelButtonTitle.length > 0) {
			CGRect rect = CGRectMake(7., newFrame.size.height - y, 306., 44.);
			_ActionSheetButton * button = [[_ActionSheetButton alloc] initWithFrame:rect];
			button.frame = rect;
			button.type = ActionSheetButtonTypeCancel;
            button.titleColor = tintColor;
			[button setTitle:cancelButtonTitle forState:UIControlStateNormal];
			[button addTarget:self action:@selector(defaultAction:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			[buttons addObject:button];
			y += 44.;
		}
		
		y += 10.;
		
		for (NSString * aTitle in titles.reverseObjectEnumerator) {
			CGRect rect = CGRectMake(7., newFrame.size.height - y, 306., 44.);
			_ActionSheetButton * button = [[_ActionSheetButton alloc] initWithFrame:rect];
			button.frame = rect;
			button.type = ActionSheetButtonTypeDefault;
            button.titleColor = tintColor;
			[button setTitle:aTitle forState:UIControlStateNormal];
			[button addTarget:self action:@selector(defaultAction:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			[buttons insertObject:button atIndex:0];
			y += 44.;
		}
		
		if (destructiveButtonTitle && destructiveButtonTitle.length > 0) {
			
			CGRect rect = CGRectMake(7., newFrame.size.height - y, 306., 44.);
			_ActionSheetButton * button = [[_ActionSheetButton alloc] initWithFrame:rect];
			button.frame = rect;
			button.type = ActionSheetButtonTypeDelete;
            button.titleColor = tintColor;
			[button setTitle:destructiveButtonTitle forState:UIControlStateNormal];
			[button addTarget:self action:@selector(defaultAction:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			[buttons insertObject:button atIndex:0];
			y += 44.;
		}
		
		y -= 44.;
		
		if (title && title.length > 0) {
            
			y += 10. + titleSize.height;
			
			CGRect rect = CGRectMake(7., newFrame.size.height - y, 306., titleSize.height);
			_titleLabel = [[UILabel alloc] initWithFrame:rect];
			_titleLabel.backgroundColor = [UIColor clearColor];
			_titleLabel.text = title;
			_titleLabel.textAlignment = NSTextAlignmentCenter;
			_titleLabel.numberOfLines = 0;
			_titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.];
			_titleLabel.font = [UIFont systemFontOfSize:13.];
			//titleLabel.shadowOffset = CGSizeMake(0., 1.);
			//titleLabel.shadowColor = [UIColor colorWithWhite:1. alpha:0.5];
			[self addSubview:_titleLabel];
		}
    }
    return self;
}

- (IBAction)defaultAction:(id)sender
{
	NSInteger index = [buttons indexOfObject:sender];
	
	if (index >= 0) {
		if ([self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)])
			[self.delegate actionSheet:self clickedButtonAtIndex:index];
	}
	
	if (index == 0) {
		if ([self.delegate respondsToSelector:@selector(actionSheetCancel:)])
			[self.delegate actionSheetCancel:self];
	}
	
	if (usingBlock) {
		usingBlock(index);
	}
	usingBlock = nil;
	
	[self dismissWithClickedButtonIndex:index animated:YES];
	
	/* Re-allow the landscape mode of the application */
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	if (point.y <= 0.) // If the hit is outside of the actionSheet (transludent black), cancel the actionSheet
		[self defaultAction:[buttons lastObject]];
	
	return [super hitTest:point withEvent:event];
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
	return nil;
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex
{
	return [(UIButton *)buttons[buttonIndex] titleForState:UIControlStateNormal];
}

- (void)showInView:(UIView *)view
{
    _tintColor = [UIApplication sharedApplication].keyWindow.tintColor.copy;
    [UIApplication sharedApplication].keyWindow.tintColor = [UIColor colorWithWhite:0.205 alpha:0.8];
    
	UIScreen * mainScreen = [UIScreen mainScreen];
	CGRect frame = mainScreen.bounds;
	window = [[UIWindow alloc] initWithFrame:frame];
	window.windowLevel = UIWindowLevelStatusBar;
	[window addSubview:self];
	
	window.backgroundColor = [UIColor colorWithWhite:0. alpha:0.4];
	
	[window makeKeyAndVisible];
	
	window.alpha = 0.;
	
	frame = self.frame;
	frame.origin.y += frame.size.height;
	self.frame = frame;
	
	[UIView animateWithDuration:0.2 animations:^{ window.alpha = 1.; }];
	[UIView animateWithDuration:0.35
					 animations:^{
						 CGRect frame = self.frame;
						 frame.origin.y -= frame.size.height;
						 self.frame = frame;
					 }];
	
	/* Disallow the landscape mode of the application */
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)showInView:(UIView *)view usingBlock:(void (^)(NSInteger buttonIndex))block
{
	usingBlock = [block copy];
    
	[self showInView:view];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;
{
	[UIView animateWithDuration:(animated)? 0.25 : 0.
					 animations:^{
						 CGRect frame = self.frame;
						 frame.origin.y += frame.size.height;
						 self.frame = frame;
					 }];
	
	[UIView animateWithDuration:(animated)? 0.25 : 0.
						  delay:0.15
						options:0
					 animations:^{
						 window.alpha = 0.;
					 }
					 completion:^(BOOL finished) {
						 [window setHidden:YES];
						 [window resignKeyWindow];
                         // Re-set the tintColor of the key window (the main window of the app now that |window| is resigned)
                         [UIApplication sharedApplication].keyWindow.tintColor = _tintColor;
					 }];
}

- (void)fillRoundedRect:(CGRect)rect radius:(CGFloat)radius
{
    float x = rect.origin.x, y = rect.origin.y;
    float width = rect.size.width, height = rect.size.height;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, y + radius);
	CGContextAddArcToPoint(context, x, y, x + radius, y, radius);
	CGContextAddArcToPoint(context, x + width, y, x + width, y + radius, radius);
	CGContextAddArcToPoint(context, x + width, height + y, x + width - radius, height + y, radius);
	CGContextAddArcToPoint(context, x, height + y, x, height - radius, radius);
	CGContextClosePath(context);
    CGContextFillPath(context);
}

- (void)drawRect:(CGRect)rect
{
    /*
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor redColor] setFill];
    CGContextFillRect(context, rect);
    */
    
    [[UIColor colorWithWhite:0.9 alpha:1.] setFill];
    
    CGFloat height = [_titleLabel sizeThatFits:CGSizeMake(306., INFINITY)].height;
    height += (height > 0.) ? 20. : 0.;
    height += (buttons.count - 1) * 44.;
    
    CGRect frame = CGRectMake(7., 10., rect.size.width - 2. * 7., height);
    [self fillRoundedRect:frame radius:4.];
    
    frame = CGRectMake(7., rect.size.height - 50., rect.size.width - 2. * 7., 44.);
	[self fillRoundedRect:frame radius:4.];
    
    [[UIColor colorWithWhite:0.85 alpha:1.] setFill];
    CGFloat y = rect.size.height - 104.;
    NSInteger count = buttons.count - ((_title.length) ? 1 : 2);
    for (int i = 0; i < count; ++i) {
        CGRect frame = CGRectMake(7., y, rect.size.width - 2. * 7., 1.);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextFillRect(context, frame);
        
        y -= 44.;
    }
}

@end
