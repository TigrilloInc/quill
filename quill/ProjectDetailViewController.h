//
//  ProjectDetailViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/18/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "DrawView.h"
#import "MasterViewController.h"
#import "UICollectionView+Draggable.h"
#import "AvatarButton.h"

@class MasterView;

@interface ProjectDetailViewController : UIViewController <iCarouselDataSource, iCarouselDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource_Draggable, UICollectionViewDelegate> {
    
    BOOL newBoardCreated;
    BOOL commentsOpen;
    UIButton *boardButton;
    DrawView *currentDrawView;
    UIImageView *carouselFadeLeft;
    UIImageView *carouselFadeRight;
    
    MasterViewController *masterVC;
    
    NSString *tappedUserID;
    
    CGFloat keyboardDiff;
}

@property (strong, nonatomic) NSString *projectName;
@property (strong, nonatomic) NSString *chatID;
@property (strong, nonatomic) NSString *activeBoardID;
@property (strong, nonatomic) NSString *activeCommentThreadID;
@property (strong, nonatomic) NSString *activeBoardUndoIndexDate;
@property (strong, nonatomic) NSMutableArray *boardIDs;
@property (strong, nonatomic) NSMutableArray *editBoardIDs;
@property (strong, nonatomic) NSMutableArray *viewedBoardIDs;
@property (strong, nonatomic) NSMutableArray *viewedCommentThreadIDs;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableDictionary *roles;

@property BOOL carouselMoving;
@property BOOL chatViewed;

@property int userRole;

@property float carouselOffset;

@property (weak, nonatomic) IBOutlet MasterView *masterView;
@property (weak, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UILabel *projectNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

@property (weak, nonatomic) IBOutlet UIButton *addBoardButton;

@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;

@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *boardNameEditButton;
@property (weak, nonatomic) IBOutlet UILabel *boardNameLabel;

@property (weak, nonatomic) IBOutlet UIButton *addUserButton;
@property (strong, nonatomic) NSMutableArray *avatars;

@property (weak, nonatomic) IBOutlet UIView *chatView;
@property (weak, nonatomic) IBOutlet UITextField *chatTextField;
@property (weak, nonatomic) IBOutlet UITableView *chatTable;
@property (weak, nonatomic) IBOutlet UIButton *chatOpenButton;
@property (weak, nonatomic) IBOutlet UIImageView *chatFadeImage;
@property (weak, nonatomic) IBOutlet AvatarButton *chatAvatar;

@property (weak, nonatomic) IBOutlet UITextField *editProjectNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *editBoardNameTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *draggableCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *applyChangesButton;

-(void) updateDetails;
-(void) drawBoard:(DrawView *)drawView;
-(IBAction) cancelTapped:(id)sender;
-(void) showDrawMenu;
-(void) layoutAvatars;
-(void) updateMessages;

@end
