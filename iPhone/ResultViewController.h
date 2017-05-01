//
//  ResultViewController.h
//  iVerb
//
//  Created by Max on 9/12/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

@import CoreData;
@import MessageUI;
@import AVFoundation;
@import WebKit;

#import "ResultView.h"

#import "Playlist.h"
#import "Verb.h"
#import "Verb+additions.h"

typedef NS_ENUM(NSUInteger, TransitionDirection) {
	// Show previous verb on playlist
	TransitionDirectionLeft,
	
	// Show next verb on playlist
	TransitionDirectionRight
};

@interface ResultViewController : UIViewController <ResultViewDelegate>

@property (nonatomic, strong) NSString * verbString;
@property (nonatomic, strong) Verb * verb;

@end
