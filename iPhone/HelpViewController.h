//
//  HelpViewController.h
//  iVerb
//
//  Created by Max on 08/02/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

@import WebKit;

@interface HelpViewController : UIViewController <WKNavigationDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSString * anchor;

@end
