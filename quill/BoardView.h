//
//  BoardView.h
//  Quill
//
//  Created by Alex Costantini on 7/2/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentButton.h"

@interface BoardView : UIView {

}

@property (nonatomic, strong) NSNumber *lineColorNumber;
@property (nonatomic, assign) int penType;
@property (nonatomic, assign) BOOL empty;
@property (nonatomic, assign) BOOL drawable;
@property (nonatomic, assign) BOOL commenting;
@property (nonatomic, assign) NSString *boardID;
@property (nonatomic, assign) NSString *selectedAvatarUserID;
@property (nonatomic, strong) NSMutableDictionary *subpaths;
@property (nonatomic, strong) NSMutableArray *activeUserIDs;
@property (nonatomic, strong) NSMutableArray *avatarButtons;
@property (nonatomic, strong) NSMutableArray *commentButtons;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) CommentButton *movingCommentButton;
@property (strong, nonatomic) UIImageView *avatarBackgroundImage;
@property (nonatomic, strong) NSMutableArray *paths;
@property (strong, nonatomic) UIColor *backgroundColor;

-(void)clear;
-(void)drawSubpath:(NSDictionary *)subpathValues;
-(void)hideChat;
-(void)layoutAvatars;
-(void)layoutComments;

@end