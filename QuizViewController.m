//
//  QuizViewController.m
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import "QuizViewController.h"
#import "ResultViewController.h"
#import "QuizResultsViewController.h"

#import "Quote.h"
#import "QuizResult.h"

#import "UIFont+addition.h"
#import "UIColor+addition.h"
#import "NSString+addition.h"

@implementation SFSpeechRecognizer (Availability)

+ (BOOL)isAvailable
{
#if TARGET_OS_SIMULATOR
	return YES;
#else
	if (!NSClassFromString(@"SFSpeechRecognizer")) return NO;
	
	SFSpeechRecognizerAuthorizationStatus status = [SFSpeechRecognizer authorizationStatus];
	if (status != SFSpeechRecognizerAuthorizationStatusAuthorized &&
		status != SFSpeechRecognizerAuthorizationStatusNotDetermined)
		return NO;
	
	NSLocale * locale = [NSLocale localeWithLocaleIdentifier:@"en-US"];
	SFSpeechRecognizer * recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
	return (recognizer != nil); // @TODO: Should use [recognizer isAvailable], but this actually always returns NO
#endif
}

@end


typedef NS_ENUM(NSUInteger, SpeechRecognizerButtonState) {
	SpeechRecognizerButtonStateIdle, 
	SpeechRecognizerButtonStateLoading,
	SpeechRecognizerButtonStateMetering
};

@interface SpeechRecognizerButton ()

@property (nonatomic, strong) CAShapeLayer * shapeLayer;
@property (nonatomic, strong) CAShapeLayer * shapeLayerExtra;

@property (nonatomic, assign) SpeechRecognizerButtonState buttonState;

@end

@implementation SpeechRecognizerButton

#define kStrokeWidth 2

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self.tintColor = [UIColor foregroundColor];
		
		self.imageView.image = [UIImage imageNamed:@"dictate"];
		self.adjustsImageWhenHighlighted = NO;
		
		self.layer.borderColor = [UIColor grayColor].CGColor;
		self.layer.borderWidth = 1.;
		self.layer.cornerRadius = self.frame.size.height / 2.;
		
		_shapeLayer = [[CAShapeLayer alloc] init];
		_shapeLayer.frame = self.bounds;
		_shapeLayer.fillColor = [UIColor clearColor].CGColor;
		_shapeLayer.strokeColor = self.tintColor.CGColor;
		_shapeLayer.lineWidth = kStrokeWidth;
		_shapeLayer.lineCap = kCALineJoinRound;
		[self.layer addSublayer:_shapeLayer];
		
		_shapeLayerExtra = [[CAShapeLayer alloc] initWithLayer:_shapeLayer];
		_shapeLayerExtra.frame = _shapeLayer.frame;
		_shapeLayerExtra.fillColor = _shapeLayer.fillColor;
		_shapeLayerExtra.strokeColor = _shapeLayer.strokeColor;
		_shapeLayerExtra.lineWidth = kStrokeWidth;
		_shapeLayerExtra.lineCap = _shapeLayer.lineCap;
		[self.layer addSublayer:_shapeLayerExtra];
	}
	return self;
}

- (void)setLoading:(BOOL)loading
{
	BOOL needsUpdate = (loading != _loading);
	_loading = loading;
	_buttonState = (loading) ? SpeechRecognizerButtonStateLoading : SpeechRecognizerButtonStateIdle;
	if (needsUpdate) [self updateUI];
}

- (void)setLeftChannelLevel:(CGFloat)level
{
	_leftChannelLevel = level;
	if (!_loading) {
		_buttonState = SpeechRecognizerButtonStateMetering;
		[self updateUI];
	}
}

- (void)setRightChannelLevel:(CGFloat)level
{
	_rightChannelLevel = level;
	if (!_loading) {
		_buttonState = SpeechRecognizerButtonStateMetering;
		[self updateUI];
	}
}

- (void)updateUI
{
	[_shapeLayer removeAllAnimations];
	_shapeLayerExtra.hidden = YES;
	self.enabled = (_buttonState != SpeechRecognizerButtonStateLoading);
	
	const CGFloat radius = _shapeLayer.frame.size.height / 2 - kStrokeWidth;
	if (_buttonState == SpeechRecognizerButtonStateLoading) {
		CGMutablePathRef mPath = CGPathCreateMutable();
		CGPathAddArc(mPath, NULL,
					 CGRectGetMidX(_shapeLayer.frame), CGRectGetMidY(_shapeLayer.frame),
					 radius, 0, M_PI_2, NO);
		_shapeLayer.path = mPath;
		
		CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
		animation.repeatCount = FLT_MAX;
		animation.duration = 1;
		animation.fromValue = @0;
		animation.toValue = @(2 * M_PI);
		[_shapeLayer addAnimation:animation forKey:@"animation"];
		_shapeLayer.hidden = NO;
	} else if (_buttonState == SpeechRecognizerButtonStateMetering) {
		CGMutablePathRef mPath = CGPathCreateMutable();
		CGPathAddArc(mPath, NULL,
					 CGRectGetMidX(_shapeLayer.frame), CGRectGetMidY(_shapeLayer.frame),
					 radius, M_PI_2 - 0.05*M_PI, M_PI_2 - 0.95*M_PI * _leftChannelLevel, YES);
		_shapeLayer.path = mPath;
		_shapeLayer.hidden = NO;
		
		mPath = CGPathCreateMutable();
		CGPathAddArc(mPath, NULL,
					 CGRectGetMidX(_shapeLayerExtra.frame), CGRectGetMidY(_shapeLayerExtra.frame),
					 radius, M_PI_2 + 0.05*M_PI, M_PI_2 + 0.95*M_PI * _rightChannelLevel, NO);
		_shapeLayerExtra.path = mPath;
		_shapeLayerExtra.hidden = NO;
	} else {
		_shapeLayer.hidden = YES;
	}
}

@end


@interface QuizViewController ()

@property (nonatomic, strong) NSArray * allVerbs;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger goodResponseCount, badResponseCount;
@property (nonatomic, strong) MArray(String) responses;
@property (nonatomic, strong) MArray(Number/*BOOL*/) responsesCorrect;
@property (nonatomic, strong) MArray(Number/*VerbForm*/) forms;

@property (nonatomic, strong) UIView * previousPushedView;

@property (nonatomic, strong) NSString * currentResponse;

@property (nonatomic, strong) Playlist * playlist;
@property (nonatomic, strong) Verb * firstVerb;
@property (nonatomic, strong) NSMutableArray <Verb *> * askedVerbs;
@property (nonatomic, assign) VerbForm firstVerbForm;
@property (nonatomic, strong) SFSpeechRecognizer * recognizer;
@property (nonatomic, strong) AVAudioRecorder * recorder;
@property (nonatomic, strong) NSTimer * updateMetersTimer;

- (void)start;

- (void)pushView:(UIView *)view animated:(BOOL)animated;

- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated;

@end

@implementation QuizViewController

- (instancetype)initWithPlaylist:(Playlist *)playlist
{
	if ((self = [self initWithPlaylist:playlist firstVerb:nil verbForm:VerbFormUnspecified])) { }
	return self;
}

- (instancetype)initWithPlaylist:(Playlist *)playlist firstVerb:(Verb *)verb verbForm:(VerbForm)verbForm
{
	NSString * nibName = (TARGET_IS_IPAD())? @"QuizViewController_Pad" : @"QuizViewController_Phone";
	if ((self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]])) {
		_playlist = playlist;
		
		srand((unsigned int)time(NULL));
		
		_firstVerb = verb;
		if (!_firstVerb && _playlist.verbs.count > 0) {
			NSInteger index = rand() % _playlist.verbs.count;
			_firstVerb = _playlist.verbs.allObjects[index];
		}
		
		_firstVerbForm = verbForm;
		if (_firstVerbForm == VerbFormUnspecified)
			_firstVerbForm = (rand() % 2)? VerbFormPastSimple : VerbFormPastParticiple;
	}
	return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [self initWithPlaylist:[Playlist allVerbsPlaylist] firstVerb:nil verbForm:VerbFormUnspecified])) { }
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [self initWithPlaylist:[Playlist allVerbsPlaylist] firstVerb:nil verbForm:VerbFormUnspecified])) { }
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self action:@selector(cancelAction:)];
	
	// @TODO: add a "Details" button on result to show a list with good and bad responses
	
	NSLocale * locale = [NSLocale localeWithLocaleIdentifier:@"en-US"];
	_recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
	
	NSError * error = nil;
	NSURL * const outputURL = [NSURL fileURLWithPathComponents:@[ NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject,
																  @"recording.caf" ]];
	NSDictionary * const settings = @{ AVFormatIDKey : @(kAudioFormatLinearPCM),
									   AVSampleRateKey : @22050,
									   AVNumberOfChannelsKey : @1 };
	_recorder = [[AVAudioRecorder alloc] initWithURL:outputURL settings:settings error:&error];
	_recorder.meteringEnabled = YES;
	
	self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.];
	
	_allVerbs = self.playlist.verbs.allObjects;
	
	_responseView.hidden = YES;
	[self.view addSubview:_responseView];
	
	_textField.delegate = self;
	_backgroundFieldImageView.image = [UIImage imageNamed:@"quiz-field"];
	
	_speechButton.hidden = !([SFSpeechRecognizer isAvailable]);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textFieldDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:nil];
	[self start];
	
	if (!TARGET_IS_IPAD()) {
        /* Disallow the landscape mode of the application */
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[_textField resignFirstResponder];
}

- (IBAction)cancelAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
	
	if (!TARGET_IS_IPAD()) {
        /* Re-allow the landscape mode of the application */
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	}
}

- (IBAction)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
	
	if (!TARGET_IS_IPAD()) {
        /* Re-allow the landscape mode of the application */
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	}
}

- (IBAction)skipAction:(id)sender
{
	[self pushNewVerbAction:sender];
}

- (void)start
{
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self action:@selector(cancelAction:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Skip" style:UIBarButtonItemStylePlain
																			 target:self action:@selector(skipAction:)];
	
	_goodResponseCount = 0, _badResponseCount = 0;
	
	_responses = [[NSMutableArray alloc] initWithCapacity:_allVerbs.count];
	_responsesCorrect = [[NSMutableArray alloc] initWithCapacity:_allVerbs.count];
	_forms = [[NSMutableArray alloc] initWithCapacity:_allVerbs.count];
	
	_askedVerbs = [NSMutableArray arrayWithCapacity:_allVerbs.count];
	_currentIndex = 0;
	if (!_firstVerb)
		_firstVerb = _allVerbs.firstObject;
	
	if (_firstVerbForm == VerbFormUnspecified)
		_firstVerbForm = (arc4random() % 2) ? VerbFormPastSimple : VerbFormPastParticiple;
	
	[self pushVerb:_firstVerb form:_firstVerbForm animated:NO];
}

- (Verb * _Nullable)nextVerb
{
	NSMutableArray <Verb *> * remainingVerbs = _allVerbs.mutableCopy;
	[remainingVerbs removeObjectsInArray:_askedVerbs];
	if (remainingVerbs > 0) {
		NSInteger index = arc4random() % remainingVerbs.count;
		return remainingVerbs[index];
	}
	return nil;
}

- (void)pushView:(UIView *)view animated:(BOOL)animated
{
	// "Pop" the previous pushed view (if exists)
	if (_previousPushedView && _previousPushedView != view) {
		CGRect frame = _previousPushedView.frame;
		frame.origin.x = 0;
		_previousPushedView.frame = frame;
		
		[UIView animateWithDuration:(animated)? 0.25 : 0.
						 animations:^{
							 CGRect frame = _previousPushedView.frame;
							 frame.origin.x = -self.view.frame.size.width;
							 _previousPushedView.frame = frame;
						 }];
	}
	
	// Push the new view
	CGRect frame = view.frame;
	frame.origin.x = self.view.frame.size.width;
	view.frame = frame;
	
	// If "view" have been hidden, just re-show it, else add it to the main view
	if (view.hidden) view.hidden = NO;
	else [self.view addSubview:view];
	
	[UIView animateWithDuration:(animated)? 0.25 : 0.
					 animations:^{
						 CGRect frame = view.frame;
						 frame.origin.x = 0.;
						 view.frame = frame;
					 }
					 completion:^(BOOL finished) {
						 if (_previousPushedView != view)
							 _previousPushedView.hidden = YES;
							 
						 _previousPushedView = view;
					 }];
}

- (IBAction)startRecognizingAction:(id)sender
{
	[SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
		if (status == SFSpeechRecognizerAuthorizationStatusAuthorized) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (_speechButton.state == SpeechRecognizerButtonStateIdle) {
					[self speechRecognizeResponse:_currentResponse];
				}
			});
		}
	}];
}

- (void)speechRecognizeResponse:(NSString *)response
{
	NSAssert([SFSpeechRecognizer isAvailable], @"");
	
	AVAudioSession * session = [AVAudioSession sharedInstance];
	[session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
	
	_speechButton.loading = NO;
	
	NSTimeInterval const kRecordingDuration = 5;
	[_recorder recordForDuration:kRecordingDuration];
	_updateMetersTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * timer) {
		[self.recorder updateMeters];
#define CLIP(X) (MAX(0, MIN(X, 1)))
		float level = CLIP(logf(-160/[self.recorder averagePowerForChannel:0]) / expf(1.5));
#undef CLIP
		_speechButton.leftChannelLevel = level;
		_speechButton.rightChannelLevel = level;
	}];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRecordingDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[_recorder stop];
		_speechButton.loading = YES;
		
		NSURL * const outputURL = [NSURL fileURLWithPathComponents:@[ NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject,
																	  @"recording.caf" ]];
		SFSpeechURLRecognitionRequest * request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:outputURL];
		request.taskHint = SFSpeechRecognitionTaskHintDictation;
		request.contextualStrings = @[ response ];
		[_recognizer recognitionTaskWithRequest:request
								  resultHandler:^(SFSpeechRecognitionResult * result, NSError * error) {
									  if (error) {
										  // @TODO: Display error
										  [_updateMetersTimer invalidate]; _updateMetersTimer = nil;
										  [self.recorder deleteRecording];
										  self.speechButton.loading = NO;
										  return ;
									  }
									  if (result) {
										  BOOL found = NO;
										  NSArray * transcriptions = @[ result.bestTranscription ];
										  [transcriptions arrayByAddingObjectsFromArray:result.transcriptions];
										  for (SFTranscription * transcription in transcriptions) {
											  if ([transcription.formattedString containsString:response]) {
												  found = YES; break;
											  }
										  }
										  if (found) {
											  self.textField.text = response;
											  // @TODO: Validate the quizz
										  } else {
											  self.textField.text = result.bestTranscription.formattedString.lowercaseString;
										  }
										  if (result.final) {
											  [_updateMetersTimer invalidate]; _updateMetersTimer = nil;
											  [self.recorder deleteRecording];
											  self.speechButton.loading = NO;
										  }
									  }
								  }];
	});
}

#pragma mark - Next Verb Management

- (IBAction)pushNewVerbAction:(id)sender
{
	_currentIndex++;
	if (_currentIndex < _allVerbs.count) { // Push the next verb
		Verb * verb = [self nextVerb];
		VerbForm form = (arc4random() % 2)? VerbFormPastSimple : VerbFormPastParticiple;
		[self pushVerb:verb form:form animated:YES];
		
	} else // Show results
		[self pushResultAnimated:YES];
}

- (void)pushVerb:(Verb *)verb form:(VerbForm)form animated:(BOOL)animated
{
	[_askedVerbs addObject:verb];
	[_forms addObject:@(form)];
	
	self.title = [NSString stringWithFormat:@"%ld of %ld", (long)_currentIndex + 1, (long)_allVerbs.count];
	
	_infinitifLabel.text = [@"To " stringByAppendingString:verb.infinitif];
	_infinitifLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	
	NSString * response = verb.past, * quote = verb.quote.pastDescription, * author = verb.quote.pastAuthor;
	if (form == VerbFormPastParticiple) {
		response = verb.pastParticiple; quote = verb.quote.pastParticipleDescription; author = verb.quote.pastParticipleAuthor; }
	
	if (quote.length > 0) {
		NSMutableAttributedString * string = [[NSMutableAttributedString alloc] init];
		
		NSMutableString * placeholder = [[NSMutableString alloc] initWithCapacity:response.length];
		for (int i = 0; i < response.length; i++) { [placeholder appendString:@"_"]; }
		// Replace all occurrences (only for the whole word)
		NSMutableArray * words = [quote componentsSeparatedByString:@" "].mutableCopy;
		for (NSInteger index = 0; index < words.count; ++index) {
			NSString * word = [words[index] stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]]; // Remove ",;-" (and so on) to compare occurrence
			if ([word isEqualToString:response])
				words[index] = [words[index] stringByReplacingOccurrencesOfString:response withString:placeholder];
		}
		
		NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
		style.hyphenationFactor = 0.5; style.alignment = NSTextAlignmentCenter;
		NSDictionary * const attributes = @{ NSForegroundColorAttributeName : [UIColor darkGrayColor],
											 NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
											 NSParagraphStyleAttributeName : style };
		NSString * quote = [NSString stringWithFormat:@"« %@ »", [words componentsJoinedByString:@" "]];
		[string appendAttributedString:[[NSAttributedString alloc] initWithString:quote attributes:attributes]];
		
		NSDictionary * italics = @{ NSForegroundColorAttributeName : [UIColor darkGrayColor],
									NSFontAttributeName : [UIFont preferredItalicFontForTextStyle:UIFontTextStyleFootnote] };
		[string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", author]
																	   attributes:italics]];
		_formLabel.attributedText = string;
	} else {
		_formLabel.text = (form == VerbFormPastParticiple) ? @"Past Participle Form:" : @"Past Simple Form:";
	}
	
	_currentResponse = response;
	
	/* Update the label with the number of remaining letters */
	_remainingCount.text = [NSString stringWithFormat:@"%ld remaining letters", (long)_currentResponse.length];
	
	CGSize size = [_currentResponse sizeWithAttributes:@{ NSFontAttributeName : _textField.font }];
 	
	/* Fit "_backgroundFieldImageView" from "size.width" + 50px + 2 x 8px */
	CGRect frame = _backgroundFieldImageView.frame;
	frame.size.width = size.width + 50. + 2 * 8.;
	frame.origin.x = ceilf((self.view.frame.size.width - frame.size.width) / 2.);
	_backgroundFieldImageView.frame = frame;
	
	/* Fit "_textField" from "size.width" + 50px */
	frame = _textField.frame;
	frame.size.width = size.width + 50.;
	frame.origin.x = ceilf((self.view.frame.size.width - frame.size.width) / 2.);
	_textField.frame = frame;
	
	_textField.text = nil;
	[self pushView:_quizView animated:animated];
	
	[_textField performSelector:@selector(becomeFirstResponder) withObject:nil
					 afterDelay:(animated)? 0.25 : 0.];
}

#pragma mark Result Management

- (void)pushResultAnimated:(BOOL)animated
{
    [_textField becomeFirstResponder];
	[_textField resignFirstResponder];
	
	if (_goodResponseCount + _badResponseCount > 0) {
		NSManagedObjectContext * context = _playlist.managedObjectContext;
		NSEntityDescription * entity = [NSEntityDescription entityForName:NSStringFromClass(QuizResult.class)
												   inManagedObjectContext:context];
		QuizResult * result = [[QuizResult alloc] initWithEntity:entity
									insertIntoManagedObjectContext:context];
		result.playlist = _playlist;
		result.date = [NSDate date];
		result.rightResponses = @(_goodResponseCount);
		result.wrongResponses = @(_badResponseCount);
		[context save:NULL];
	}
	
	QuizResultsViewController * controller = [[QuizResultsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	controller.playlist = _playlist;
	[self.navigationController pushViewController:controller animated:animated];
}

#pragma mark Response Management

- (void)pushResponse:(ResponseState)response animated:(BOOL)animated
{
	const BOOL correct = (response == ResponseStateRight);
	_responseImageView.image = [UIImage imageNamed:correct ? @"true" : @"false"];
	_responseImageView.tintColor = (correct) ? [UIColor foregroundColor] : [UIColor errorColor];
	
	NSString * const answers = _textField.text;
	_responseLabel.attributedText = [answers highlightDifferencesAgainstReference:_currentResponse];
	
	_responseView.frame = self.view.bounds;
	[self pushView:_responseView animated:animated];
	
	const double seconds = (animated ? (correct ? 0.2 : 0.5) : 0.) + 1.;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
				   dispatch_get_main_queue(), ^{ [self pushNewVerbAction:nil]; });
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField.text.length == _currentResponse.length) {
		BOOL goodResponse = [textField.text isEqualToString:_currentResponse];
		if (goodResponse) {
			_goodResponseCount++;
			[self pushResponse:ResponseStateRight animated:YES];
		} else {
			_badResponseCount++;
			[self pushResponse:ResponseStateWrong animated:YES];
		}
		
		[_responses addObject:textField.text];
		[_responsesCorrect addObject:@(goodResponse)];
		return YES;
		
	} else
		_remainingCount.textColor = [UIColor errorColor];
	
	return NO;
}

- (void)textFieldDidChange:(NSNotification *)notification
{
	static NSUInteger oldLength = 0;
	
	NSUInteger location = [_currentResponse rangeOfString:@"-"].location;
	if (location != NSNotFound) {
		if (oldLength > _textField.text.length) { // If the old lenght is greated than the actual, the user is deleting
			// Remove "-" if needed
			if (_textField.text.length == (location + 1)) {
				// Remove the two last caracters (as if we delete the last caracter with the "-")
				_textField.text = [_textField.text stringByReplacingCharactersInRange:NSMakeRange(location - 1, 2) withString:@""];
			}
		} else {
			// Add "-" if needed
			if (_textField.text.length == location)
				_textField.text = [_textField.text stringByAppendingString:@"-"];
		}
	}
	oldLength = _textField.text.length;
	
	// Update the label with the number of remaining letters
	NSInteger rem = _currentResponse.length - _textField.text.length;
	_remainingCount.text = [NSString stringWithFormat:@"%ld remaining letters", (long)rem];
	_remainingCount.textColor = (rem < 0) ? [UIColor errorColor] : [UIColor grayColor];
}

#pragma mark - Navigation controller delegate

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.navigationController.delegate = nil;
}

@end
