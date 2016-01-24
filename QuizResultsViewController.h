//
//  QuizResultsViewController.h
//  iVerb
//
//  Created by Max on 22/01/16.
//
//

@import UIKit;

#import "Playlist.h"

@interface QuizResultCell : UITableViewCell

@property (nonatomic, strong) QuizResult * result;
@property (nonatomic, strong) UIColor * tintColor;

@end


@interface QuizResultsViewController : UITableViewController

@property (nonatomic, strong) Playlist * playlist;

@end
