//
//  UIFont+addition.m
//  iVerb
//
//  Created by Max on 05/01/2017.
//
//

#import "UIFont+addition.h"

@implementation UIFont (addition)

+ (UIFont *)preferredItalicFontForTextStyle:(UIFontTextStyle)style
{
	UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
	descriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
	return [UIFont fontWithDescriptor:descriptor size:descriptor.pointSize];
}

+ (UIFont *)preferredBoldFontForTextStyle:(UIFontTextStyle)style
{
	UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
	descriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
	return [UIFont fontWithDescriptor:descriptor size:descriptor.pointSize];
}

@end
