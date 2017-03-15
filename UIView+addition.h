//
//  UIView+addition.h
//  iVerb
//
//  Created by Max on 17/02/2017.
//
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, ParallaxAxis) {
	ParallaxAxisVertical = 1 << 0,
	ParallaxAxisHorizontal = 1 << 1
};

@interface UIView (addition)

- (void)addParallaxEffect:(ParallaxAxis)axis offset:(CGFloat)offset;

@end
