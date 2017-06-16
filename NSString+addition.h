//
//  NSString+addition.h
//  iVerb
//
//  Created by Max on 17/02/16.
//
//

@interface NSString (addition)

- (NSAttributedString *)highlightOccurrencesOfString:(NSString *)occurence fontSize:(CGFloat)fontSize;

//- (NSAttributedString *)highlightOccurrencesOfString:(NSString *)occurence textStyle:(UIFontTextStyle)style; // @TODO: Implement it

/// Returns attributed string with differences of the sender again the reference (validation) string in red color.
/// If the sender and the reference are equals, the returned string contains no red color.
// Examples (differences (red) are in parentheses):
// "cast" against reference "test" returns "(te)st"
// "abode" vs "abiden" returns "ab(i)de(n)"
// "abode" vs "abind" returns "ab(in)d"
// "abac" vs "abcc" returns "abc(c)"
// "misindertsoo" vs "misunderstood" returns "mis(u)nder(st)oo(d)"
// "tetet" vs "teeteet" returns "te(e)te(e)"
// "tatete" vs "teteta" returns "t(e)tet(e)"
// "teda" vs "date" returns "(da)te"

- (NSAttributedString *)highlightDifferencesAgainstReference:(NSString *)referenceString;

@end
