//
//  VerbOptionsViewController_Pad.h
//  iVerb
//
//  Created by Max on 08/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Playlist.h"
#import "Verb.h"

@interface VerbOptionsViewController_Pad : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSArray * userPlaylists;
}

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@property (nonatomic, strong) NSArray * verbs;

@end
