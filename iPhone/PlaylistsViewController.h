//
//  PlaylistsViewController.h
//  iVerb
//
//  Created by Max on 06/12/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Playlist.h"

#import "EditableTableViewCell.h"

#import "ActionSheet.h"

@interface PlaylistsViewController : UIViewController <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, EditableTableViewCellDelegate, ActionSheetDelegate, UIActionSheetDelegate>
{
	IBOutlet UITableView * tableView;
	
	@private
	NSArray * defaultPlaylists;
	//NSArray * cellTitles;
	NSArray * userPlaylists;
	
	NSInteger rowWithDeleteConfirmation;
	
	Playlist * selectedPlaylist;
}

@property (nonatomic, strong) IBOutlet UITableView * tableView;

// Private
- (void)reloadData;

- (void)createNewListWithName:(NSString *)name;

- (void)removeCell:(id)sender;
- (void)cellsGestureRecognized:(UIGestureRecognizer *)recognizer;
- (void)cellDidSwipe:(UITableViewCell *)cell;

@end
