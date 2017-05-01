//
//  Verb+additions.m
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Verb+additions.h"
#import "Quote.h"

#import "ManagedObjectContext.h"
#import "UIFont+addition.h"
#import "NSMutableAttributedString+addition.h"

@implementation Verb (additions)

+ (nullable Verb *)verbWithInfinitif:(NSString *)infinitif;
{
	return [self verbsWithInfinitives:@[ infinitif ]].firstObject;
}

+ (NSArray <Verb *> *)verbsWithInfinitives:(Array(String))infinitives
{
	NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(Verb.class)];
	request.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", SelectorName(infinitif), infinitives];
	request.fetchLimit = infinitives.count;
	NSError * error = nil;
	NSArray * verbs = [[ManagedObjectContext sharedContext] executeFetchRequest:request error:&error];
	if (error) {
		NSLog(@"Error during fetch: %@", error.localizedDescription);
		return nil;
	}
	return verbs;
}

- (NSAttributedString *)attributedDescription
{
	Dictionary(String, Object) boldAttributes = @{ NSFontAttributeName : [UIFont preferredBoldFontForTextStyle:UIFontTextStyleBody] };
	Dictionary(String, Object) italicsAttributes = @{ NSFontAttributeName : [UIFont preferredItalicFontForTextStyle:UIFontTextStyleBody] };
	
	NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] init];
	
	[attrString appendString:[NSString stringWithFormat:@"To %@", self.infinitif] attributes:boldAttributes];
	[attrString appendString:[NSString stringWithFormat:@", %@, %@", self.past, self.pastParticiple] attributes:@{}];
	if (self.definition)
		[attrString appendString:[@"\n" stringByAppendingString:self.definition] attributes:@{}];
	
	if (self.note)
		[attrString appendString:[@"\n" stringByAppendingString:self.note] attributes:italicsAttributes];
	
	return attrString;
}

@end
