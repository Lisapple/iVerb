//
//  QuizResultsView.h
//  iVerb
//
//  Created by Max on 24/01/16.
//
//

@import UIKit;

@interface QuizResultsView : UIView

@property (nonatomic, strong) NSString * leftText, * rightText;
@property (nonatomic, strong) NSArray <NSValue /* CGPoint */ *> * points; // (x, y) | x,y E (0,1)

@end
