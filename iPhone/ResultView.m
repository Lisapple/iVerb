//
//  ResultView.m
//  iVerb
//
//  Created by Max on 08/04/2017.
//
//

#import "ResultView.h"

#import "Verb.h"
#import "Quote.h"

#import "UIColor+addition.h"

@interface ResultLabel: UILabel
@end

@implementation ResultLabel

- (void)drawTextInRect:(CGRect)rect
{
	UIEdgeInsets insets = UIEdgeInsetsMake(0, 10, 0, 10);
	[super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end

@interface ResultView ()

@property (nonatomic, strong) UIView * contentView;

@property (nonatomic, strong) UIButton * infinitiveButton;
@property (nonatomic, strong) UILabel * infinitiveLabel;
@property (nonatomic, strong) UIButton * pastButton;
@property (nonatomic, strong) UILabel * pastLabel;
@property (nonatomic, strong) UIButton * participleButton;
@property (nonatomic, strong) UILabel * participleLabel;
@property (nonatomic, nullable, strong) UIButton * definitionButton;
@property (nonatomic, nullable, strong) UILabel * definitionLabel;
@property (nonatomic, nullable, strong) UIButton * compositionButton;
@property (nonatomic, nullable, strong) UILabel * compositionLabel;
@property (nonatomic, nullable, strong) UIButton * noteButton;
@property (nonatomic, nullable, strong) UILabel * noteLabel;
@property (nonatomic, nullable, strong) UIButton * quoteButton;
@property (nonatomic, nullable, strong) UILabel * quoteLabel;

@end

@implementation ResultView

@dynamic delegate;

+ (BOOL)requiresConstraintBasedLayout
{
	return YES;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor whiteColor];
		
		_contentView = [[UIView alloc] initWithFrame:CGRectZero];
		_contentView.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_contentView];
		[self addConstraints:@[ [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
																toItem:_contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
								[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
																toItem:_contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
								[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
																toItem:_contentView attribute:NSLayoutAttributeRight multiplier:1 constant:0],
								[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
																toItem:_contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
								[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
																toItem:_contentView attribute:NSLayoutAttributeWidth multiplier:1 constant:0] ]];
	}
	return self;
}

- (void)setVerb:(Verb *)verb
{
	_verb = verb;
	[self reloadData];
}

- (void)reloadData
{
	[_contentView.subviews valueForKey:NSStringFromSelector(@selector(removeFromSuperview))];
	
	// Infinitive
	_infinitiveButton = [UIButton buttonWithType:UIButtonTypeSystem];
	_infinitiveButton.translatesAutoresizingMaskIntoConstraints = NO;
	_infinitiveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	_infinitiveButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_infinitiveButton.tintColor = [UIColor foregroundColor];
	[_infinitiveButton addTarget:self action:@selector(titleAction:) forControlEvents:UIControlEventTouchUpInside];
	[_infinitiveButton setTitle:@"Infinitive" forState:UIControlStateNormal];
	[_contentView addSubview:_infinitiveButton];
	
	_infinitiveLabel = [[ResultLabel alloc] init];
	_infinitiveLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_infinitiveLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_infinitiveLabel.textColor = [UIColor darkGrayColor];
	_infinitiveLabel.text = _verb.infinitif;
	_infinitiveLabel.layoutMargins = UIEdgeInsetsMake(0, 10, 0, 10);
	[_contentView addSubview:_infinitiveLabel];
	
	// Past
	_pastButton = [UIButton buttonWithType:UIButtonTypeSystem];
	_pastButton.translatesAutoresizingMaskIntoConstraints = NO;
	_pastButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	_pastButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_pastButton.tintColor = [UIColor foregroundColor];
	[_pastButton addTarget:self action:@selector(titleAction:) forControlEvents:UIControlEventTouchUpInside];
	[_pastButton setTitle:@"Past" forState:UIControlStateNormal];
	[_contentView addSubview:_pastButton];
	
	_pastLabel = [[ResultLabel alloc] init];
	_pastLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_pastLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_pastLabel.textColor = [UIColor darkGrayColor];
	_pastLabel.text = _verb.past;
	[_contentView addSubview:_pastLabel];
	
	// Past participle
	_participleButton = [UIButton buttonWithType:UIButtonTypeSystem];
	_participleButton.translatesAutoresizingMaskIntoConstraints = NO;
	_participleButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	_participleButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_participleButton.tintColor = [UIColor foregroundColor];
	[_participleButton addTarget:self action:@selector(titleAction:) forControlEvents:UIControlEventTouchUpInside];
	[_participleButton setTitle:@"Past Participle" forState:UIControlStateNormal];
	[_contentView addSubview:_participleButton];
	
	_participleLabel = [[ResultLabel alloc] init];
	_participleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_participleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_participleLabel.textColor = [UIColor darkGrayColor];
	_participleLabel.text = _verb.pastParticiple;
	[_contentView addSubview:_participleLabel];
	
	// Definition
	if (_verb.definition) {
		_definitionButton = [UIButton buttonWithType:UIButtonTypeSystem];
		_definitionButton.translatesAutoresizingMaskIntoConstraints = NO;
		_definitionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		_definitionButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		_definitionButton.tintColor = [UIColor foregroundColor];
		[_definitionButton addTarget:self action:@selector(titleAction:) forControlEvents:UIControlEventTouchUpInside];
		[_definitionButton setTitle:@"Definition" forState:UIControlStateNormal];
		[_contentView addSubview:_definitionButton];
		
		_definitionLabel = [[ResultLabel alloc] init];
		_definitionLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_definitionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		_definitionLabel.textColor = [UIColor darkGrayColor];
		_definitionLabel.numberOfLines = 0;
		_definitionLabel.text = _verb.definition;
		[_contentView addSubview:_definitionLabel];
	}
	
	// Components
	NSArray <NSString *> * const components = [_verb.components componentsSeparatedByString:@"."];
	if (components.count > 1) {
		_compositionButton = [UIButton buttonWithType:UIButtonTypeSystem];
		_compositionButton.translatesAutoresizingMaskIntoConstraints = NO;
		_compositionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		_compositionButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		_compositionButton.tintColor = [UIColor purpleColor];
		[_compositionButton addTarget:self action:@selector(titleAction:) forControlEvents:UIControlEventTouchUpInside];
		[_compositionButton setTitle:@"Components" forState:UIControlStateNormal];
		[_contentView addSubview:_compositionButton];
		
		_compositionLabel = [[ResultLabel alloc] init];
		_compositionLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_compositionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		_compositionLabel.textColor = [UIColor darkGrayColor];
		_compositionLabel.text = [components componentsJoinedByString:@"•"];
		[_contentView addSubview:_compositionLabel];
	}
	
	// Notes
	if (_verb.note.length > 0) {
		_noteButton = [UIButton buttonWithType:UIButtonTypeSystem];
		_noteButton.translatesAutoresizingMaskIntoConstraints = NO;
		_noteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		_noteButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		_noteButton.tintColor = [UIColor foregroundColor];
		[_noteButton addTarget:self action:@selector(titleAction:) forControlEvents:UIControlEventTouchUpInside];
		[_noteButton setTitle:@"Notes" forState:UIControlStateNormal];
		[_contentView addSubview:_noteButton];
		
		_noteLabel = [[ResultLabel alloc] init];
		_noteLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_noteLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		_noteLabel.textColor = [UIColor darkGrayColor];
		_noteLabel.numberOfLines = 0;
		_noteLabel.text = _verb.note;
		[_contentView addSubview:_noteLabel];
	}
	
	// Quote
	if (_verb.quote.infinitif.length > 0) {
		_quoteButton = [UIButton buttonWithType:UIButtonTypeSystem];
		_quoteButton.translatesAutoresizingMaskIntoConstraints = NO;
		_quoteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		_quoteButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		_quoteButton.tintColor = [UIColor foregroundColor];
		[_quoteButton addTarget:self action:@selector(titleAction:) forControlEvents:UIControlEventTouchUpInside];
		[_quoteButton setTitle:@"Quote" forState:UIControlStateNormal];
		[_contentView addSubview:_quoteButton];
		
		_quoteLabel = [[ResultLabel alloc] init];
		_quoteLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_quoteLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		_quoteLabel.textColor = [UIColor darkGrayColor];
		_quoteLabel.numberOfLines = 0;
		[_contentView addSubview:_quoteLabel];
		
		NSString * const quote = [NSString stringWithFormat:@"« %@ » ", _verb.quote.infinitifDescription];
		NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:quote];
		
		NSDictionary * attributes = @{ NSForegroundColorAttributeName : [UIColor grayColor],
									   NSObliquenessAttributeName : @0.25 };
		[string appendAttributedString:[[NSAttributedString alloc] initWithString:_verb.quote.infinitifAuthor
																	   attributes:attributes]];
		_quoteLabel.attributedText = string;
	}
	
	NSMutableDictionary <NSString *, UIView *> * views = [NSMutableDictionary dictionaryWithCapacity:14];
	for (UIView * subview in _contentView.subviews) {
		NSString * const key = [NSString stringWithFormat:@"v%lu", subview.hash];
		views[key] = subview;
	}
	
	NSMutableArray <NSString *> * formats = [NSMutableArray arrayWithCapacity:14];
	for (UIView * subview in _contentView.subviews) {
		NSString * const key = [NSString stringWithFormat:@"v%lu", subview.hash];
		[formats addObject:[NSString stringWithFormat:@"[%@]", key]];
	}
	
	assert(views.count == formats.count);
	[_contentView addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%@-|", [formats componentsJoinedByString:@"-15-"]]
											 options:(NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight)
											 metrics:nil
											   views:views]];
	[_contentView addConstraints:
	 @[ [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeTopMargin relatedBy:NSLayoutRelationEqual
										toItem:_infinitiveButton attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeftMargin relatedBy:NSLayoutRelationEqual
										toItem:_infinitiveButton attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeRightMargin relatedBy:NSLayoutRelationEqual
										toItem:_infinitiveButton attribute:NSLayoutAttributeRight multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationEqual
										toItem:_contentView.subviews.lastObject attribute:NSLayoutAttributeBottom multiplier:1 constant:0] ]];
}

- (void)titleAction:(UIButton *)sender
{
	ResultTitle title;
	if /*  */ (sender == _infinitiveButton) {
		title = ResultTitleInfinitive;
	} else if (sender == _pastButton) {
		title = ResultTitlePast;
	} else if (sender == _participleButton) {
		title = ResultTitleParticiple;
	} else if (sender == _definitionButton) {
		title = ResultTitleDefinition;
	} else if (sender == _compositionButton) {
		title = ResultTitleComposition;
	} else if (sender == _noteButton) {
		title = ResultTitleNote;
	} else if (sender == _quoteButton) {
		title = ResultTitleQuote;
	} else { assert(false); }
	
	[self.delegate resultView:self didSelectTitle:title];
}

@end
