//
//  BoardCollectionViewCell.h
//  chalk
//
//  Created by Alex Costantini on 8/19/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawView.h"

@interface BoardCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) DrawView *drawView;
@property (nonatomic, strong) UIButton *deleteButton;

-(void) updateSubpathsForBoardID:(NSString *)boardID;

@end
