//
//  ProjectDetailViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/18/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "BoardView.h"
#import "MasterViewController.h"
#import "UICollectionView+Draggable.h"
#import "AvatarButton.h"

@class MasterView;

@interface ProjectDetailViewController : UIViewController <iCarouselDataSource, iCarouselDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource_Draggable, UICollectionViewDelegate, UIGestureRecognizerDelegate> {

    BOOL newBoardCreated;

    UIButton *boardButton;
    UIImageView *carouselFade;
    UIImageView *editFade;
    
    MasterViewController *masterVC;
    
    NSString *tappedUserID;
    
    CGFloat keyboardDiff;
    
    UITapGestureRecognizer *chatTapRecognizer;
}

@property (strong, nonatomic) NSString *projectName;
@property (strong, nonatomic) NSString *chatID;
@property (strong, nonatomic) NSString *activeBoardID;
@property (strong, nonatomic) NSString *activeCommentThreadID;
@property (strong, nonatomic) NSString *activeBoardUndoIndexDate;
@property (strong, nonatomic) NSArray *drawButtons;
@property (strong, nonatomic) NSMutableArray *boardIDs;
@property (strong, nonatomic) NSMutableArray *editBoardIDs;
@property (strong, nonatomic) NSMutableArray *viewedBoardIDs;
@property (strong, nonatomic) NSMutableArray *editedBoardIDs;
@property (strong, nonatomic) NSMutableArray *viewedCommentThreadIDs;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableDictionary *roles;

@property BOOL carouselMoving;
@property BOOL chatViewed;
@property BOOL erasing;
@property BOOL versioning;
@property BOOL chatOpen;
@property BOOL showButtons;

@property int userRole;
@property float chatDiff;
@property float carouselOffset;

@property (weak, nonatomic) IBOutlet MasterView *masterView;
@property (weak, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet iCarousel *versionsCarousel;
@property (weak, nonatomic) IBOutlet UILabel *projectNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (strong, nonatomic) UIImageView *avatarBackgroundImage;
@property (strong, nonatomic) UIScrollView *avatarScrollView;

@property (weak, nonatomic) BoardView *currentBoardView;

@property (weak, nonatomic) IBOutlet UIButton *addBoardButton;
@property (weak, nonatomic) IBOutlet UIImageView *addBoardBackgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *buttonsBackgroundImage;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *versionsButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteBoardButton;
@property (weak, nonatomic) IBOutlet UIImageView *upArrowImage;
@property (weak, nonatomic) IBOutlet UIImageView *downArrowImage;
@property (weak, nonatomic) IBOutlet UIImageView *gridImageView;


@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;

@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *projectNameEditButton;
@property (weak, nonatomic) IBOutlet UIButton *boardNameEditButton;
@property (weak, nonatomic) IBOutlet UILabel *boardNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionsLabel;

@property (strong, nonatomic) UIButton *addUserButton;
@property (strong, nonatomic) NSMutableArray *avatars;

@property (weak, nonatomic) IBOutlet UIView *chatView;
@property (weak, nonatomic) IBOutlet UITextField *chatTextField;
@property (weak, nonatomic) IBOutlet UITableView *chatTable;
@property (weak, nonatomic) IBOutlet UIButton *chatOpenButton;
@property (weak, nonatomic) IBOutlet UIImageView *chatFadeImage;
@property (strong, nonatomic) AvatarButton *chatAvatar;

@property (weak, nonatomic) IBOutlet UIView *commentTitleView;
@property (weak, nonatomic) IBOutlet UITextField *commentTitleTextField;

@property (weak, nonatomic) IBOutlet UITextField *editProjectNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *editBoardNameTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *draggableCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIImageView *cancelBackgroundImage;
@property (weak, nonatomic) IBOutlet UIButton *applyChangesButton;
@property (weak, nonatomic) IBOutlet UIImageView *applyBackgroundImage;
@property (weak, nonatomic) IBOutlet UIButton *deleteProjectButton;
@property (weak, nonatomic) IBOutlet UIImageView *deleteProjectBackgroundImage;

@property (strong, nonatomic) UIImageView *eraserCursor;

-(void) updateDetails:(BOOL)reloadCarousel;
-(void) drawBoard:(BoardView *)boardView;
-(IBAction) cancelTapped:(id)sender;
-(IBAction) versionsTapped:(id)sender;
-(void) closeTapped;
-(void) gridTapped:(id)sender;
-(void) showDrawMenu;
-(void) showChat;
-(void) hideAll;
-(void) layoutAvatars;
-(void) updateMessages;
-(void) updateChatHeight;
-(void) updateCommentCount;
-(void) createBoard;
-(void) deleteBoardWithID:(NSString *)boardID;
-(BOOL)canUndo;
-(BOOL)canRedo;
-(BOOL)canClear;

@end
