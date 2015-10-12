//
//  Quote.m
//  iVerb
//
//  Created by Max on 06/10/15.
//
//

#import "Quote.h"

@implementation Quote

@dynamic infinitif, past, pastParticiple;
@dynamic verb;

- (NSString *)descriptionFromString:(NSString *)string
{
	if (!string)
		return nil;
	
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"[^\\[]+" options:0 error:NULL];
	NSRange range = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)].firstObject.range;
	return [string substringWithRange:range];
}

- (NSString *)authorFromString:(NSString *)string
{
	if (!string)
		return nil;
		
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^.+\\[(.+)\\]" options:0 error:NULL];
	return [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"$1"];
}

- (NSString *)infinitifDescription
{
	return [self descriptionFromString:self.infinitif];
}

- (NSString *)infinitifAuthor
{
	return [self authorFromString:self.infinitif];
}

- (NSString *)pastDescription
{
	return [self descriptionFromString:self.past];
}

- (NSString *)pastAuthor
{
	return [self authorFromString:self.past];
}

- (NSString *)pastParticipleDescription
{
	return [self descriptionFromString:self.pastParticiple];
}

- (NSString *)pastParticipleAuthor
{
	return [self authorFromString:self.pastParticiple];
}

@end
