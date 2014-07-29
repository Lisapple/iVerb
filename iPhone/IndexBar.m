//
//  IndexBar.m
//  IndexBar
//
//  Created by Max on 20/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IndexBar.h"

@interface IndexBar (PrivateMethods)

- (void)drawLabels;
- (void)update;

@end


@implementation IndexBar

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		super.backgroundColor = [UIColor clearColor];
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawLabels
{
	for (UILabel * label in _letterViews) [label removeFromSuperview];
	[_letterViews removeAllObjects];
	
	float height = self.frame.size.height;
	NSUInteger count = _letters.count;
	
	float letterHeight = (height / (float)count) * 3. / 4.;
	float separation = (height / (float)count) * 1. / 4.;
	
	int index = 0;
	for (NSString * letter in _letters) {
		CGRect frame = CGRectMake(4., (separation / 2.) + index * (letterHeight + separation), self.frame.size.width - 8., letterHeight);
		UILabel * label = [[UILabel alloc] initWithFrame:frame];
		
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		label.font = [UIFont boldSystemFontOfSize:13.];
		label.textColor = [UIColor darkGrayColor];
		
		label.text = letter;
		[_letterViews addObject:label];
		[self addSubview:label];
		
		index++;
	}
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
	_backgroundColor = backgroundColor;
	
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	float radius = self.frame.size.width / 2.;
	float height = self.frame.size.height;
	
	CGContextBeginPath(context);
	
	CGContextMoveToPoint(context, 0., radius);
	CGContextAddArcToPoint(context, 0., 0., radius, 0., radius);
	CGContextAddArcToPoint(context, 2. * radius, 0., 2. * radius, radius, radius);
	
	CGContextAddArcToPoint(context, 2. * radius, height, radius, height, radius);
	CGContextAddArcToPoint(context, 0., height, 0., height - radius, radius);
	
	[_backgroundColor setFill];
	CGContextFillPath(context);
}

- (NSInteger)indexForPosition:(CGPoint)point withSpace:(float)space atIndex:(NSInteger)anIndex
{
	float height = self.frame.size.height - space;
	float letterHeight = (height / (float)_letters.count) * 3. / 4.;
	float separation = (height / (float)_letters.count) * 1. / 4.;
	
	float y = point.y - (separation / 2.);
	
	int index = y / (letterHeight + separation);
	
	if (0 <= index && index < _letters.count)
		return index;
	
	return NSNotFound;
}

- (NSInteger)indexForPosition:(CGPoint)point
{
	float height = self.frame.size.height;
	float letterHeight = (height / (float)_letters.count) * 3. / 4.;
	float separation = (height / (float)_letters.count) * 1. / 4.;
	
	float y = point.y - (separation / 2.);
	
	int index = y / (letterHeight + separation);
	
	if (0 <= index && index < _letters.count)
		return index;
	
	return NSNotFound;
}

- (void)setLetters:(NSArray *)letters
{
	_letters = letters;
	
	_letterViews = [[NSMutableArray alloc] initWithCapacity:letters.count];
	
	NSArray * subviewsCopy = [self.subviews copy];
	for (UIView * subview in subviewsCopy) {
		[subview removeFromSuperview];
	}
	
	// Force reload all labels (remove them then re-add from letters)
	[self drawLabels];
}

- (void)update
{
	if (_letterViews.count == 0)
		[self drawLabels];
	
	float height = self.frame.size.height;
	NSUInteger count = _letters.count;
	
	float letterHeight = (height / (float)count) * 3. / 4.;
	float separation = (height / (float)count) * 1. / 4.;
	
	int i = 0;
	for (UILabel * label in _letterViews) {
		CGRect frame = CGRectMake(4., (separation / 2.) + i * (letterHeight + separation), self.frame.size.width - 8., letterHeight);
		label.frame = frame;
		
		label.textColor = [UIColor darkGrayColor];
		label.font = [UIFont boldSystemFontOfSize:13.];
		
		i++;
	}
}

- (void)updateWithSpace:(float)space atIndex:(NSInteger)index
{
	float height = self.frame.size.height - space;
	NSUInteger count = _letters.count;
	
	float letterHeight = (height / (float)count) * 3. / 4.;
	float separation = (height / (float)count) * 1. / 4.;
	
	int i = 0;
	for (UILabel * label in _letterViews) {
		
		float _space = 0.;
		if (i >= index)
			_space = space;
		
		if (i == (index - 1)) {
			label.textColor = [UIColor blackColor];
			label.font = [UIFont boldSystemFontOfSize:17.];
		} else {
			label.textColor = [UIColor darkGrayColor];
			label.font = [UIFont boldSystemFontOfSize:13.];
		}
		
		CGRect frame = CGRectMake(4., (separation / 2.) + i * (letterHeight + separation) + _space, self.frame.size.width - 8., letterHeight);
		label.frame = frame;
		
		i++;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.backgroundColor = [UIColor colorWithWhite:0. alpha:0.333];
	
	if ([(NSObject <IndexBarDelegate> *)self.delegate respondsToSelector:@selector(indexBarDidSelectIndex:)]) {
		
		UITouch * touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		
		NSInteger index = [self indexForPosition:point withSpace:0. atIndex:1];
		[self.delegate indexBarDidSelectIndex:index];
		
		[self updateWithSpace:0. atIndex:(index + 1)];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([(NSObject <IndexBarDelegate> *)self.delegate respondsToSelector:@selector(indexBarDidSelectIndex:)]) {
		
		UITouch * touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		
		NSInteger index = [self indexForPosition:point withSpace:0. atIndex:1];
		[self.delegate indexBarDidSelectIndex:index];
		
		[self updateWithSpace:0. atIndex:(index + 1)];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.backgroundColor = [UIColor clearColor];
	
	[self update];
}

@end
