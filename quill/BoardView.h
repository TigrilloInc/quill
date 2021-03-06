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
@property (nonatomic, strong) UIButton *gradientButton;
@property (nonatomic, assign) NSInteger penType;
@property (nonatomic, assign) NSInteger shapeType;
@property (nonatomic, assign) BOOL empty;
@property (nonatomic, assign) BOOL drawable;
@property (nonatomic, assign) BOOL commenting;
@property (nonatomic, assign) BOOL hideComments;
@property (nonatomic, assign) BOOL shouldRedraw;
@property (nonatomic, assign) BOOL drawingBoard;
@property (nonatomic, assign) BOOL gridOn;
@property (nonatomic, assign) NSString *boardID;
@property (nonatomic, assign) NSString *selectedAvatarUserID;
@property (nonatomic, assign) NSString *drawingUserID;
@property (nonatomic, strong) NSMutableDictionary *subpaths;
@property (nonatomic, strong) NSMutableArray *activeUserIDs;
@property (nonatomic, strong) NSMutableArray *avatarButtons;
@property (nonatomic, strong) NSMutableArray *commentButtons;
@property (strong, nonatomic) NSMutableDictionary *drawingTimers;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) UIView *fadeView;
@property (nonatomic, strong) UILabel *leaveCommentLabel;
@property (nonatomic, strong) CommentButton *movingCommentButton;
@property (strong, nonatomic) UIImageView *avatarBackgroundImage;
@property (strong, nonatomic) UILabel *userLabel;
@property CGRect shapeRect;

-(void)clear;
-(void)drawSubpath:(NSDictionary *)subpathValues;
-(void)addUserDrawing:(NSString *)userID;
-(void)removeUserDrawing:(NSString *)userID;
-(void)hideChat;
-(void)layoutAvatars;
-(void)layoutComments;
-(void)updateCarouselOffsetWithPoint:(CGPoint)point;
-(UIImage *)generateImage;

@end
