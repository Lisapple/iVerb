//
//  CloudViewController.h
//  iVerb
//
//  Created by Max on 05/02/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CloudViewController : UIViewController <UINavigationControllerDelegate>
{
	NSArray * verbs;
}

- (IBAction)doneAction:(id)sender;

@end
