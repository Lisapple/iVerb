//
//  UIView+addition.m
//  iVerb
//
//  Created by Max on 17/02/2017.
//
//

#import "UIView+addition.h"

@implementation UIView (addition)

- (void)addParallaxEffect:(ParallaxAxis)axis offset:(CGFloat)offset
{
	NSMutableArray <UIMotionEffect *> * effects = [NSMutableArray arrayWithCapacity:2];
	
	UIInterpolatingMotionEffect * motionEffect = nil;
	if (axis & ParallaxAxisHorizontal) {
		motionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
																	   type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
		motionEffect.minimumRelativeValue = @(-offset);
		motionEffect.maximumRelativeValue = @(offset);
		[effects addObject:motionEffect];
	}
	
	if (axis & ParallaxAxisVertical) {
		motionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
																	   type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
		motionEffect.minimumRelativeValue = @(-offset);
		motionEffect.maximumRelativeValue = @(offset);
		[effects addObject:motionEffect];
	}
	
	UIMotionEffectGroup * group = [[UIMotionEffectGroup alloc] init];
	group.motionEffects = effects;
	[self addMotionEffect:group];
}

@end
