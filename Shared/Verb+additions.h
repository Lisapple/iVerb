//
//  Verb+additions.h
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import UIKit;

#import "Verb.h"

NS_ASSUME_NONNULL_BEGIN

@interface Verb (additions)

+ (nullable Verb *)verbWithInfinitif:(NSString *)infinitif;
+ (nullable NSArray <Verb *> *)verbsWithInfinitives:(Array(String))infinitives;

- (NSString *)HTMLFormat UNAVAILABLE_ATTRIBUTE;

- (NSAttributedString *)attributedDescription;

@end

NS_ASSUME_NONNULL_END
