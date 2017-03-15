//
//  QuizResultsView.m
//  iVerb
//
//  Created by Max on 24/01/16.
//
//

#import "QuizResultsView.h"

@interface QuizResultsView ()

@property (nonatomic, strong) UILabel * leftLabel, * rightLabel;
@property (nonatomic, strong) UILabel * topPercentLabel;
@property (nonatomic, assign, readonly) CGFloat contentHeight;

@end

@implementation QuizResultsView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		
		_leftLabel = [[UILabel alloc] init];
		_leftLabel.textAlignment = NSTextAlignmentLeft;
		_leftLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1];
		[_leftLabel sizeToFit];
		[self addSubview:_leftLabel];
		
		_rightLabel = [[UILabel alloc] init];
		_rightLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		_rightLabel.textAlignment = NSTextAlignmentRight;
		_rightLabel.textColor = [UIColor darkGrayColor];
		[_rightLabel sizeToFit];
		[self addSubview:_rightLabel];
		
		_topPercentLabel = [[UILabel alloc] init];
		_topPercentLabel.textAlignment = NSTextAlignmentCenter;
		_topPercentLabel.text = @"80%";
		_topPercentLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1];
		[_topPercentLabel sizeToFit];
		_topPercentLabel.frame = CGRectInset(_topPercentLabel.frame, -3, -1); // Add extra margins
		_topPercentLabel.backgroundColor = [UIColor whiteColor];
		_topPercentLabel.clipsToBounds = YES;
		_topPercentLabel.layer.cornerRadius = _topPercentLabel.frame.size.height / 2;
		[self addSubview:_topPercentLabel];
		
		[self updateUI];
	}
	return self;
}

- (void)setLeftText:(NSString *)leftText
{
	_leftText = leftText;
	_leftLabel.text = _leftText;
	[_leftLabel sizeToFit];
	
	[self updateUI];
}

- (void)setRightText:(NSString *)rightText
{
	_rightText = rightText;
	_rightLabel.text = _rightText;
	[_rightLabel sizeToFit];
	
	[self updateUI];
}

- (void)updateUI
{
	CGRect rect = _leftLabel.frame;
	rect.origin = CGPointMake(2, self.frame.size.height - _leftLabel.frame.size.height - 8);
	_leftLabel.frame = rect;
	
	rect = _rightLabel.frame;
	rect.origin = CGPointMake(self.frame.size.width - _rightLabel.frame.size.width - 2, self.frame.size.height - _rightLabel.frame.size.height - 8);
	_rightLabel.frame = rect;
	
	_contentHeight = self.frame.size.height - (10 + MAX(_rightLabel.frame.size.height, _leftLabel.frame.size.height) + 2);
	
	rect = _topPercentLabel.frame;
	rect.origin = CGPointMake(10, _contentHeight * 0.2 + 4 - (rect.size.height / 2));
	_topPercentLabel.frame = rect;
	
	[self setNeedsDisplay];
}

- (void)setPoints:(Array(Value))points
{
	_points = points;
	[self updateUI];
}

/**
 Add a smooth spline path passing through each `points'; Add an empty path if `count' is zero.
 @discussion First and last points tangents are zero.
 */
void LSContextAddSmoothSpline(CGContextRef context, CGPoint points[], size_t count)
{
	CGContextBeginPath(context);
	if (count == 0)
		return ;
	
	CGContextMoveToPoint(context, points[0].x, points[0].y);
	
	CGFloat prevTangentAngle = 0;
	for (NSUInteger i = 1; i < count; ++i) {
		
		const CGPoint prev_pt = points[i-1];
		const CGPoint pt = points[i];
		
		const CGFloat tangentLength = MIN(60, ABS(pt.x - prev_pt.x) / 2) * ((prev_pt.x < pt.x) ?: -1); // Negative if points goes from right to left
		CGFloat tangentAngle = 0; // Set vertical tangent by default
		if (i != (count - 1)) { // Skip for last point
			const CGPoint next_pt = points[i+1];
			if ((prev_pt.y < pt.y && pt.y < next_pt.y) ||
				(prev_pt.y > pt.y && pt.y > next_pt.y)) // If the point is between previous and next points (from y-axis), compute tangent angle
				tangentAngle = atan2(next_pt.y - prev_pt.y, next_pt.x - prev_pt.x);
		}
		
		CGContextAddCurveToPoint(context,
								 prev_pt.x + tangentLength * cos(prevTangentAngle), prev_pt.y + tangentLength * sin(prevTangentAngle),
								 pt.x - tangentLength * cos(tangentAngle), pt.y - tangentLength * sin(tangentAngle),
								 pt.x, pt.y);
		
		prevTangentAngle = tangentAngle; // Keep the same tangent angle for each point (at left and right of the point)
	}
}

- (void)drawRect:(CGRect)rect
{
	rect.size.height = self.contentHeight;
	CGRect frame = CGRectInset(rect, 4, 2);
	frame.origin.y += 4;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Clip content ouside |frame|
	CGContextClipToRect(context, CGRectInset(rect, 2, 1));
	
	const UIColor * lightGrayColor = [UIColor colorWithWhite:0.85 alpha:1];
	
	// Draw bottom line (at 0%)
	[lightGrayColor setStroke];
	CGContextSetLineWidth(context, 1);
	CGContextBeginPath(context);
	{
		const CGFloat percent = 0;
		CGFloat y = frame.origin.y + frame.size.height * (1 - percent);
		CGContextMoveToPoint(context, frame.origin.x, y);
		CGContextAddLineToPoint(context, frame.origin.x + frame.size.width, y);
	}
	CGContextStrokePath(context);
	
	// Draw middle line (at 50%)
	CGContextBeginPath(context);
	{
		const CGFloat percent = 0.5;
		CGFloat y = frame.origin.y + frame.size.height * (1 - percent);
		CGContextMoveToPoint(context, frame.origin.x, y);
		CGContextAddLineToPoint(context, frame.origin.x + frame.size.width, y);
	}
	CGContextStrokePath(context);
	
	// Draw top line (at 80%)
	CGContextBeginPath(context);
	{
		const CGFloat percent = 0.8;
		CGFloat y = frame.origin.y + frame.size.height * (1 - percent);
		CGContextMoveToPoint(context, frame.origin.x, y);
		CGContextAddLineToPoint(context, frame.size.width, y);
	}
	[[UIColor colorWithWhite:0.75 alpha:1] setStroke];
	CGContextSaveGState(context);
	CGContextSetLineDash(context, 0, (const CGFloat[]){ 8, 4 }, 2);
	CGContextStrokePath(context);
	CGContextRestoreGState(context);
	
	CGPoint * points = (CGPoint *)calloc(_points.count, sizeof(CGPoint));
	int index = 0;
	for (NSValue * pointValue in _points) {
		CGPoint point = pointValue.CGPointValue;
		points[index] = CGPointMake(frame.origin.x + point.x * frame.size.width,
									frame.origin.y + (1 - point.y) * frame.size.height);
		++index;
	}
	
	// Draw vertical line for last (left) point
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, points[_points.count-1].x, points[_points.count-1].y);
	CGContextAddLineToPoint(context, points[_points.count-1].x, frame.size.height);
	CGContextSetLineWidth(context, 1);
	[lightGrayColor setStroke];
	CGContextStrokePath(context);
	
	// Draw vertical line for first (right) point
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, points[0].x, points[0].y);
	CGContextAddLineToPoint(context, points[0].x, frame.size.height);
	[[UIColor darkGrayColor] setStroke];
	CGContextStrokePath(context);
	
	// Create progression mask
	UIImage * image = nil;
	CGContextSaveGState(context);
	{
		UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextScaleCTM(context, 1, -1);
		CGContextTranslateCTM(context, 0, -rect.size.height);
		
		[[UIColor blackColor] set];
		
		// Draw points
		const CGFloat pointWide = 5;
		for (int i = 0; i < _points.count; ++i) {
			const CGRect rect = CGRectMake(points[i].x - pointWide/2, points[i].y - pointWide/2, pointWide, pointWide);
			CGContextFillEllipseInRect(context, rect);
		}
		
		// Draw progression curve
		LSContextAddSmoothSpline(context, points, _points.count);
		CGContextSetLineWidth(context, 2);
		CGContextSetLineJoin(context, kCGLineJoinRound);
		CGContextStrokePath(context);
		
		image = UIGraphicsGetImageFromCurrentImageContext();
	}
	CGContextRestoreGState(context);
	
	if (points) free(points);
	
	// Create gradient from progression mask
	CGContextClipToMask(context, rect, image.CGImage);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
														(__bridge CFArrayRef)@[ (id)lightGrayColor.CGColor, (id)[UIColor darkGrayColor].CGColor ],
														(const CGFloat[]){ 0, 1 });
	CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(rect.size.width, 0), 0);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
}

@end
