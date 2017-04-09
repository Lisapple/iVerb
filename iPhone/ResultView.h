//
//  ResultView.h
//  iVerb
//
//  Created by Max on 08/04/2017.
//
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ResultTitle) {
	ResultTitleInfinitive,
	ResultTitlePast,
	ResultTitleParticiple,
	ResultTitleDefinition,
	ResultTitleComposition,
	ResultTitleNote,
	ResultTitleQuote
};

@class ResultView;
@protocol ResultViewDelegate <UIScrollViewDelegate>

- (void)resultView:(ResultView *)resultView didSelectTitle:(ResultTitle)title;

@end

@class Verb;
@interface ResultView : UIScrollView

@property (nonatomic, weak) id <ResultViewDelegate> delegate;
@property (nonatomic, strong) Verb * verb;

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder UNAVAILABLE_ATTRIBUTE;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
