//
//  BoardCollectionViewCell.h
//  Quill
//
//  Created by Alex Costantini on 8/19/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BoardView.h"

@interface BoardCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) BoardView *boardView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIImageView *gradientImage;

-(void) updateSubpathsForBoardID:(NSString *)boardID;

@end
