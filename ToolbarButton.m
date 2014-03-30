//
//  ToolbarButton.m
//  iVerb
//
//  Created by Maxime Leroy on 3/23/13.
//
//

#import "ToolbarButton.h"

@implementation ToolbarButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitleColor:[UIColor darkGrayColor]
				   forState:UIControlStateHighlighted];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	float x = .5, y = .5, width = rect.size.width - 1., height = rect.size.height - 1.;
	float radius = 4.;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, radius);
	CGContextAddArcToPoint(context, x, y, x + radius, y, radius);
	CGContextAddArcToPoint(context, x + width, y, x + width, radius, radius);
	CGContextAddArcToPoint(context, x + width, height + y, x + width - radius, height + y, radius);
	CGContextAddArcToPoint(context, x, height + y, x, height - radius, radius);
	CGContextClosePath(context);
	
	CGPathRef pathRef = CGContextCopyPath(context);
	
	if (self.highlighted) {
		[[UIColor grayColor] setFill];
	} else {
		[[UIColor whiteColor] setFill];
	}
	
	CGContextFillPath(context);
	
	CGContextAddPath(context, pathRef);
	[[UIColor grayColor] setStroke];
	CGContextSetLineWidth(context, 1.);
	CGContextStrokePath(context);
	
	CGPathRelease(pathRef);
}

- (void)setHighlighted:(BOOL)highlighted
{
	[self setNeedsDisplay];
	super.highlighted = highlighted;
}

@end

@implementation DeleteToolbarButton

- (void)drawRect:(CGRect)rect
{
	float x = 1., y = 1., width = rect.size.width - 2., height = rect.size.height - 2.;
	float radius = 4.;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, radius);
	CGContextAddArcToPoint(context, x, y, x + radius, y, radius);
	CGContextAddArcToPoint(context, x + width, y, x + width, radius, radius);
	CGContextAddArcToPoint(context, x + width, height + y, x + width - radius, height + y, radius);
	CGContextAddArcToPoint(context, x, height + y, x, height - radius, radius);
	CGContextClosePath(context);
	
	//CGPathRef pathRef = CGContextCopyPath(context);
	
	if (self.highlighted) {
		[[UIColor blackColor] setFill];
	} else {
		[[UIColor darkGrayColor] setFill];
	}
	
	CGContextFillPath(context);
	
	/*
	CGContextAddPath(context, pathRef);
	[[UIColor darkGrayColor] setStroke];
	CGContextSetLineWidth(context, 2.);
	CGContextStrokePath(context);
	 
	 CGPathRelease(pathRef);
	*/
}

@end
