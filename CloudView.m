//
//  CloudView.m
//  CloudVerb
//
//  Created by Max on 06/02/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CloudView.h"

@implementation CloudLabel

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.backgroundColor = [UIColor clearColor];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.backgroundColor = [UIColor clearColor];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.backgroundColor = [UIColor clearColor];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CloudLabelDidSelectedNotification" object:_verb];
}

@end


@implementation CloudView

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		speed = 1.;
		totalOffset = 0.;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
    [self update];
}

- (void)update
{
	speed = 1. + addedSpeed;
	if (addedSpeed > 0.25) addedSpeed -= 0.25;
	else if (addedSpeed < -0.25) addedSpeed += 0.25;
	else addedSpeed = 0.;
	
	totalOffset += speed;
	
	if (totalOffset < 0.)
		totalOffset += _totalWidth;
	
	CGFloat width = self.frame.size.width;
	for (CloudLabel * label in self.subviews) {
		CGRect frame = label.frame;
		if (frame.origin.x < -(_totalWidth - width))
			label.origin = CGPointMake(label.origin.x + _totalWidth + 400., label.origin.y);
		
		frame.origin.x = label.origin.x - totalOffset * (label.font.pointSize / 30);
		label.frame = frame;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch * touch = touches.anyObject;
	beginPosition = [touch locationInView:self];
	beginTimestamp = touch.timestamp;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch * touch = touches.anyObject;
	CGPoint position = [touch locationInView:self];
	
	float delta = beginPosition.x - position.x;
	
	NSTimeInterval duration = touch.timestamp - beginTimestamp;
	duration = (duration < 0.01)? 0.01: duration;
	
	addedSpeed = (delta / 320.) / duration;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch * touch = touches.anyObject;
	CGPoint position = [touch locationInView:self];
	float delta = beginPosition.x - position.x;
	
	NSTimeInterval duration = touch.timestamp - beginTimestamp;
	duration *= duration;
	duration = (duration < 0.05)? 0.05: duration;
	
	addedSpeed = (delta / 320.) / duration;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	for (CloudLabel * label in self.subviews) {
		if (CGRectContainsPoint(label.frame, point))
			return label;
	}
	
	return [super hitTest:point withEvent:event];
}

@end
