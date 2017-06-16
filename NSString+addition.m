//
//  NSString+addition.m
//  iVerb
//
//  Created by Max on 17/02/16.
//
//

#import "NSString+addition.h"

#import "NSMutableAttributedString+addition.h"
#import "UIColor+addition.h"

@implementation NSString (addition)

- (NSAttributedString *)highlightOccurrencesOfString:(NSString *)occurence fontSize:(CGFloat)fontSize
{
	NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] init];
	
	NSDictionary * const attributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:fontSize] };
	NSDictionary * const boldAttributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:fontSize weight:UIFontWeightHeavy] };
	
	NSInteger index = 0;
	NSRange range;
	while ((range = [self rangeOfString:occurence
								options:NSCaseInsensitiveSearch
								  range:NSMakeRange(index, self.length - index)]).location != NSNotFound) {
		[attrString appendString:[self substringWithRange:NSMakeRange(index, range.location - index)]
					  attributes:attributes];
		[attrString appendString:[self substringWithRange:range]
					  attributes:boldAttributes];
		index = range.location + range.length;
	}
	[attrString appendString:[self substringWithRange:NSMakeRange(index, self.length - index)]
				  attributes:attributes];
	return attrString;
}

- (NSAttributedString *)highlightDifferencesAgainstReference:(NSString *)referenceString
{
	NSDictionary * differencesAttrs = @{ NSForegroundColorAttributeName : [UIColor errorColor] };
	
	NSMutableString * commonLongestString = [NSMutableString string];
	NSMutableString * diffentLongestString = [NSMutableString string];
	NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] init];
	
	NSUInteger length = MIN(referenceString.length, self.length);
	for (NSInteger i = 0, offset = 0; i < length; ++i, ++offset) {
		NSString * const s1 = [referenceString substringWithRange:NSMakeRange(i, 1)];
		
		// If we are looking differences, allows searching into the whole remaining string
		NSRange range = (diffentLongestString.length > 0) ? NSMakeRange(offset, self.length - offset) : NSMakeRange(offset, 1);
		NSString * const str2 = [self substringWithRange:range];
		
		if ([str2 containsString:s1]) {
			if (diffentLongestString.length) {
				[attrString appendString:diffentLongestString attributes:differencesAttrs];
				diffentLongestString.string = @"";
				offset = MIN(offset+1, length-2);
			}
			[commonLongestString appendString:s1];
		} else {
			if (commonLongestString.length) {
				[attrString appendString:commonLongestString attributes:@{}];
				commonLongestString.string = @"";
				--offset;
			}
			[diffentLongestString appendString:s1];
		}
	}
	[attrString appendString:commonLongestString attributes:@{}];
	[attrString appendString:diffentLongestString attributes:differencesAttrs];
	
	if (length < referenceString.length)
		[attrString appendString:[referenceString substringFromIndex:length] attributes:differencesAttrs];
	
	NSAssert([attrString.string isEqualToString:referenceString], @"");
	return attrString;
}

@end
