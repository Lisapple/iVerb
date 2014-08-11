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
	NSMutableString * content = [NSMutableString stringWithCapacity:1000];
	
	/* <a href="#help">Infinitif</span><br>
	 * <div class="verb-form">%@</div>
	 * <a href="#help">Simple Past</span><br>
	 * <div class="verb-form">%@</div>
	 * <a href="#help">Past Participle</span><br>
	 * <div class="verb-form">%@</div>
	 */
	
	[content appendFormat:@"\
	 <a href=\"#help-infinitive\">Infinitif</a><br>\
	 <div class=\"verb-form\">%@</div>\
	 <a href=\"#help-simple-past\">Simple Past</a><br>\
	 <div class=\"verb-form\">%@</div>\
	 <a href=\"#help-past-participle\">Past Participle</a><br>\
	 <div class=\"verb-form\">%@</div>", self.infinitif, self.past, self.pastParticiple];
	
	if (self.definition) {
		/* <a href="#help">Definition</span><br>
		 * <div class="verb-definition">%@</div>
		 */
		[content appendFormat:@"<a href=\"#help-definition\">Definition</a><br>\
		 <div class=\"verb-definition\">%@</div>", self.definition];
	}
	
	if (self.example) {
		/* <a href="#help">Example</span><br>
		 * <div class="verb-example">%@</div>
		 */
		[content appendFormat:@"<a href=\"#help-example\">Example</a><br>\
		 <div class=\"verb-example\">%@</div>", self.example];
	}
	
	NSArray * components = [self.components componentsSeparatedByString:@"."];
	if (components.count > 1) {
		/* <a href="#help">Composition</span><br>
		 * <div class="verb-composition">%@</div>
		 */
		[content appendFormat:@"<a href=\"#help-composition\">Composition</a><br>\
		 <div class=\"verb-composition\">%@</div>", [components componentsJoinedByString:@"&bull;"]];
	}
	
	/* Retreive the note from userDefaults */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString * key = [NSString stringWithFormat:@"note_%@", self.infinitif];
	NSString * note = [userDefaults stringForKey:key];
	if (note.length > 0) {
		[content appendFormat:@"<a href=\"#edit-note\">Notes</a><br>\
		 <div class=\"verb-notes\">%@</div>", note];
	}
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
	NSString * template = [NSString stringWithContentsOfFile:path
													encoding:NSUTF8StringEncoding
													   error:NULL];
	return [template stringByReplacingOccurrencesOfString:@"{{@}}" withString:content];
}

@end
