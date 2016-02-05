//
//  EditNoteViewController.h
//  iVerb
//
//  Created by Maxime Leroy on 4/2/13.
//
//

#import <UIKit/UIKit.h>

#import "Verb.h"

@interface EditNoteViewController : UIViewController

@property (nonatomic, assign) IBOutlet UITextView * textView;

@property (nonatomic, strong) Verb * verb;

@end
