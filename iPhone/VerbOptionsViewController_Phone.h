//
//  VerbOptionsViewController.h
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IVViewController.h"

#import "Playlist.h"
#import "Verb.h"

@interface VerbOptionsViewController_Phone : IVViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSArray * userPlaylists;
}

@property (nonatomic, assign) IBOutlet UITableView * tableView;
@property (nonatomic, assign) IBOutlet UILabel * headerLabel;
@property (nonatomic, assign) IBOutlet UIView * headerView;

@property (nonatomic, strong) NSArray * verbs;

@end
