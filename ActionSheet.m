//
//  ActionSheet.m
//  iVerb
//
//  Created by Maxime Leroy on 3/23/13.
//
//

#import "ActionSheet.h"

@implementation _ActionSheetButton

@synthesize type = _type;

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		[self setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		self.titleLabel.font = [UIFont boldSystemFontOfSize:17.];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	float x = .5, y = .5, width = rect.size.width - 1., height = rect.size.height - 1.;
	float radius = 8.;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, radius);
	CGContextAddArcToPoint(context, x, y, x + radius, y, radius);
	CGContextAddArcToPoint(context, x + width, y, x + width, radius, radius);
	CGContextAddArcToPoint(context, x + width, height + y, x + width - radius, height + y, radius);
	CGContextAddArcToPoint(context, x, height + y, x, height - radius, radius);
	CGContextClosePath(context);
	
	switch (_type) {
		case ActionSheetButtonTypeDelete: {
			[(self.highlighted)? [UIColor blackColor] : [UIColor darkGrayColor] setFill];
			[(self.highlighted)? [UIColor blackColor] : [UIColor darkGrayColor] setStroke];
		}
			break;
		case ActionSheetButtonTypeCancel: {
			[(self.highlighted)? [UIColor lightGrayColor] : [UIColor colorWithWhite:0.9 alpha:1.] setFill];
			[[UIColor grayColor] setStroke];
		}
			break;
		default: { // "ActionSheetButtonTypeDefault"
			[(self.highlighted)? [UIColor grayColor] : [UIColor whiteColor] setFill]; // [UIColor colorWithWhite:0.9 alpha:1.]
			[[UIColor grayColor] setStroke];
		}
			break;
	}
	
	CGPathRef pathRef = CGContextCopyPath(context);
	CGContextFillPath(context);
	
	CGContextAddPath(context, pathRef);
	CGContextSetLineWidth(context, 1.);
	CGContextStrokePath(context);
	CGPathRelease(pathRef);
}

- (void)setType:(ActionSheetButtonType)type
{
	_type = type;
	
	if (type == ActionSheetButtonTypeDelete) {
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	}
}

- (void)setHighlighted:(BOOL)highlighted
{
	[self setNeedsDisplay];
	super.highlighted = highlighted;
}

@end


@implementation ActionSheet

- (id)initWithTitle:(NSString *)title delegate:(id <ActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	UIScreen * mainScreen = [UIScreen mainScreen];
	CGRect frame = mainScreen.applicationFrame;
	if ((self = [super initWithFrame:frame])) {
		
		self.delegate = delegate;
		
		self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.];
		
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
		
		CGFloat height = 20. /* Bottom margin */ + 44. /* Cancel button's height */ + 20. /* Margin between "Cancel" button and other buttons */ + ((44. + 10.) * titles.count) /* 44px height + 10px for each button */ + 10. /* 10px for top margin */;
		if (destructiveButtonTitle && destructiveButtonTitle.length > 0) height += 44. + 10.; /* Add 44px height + 10px for the top margin */
		
		if (title.length > 0) {
			CGSize size = [title sizeWithFont:[UIFont systemFontOfSize:13.]
							constrainedToSize:CGSizeMake(280., INFINITY)];
			height += size.height;
		}
		
		CGRect newFrame = self.frame;
		newFrame.origin.y = frame.size.height - height + 20.;
		newFrame.size.height = height;
		self.frame = newFrame;
		
		
		CGFloat y = 20. + 20. + 20.; // 20px from status bar offset + 20px bottom margin + 20px (=> ???)
		
		if (cancelButtonTitle && cancelButtonTitle.length > 0) {
			CGRect rect = CGRectMake(20., newFrame.size.height - y, 280., 44.);
			_ActionSheetButton * button = [[_ActionSheetButton alloc] initWithFrame:rect];
			button.frame = rect;
			button.type = ActionSheetButtonTypeCancel;
			[button setTitle:cancelButtonTitle forState:UIControlStateNormal];
			[button addTarget:self action:@selector(defaultAction:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			[buttons addObject:button];
			y += 44.;
		}
		
		
		y += 10.;
		
		for (NSString * aTitle in titles.reverseObjectEnumerator) {
			y += 10.;
			CGRect rect = CGRectMake(20., newFrame.size.height - y, 280., 44.);
			_ActionSheetButton * button = [[_ActionSheetButton alloc] initWithFrame:rect];
			button.frame = rect;
			button.type = ActionSheetButtonTypeDefault;
			[button setTitle:aTitle forState:UIControlStateNormal];
			[button addTarget:self action:@selector(defaultAction:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			[buttons insertObject:button atIndex:0];
			y += 44.;
		}
		
		if (destructiveButtonTitle && destructiveButtonTitle.length > 0) {
			
			y += 10.;
			CGRect rect = CGRectMake(20., newFrame.size.height - y, 280., 44.);
			_ActionSheetButton * button = [[_ActionSheetButton alloc] initWithFrame:rect];
			button.frame = rect;
			button.type = ActionSheetButtonTypeDelete;
			[button setTitle:destructiveButtonTitle forState:UIControlStateNormal];
			[button addTarget:self action:@selector(defaultAction:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			[buttons insertObject:button atIndex:0];
			y += 44.;
		}
		
		y += 10. - 44.;
		
		if (title && title.length > 0) {
			
			CGSize size = [title sizeWithFont:[UIFont systemFontOfSize:13.]
							constrainedToSize:CGSizeMake(280., INFINITY)];
			y += size.height;
			
			CGRect rect = CGRectMake(20., newFrame.size.height - y, 280., size.height);
			UILabel * titleLabel = [[UILabel alloc] initWithFrame:rect];
			titleLabel.backgroundColor = [UIColor clearColor];
			titleLabel.text = title;
			titleLabel.textAlignment = NSTextAlignmentCenter;
			titleLabel.numberOfLines = 0;
			titleLabel.textColor = [UIColor darkGrayColor];
			titleLabel.font = [UIFont systemFontOfSize:13.];
			titleLabel.shadowOffset = CGSizeMake(0., 1.);
			titleLabel.shadowColor = [UIColor colorWithWhite:1. alpha:0.5];
			[self addSubview:titleLabel];
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
	return [(UIButton *)[buttons objectAtIndex:buttonIndex] titleForState:UIControlStateNormal];
}

- (void)showInView:(UIView *)view
{
	UIScreen * mainScreen = [UIScreen mainScreen];
	CGRect frame = mainScreen.bounds;
	window = [[UIWindow alloc] initWithFrame:frame];
	window.windowLevel = UIWindowLevelStatusBar;
	[window addSubview:self];
	
	window.backgroundColor = [UIColor colorWithWhite:0. alpha:0.5];
	
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
					 }];
}

- (void)drawRect:(CGRect)rect
{	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	/* Draw the gradient to the background */
	CFMutableArrayRef colors = CFArrayCreateMutable(kCFAllocatorDefault, 3, NULL);
	CFArrayAppendValue(colors, (const void *)[UIColor darkGrayColor].CGColor);
	CFArrayAppendValue(colors, (const void *)[UIColor whiteColor].CGColor);
	
	CGColorRef color = CGColorRetain([UIColor colorWithWhite:0.9 alpha:1.].CGColor); // Force retaining of this value (because ARC could release it)
	CFArrayAppendValue(colors, (const void *)color);
	
	const CGFloat locations[3] = { 1. / rect.size.height, 1.5 / rect.size.height, 0.08 }; // Use fix to get a 1px dark gray on top, then a gradient from white to light gray (90% white)
	
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
	CFRelease(colors);
	CGColorSpaceRelease(colorSpace);
	CGColorRelease(color);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextDrawLinearGradient(context, gradient, rect.origin, CGPointMake(rect.origin.x, rect.origin.y + rect.size.height), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(gradient);
}

@end
