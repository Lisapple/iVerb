//
//  NSString+addition.h
//  iVerb
//
//  Created by Max on 17/02/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (addition)

- (NSAttributedString *)highlightOccurrencesOfString:(NSString *)occurence fontSize:(CGFloat)fontSize;

@end