//
//  QuizViewController.h
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import "Playlist.h"
@import AVFoundation;
@import Speech;

NS_ASSUME_NONNULL_BEGIN

@interface SpeechRecognizerButton: UIButton

@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) CGFloat leftChannelLevel, rightChannelLevel;

@end


typedef NS_ENUM(NSUInteger, ResponseState) {
	ResponseStateTrue,
	ResponseStateFalse
};

typedef NS_ENUM(NSInteger, VerbForm) {
	VerbFormUnspecified = -1,
	VerbFormPastSimple = 0,
	VerbFormPastParticiple
};

@interface QuizViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView * quizView, * responseView;

@property (nonatomic, weak) IBOutlet UILabel * infinitifLabel, * formLabel, * remainingCount;
@property (nonatomic, weak) IBOutlet UITextField * textField;
@property (nonatomic, weak) IBOutlet UIImageView * backgroundFieldImageView;
@property (nonatomic, weak) IBOutlet SpeechRecognizerButton * speechButton;

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
