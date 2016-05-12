//
//  VerbOptionsViewController.h
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Playlist.h"
#import "Verb.h"

@interface VerbOptionsViewController_Phone : UITableViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSArray * userPlaylists;
}

@property (nonatomic, strong) NSArray * verbs;

@end
