//
//  Verb+additions.m
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Verb+additions.h"
#import "Quote.h"

#import "UIFont+addition.h"
#import "NSMutableAttributedString+addition.h"

@implementation Verb (additions)

- (NSString *)HTMLFormat
{
	NSMutableString * content = [NSMutableString stringWithCapacity:1000];
	[content appendFormat:
	 @"<a href=\"#help-infinitive\">Infinitive</a>" @"<br>"
	 @"<p class=\"verb-form\">%@</p>"
	 @"<a href=\"#help-simple-past\">Simple Past</a>" @"<br>"
	 @"<p class=\"verb-form\">%@</p>"
	 @"<a href=\"#help-past-participle\">Past Participle</a>" @"<br>"
	 @"<p class=\"verb-form\">%@</p>", self.infinitif, self.past, self.pastParticiple];
	
	if (self.definition) {
		[content appendFormat:
		 @"<a href=\"#help-definition\">Definition</a>" @"<br>"
		 @"<p class=\"verb-definition\">%@</p>", self.definition];
	}
	
	if (self.example) {
		[content appendFormat:
		 @"<a href=\"#help-example\">Example</a>" @"<br>"
		 @"<p class=\"verb-example\">%@</p>", self.example];
	}
	
	NSArray * components = [self.components componentsSeparatedByString:@"."];
	if (components.count > 1) {
		[content appendFormat:
		 @"<a href=\"#help-composition\">Composition</a>" @"<br>"
		 @"<p class=\"verb-composition\">%@</p>", [components componentsJoinedByString:@"&bull;"]];
	}
	
	if (self.note.length > 0) {
		[content appendFormat:
		 @"<a href=\"#edit-note\">Notes</a>" @"<br>"
		 @"<p class=\"verb-notes\">%@</p>", self.note];
	}
	
	if (self.quote.infinitif.length > 0) {
		NSString * quote = self.quote.infinitifDescription;
		[content appendFormat:
		 @"<a href=\"#help-quote\">Quote</a>" @"<br>"
		 @"<p class=\"verb-notes\" style=\"padding-bottom:8px\">&laquo;&nbsp;%@&nbsp;&raquo;</p>"
		 @"<p class=\"verb-notes\" style=\"font-style:italic;padding-top:0px\">%@</p>", quote, self.quote.infinitifAuthor];
	}
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
	NSString * template = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	return [template stringByReplacingOccurrencesOfString:@"{{@}}" withString:content];
}

- (NSAttributedString *)attributedDescription
{
	Dictionary(String, Object) boldAttributes = @{ NSFontAttributeName : [UIFont preferredBoldFontForTextStyle:UIFontTextStyleBody] };
	Dictionary(String, Object) italicsAttributes = @{ NSFontAttributeName : [UIFont preferredItalicFontForTextStyle:UIFontTextStyleBody] };
	
	NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] init];
	
	[attrString appendString:[NSString stringWithFormat:@"To %@", self.infinitif] attributes:boldAttributes];
	[attrString appendString:[NSString stringWithFormat:@", %@, %@", self.past, self.pastParticiple] attributes:@{}];
	if (self.definition) {
		[attrString appendString:[@"\n" stringByAppendingString:self.definition] attributes:@{}];
	}
	if (self.note) {
		[attrString appendString:[@"\n" stringByAppendingString:self.note] attributes:italicsAttributes];
	}
	return attrString;
}

@end
