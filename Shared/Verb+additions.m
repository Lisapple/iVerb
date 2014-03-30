//
//  Verb+additions.m
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Verb+additions.h"

@implementation Verb (additions)

- (NSString *)HTMLFormatInlineCSS
{
	if (self.isBookmarked) {
		// @TODO: add a field "data-bookmark" to show the star to bookmark/unbookmark
	}
	
	NSMutableString * content = [NSMutableString stringWithCapacity:1000];
	
	/* <span class="section">Infinitif</span><br>
	 * <div class="verb-form">%@</div>
	 * <span class="section">Simple Past</span><br>
	 * <div class="verb-form">%@</div>
	 * <span class="section">Past Participle</span><br>
	 * <div class="verb-form">%@</div>
	 */
	
	[content appendFormat:@"\
	 <span style=\"color:#aaa\">Infinitif</span><br>\
	 <div style=\"font-weight:bold;font-size:20px;padding:15px\">%@</div>\
	 <span style=\"color:#aaa\">Simple Past</span><br>\
	 <div style=\"font-weight:bold;font-size:20px;padding:15px\">%@</div>\
	 <span style=\"color:#aaa\">Past Participle</span><br>\
	 <div style=\"font-weight:bold;font-size:20px;padding:15px\">%@</div>", self.infinitif, self.past, self.pastParticiple];
	
	if (self.definition) {
		/* <span class="section">Definition</span><br>
		 * <div class="verb-definition">%@</div>
		 */
		[content appendFormat:@"<span style=\"color:#aaa\">Definition</span><br>\
		 <div style=\"font-weight:bold;font-size:16px;padding:15px\">%@</div>", self.definition];
	}
	
	if (self.example) {
		/* <span class="section">Example</span><br>
		 * <div class="verb-example">%@</div>
		 */
		[content appendFormat:@"<span style=\"color:#aaa\">Example</span><br>\
		 <div style=\"font-weight:bold;font-size:16px;padding:15px\">%@</div>", self.example];
	}
	
	NSArray * components = [self.components componentsSeparatedByString:@"."];
	if (components.count > 1) {
		/* <span class="section">Composition</span><br>
		 * <div class="verb-composition">%@</div>
		 */
		[content appendFormat:@"<span style=\"color:#aaa\">Composition</span><br>\
		 <div style=\"font-weight:bold;font-size:16px;padding:15px\">%@</div>", [components componentsJoinedByString:@"&bull;"]];
	}
	
	/* Retreive the note from userDefaults */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString * key = [NSString stringWithFormat:@"note_%@", self.infinitif];
	NSString * note = [userDefaults stringForKey:key];
	if (note.length > 0) {
		[content appendFormat:@"<span style=\"color:#aaa\">Notes</span><br>\
		 <div style=\"font-weight:bold;font-size:16px;padding:15px\">%@</div>", note];
	}
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
	NSString * template = [NSString stringWithContentsOfFile:path
													encoding:NSUTF8StringEncoding
													   error:NULL];
	return [template stringByReplacingOccurrencesOfString:@"{{@}}" withString:content];
}

- (NSString *)HTMLFormat
{
	if (self.isBookmarked) {
		// @TODO: add a field "data-bookmark" to show the star to bookmark/unbookmark
	}
	
	NSMutableString * content = [NSMutableString stringWithCapacity:1000];
	
	/* <span class="section">Infinitif</span><br>
	 * <div class="verb-form">%@</div>
	 * <span class="section">Simple Past</span><br>
	 * <div class="verb-form">%@</div>
	 * <span class="section">Past Participle</span><br>
	 * <div class="verb-form">%@</div>
	 */
	
	[content appendFormat:@"\
	 <span class=\"section\">Infinitif</span><br>\
	 <div class=\"verb-form\">%@</div>\
	 <span class=\"section\">Simple Past</span><br>\
	 <div class=\"verb-form\">%@</div>\
	 <span class=\"section\">Past Participle</span><br>\
	 <div class=\"verb-form\">%@</div>", self.infinitif, self.past, self.pastParticiple];
	
	if (self.definition) {
		/* <span class="section">Definition</span><br>
		 * <div class="verb-definition">%@</div>
		 */
		[content appendFormat:@"<span class=\"section\">Definition</span><br>\
		 <div class=\"verb-definition\">%@</div>", self.definition];
	}
	
	if (self.example) {
		/* <span class="section">Example</span><br>
		 * <div class="verb-example">%@</div>
		 */
		[content appendFormat:@"<span class=\"section\">Example</span><br>\
		 <div class=\"verb-example\">%@</div>", self.example];
	}
	
	NSArray * components = [self.components componentsSeparatedByString:@"."];
	if (components.count > 1) {
		/* <span class="section">Composition</span><br>
		 * <div class="verb-composition">%@</div>
		 */
		[content appendFormat:@"<span class=\"section\">Composition</span><br>\
		 <div class=\"verb-composition\">%@</div>", [components componentsJoinedByString:@"&bull;"]];
	}
	
	/* Retreive the note from userDefaults */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString * key = [NSString stringWithFormat:@"note_%@", self.infinitif];
	NSString * note = [userDefaults stringForKey:key];
	if (note.length > 0) {
		[content appendFormat:@"<span class=\"section\">Notes</span><br>\
		 <div class=\"verb-notes\">%@</div>", note];
	}
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
	NSString * template = [NSString stringWithContentsOfFile:path
													encoding:NSUTF8StringEncoding
													   error:NULL];
	return [template stringByReplacingOccurrencesOfString:@"{{@}}" withString:content];
}

@end
