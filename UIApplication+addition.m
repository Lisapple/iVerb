//
//  UIApplication+addition.m
//  iVerb
//
//  Created by Max on 20/09/16.
//
//

#import "UIApplication+addition.h"

@implementation UIApplication (addition)

- (void)openExternalURL:(NSURL *)url
{
	if ([self respondsToSelector:@selector(openURL:options:completionHandler:)]) {
		[self openURL:url options:@{} completionHandler:nil];
	} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		[self openURL:url];
#pragma clang diagnostic pop
	}
}

@end
