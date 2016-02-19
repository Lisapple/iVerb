//
//  NSString+addition.m
//  iVerb
//
//  Created by Max on 17/02/16.
//
//

#import "NSString+addition.h"
#import "NSMutableAttributedString+addition.h"

@implementation NSString (addition)

- (NSAttributedString *)highlightOccurrencesOfString:(NSString *)occurence fontSize:(CGFloat)fontSize
{
	NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] init];
	
	NSDictionary * const attributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:fontSize] };
	NSDictionary * const boldAttributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:fontSize] };
	
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

@end
