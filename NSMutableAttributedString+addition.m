//
//  NSMutableAttributedString+addition.m
//  iVerb
//
//  Created by Maxime on 8/20/14.
//
//

#import "NSMutableAttributedString+addition.h"

@implementation NSMutableAttributedString (addition)

- (void)appendString:(NSString *)string attributes:(NSDictionary *)attributes
{
	NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:string
																			attributes:attributes];
	[self appendAttributedString:attributedString];
}

@end
