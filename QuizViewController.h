//
//  QuizViewController.h
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import <UIKit/UIKit.h>

#import "Playlist.h"

typedef enum {
	ResponseStateTrue,
	ResponseStateFalse
} ResponseState;

typedef enum {
	VerbFormPastSimple = 0,
	VerbFormPastParticiple
} VerbForm;

@interface QuizViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>
{
	NSArray * allVerbs;
	NSInteger currentIndex;
	NSString * currentResponse;
	NSInteger goodResponseCount, badResponseCount;
	NSMutableArray * responses, * responsesCorrect, * forms;
	
	UIView * previousPushedView;
}

@property (nonatomic, strong) IBOutlet UIView * quizView, * responseView;
@property (nonatomic, strong) IBOutlet UITableView * resultTableView;

@property (nonatomic, strong) IBOutlet UILabel * infinitifLabel, * formLabel, * remainingCount;
@property (nonatomic, strong) IBOutlet UITextField * textField;
@property (nonatomic, strong) IBOutlet UIImageView * backgroundFieldImageView;

@property (nonatomic, strong) IBOutlet UIImageView * responseImageView;
@property (nonatomic, strong) IBOutlet UILabel * responseLabel;

//@property (nonatomic, strong) IBOutlet UILabel * goodResponseCountLabel, * badResponseCountLabel;

@property (nonatomic, strong) Playlist * playlist;

#pragma mark Next Verb Management
- (IBAction)pushNewVerbAction:(id)sender;
- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated;

#pragma mark Result Management
- (void)pushResultAnimated:(BOOL)animated;

#pragma mark Response Management
- (void)pushResponse:(ResponseState)response animated:(BOOL)animated;

@end
