//
//  QuizViewController.h
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import <UIKit/UIKit.h>

#import "Playlist.h"

typedef NS_ENUM(NSUInteger, ResponseState) {
	ResponseStateTrue,
	ResponseStateFalse
};

typedef NS_ENUM(NSUInteger, VerbForm) {
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

@property (nonatomic, strong) IBOutlet UIView * quizView, * responseView;

@property (nonatomic, strong) IBOutlet UILabel * infinitifLabel, * formLabel, * remainingCount;
@property (nonatomic, strong) IBOutlet UITextField * textField;
@property (nonatomic, strong) IBOutlet UIImageView * backgroundFieldImageView;

@property (nonatomic, strong) IBOutlet UIImageView * responseImageView;
@property (nonatomic, strong) IBOutlet UILabel * responseLabel;

- (instancetype)initWithPlaylist:(Playlist *)playlist;
- (instancetype)initWithPlaylist:(Playlist *)playlist firstVerb:(Verb *)verb verbForm:(VerbForm)verbForm NS_DESIGNATED_INITIALIZER;

#pragma mark Next Verb Management
- (IBAction)pushNewVerbAction:(id)sender;
- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated;

#pragma mark Result Management
- (void)pushResultAnimated:(BOOL)animated;

#pragma mark Response Management
- (void)pushResponse:(ResponseState)response animated:(BOOL)animated;

@end
