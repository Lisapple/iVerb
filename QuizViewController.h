//
//  QuizViewController.h
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import <UIKit/UIKit.h>

#import "Playlist.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ResponseState) {
	ResponseStateTrue,
	ResponseStateFalse
};

typedef NS_ENUM(NSUInteger, VerbForm) {
	VerbFormUnspecified = -1,
	VerbFormPastSimple = 0,
	VerbFormPastParticiple
};

@interface QuizViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>
{
	NSArray * allVerbs;
	NSInteger currentIndex;
	NSString * currentResponse;
	NSInteger goodResponseCount, badResponseCount;
	NSMutableArray <NSString *> * responses;
	NSMutableArray <NSNumber /* BOOL */ *> * responsesCorrect;
	NSMutableArray <NSNumber /* VerbForm */ *> * forms;
	
	UIView * previousPushedView;
}

@property (nonatomic, weak) IBOutlet UIView * quizView, * responseView;

@property (nonatomic, weak) IBOutlet UILabel * infinitifLabel, * formLabel, * remainingCount;
@property (nonatomic, weak) IBOutlet UITextField * textField;
@property (nonatomic, weak) IBOutlet UIImageView * backgroundFieldImageView;

@property (nonatomic, weak) IBOutlet UIImageView * responseImageView;
@property (nonatomic, weak) IBOutlet UILabel * responseLabel;

- (instancetype)initWithPlaylist:(nonnull Playlist *)playlist;
- (instancetype)initWithPlaylist:(nonnull Playlist *)playlist firstVerb:(nullable Verb *)verb verbForm:(VerbForm)verbForm NS_DESIGNATED_INITIALIZER;

#pragma mark Next Verb Management
- (IBAction)pushNewVerbAction:(nullable id)sender;
- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated;

#pragma mark Result Management
- (void)pushResultAnimated:(BOOL)animated;

#pragma mark Response Management
- (void)pushResponse:(ResponseState)response animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END