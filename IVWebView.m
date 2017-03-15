//
//  IVWebView.m
//  iVerb
//
//  Created by Maxime on 7/28/14.
//
//

#import "IVWebView.h"

@implementation IVWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
	if ((self = [super initWithFrame:frame configuration:configuration])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tintColorDidChange)
													 name:UIAccessibilityDarkerSystemColorsStatusDidChangeNotification object:nil];
	}
	return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    CGFloat r, g, b, a;
    [self.tintColor getRed:&r green:&g blue:&b alpha:&a];
	
	NSString * const script = [NSString stringWithFormat:
							   @"function setTintColor() {"
							   @"  var elements = document.getElementsByTagName('a');"
							   @"  for (i = 0, len = elements.length; i < len; ++i) {"
							   @"    elements[i].style.color = 'rgba(%.0f, %.0f, %.0f, %.3f)';"
							   @"  }"
							   @"}; setTintColor(); document.body.onload = setTintColor;",
							   (r * 255), (g * 255), (b * 255), a];
	[self evaluateJavaScript:script completionHandler:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIAccessibilityDarkerSystemColorsStatusDidChangeNotification object:nil];
}

@end
