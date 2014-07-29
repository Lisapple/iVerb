//
//  IVWebView.m
//  iVerb
//
//  Created by Maxime on 7/28/14.
//
//

#import "IVWebView.h"

@implementation IVWebView

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    CGFloat r, g, b, a;
    [self.window.tintColor getRed:&r green:&g blue:&b alpha:&a];
    
    NSString * script = [NSString stringWithFormat:@"var e; var elements = document.getElementsByTagName('a'); for (i = 0; i < elements.length; ++i) { elements[i].style.color = 'rgba(%.0f, %.0f, %.0f, %.0f)'; }", (r * 255), (g * 255), (b * 255), (a * 255)];
    [self stringByEvaluatingJavaScriptFromString:script];
}

@end
