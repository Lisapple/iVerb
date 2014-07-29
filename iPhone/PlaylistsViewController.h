//
//  PlaylistsViewController.h
//  iVerb
//
//  Created by Max on 06/12/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IVTableViewController.h"

#import "Playlist.h"

#import "EditableTableViewCell.h"

#import "ActionSheet.h"

@interface PlaylistsViewController : IVTableViewController <UINavigationControllerDelegate, EditableTableViewCellDelegate, ActionSheetDelegate, UIActionSheetDelegate>
{
	@private
	NSArray * defaultPlaylists;
	NSArray * userPlaylists;
	
	Playlist * selectedPlaylist;
}

// Private
- (void)reloadData;

- (void)createNewListWithName:(NSString *)name;

@end
