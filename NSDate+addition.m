//
//  NSDate+addition.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NSDate+addition.h"

@implementation NSDate(addition)

- (NSInteger)year
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"yyyy";
	return [dateFormatter stringFromDate:self].integerValue;
}

- (NSString *)naturalTimeString
{
	// Returns the more natural time format string. ex: 7h55
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.locale = [NSLocale currentLocale];
	dateFormatter.timeStyle = NSDateFormatterShortStyle;
	return [dateFormatter stringFromDate:self];
}

- (NSString *)description // ???: USED?
{
	if (self.timeIntervalSinceNow < 0)
		return nil;
	
	// Returns the smallest format. ex: 22/07/11, 16h09
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.locale = [NSLocale currentLocale];
	dateFormatter.dateStyle = NSDateFormatterShortStyle; // e.g.: 22/07/11
	NSString * dateString = [dateFormatter stringFromDate:self];
	
	return [NSString stringWithFormat:@"%@, %@", dateString, [self naturalTimeString]];
}

@end
