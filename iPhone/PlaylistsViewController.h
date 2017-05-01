//
//  PlaylistsViewController.h
//  iVerb
//
//  Created by Max on 06/12/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "Playlist.h"

#import "EditableTableViewCell.h"

@interface PlaylistsViewController : UITableViewController <EditableTableViewCellDelegate>
{
@private
	NSArray * defaultPlaylists;
	NSArray * userPlaylists;
}

// Private
- (void)reloadData;

- (void)createNewListWithName:(NSString *)name;

@end
