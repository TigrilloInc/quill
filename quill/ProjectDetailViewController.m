//
//  ProjectDetailViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/18/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "ProjectDetailViewController.h"
#import "BoardCollectionViewCell.h"
#import "AddUserViewController.h"
#import "AvatarButton.h"
#import "CommentButton.h"
#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"
#import "NSDate+ServerDate.h"
#import "MasterView.h"
#import "ChatTableViewCell.h"
#import "AvatarPopoverViewController.h"
#import "ColorPopoverViewController.h"
#import "PenTypePopoverViewController.h"
#import "ShapePopoverViewController.h"
#import "CommentPopoverViewController.h"
#import "SharePopoverViewController.h"
#import "InstabugViewController.h"
#import "DeleteProjectAlertViewController.h"
#import "DeleteBoardAlertViewController.h"
#import "GeneralAlertViewController.h"
#import "SignedOutAlertViewController.h"
#import "OfflineAlertViewController.h"
#import "Flurry.h"
#import "OneSignalHelper.h"

@implementation ProjectDetailViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    [[UITextField appearance] setTintColor:[UIColor grayColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"SourceSansPro-Light" size:24.0], NSFontAttributeName, nil]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:5 forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"SourceSansPro-Semibold" size:16],NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    self.chatTextField.delegate = self;
    self.editBoardNameTextField.delegate = self;
    self.carousel.delegate = self;
    self.versionsCarousel.delegate = self;
    
    self.carousel.type = iCarouselTypeCoverFlow2;
    self.carousel.bounceDistance = 0.1f;
    UISwipeGestureRecognizer *upBoardSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(boardSwiped:)];
    upBoardSwipe.direction = UISwipeGestureRecognizerDirectionUp;
    [self.carousel addGestureRecognizer:upBoardSwipe];
    UISwipeGestureRecognizer *downBoardSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(boardSwiped:)];
    downBoardSwipe.direction = UISwipeGestureRecognizerDirectionDown;
    [self.carousel addGestureRecognizer:downBoardSwipe];
    
    self.versionsCarousel.type = iCarouselTypeInvertedTimeMachine;
    self.versionsCarousel.pagingEnabled = YES;
    self.versionsCarousel.bounceDistance = 0.15f;
    self.versionsCarousel.viewpointOffset = CGSizeMake(0, -2750);
    self.versionsCarousel.contentOffset = CGSizeMake(0, -2750);
    self.versionsCarousel.vertical = YES;
    self.versionsCarousel.scrollSpeed = 4;
    self.versionsCarousel.perspective = -0.0001;
    UISwipeGestureRecognizer *leftVersionSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(versionSwiped:)];
    leftVersionSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.versionsCarousel addGestureRecognizer:leftVersionSwipe];
    UISwipeGestureRecognizer *rightVersionSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(versionSwiped:)];
    rightVersionSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.versionsCarousel addGestureRecognizer:rightVersionSwipe];
    
    carouselFade = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"carouselfadeleft.png"]];
    [self.carousel addSubview:carouselFade];
    carouselFade.frame = CGRectMake(0, -5, 15, 400);
    
    editFade = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"editfadeleft.png"]];
    [self.view addSubview:editFade];
    editFade.frame = CGRectMake(210, 0, 15, 768);
    
    self.chatTable.transform = CGAffineTransformMakeRotation(M_PI);
    [self showChat];
    
    self.masterView.projectsTable.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"projectsshadow.png"]];

    self.editBoardNameTextField.hidden = true;
    self.eraserCursor = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"eraser.png"]];
    self.eraserCursor.hidden = true;
    self.eraserCursor.frame = CGRectMake(0, 0, 62, 62);
    [self.view addSubview:self.eraserCursor];
    
    [self setUpDrawMenu];
}


- (void) viewDidAppear:(BOOL)animated {
    
    chatTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatTableTapped)];
    [chatTapRecognizer setDelegate:self];
    [chatTapRecognizer setNumberOfTapsRequired:1];
    chatTapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:chatTapRecognizer];
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];

    [chatTapRecognizer setDelegate:nil];
    [self.view removeGestureRecognizer:chatTapRecognizer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if (motion == UIEventSubtypeMotionShake) {
        
        InstabugViewController *instabugVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Instabug"];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instabugVC];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
        logoImageView.frame = CGRectMake(195, 8, 32, 32);
        logoImageView.tag = 800;
        [nav.navigationBar addSubview:logoImageView];
        
        if (self.presentedViewController) {
            
            UINavigationController *presentedNav = (UINavigationController *)self.presentedViewController;
            
            UIViewController *vc;
        
            if ([presentedNav respondsToSelector:@selector(viewControllers)]) vc = presentedNav.viewControllers[0];
            else vc = self.presentedViewController;
            
            if (![vc isKindOfClass:[InstabugViewController class]]) [self.presentedViewController presentViewController:nav animated:YES completion:nil];
        }
        else [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void) setUpDrawMenu {
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(10, 13, 30, 60);
    [closeButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    closeButton.adjustsImageWhenHighlighted = NO;
    closeButton.tintColor = [UIColor blackColor];
    [closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    closeButton.hidden = true;
    [self.view addSubview:closeButton];
    closeButton.tag = 100;
    
    UIButton *projectNameButton = [UIButton buttonWithType:UIButtonTypeSystem];
    projectNameButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
    [projectNameButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    projectNameButton.tintColor = [UIColor blackColor];
    projectNameButton.hidden = true;
    projectNameButton.frame = CGRectMake(35, 24, 0, 0);
    [self.view addSubview:projectNameButton];
    projectNameButton.tag = 101;
    
    UILabel *boardNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    boardNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
    boardNameLabel.hidden = true;
    [self.view addSubview:boardNameLabel];
    boardNameLabel.tag = 102;
    
    UIButton *editBoardNameButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [editBoardNameButton setBackgroundImage:[UIImage imageNamed:@"edit.png"] forState:UIControlStateNormal];
    [editBoardNameButton addTarget:self action:@selector(showEditBoardName) forControlEvents:UIControlEventTouchUpInside];
    editBoardNameButton.hidden = true;
    editBoardNameButton.alpha = .2;
    [self.view addSubview:editBoardNameButton];
    editBoardNameButton.tag = 103;
    
    UITextField *editBoardNameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    editBoardNameTextField.font = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
    editBoardNameTextField.placeholder = @"Board Name";
    [editBoardNameTextField setBorderStyle:UITextBorderStyleNone];
    editBoardNameTextField.hidden = true;
    editBoardNameTextField.tag = 104;
    editBoardNameTextField.delegate = self;
    [self.view addSubview:editBoardNameTextField];
    
    UILabel *boardVersionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    boardVersionsLabel.font = [UIFont fontWithName:@"SourceSansPro-LightIt" size:18];
    boardVersionsLabel.hidden = true;
    [self.view addSubview:boardVersionsLabel];
    boardVersionsLabel.tag = 105;
    
    self.drawButtons = @[ @"undo",
                          @"redo",
                          @"clear",
                          @"handshape",
                          @"pen",
                          @"erase",
                          @"color",
                          @"grid",
                          @"comment"
                        ];
    
    for (int i=0; i<self.drawButtons.count; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *imageName;
        if (i==6) imageName = @"black.png";
        else imageName = [NSString stringWithFormat:@"%@.png",self.drawButtons[i]];
        UIImage *buttonImage = [UIImage imageNamed:imageName];
        if (i>2 && i!=6 && i!=7) {
            UIImageView *selectedImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selected.png"]];
            selectedImage.frame = CGRectMake(-7.5, -7.5, 75, 75);
            selectedImage.tag = 50;
            [button addSubview:selectedImage];
            if (i!=4) selectedImage.hidden = true;
        }
        if (i==8) {
            
            UILabel *commentCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(46, -25, 75, 75)];
            commentCountLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
            commentCountLabel.tag = 51;
            [button addSubview:commentCountLabel];
        }
        button.frame = CGRectMake(0, 0, 60, 60);
        [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
        button.center = CGPointMake(172+i*85, 720);
        [button addTarget:self action:NSSelectorFromString([NSString stringWithFormat:@"%@Tapped:", self.drawButtons[i]]) forControlEvents:UIControlEventTouchUpInside];
        button.hidden = true;
        [self.view addSubview:button];
        button.tag = i+2;
    }
}

-(void) showDrawMenu {
    
    UIButton *closeButton = (UIButton *)[self.view viewWithTag:100];
    closeButton.hidden = false;
    [self.view bringSubviewToFront:closeButton];
    
    UIButton *projectNameButton = (UIButton *)[self.view viewWithTag:101];
    projectNameButton.hidden = false;
    [self.view bringSubviewToFront:projectNameButton];
    
    UILabel *boardNameLabel = (UILabel *)[self.view viewWithTag:102];
    boardNameLabel.hidden = false;
    [self.view bringSubviewToFront:boardNameLabel];

    if (self.versioning && self.versionsCarousel.currentItemIndex > 0) {
        
        UILabel *boardVersionLabel = (UILabel *)[self.view viewWithTag:105];
        boardVersionLabel.hidden = false;
        [self.view bringSubviewToFront:boardVersionLabel];
    }
    
    if (self.userRole > 0) {
        
        UIButton *editBoardNameButton = (UIButton *)[self.view viewWithTag:103];
        editBoardNameButton.frame = CGRectMake(boardNameLabel.frame.origin.x+boardNameLabel.frame.size.width-5, boardNameLabel.frame.origin.y-6, 36, 36);
        editBoardNameButton.hidden = false;
        [self.view bringSubviewToFront:editBoardNameButton];
        
        for (int i=0; i<self.drawButtons.count; i++) {
            
            UIButton *button = (UIButton *)[self.view viewWithTag:i+2];
            button.hidden = false;
            [self.view bringSubviewToFront:button];
            
            button.alpha = 1;
            
            if (i==0 && ![self canUndo]) button.alpha = .3;
            else if (i==1 && ![self canRedo]) button.alpha = .3;
            else if (i==2 && ![self canClear]) button.alpha = .3;
            else if (i==7 && !self.currentBoardView.gridOn) button.alpha = .3;
        }
        
        [self updateCommentCount];
    }
}

-(void) hideDrawMenu {
    
    UIButton *closeButton = (UIButton *)[self.view viewWithTag:100];
    closeButton.hidden = true;
    
    UIButton *projectNameButton = (UIButton *)[self.view viewWithTag:101];
    projectNameButton.hidden = true;
    
    UILabel *boardNameLabel = (UILabel *)[self.view viewWithTag:102];
    boardNameLabel.hidden = true;
    
    UIButton *editBoardNameButton = (UIButton *)[self.view viewWithTag:103];
    editBoardNameButton.hidden = true;
    
    UITextField *editBoardNameTextField = (UITextField *)[self.view viewWithTag:104];
    editBoardNameTextField.hidden = true;
    
    UILabel *boardVersionLabel = (UILabel *)[self.view viewWithTag:105];
    boardVersionLabel.hidden = true;
    
    for (int i=0; i<=self.drawButtons.count; i++) {
        
        UIButton *button = (UIButton *)[self.view viewWithTag:i+2];
        button.hidden = true;
    }
}

-(void) showChat {
    
    [self.view bringSubviewToFront:self.chatView];
    [self.view bringSubviewToFront:self.chatTable];
    [self.view bringSubviewToFront:self.chatFadeImage];
    [self.view bringSubviewToFront:self.chatOpenButton];
    [self.view bringSubviewToFront:self.commentTitleView];
}

-(void) hideChat {
    
    [self.view sendSubviewToBack:self.commentTitleView];
    [self.view sendSubviewToBack:self.chatOpenButton];
    [self.view sendSubviewToBack:self.chatFadeImage];
    [self.view sendSubviewToBack:self.chatTable];
    [self.view sendSubviewToBack:self.chatView];
    [self.view sendSubviewToBack:self.backgroundImage];
}

-(void) hideAvatars {
    
    for (AvatarButton *avatar in self.avatars) [self.view sendSubviewToBack:avatar];
    [self.view sendSubviewToBack:self.addUserButton];
    [self.view sendSubviewToBack:self.avatarBackgroundImage];
    [self.view sendSubviewToBack:self.backgroundImage];
}

-(void) showEditBoardName {
    
    UILabel *label = (UILabel *)[self.view viewWithTag:102];
    label.text = @"|";
    
    UIButton *button = (UIButton *)[self.view viewWithTag:103];
    button.hidden = true;
    
    UITextField *textField = (UITextField *)[self.view viewWithTag:104];
    textField.frame = CGRectMake(label.frame.origin.x+17, label.frame.origin.y+1, 500, 25);
    NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.activeBoardID] objectForKey:@"name"];
    if ([boardName isEqualToString:@"Untitled"]) textField.text = nil;
    else textField.text = boardName;
    [self.view bringSubviewToFront:textField];
    textField.hidden = false;
    [textField becomeFirstResponder];

    
}

-(void) hideAll {
    
    self.projectNameLabel.hidden = true;
    self.versionsLabel.hidden = true;
    self.editButton.hidden = true;
    self.editProjectNameTextField.hidden = true;
    self.editBoardNameTextField.hidden = true;
    
    self.boardNameLabel.hidden = true;
    self.boardNameEditButton.hidden = true;
    self.editBoardNameTextField.hidden = true;
    
    self.carousel.hidden = true;
    self.versionsCarousel.hidden = true;
    self.upArrowImage.hidden = true;
    self.downArrowImage.hidden = true;
    self.versioning = false;
    carouselFade.hidden = false;
    
    for (AvatarButton *avatar in self.avatars) avatar.hidden = true;
    self.avatarBackgroundImage.hidden = true;
    self.addUserButton.hidden = true;
    
    [self updateMessages];
    [self.chatTable reloadData];
    self.chatView.hidden = false;
    self.chatFadeImage.hidden = false;
    self.chatTable.hidden = false;
    self.chatOpenButton.hidden = true;
    self.chatAvatar.hidden = true;
    self.sendMessageButton.hidden = true;
    self.chatTextField.hidden = true;
    
    self.addBoardBackgroundImage.hidden = true;
    self.addBoardButton.hidden = true;
    self.buttonsBackgroundImage.hidden = true;
    self.shareButton.hidden = true;
    self.versionsButton.hidden = true;
    self.versionsCountLabel.hidden = true;
    self.deleteBoardButton.hidden = true;
    self.projectNameEditButton.hidden = true;
    self.draggableCollectionView.hidden = true;
    
    self.applyChangesButton.hidden = true;
    self.applyBackgroundImage.hidden = true;
    self.cancelButton.hidden = true;
    self.cancelBackgroundImage.hidden = true;
    self.deleteProjectButton.hidden = true;
    self.deleteProjectBackgroundImage.hidden = true;
    self.feedbackButton.hidden = true;
    self.feedbackBackground.hidden = true;
    editFade.hidden = true;
    self.editing = false;
}

-(void) updateDetails:(BOOL)differentProject {
    
    self.chatTextField.hidden = false;
    self.sendMessageButton.hidden = false;
    self.chatAvatar.hidden = false;
    self.chatOpenButton.hidden = false;
    
    if  (self.userRole > 0) {
        
        self.chatDiff = 0;
        [self.buttonsBackgroundImage setImage:[UIImage imageNamed:@"buttonsbackground.png"]];
        self.buttonsBackgroundImage.frame = CGRectMake(340, 508, 162, 48);
    }
    else {
        
        [self.buttonsBackgroundImage setImage:[UIImage imageNamed:@"buttonsbackground2.png"]];
        self.buttonsBackgroundImage.frame = CGRectMake(340, 508, 112, 48);
        self.chatDiff = self.chatView.frame.size.height;
    }
    
    if (![self.chatTextField isFirstResponder]) {
        
        self.chatView.center = CGPointMake(617, 743.5);
        self.chatOpenButton.center = CGPointMake(617.5, 598);
        self.chatFadeImage.center = CGPointMake(722, 615.5);
        self.chatTable.frame = CGRectMake(210, 612, self.view.frame.size.width-210, 107+self.chatDiff);
    }
    
    self.projectNameLabel.text = self.projectName;
    CGRect projectRect = [self.projectNameLabel.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.projectNameLabel.font} context:nil];
    self.editButton.center = CGPointMake(MIN(projectRect.size.width+290,600), self.projectNameLabel.center.y+3);
    self.projectNameEditButton.center = self.editButton.center;
    
    UIButton *projectNameButton = (UIButton *)[self.view viewWithTag:101];
    [projectNameButton setTitle:self.projectName forState:UIControlStateNormal];
    [projectNameButton sizeToFit];
    
    if (differentProject) {
        chatViewedAt = nil;
        [self updateMessages];
        [self.chatTable reloadData];
        [self.carousel reloadData];
        [self.draggableCollectionView reloadData];
    }
    
    [self layoutAvatars];

    if (self.userRole > 1) self.editButton.hidden = false;
    else self.editButton.hidden = true;
    
    [self carouselCurrentItemIndexDidChange:self.carousel];
    
    self.chatOpen = false;
}

-(void) updateMessages {
    
    self.messages = [NSMutableArray array];
    
    NSArray *messageKeys;
    
    if (self.activeCommentThreadID) {
        
        NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
        messageKeys = [[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] allKeys];
    }
    else messageKeys = [[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] allKeys];
    
    for (NSString *messageID in messageKeys) {
        
        NSString *date;
        
        if (self.activeCommentThreadID != nil) {
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
            
            date = [[[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] objectForKey:messageID] objectForKey:@"sentAt"];
            
        }
        else date = [[[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] objectForKey:messageID]  objectForKey:@"sentAt"];
        
        [self.messages addObject:date];
    }
    
    NSString *viewedAt = [[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid];
    if (!viewedAt) viewedAt = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    if (!chatViewedAt) chatViewedAt = viewedAt;
    
    [self.messages addObject:chatViewedAt];
    
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [self.messages sortUsingDescriptors:@[sorter]];
    
    if ([self.messages.lastObject isEqualToString:chatViewedAt] && !self.activeCommentThreadID) {
        [self.updatedElements setObject:@1 forKey:@"chat"];
    }
    
    if ((!self.activeCommentThreadID && [self.updatedElements objectForKey:@"chat"]) || self.activeCommentThreadID) {
        
        [self.messages removeObject:chatViewedAt];
        
        if (![self.chatTextField isFirstResponder]) {
            
            CGPoint chatCenter = self.chatOpenButton.center;
            self.chatOpenButton.frame = CGRectMake(0, 0, 51, 28);
            self.chatOpenButton.center = chatCenter;
            if (self.chatOpen) [self.chatOpenButton setImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
            else [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
        }
    }
    else if (![self.chatTextField isFirstResponder]) {
        
        self.chatOpenButton.frame = CGRectMake(0, 0, 150, 31);
        self.chatOpenButton.center = CGPointMake(617.9, 598);
        [self.chatOpenButton setImage:[UIImage imageNamed:@"newmessages.png"] forState:UIControlStateNormal];
    }
    
    for (NSString *messageID in messageKeys) {
        
        NSString *date;
        
        if (self.activeCommentThreadID){
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
            date = [[[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] objectForKey:messageID] objectForKey:@"sentAt"];
        }
        else date = [[[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] objectForKey:messageID]  objectForKey:@"sentAt"];
        
        for (int i=0; i<self.messages.count; i++) {
            
            if ([viewedAt isEqualToString:self.messages[i]])
                [self.messages replaceObjectAtIndex:i withObject:@"new messages"];
            
            else if ([date isEqualToString:self.messages[i]]) {
                
                NSDictionary *messageDict;
                
                if (self.activeCommentThreadID) {
                    
                    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
                    messageDict = [[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] objectForKey:messageID];
                }
                else messageDict = [[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] objectForKey:messageID];
                
                [self.messages replaceObjectAtIndex:i withObject:messageDict];
            }
        }
    }
}

-(void) updateChatHeight {
    
    float tableHeight = 10;
    
    for (int i=0; i<self.messages.count; i++) {
        tableHeight += [self tableView:self.chatTable heightForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    
    CGRect chatTableRect = self.chatTable.frame;
    float maxHeight = 673;
    if (self.activeBoardID && self.userRole == 0) maxHeight = 384;
    
    if (chatTableRect.size.height < maxHeight) {
        
        float tableDiff = tableHeight-chatTableRect.size.height;
        chatTableRect.size.height += tableDiff;
        chatTableRect.origin.y -= tableDiff;
        
        if (chatTableRect.size.height > 156) {
            
            self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y-tableDiff);
            self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-tableDiff);
            self.chatTable.frame = chatTableRect;
        }
    }
}

-(void) updateCommentCount {
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.activeBoardID] objectForKey:@"commentsID"];
    NSInteger commentCount = [[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] allKeys] count];
    
    UILabel *commentCountLabel = (UILabel *)[[self.view viewWithTag:10] viewWithTag:51];

    if (commentCount > 0) commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)commentCount];
    else commentCountLabel.text = @"";
}

-(void) layoutAvatars {

    for (AvatarButton *avatar in self.avatars) [avatar removeFromSuperview];

    self.avatars = [NSMutableArray array];
    
    NSMutableArray *users = [self.roles.allKeys mutableCopy];

    for (NSString *user in self.roles.allKeys) {
        
        if ([[self.roles objectForKey:user] integerValue] == -1) [users removeObject:user];
    }
    
    NSArray *userIDs = [users sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    [self.avatarBackgroundImage removeFromSuperview];
    self.avatarBackgroundImage.hidden = false;
    CGRect imageRect = CGRectMake(0, 0, 345+userIDs.count*(66*4), 280);
    CGImageRef imageRef = CGImageCreateWithImageInRect([[UIImage imageNamed:@"avatarbackground.png"] CGImage], imageRect);
    self.avatarBackgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:imageRef]];
    CGImageRelease(imageRef);
    self.avatarBackgroundImage.transform = CGAffineTransformScale(self.avatarBackgroundImage.transform, .25, .25);
    self.avatarBackgroundImage.frame = CGRectMake(MAX(617.75,1034-self.avatarBackgroundImage.frame.size.width), 18, self.avatarBackgroundImage.frame.size.width, self.avatarBackgroundImage.frame.size.height);
    self.avatarBackgroundImage.alpha = .25;
    [self.view addSubview:self.avatarBackgroundImage];
    
    
    [self.addUserButton removeFromSuperview];
    self.addUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.addUserButton addTarget:self action:@selector(addUserTapped) forControlEvents:UIControlEventTouchUpInside];
    UIImage *plusImage = [UIImage imageNamed:@"plus1.png"];
    [self.addUserButton setImage:plusImage forState:UIControlStateNormal];
    self.addUserButton.frame = CGRectMake(MAX(538,868-(userIDs.count*66)), -63, plusImage.size.width, plusImage.size.height);
    self.addUserButton.transform = CGAffineTransformScale(self.addUserButton.transform, .25, .25);
    [self.view insertSubview:self.addUserButton aboveSubview:self.avatarBackgroundImage];
    
    [self.avatarScrollView removeFromSuperview];
    
    if (userIDs.count > 5) {
        
        self.avatarScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(689, 18, 334, 78)];
        self.avatarScrollView.contentSize = CGSizeMake(userIDs.count*66+7, 70);
        self.avatarScrollView.panGestureRecognizer.delaysTouchesBegan = YES;
        [self.view addSubview:self.avatarScrollView];
        [self.avatarScrollView flashScrollIndicators];
    }
    
    for (int i=0; i<userIDs.count; i++) {
        
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.userID = userIDs[i];
        [avatar addTarget:self action:@selector(avatarTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *avatarImage = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"avatar"];
        
        if ([avatarImage isKindOfClass:[UIImage class]]) {
            
            avatar.shadowImage.hidden = false;
            [avatar setImage:avatarImage forState:UIControlStateNormal];
            avatar.imageView.layer.cornerRadius = avatarImage.size.width/2;
            avatar.imageView.layer.masksToBounds = YES;
            avatar.frame = CGRectMake(921-(i*66), -11, avatarImage.size.width, avatarImage.size.height);
            avatar.transform = CGAffineTransformMakeScale(.86*64/avatarImage.size.width, .86*64/avatarImage.size.width);
            avatar.shadowImage.center = CGPointMake(64, 69);
            
            if (avatar.imageView.frame.size.height == 64) {
                avatar.frame = CGRectMake(953-(i*66), 21, avatarImage.size.width, avatarImage.size.height);
                avatar.shadowImage.frame = CGRectMake(2, 5, 70, 70);
            }
            
            if (userIDs.count > 5) avatar.center = CGPointMake(33+(i*66), 34.5);
        }
        else {
            [avatar generateIdenticonWithShadow:true];
            avatar.frame = CGRectMake(860-(i*66), -70, avatar.userImage.size.width, avatar.userImage.size.height);
            avatar.transform = CGAffineTransformMakeScale(.25, .25);
            if (userIDs.count > 5) avatar.center = CGPointMake(33+(i*66), 36.5);
        }
        
        if (userIDs.count > 5) [self.avatarScrollView addSubview:avatar];
        else [self.view insertSubview:avatar aboveSubview:self.avatarBackgroundImage];
        
        
        NSString *inProjectID = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"inProject"];

        if (![inProjectID isEqualToString:[FirebaseHelper sharedHelper].currentProjectID] && ![avatar.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
            avatar.alpha = 0.5;
        }
        [self.avatars addObject:avatar];
    }
    
    if (self.activeBoardID) [self hideAvatars];
}

-(void) createBoard {
    
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards", [FirebaseHelper sharedHelper].db];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    
    NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments", [FirebaseHelper sharedHelper].db];
    Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
    Firebase *commentsRefWithID = [commentsRef childByAutoId];
    NSString *commentsID = commentsRefWithID.key;
    [[FirebaseHelper sharedHelper].comments setObject:[NSMutableDictionary dictionary] forKey:commentsID];
    
    Firebase *boardRefWithID = [boardRef childByAutoId];
    NSString *boardID = boardRefWithID.key;
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSMutableDictionary *subpathsDict;
    NSMutableDictionary *undoDict;
    NSUInteger boardNum;
    NSString *boardName;
    
    if (self.versioning) {
        
        NSMutableDictionary *currentBoardDict = [[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]];
        
        subpathsDict = [NSMutableDictionary dictionary];
        undoDict = [NSMutableDictionary dictionary];
        
        for (NSString *userID in [[currentBoardDict objectForKey:@"subpaths"] allKeys]) {
            
            [subpathsDict setObject:[NSMutableDictionary dictionary] forKey:userID];
            
            for (NSString *dateString in [[[currentBoardDict objectForKey:@"subpaths"] objectForKey:userID] allKeys]) {
                
                [[subpathsDict objectForKey:userID] setObject:[[[[currentBoardDict objectForKey:@"subpaths"] objectForKey:userID] objectForKey:dateString] copy] forKey:dateString];
            }
            
            [undoDict setObject:[[[currentBoardDict objectForKey:@"undo"] objectForKey:userID] mutableCopy] forKey:userID];
        }
        
        boardNum = [[currentBoardDict objectForKey:@"versions"] count];
        boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"name"];
        
        [[currentBoardDict objectForKey:@"versions"] addObject:boardID];
        
        [[FirebaseHelper sharedHelper] setBoard:self.boardIDs[self.carousel.currentItemIndex] UpdatedAt:dateString];
    }
    else {
        
        boardNum = self.boardIDs.count;
        NSString *boardNumString = [NSString stringWithFormat:@"%lu", (unsigned long)self.boardIDs.count];
        boardName = @"Untitled";
        
        [self.boardIDs addObject:boardID];
        
        subpathsDict = [NSMutableDictionary dictionary];
        undoDict = [NSMutableDictionary dictionary];
        
        NSMutableArray *userIDs = [self.roles.allKeys mutableCopy];
        
        for (NSString *userID in userIDs) {
            
            [subpathsDict setObject:[@{ dateString : @"penUp"} mutableCopy] forKey:userID];
            
            [undoDict  setObject:[@{ @"currentIndex" : @0,
                                     @"currentIndexDate" : dateString,
                                     @"total" : @0
                                     } mutableCopy]
                          forKey:userID];
        }
        
        NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info/boards", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID];
        Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
        [projectRef updateChildValues:@{ boardNumString : boardID}];
        [[[FirebaseHelper sharedHelper].projects objectForKey:@"boards"] setObject:boardID forKey:boardNumString];
    }
    
    
    NSDictionary *boardDict =  @{ @"name" : boardName,
                                  @"project" : self.projectName,
                                  @"commentsID" : commentsID,
                                  @"subpaths" : subpathsDict,
                                  @"updatedAt" : dateString,
                                  @"undo" : undoDict,
                                  @"versions" : [@[boardID] mutableCopy]
                                  };
    
    BOOL versioning = self.versioning;
    int currentIndex = self.carousel.currentItemIndex;
    
    [boardRefWithID updateChildValues:boardDict withCompletionBlock:^(NSError *error, Firebase *ref) {

        if (versioning) {
            
            NSMutableDictionary *currentBoardDict = [[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]];
            
            NSString *currentBoardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/versions/%lu", [FirebaseHelper sharedHelper].db, self.boardIDs[currentIndex], (unsigned long)boardNum];
            Firebase *currentBoardRef = [[Firebase alloc] initWithUrl:currentBoardString];
            [currentBoardRef setValue:boardID];
            [[currentBoardDict objectForKey:@"versions"] addObject:boardID];
        }
    }];
    
    [[FirebaseHelper sharedHelper].boards setObject:[boardDict mutableCopy] forKey:boardID];
    [[FirebaseHelper sharedHelper].loadedBoardIDs addObject:boardID];

    [[FirebaseHelper sharedHelper] setProjectUpdatedAt:dateString];
    [[FirebaseHelper sharedHelper] observeBoardWithID:boardID];
}

-(void) deleteBoardWithID:(NSString *)boardID {
    
    [Flurry logEvent:@"Board-Deleted" withParameters: @{ @"projectID" : [FirebaseHelper sharedHelper].currentProjectID, @"teamID" : [FirebaseHelper sharedHelper].teamID }];
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"commentsID"];
    NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@", [FirebaseHelper sharedHelper].db, commentsID];
    Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
    [commentsRef removeAllObservers];
    
    for (NSString *commentThreadID in [[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] allKeys]) {
        
        NSString *infoString = [NSString stringWithFormat:@"%@/info", commentThreadID];
        [[commentsRef childByAppendingPath:infoString] removeAllObservers];
        
        NSString *messageString = [NSString stringWithFormat:@"%@/messages", commentThreadID];
        [[commentsRef childByAppendingPath:messageString] removeAllObservers];
        
        NSString *updatedString = [NSString stringWithFormat:@"%@/updatedAt", commentThreadID];
        [[commentsRef childByAppendingPath:updatedString] removeAllObservers];
    }
    
    [commentsRef removeValue];
    
    if (commentsID) [[FirebaseHelper sharedHelper].comments removeObjectForKey:commentsID];
    
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", [FirebaseHelper sharedHelper].db, boardID];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    [[boardRef childByAppendingPath:@"name"] removeAllObservers];
    [[boardRef childByAppendingPath:@"updatedAt"] removeAllObservers];
    
    for (NSString *userID in [[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"undo"] allKeys]) {
        
        NSString *undoString = [NSString stringWithFormat:@"undo/%@", userID];
        [[boardRef childByAppendingPath:undoString] removeAllObservers];
    }
    
    for (NSString *userID in [[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"subpaths"] allKeys]) {
        
        NSString *subpathsString = [NSString stringWithFormat:@"subpaths/%@", userID];
        [[boardRef childByAppendingPath:subpathsString] removeAllObservers];
    }

    [[boardRef childByAppendingPath:@"versions"] removeAllObservers];
    
    [boardRef removeValue];
    [[FirebaseHelper sharedHelper].boards removeObjectForKey:boardID];
}

-(void) drawBoard:(BoardView *)boardView {
    
    boardView.shapeRect = CGRectNull;
    
    [boardView clear];
    
    boardView.drawingBoard = true;
    
    NSDictionary *subpathsDict = [[[FirebaseHelper sharedHelper].boards objectForKey:boardView.boardID] objectForKey:@"subpaths"];

    NSDictionary *dictRef = [[[FirebaseHelper sharedHelper].boards objectForKey:boardView.boardID] objectForKey:@"undo"];
    NSMutableDictionary *undoDict = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)dictRef, kCFPropertyListMutableContainers));
    
    NSMutableDictionary *pathsToDraw = [NSMutableDictionary dictionary];
    
    for (NSString *uid in subpathsDict.allKeys) {
        
        NSDictionary *uidDict = [subpathsDict objectForKey:uid];
        
        NSMutableArray *userOrderedKeys = [uidDict.allKeys mutableCopy];
        NSSortDescriptor *descendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        [userOrderedKeys sortUsingDescriptors:@[descendingSorter]];
        
        BOOL undone = true;
        BOOL cleared = false;
        int undoCount = [[[undoDict objectForKey:uid] objectForKey:@"currentIndex"] intValue];
        
        NSMutableDictionary *subpathsToAdd = [NSMutableDictionary dictionary];
        NSString *startDate;
        
        for (int i=0; i<userOrderedKeys.count; i++) {
            
            NSMutableDictionary *subpathValues = [[uidDict objectForKey:userOrderedKeys[i]] mutableCopy];
            
            if ([subpathValues respondsToSelector:@selector(objectForKey:)]){
                
                if (boardView.selectedAvatarUserID != nil && ![uid isEqualToString:boardView.selectedAvatarUserID]) [subpathValues setObject:@1 forKey:@"faded"];
                if (!undone && !cleared) [subpathsToAdd setObject:subpathValues forKey:userOrderedKeys[i]];
                
            } else if ([[uidDict objectForKey:userOrderedKeys[i]] respondsToSelector:@selector(isEqualToString:)]) {
                
                if ([[uidDict objectForKey:userOrderedKeys[i]] isEqualToString:@"penUp"]) {
                    
                    [subpathsToAdd setObject:@{userOrderedKeys[i] : @"penUp"} forKey:userOrderedKeys[i]];
                    if (startDate) [pathsToDraw setObject:[subpathsToAdd copy] forKey:startDate];
                    else [pathsToDraw setObject:[subpathsToAdd copy] forKey:userOrderedKeys[i]];
                    subpathsToAdd = [NSMutableDictionary dictionary];
                    
                    if (i < userOrderedKeys.count-1) startDate = userOrderedKeys[i+1];
                    
                    if (undoCount > 0) {
                        
                        undone = true;
                        undoCount--;
                        
                    } else {
                        
                        if (undone && [uid isEqualToString:[FirebaseHelper sharedHelper].uid]) self.activeBoardUndoIndexDate = userOrderedKeys[i];
                        
                        undone = false;
                    }
                    
                } else if ([[uidDict objectForKey:userOrderedKeys[i]] isEqualToString:@"clear"]) {
                    
                    if (!undone) cleared = true;
                }
            }
        }
    }
    
    NSSortDescriptor *ascendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    NSMutableArray *pathsOrderedKeys = [pathsToDraw.allKeys mutableCopy];
    [pathsOrderedKeys sortUsingDescriptors:@[ascendingSorter]];
    
    for (int i=0; i<pathsOrderedKeys.count; i++) {
        
        NSDictionary *pathDict = [pathsToDraw objectForKey:pathsOrderedKeys[i]];
        NSMutableArray *subpathsOrderedKeys = [pathDict.allKeys mutableCopy];
        [subpathsOrderedKeys sortUsingDescriptors:@[ascendingSorter]];
        
        for (int j=0; j<subpathsOrderedKeys.count; j++) {
            
            NSDictionary *subpathDict = [pathDict objectForKey:subpathsOrderedKeys[j]];
            
            if (j==subpathsOrderedKeys.count-1 && i==pathsOrderedKeys.count-1) boardView.drawingBoard = false;
            
            [boardView drawSubpath:subpathDict];
        }
    }
}

- (IBAction)sendTapped:(id)sender {
    
    if (![self.chatTextField isFirstResponder]) [self.chatTextField becomeFirstResponder];
    else [self textFieldShouldReturn:self.chatTextField];
}

-(void) boardTapped:(id)sender {
    
    self.showButtons = true;
    
    iCarousel *carousel;
    
    if (self.versioning) carousel = self.versionsCarousel;
    else carousel = self.carousel;
    
    if([self.editBoardNameTextField isFirstResponder]) {
        [self textFieldShouldReturn:self.editBoardNameTextField];
        [self.editBoardNameTextField resignFirstResponder];
        return;
    }
    
    if (self.carouselMoving) {
        [carousel scrollToItemAtIndex:carousel.currentItemIndex animated:YES];
        return;
    }
    
    UIButton *button = (UIButton *)sender;
    self.currentBoardView = (BoardView *)button.superview;

    if (![[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:self.currentBoardView.boardID]) return;
    
    [carousel setScrollEnabled:NO];
    self.carouselOffset = 0;

    for (UIGestureRecognizer *swipe in carousel.gestureRecognizers) {
        swipe.enabled = false;
    }
    
    self.boardNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:24];
    [self.boardNameLabel sizeToFit];
    self.boardNameLabel.center = CGPointMake(self.carousel.center.x, self.boardNameLabel.center.y);
    self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+17, self.boardNameLabel.center.y);
    boardButton = button;
    self.activeBoardID = self.currentBoardView.boardID;
    self.activeBoardUndoIndexDate = [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndexDate"];
    
    [[FirebaseHelper sharedHelper] setInBoard:self.currentBoardView.boardID];

    if (![self.currentBoardView.activeUserIDs containsObject:[FirebaseHelper sharedHelper].uid]) [self.currentBoardView.activeUserIDs addObject:[FirebaseHelper sharedHelper].uid];
    [self.currentBoardView layoutAvatars];
    
    self.currentBoardView.lineColorNumber = @1;
    [(UIButton *)[self.view viewWithTag:8] setBackgroundImage:[UIImage imageNamed:@"black.png"] forState:UIControlStateNormal];
    self.currentBoardView.penType = 1;
    [(UIButton *)[self.view viewWithTag:6] setBackgroundImage:[UIImage imageNamed:@"pen.png"] forState:UIControlStateNormal];
    self.currentBoardView.shapeType = 1;
    [(UIButton *)[self.view viewWithTag:5] setBackgroundImage:[UIImage imageNamed:@"handshape.png"] forState:UIControlStateNormal];
    self.erasing = false;
    for (int i=6; i<=10; i++) {
        if (i==8) continue;
        UIView *button = [self.view viewWithTag:i];
        if (i==6) [button viewWithTag:50].hidden = false;
        else if (i==9) button.alpha = .3;
        else [button viewWithTag:50].hidden = true;
    }

    NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"name"];
    NSString *labelString = [NSString stringWithFormat:@"|   %@", boardName];
    UILabel *boardNameLabel = (UILabel *)[self.view viewWithTag:102];
    boardNameLabel.text = labelString;
    if ([boardName isEqualToString:@"Untitled"]) boardNameLabel.alpha = .2;
    else boardNameLabel.alpha = 1;
    [boardNameLabel sizeToFit];
    CGRect projectNameRect = [self.view viewWithTag:101].frame;
    boardNameLabel.frame = CGRectMake(projectNameRect.size.width+46, projectNameRect.origin.y+5.5, boardNameLabel.frame.size.width, boardNameLabel.frame.size.height);
    UILabel *versionLabel = (UILabel *)[self.view viewWithTag:105];
    versionLabel.text = [NSString stringWithFormat:@"Version %ld", self.versionsCarousel.currentItemIndex+1];
    versionLabel.frame = CGRectMake(boardNameLabel.frame.origin.x+17, 42, 100, 50);
    
    self.chatTextField.text = nil;
    self.chatTextField.placeholder = @"Leave a comment...";
    self.messages = [NSMutableArray array];
    [self.chatTable reloadData];
    [self hideChat];
    [self.view sendSubviewToBack:self.addBoardButton];
    [self.view sendSubviewToBack:self.addBoardBackgroundImage];
    [self.view sendSubviewToBack:self.upArrowImage];
    [self.view sendSubviewToBack:self.downArrowImage];
    self.shareButton.hidden = true;
    self.deleteBoardButton.hidden = true;
    self.versionsButton.hidden = true;
    self.versionsCountLabel.hidden = true;
    self.buttonsBackgroundImage.hidden = true;
    [self hideAvatars];
    
    [UIView animateWithDuration:.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         carousel.center = CGPointMake(self.view.center.x, self.view.center.y);
                         CGAffineTransform tr = CGAffineTransformScale(carousel.transform, 2, 2);
                         carousel.transform = tr;
                         
                         self.masterView.center = CGPointMake(-105, self.masterView.center.y);
                         
                         self.chatTextField.frame = CGRectMake(51, 10, 877, 30);
                         self.chatView.frame = CGRectMake(0, 719, 1024, 152);
                         self.chatTable.frame = CGRectMake(0, 612, self.view.frame.size.width, 107+self.chatDiff);
                         self.sendMessageButton.frame = CGRectMake(936, 9, 80, 30);
                         self.chatOpenButton.center = CGPointMake(self.view.center.x, self.chatOpenButton.center.y);
                         self.chatFadeImage.frame = CGRectMake(0, 603, 1024, 25);
                         self.commentTitleView.frame = CGRectMake(0, 613, 1024, 50);
                         
                         boardButton.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         
                         boardButton.hidden = true;

                         [self showDrawMenu];
                         
                         if (newBoardCreated && !self.versioning) [self showEditBoardName];
                         
                         newBoardCreated = false;
                         self.showButtons = false;
                         
                         if (![[NSUserDefaults standardUserDefaults] objectForKey:@"boardTutorial"]) {
                             
                             self.tutorialView.type = 4;
                             [self.view bringSubviewToFront:self.tutorialView];
                             [self.tutorialView updateTutorial];
                         }
                     }
     ];
}

-(void)closeTapped {
    
    self.showButtons = true;
    
    iCarousel *carousel;
    
    if (self.versioning) carousel = self.versionsCarousel;
    else carousel = self.carousel;
    
    for (UIGestureRecognizer *swipe in carousel.gestureRecognizers) {
        swipe.enabled = true;
    }
    
    if (self.currentBoardView.gridOn) [self gridTapped:nil];
    carouselFade.hidden = false;
    
    boardButton.hidden = false;
    self.currentBoardView.gridOn = false;
    self.currentBoardView.commenting = false;
    //self.currentBoardView.shaping = false;
    self.currentBoardView.fadeView.hidden = true;
    self.currentBoardView.leaveCommentLabel.hidden = true;
    self.chatOpen = false;
    
    self.chatOpenButton.hidden = false;
    self.chatFadeImage.hidden = false;
    self.chatTable.hidden = false;
    self.chatView.hidden = false;
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    if ([[self.view viewWithTag:104] isFirstResponder]) [[self.view viewWithTag:104] resignFirstResponder];
    if ([self.commentTitleTextField isFirstResponder]) [self.commentTitleTextField resignFirstResponder];
    [self hideDrawMenu];
    
    NSString *boardID = self.activeBoardID;
    [[self.updatedElements objectForKey:@"boards"] removeObject:boardID];
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"commentsID"];
    for (NSString *commentThreadID in [[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] allKeys]) {
        [[self.updatedElements objectForKey:@"comments"] removeObject:commentThreadID];
    }
    self.activeBoardID = nil;
    self.activeCommentThreadID = nil;
    
    [[FirebaseHelper sharedHelper] setInBoard:@"none"];
    
    self.carouselOffset = 0;
    [self.currentBoardView.activeUserIDs removeObject:[FirebaseHelper sharedHelper].uid];
    [self.currentBoardView layoutAvatars];
    self.currentBoardView.selectedAvatarUserID = nil;
    self.currentBoardView.userLabel.text = nil;
    self.currentBoardView.userLabel.hidden = true;
    [self drawBoard:self.currentBoardView];
    self.currentBoardView = nil;
    
    [self.view bringSubviewToFront:self.masterView];
    [self.view bringSubviewToFront:self.feedbackBackground];
    [self.view bringSubviewToFront:self.feedbackButton];
    
    self.commentTitleView.hidden = true;
    self.messages = [NSMutableArray array];
    self.chatTextField.placeholder = @"Send a message...";
    [self.chatTable reloadData];
    
    [UIView animateWithDuration:.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         float masterWidth = self.masterView.frame.size.width;
                         
                         self.chatTextField.frame = CGRectMake(51, 10, 667, 30);
                         self.chatTable.frame = CGRectMake(masterWidth, 612, self.view.frame.size.width-masterWidth, 107+self.chatDiff);
                         self.chatView.frame = CGRectMake(masterWidth, 719, 814, 49);
                         self.sendMessageButton.frame = CGRectMake(726, 9, 80, 30);
                         self.chatOpenButton.center = CGPointMake(self.chatView.center.x, 598);
                         self.chatFadeImage.frame = CGRectMake(210, 603, 1024, 25);
                         self.commentTitleView.frame = CGRectMake(210, 613, 1024, 50);
                         
                         CGAffineTransform tr = CGAffineTransformScale(carousel.transform, .5, .5);
                         carousel.transform = tr;
                         carousel.center = CGPointMake(self.view.center.x+masterWidth/2, self.view.frame.size.height/2-44);
                         
                         self.masterView.center = CGPointMake(masterWidth/2, self.masterView.center.y);
                         
                         boardButton.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         
                         [carousel setScrollEnabled:YES];
                         
                         [self updateDetails:!self.versioning];
                         
                         [self showChat];
                         [self.view bringSubviewToFront:self.addBoardBackgroundImage];
                         [self.view bringSubviewToFront:self.buttonsBackgroundImage];
                         [self.view bringSubviewToFront:self.upArrowImage];
                         [self.view bringSubviewToFront:self.downArrowImage];
                         [self.view bringSubviewToFront:self.versionsButton];
                         [self.view bringSubviewToFront:self.addBoardButton];
                         [self.view bringSubviewToFront:self.shareButton];
                         [self.view bringSubviewToFront:self.versionsCountLabel];
                         [self.view bringSubviewToFront:self.deleteBoardButton];
                         [self.view bringSubviewToFront:self.versionsButton];
                         self.shareButton.hidden = false;
                         if  (self.userRole > 0) self.deleteBoardButton.hidden = false;
                         self.versionsButton.hidden = false;
                         NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"versions"];
                         if (versionsArray.count > 1) self.versionsCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)versionsArray.count];
                         else self.versionsCountLabel.text = @"";
                         if (!self.versioning) self.versionsCountLabel.hidden = false;
                         self.buttonsBackgroundImage.hidden = false;
                         
                         if (![FirebaseHelper sharedHelper].connected) {
                             
                             [[FirebaseHelper sharedHelper] clearData];
                             
                             [self hideAll];
                             self.masterView.teamButton.hidden = true;
                             self.masterView.teamMenuButton.hidden = true;
                             self.masterView.nameButton.hidden = true;
                             self.masterView.avatarButton.hidden = true;
                             self.masterView.avatarShadow.hidden = true;
                             
                             OfflineAlertViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Offline"];
                             
                             UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                             nav.modalPresentationStyle = UIModalPresentationFormSheet;
                             nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                             
                             UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
                             logoImageView.frame = CGRectMake(162, 8, 32, 32);
                             [nav.navigationBar addSubview:logoImageView];
                             
                             [self presentViewController:nav animated:YES completion:nil];
                         }
                         else if (![FirebaseHelper sharedHelper].loggedIn) {
    
                             NSString *email = [FirebaseHelper sharedHelper].email;
                             
                             [[FirebaseHelper sharedHelper] signOut];

                             SignedOutAlertViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SignedOut"];
                             vc.email = email;
                             
                             UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                             nav.modalPresentationStyle = UIModalPresentationFormSheet;
                             nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                             
                             UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
                             logoImageView.frame = CGRectMake(162, 8, 32, 32);
                             logoImageView.tag = 800;
                             [nav.navigationBar addSubview:logoImageView];
                         }
                         else if (![[FirebaseHelper sharedHelper].projects.allKeys containsObject:[FirebaseHelper sharedHelper].currentProjectID]) {
                             
                             [self.masterView.projectsTable reloadData];
                             
                             if ([FirebaseHelper sharedHelper].visibleProjectIDs.count > 0) {
                                 
                                 NSIndexPath *mostRecent = [[FirebaseHelper sharedHelper] getLastViewedProjectIndexPath];
                                 [self.masterView tableView:self.masterView.projectsTable didSelectRowAtIndexPath:mostRecent];
                             }
                             else {
                                 
                                 [self hideAll];
                                 [FirebaseHelper sharedHelper].currentProjectID = nil;
                             }
                         }
                         else if ((![self.boardIDs containsObject:boardID] && !self.versioning) || (![[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"] containsObject:boardID] && self.versioning)) {
                             
                             [[FirebaseHelper sharedHelper].boards removeObjectForKey:boardID];
                             
                             if (self.versioning) {
                                 
                                 NSString *parentBoardID = self.boardIDs[self.carousel.currentItemIndex];
                                 [[[[FirebaseHelper sharedHelper].boards objectForKey:parentBoardID] objectForKey:@"versions"] removeObject:boardID];
                             }
                             
                             NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", [FirebaseHelper sharedHelper].db, boardID];
                             Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
                             [[boardRef childByAppendingPath:@"name"] removeAllObservers];
                             [[boardRef childByAppendingPath:@"updatedAt"] removeAllObservers];
                             [[boardRef childByAppendingPath:@"versions"] removeAllObservers];
                             
                             for (NSString *userID in [[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"undo"] allKeys]) {
                                 
                                 NSString *undoString = [NSString stringWithFormat:@"undo/%@", userID];
                                 [[boardRef childByAppendingPath:undoString] removeAllObservers];
                             }
                             
                             for (NSString *userID in [[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"subpaths"] allKeys]) {
                                 
                                 NSString *subpathsString = [NSString stringWithFormat:@"subpaths/%@", userID];
                                 [[boardRef childByAppendingPath:subpathsString] removeAllObservers];
                             }
                             
                             NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"commentsID"];
                             
                             if ([[FirebaseHelper sharedHelper].comments.allKeys containsObject:commentsID]) [[FirebaseHelper sharedHelper].comments removeObjectForKey:commentsID];
                             
                             NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@", [FirebaseHelper sharedHelper].db, commentsID];
                             Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
                             [commentsRef removeAllObservers];
                         }
                         
                         else {
                             
                             [self.masterView.projectsTable reloadData];
                             
                             if (![self.boardIDs isEqual:[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"boards"]]) {

                                 NSUInteger currentIndex = carousel.currentItemIndex;
                                 [self.masterView tableView:self.masterView.projectsTable didSelectRowAtIndexPath:self.masterView.defaultRow];
                                 [carousel scrollToItemAtIndex:currentIndex animated:NO];
                             }
                             else [self.masterView.projectsTable selectRowAtIndexPath:self.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
                             
                         }
            }];
}

- (IBAction)editTapped:(id)sender {
    
    self.editing = true;
    
    [self.draggableCollectionView reloadData];
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    if ([self.editBoardNameTextField isFirstResponder]) [self.editBoardNameTextField resignFirstResponder];
    
    self.editBoardIDs = [self.boardIDs mutableCopy];
    
    self.editProjectNameTextField.text = self.projectName;
    
    editFade.hidden = false;
    
    self.editButton.hidden = true;
    self.carousel.hidden = true;
    self.versionsCarousel.hidden = true;
    self.versioning = false;
    self.versionsLabel.hidden = false;
    self.versionsLabel.alpha = .3;
    self.versionsLabel.text = @"press and hold on boards to rearrange them";
    self.upArrowImage.hidden = true;
    self.downArrowImage.hidden = true;
    self.draggableCollectionView.hidden = false;
    self.boardNameLabel.hidden = true;
    self.addBoardButton.hidden = true;
    self.shareButton.hidden = true;
    self.versionsButton.hidden = true;
    self.versionsCountLabel.hidden = true;
    self.deleteBoardButton.hidden = true;
    self.addBoardBackgroundImage.hidden = true;
    self.buttonsBackgroundImage.hidden = true;
    
    self.projectNameEditButton.hidden = false;
    self.editBoardNameTextField.hidden = true;
    self.boardNameEditButton.hidden = true;
    self.applyChangesButton.hidden = false;
    self.applyBackgroundImage.hidden = false;
    self.cancelButton.hidden = false;
    self.cancelBackgroundImage.hidden = false;
    self.deleteProjectBackgroundImage.hidden = false;
    self.deleteProjectButton.hidden = false;
    
    self.chatFadeImage.hidden = true;
    self.chatView.hidden = true;
    self.chatTable.hidden = true;
    self.chatOpenButton.hidden = true;
    
    for (int i=0; i<self.boardIDs.count; i++) {
        [self collectionView:self.draggableCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    [self.view bringSubviewToFront:self.applyBackgroundImage];
    [self.view bringSubviewToFront:self.applyChangesButton];
    [self.view bringSubviewToFront:self.cancelBackgroundImage];
    [self.view bringSubviewToFront:self.cancelButton];
    [self.view bringSubviewToFront:self.deleteProjectBackgroundImage];
    [self.view bringSubviewToFront:self.deleteProjectButton];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"editTutorial"]) {
    
        self.tutorialView.type = 2;
        [self.view bringSubviewToFront:self.tutorialView];
        [self.tutorialView updateTutorial];
    }
}

- (IBAction)projectNameEditTapped:(id)sender {

    self.editProjectNameTextField.text = self.projectNameLabel.text;
    
    self.editProjectNameTextField.textColor = [UIColor blackColor];
    self.editProjectNameTextField.userInteractionEnabled = true;
    self.projectNameEditButton.hidden = true;
    self.projectNameLabel.hidden = true;
    self.editProjectNameTextField.hidden = false;
    
    [self.editProjectNameTextField becomeFirstResponder];
}

- (IBAction)boardNameEditTapped:(id)sender {
    
    self.editBoardNameTextField.hidden = false;
    self.boardNameLabel.hidden = true;
    self.boardNameEditButton.hidden = true;
    [self.carousel setScrollEnabled:NO];
    
    NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"name"];
    
    if ([boardName isEqualToString:@"Untitled"]) self.editBoardNameTextField.text = nil;
    else self.editBoardNameTextField.text = boardName;
    
    [self.editBoardNameTextField becomeFirstResponder];
}

-(void) avatarTapped:(id)sender {
    
    AvatarButton *avatar = (AvatarButton *)sender;
    AvatarPopoverViewController *avatarPopover = [[AvatarPopoverViewController alloc] init];
    
    avatarPopover.userID = avatar.userID;
    [avatarPopover updateMenu];
    [avatarPopover setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popover = [avatarPopover popoverPresentationController];
    popover.sourceView = avatar;
    popover.sourceRect = avatar.bounds;
    popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    
    [self presentViewController:avatarPopover animated:NO completion:nil];
}

-(IBAction) applyChangesTapped:(id)sender {
    
    NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];

    if (![self.editProjectNameTextField.text isEqualToString:[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"name"]]) {
        
        self.showButtons = true;
        
        NSString *newName = self.editProjectNameTextField.text;
        
        if (newName.length > 0) {
            
            self.projectNameLabel.text = newName;
            CGRect projectRect = [self.projectNameLabel.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.projectNameLabel.font} context:nil];
            self.editButton.center = CGPointMake(MIN(projectRect.size.width+290,600), self.projectNameLabel.center.y+3);
            self.projectNameEditButton.center = self.editButton.center;
            
            [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:newName forKey:@"name"];
            
            [self.masterView updateProjects];        
            self.masterView.defaultRow = [NSIndexPath indexPathForRow:[self.masterView.orderedProjectNames indexOfObject:newName] inSection:0];
            [self.masterView.projectsTable reloadData];
            [self.masterView tableView:self.masterView.projectsTable didSelectRowAtIndexPath:self.masterView.defaultRow];
         
            [[projectRef childByAppendingPath:@"name"] setValue:newName];
        }
    }

    if (![self.editBoardIDs isEqualToArray:self.boardIDs]) {

        self.showButtons = true;
        
        NSMutableDictionary *boardsDict = [NSMutableDictionary dictionary];
        
        for (int i=0; i<self.editBoardIDs.count; i++) [boardsDict setObject:self.editBoardIDs[i] forKey:[@(i) stringValue]];
        
        [[projectRef childByAppendingPath:@"boards"] setValue:boardsDict];
        
        [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:boardsDict forKey:@"boards"];
        
        for (NSString *boardID in self.boardIDs) {
            
            if (![self.editBoardIDs containsObject:boardID]) {
             
                [self deleteBoardWithID:boardID];
                
                [Flurry logEvent:@"Board-Deleted" withParameters: @{ @"projectID" : [FirebaseHelper sharedHelper].currentProjectID, @"teamID" : [FirebaseHelper sharedHelper].teamID }];
                
                NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"versions"];
                
                for (int i=1; i<versionsArray.count; i++) [self deleteBoardWithID:versionsArray[i]];
            }
        }
        
        self.boardIDs = [self.editBoardIDs mutableCopy];
        
        if (self.boardIDs.count == 0) [self createBoard];
        
        [self.carousel reloadData];
        [self carouselCurrentItemIndexDidChange:self.carousel];
        
        [self cancelTapped:nil];
    }
    
    [self cancelTapped:nil];
}

- (IBAction)cancelTapped:(id)sender {
    
    editFade.hidden = true;
    
    self.projectNameLabel.hidden = false;
    self.projectNameEditButton.hidden = true;
    self.carousel.currentItemView.hidden = false;
    self.carousel.hidden = false;
    self.carousel.userInteractionEnabled = true;
    self.versionsCarousel.hidden = true;
    self.versioning = false;
    self.upArrowImage.hidden = true;
    self.downArrowImage.hidden = true;
    self.draggableCollectionView.hidden = true;
    self.boardNameLabel.hidden = false;
    self.versionsLabel.alpha = 1;
    self.versionsLabel.text = @"";
    self.versionsLabel.hidden = true;
    
    if (self.userRole > 0) {

        if (self.userRole > 1) self.editButton.hidden = false;
        else self.editButton.hidden = true;
        self.addBoardButton.hidden = false;
        self.addBoardButton.frame = CGRectMake(804, 552, 142, 42);
        [self.addBoardButton setImage:[UIImage imageNamed:@"newboard.png"] forState:UIControlStateNormal];
        self.addBoardBackgroundImage.hidden = false;
        self.addBoardBackgroundImage.frame = CGRectMake(804, 552, 142, 42);
        [self.addBoardBackgroundImage setImage:[UIImage imageNamed:@"newboardbackground.png"]];
        self.shareButton.hidden = false;
        self.versionsButton.hidden = false;
        [self.versionsButton setImage:[UIImage imageNamed:@"versions.png"] forState:UIControlStateNormal];
        self.versionsCountLabel.text = @"";
        if (self.boardIDs.count > self.carousel.currentItemIndex) {
            NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"];
            if (versionsArray.count > 1) self.versionsCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)versionsArray.count];
        }
        self.versionsCountLabel.hidden = false;
        if  (self.userRole > 0) self.deleteBoardButton.hidden = false;
        self.buttonsBackgroundImage.hidden = false;
        self.chatView.hidden = false;
        self.chatTextField.text = nil;
        if (self.boardNameLabel.text.length > 0) self.boardNameEditButton.hidden = false;
    }
    else {
        
        self.editButton.hidden = true;
        self.addBoardButton.hidden = true;
        self.shareButton.hidden = true;
        self.versionsButton.hidden = true;
        self.versionsCountLabel.hidden = true;
        self.deleteBoardButton.hidden = true;
        self.addBoardBackgroundImage.hidden = true;
        self.buttonsBackgroundImage.hidden = true;
        self.chatView.hidden = true;
        self.boardNameEditButton.hidden = true;
    }
    
    self.editProjectNameTextField.hidden = true;
    self.editBoardNameTextField.hidden = true;
    self.applyChangesButton.hidden = true;
    self.applyBackgroundImage.hidden = true;
    self.cancelButton.hidden = true;
    self.cancelBackgroundImage.hidden = true;
    self.deleteProjectButton.hidden = true;
    self.deleteProjectBackgroundImage.hidden = true;
    
    self.chatFadeImage.hidden = false;
    self.chatTable.hidden = false;
    self.chatOpenButton.hidden = false;
    
    self.editing = false;
}

- (IBAction)deleteProjectTapped:(id)sender {
    
    DeleteProjectAlertViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DeleteProject"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(160, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (void) undoTapped:(id)sender {
    
    self.currentBoardView.commenting = false;
    self.currentBoardView.leaveCommentLabel.hidden = true;
    self.currentBoardView.fadeView.hidden = true;
    
    int undoCount = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    int undoTotal = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"total"] intValue];
    
    if (undoCount < undoTotal)  {
        
        undoCount++;
        
        if (undoCount == undoTotal) [self.view viewWithTag:2].alpha = .3;
        [self.view viewWithTag:3].alpha = 1;
        
        NSMutableDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
        [undoDict setObject:@(undoCount) forKey:@"currentIndex"];
        
        [self drawBoard:self.currentBoardView];
        
        [self.currentBoardView addUserDrawing:[FirebaseHelper sharedHelper].uid];
        
        [undoDict setObject:self.activeBoardUndoIndexDate forKey:@"currentIndexDate"];
        
        if ([self canClear]) [self.view viewWithTag:4].alpha = 1;
        else [self.view viewWithTag:4].alpha = .3;
        
        NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/undo/%@", [FirebaseHelper sharedHelper].db, self.currentBoardView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [ref setValue:undoDict];
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        [[FirebaseHelper sharedHelper] setBoard:self.activeBoardID UpdatedAt:dateString];
    }
}

- (void) redoTapped:(id)sender {
    
    self.currentBoardView.commenting = false;
    self.currentBoardView.leaveCommentLabel.hidden = true;
    self.currentBoardView.fadeView.hidden = true;
    
    int undoCount = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    
    if (undoCount > 0) {
        
        undoCount--;
        
        if (undoCount == 0) [self.view viewWithTag:3].alpha = .3;
        [self.view viewWithTag:2].alpha = 1;
        
        NSMutableDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
        [undoDict setObject:@(undoCount) forKey:@"currentIndex"];
        
        [self drawBoard:self.currentBoardView];
        
        [self.currentBoardView addUserDrawing:[FirebaseHelper sharedHelper].uid];
        
        [undoDict setObject:self.activeBoardUndoIndexDate forKey:@"currentIndexDate"];
        
        if ([self canClear]) [self.view viewWithTag:4].alpha = 1;
        else [self.view viewWithTag:4].alpha = .3;
        
        NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/undo/%@/", [FirebaseHelper sharedHelper].db, self.currentBoardView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [ref setValue:undoDict];
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        [[FirebaseHelper sharedHelper] setBoard:self.activeBoardID UpdatedAt:dateString];
    }
}

- (void) clearTapped:(id)sender {
    
    self.currentBoardView.commenting = false;
    self.currentBoardView.leaveCommentLabel.hidden = true;
    self.currentBoardView.fadeView.hidden = true;
    
    NSDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
    
    [self.view viewWithTag:4].alpha = .3;
    [self.view viewWithTag:3].alpha = .3;
    [self.view viewWithTag:2].alpha = 1;
    
    if ([[undoDict objectForKey:@"total"] integerValue] == [[undoDict objectForKey:@"currentIndex"] integerValue] || ![self canClear]) return;
    
    [[FirebaseHelper sharedHelper] resetUndo];
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSString *refString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/subpaths/%@", [FirebaseHelper sharedHelper].db, self.currentBoardView.boardID, [FirebaseHelper sharedHelper].uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:refString];
    NSDictionary *clearDict = @{ dateString : @"clear" };
    [ref updateChildValues:clearDict];
    
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@"clear" forKey:dateString];
    
    [self.currentBoardView touchesEnded:nil withEvent:nil];
    [self drawBoard:self.currentBoardView];
    
    [self.currentBoardView addUserDrawing:[FirebaseHelper sharedHelper].uid];
}

-(void) handshapeTapped:(id)sender {
    
    self.erasing = false;
    self.currentBoardView.commenting = false;
    self.currentBoardView.leaveCommentLabel.hidden = true;
    self.currentBoardView.fadeView.hidden = true;
    
    UIButton *shapeButton = (UIButton *)sender;
    
    ShapePopoverViewController *shapePopover = [[ShapePopoverViewController alloc] init];
    
    [shapePopover setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popover = [shapePopover popoverPresentationController];
    popover.sourceView = shapeButton;
    popover.sourceRect = shapeButton.bounds;
    popover.backgroundColor = nil;
    popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
    
    [self presentViewController:shapePopover animated:NO completion:nil];
    
    for (int i=6; i<=10; i++) {
        
        if (i==8 || i==9) continue;
        
        UIView *button = [self.view viewWithTag:i];
        if (i==6) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
}

-(void) eraseTapped:(id)sender {

    //self.currentBoardView.shaping = false;
    self.currentBoardView.commenting = false;
    self.currentBoardView.leaveCommentLabel.hidden = true;
    self.currentBoardView.fadeView.hidden = true;
    self.erasing = true;
    
    [self.view bringSubviewToFront:self.eraserCursor];
    
    for (int i=6; i<=10; i++) {
        
        if (i==8 || i==9) continue;
        
        UIView *button = [self.view viewWithTag:i];
        if (i==7) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
}

-(void) colorTapped:(id)sender {
    
    self.currentBoardView.commenting = false;
    self.currentBoardView.leaveCommentLabel.hidden = true;
    self.currentBoardView.fadeView.hidden = true;
    self.erasing = false;
    
    UIButton *colorButton = (UIButton *)sender;
    
    ColorPopoverViewController *colorPopover = [[ColorPopoverViewController alloc] init];
    
    [colorPopover setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popover = [colorPopover popoverPresentationController];
    popover.sourceView = colorButton;
    popover.sourceRect = colorButton.bounds;
    popover.backgroundColor = nil;
    popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
    
    [self presentViewController:colorPopover animated:NO completion:nil];
}

-(void) penTapped:(id)sender {
    
    self.erasing = false;
    //self.currentBoardView.shaping = false;
    self.currentBoardView.commenting = false;
    self.currentBoardView.leaveCommentLabel.hidden = true;
    self.currentBoardView.fadeView.hidden = true;
    
    UIButton *penButton = (UIButton *)sender;

    if (![penButton viewWithTag:50].hidden) {
        
        PenTypePopoverViewController *penTypePopover = [[PenTypePopoverViewController alloc] init];
        
        [penTypePopover setModalPresentationStyle:UIModalPresentationPopover];
        
        UIPopoverPresentationController *popover = [penTypePopover popoverPresentationController];
        popover.sourceView = penButton;
        popover.sourceRect = penButton.bounds;
        popover.backgroundColor = nil;
        popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
        
        [self presentViewController:penTypePopover animated:NO completion:nil];
    }
    
    for (int i=6; i<=10; i++) {
        
        if (i==8 || i==9) continue;
        
        UIView *button = [self.view viewWithTag:i];
        if (i==6) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
}

-(void) gridTapped:(id)sender {
    
    self.currentBoardView.gridOn = !self.currentBoardView.gridOn;
    
    if (self.currentBoardView.gridOn) [self.view viewWithTag:9].alpha = 1;
    else [self.view viewWithTag:9].alpha = .3;
    
    NSArray *boardIDs;
    iCarousel *carousel;
    
    if (self.versioning) {
        
        boardIDs = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"];
        carousel = self.versionsCarousel;
        
        self.carousel.hidden = true;
        carouselFade.hidden = true;
    }
    else {
        
        boardIDs = self.boardIDs;
        carousel = self.carousel;
    }
    
    self.gridImageView.hidden = !self.currentBoardView.gridOn;

    for (UIView *view in carousel.visibleItemViews) {
        
        if ([view isEqual:carousel.currentItemView]) continue;
        view.hidden = self.currentBoardView.gridOn;
    }
    
    [self drawBoard:self.currentBoardView];
}

-(void) commentTapped:(id)sender {

    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.activeBoardID] objectForKey:@"commentsID"];
    NSInteger commentCount = [[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] allKeys] count];
    
    if (commentCount == 0) {
        
        for (int i=6; i<=10; i++) {
            
            if (i==8) continue;
            
            UIView *button = [self.view viewWithTag:i];
            if (i==10) [button viewWithTag:50].hidden = false;
            else [button viewWithTag:50].hidden = true;
        }
        
        [self.currentBoardView layoutComments];
        self.currentBoardView.hideComments = true;
        
        self.currentBoardView.commenting = true;
        
        [self.currentBoardView bringSubviewToFront:self.currentBoardView.fadeView];
        self.currentBoardView.fadeView.hidden = false;
        [self.currentBoardView bringSubviewToFront:self.currentBoardView.leaveCommentLabel];
        self.currentBoardView.leaveCommentLabel.hidden = false;
        
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"commentTutorial"]) {
            
            self.tutorialView.type = 5;
            [self.view bringSubviewToFront:self.tutorialView];
            [self.tutorialView updateTutorial];
        }
    }
    else {
        
        UIButton *commentButton = (UIButton *)sender;
        
        CommentPopoverViewController *commentPopover = [[CommentPopoverViewController alloc] init];
        
        [commentPopover setModalPresentationStyle:UIModalPresentationPopover];
        
        UIPopoverPresentationController *popover = [commentPopover popoverPresentationController];
        popover.sourceView = commentButton;
        popover.sourceRect = commentButton.bounds;
        popover.backgroundColor = nil;
        popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
        
        [self presentViewController:commentPopover animated:NO completion:nil];
    }
}

- (IBAction)newBoardTapped:(id)sender {
    
    newBoardCreated = true;
    
    [self createBoard];
    
    if (self.versioning) {
        
        [Flurry logEvent:@"Versions-New_Version" withParameters: @{ @"boardID" : self.boardIDs[self.carousel.currentItemIndex], @"projectID" : [FirebaseHelper sharedHelper].currentProjectID, @"teamID" : [FirebaseHelper sharedHelper].teamID }];
        
        self.activeBoardID = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"] lastObject];

        [self.versionsCarousel reloadData];
        [self.versionsCarousel scrollByNumberOfItems:self.versionsCarousel.numberOfItems duration:.5];
    }
    else {
        
        [Flurry logEvent:@"Board-Created" withParameters: @{ @"projectID" : [FirebaseHelper sharedHelper].currentProjectID, @"teamID" : [FirebaseHelper sharedHelper].teamID }];
        
        self.activeBoardID = [self.boardIDs lastObject];
        [self.carousel reloadData];
        [self.carousel scrollByNumberOfItems:self.carousel.numberOfItems duration:.5];
    }
}

- (IBAction)deleteBoardTapped:(id)sender {

    if (![[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:self.boardIDs[self.carousel.currentItemIndex]]) return;
    
    DeleteBoardAlertViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DeleteBoard"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(177, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)versionsTapped:(id)sender {
    
    if (self.versioning) {
        
        self.versioning = false;
        
        [self drawBoard:(BoardView *)self.carousel.currentItemView];
        [(BoardView *)self.carousel.currentItemView layoutComments];
        
        if ([self.boardIDs containsObject:((BoardView *)self.carousel.currentItemView).boardID]) {
            self.carousel.alpha = 0;

            self.carousel.hidden = false;
            
            [UIView animateWithDuration:.1
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 
                                 self.carousel.alpha = 1;
                                 self.versionsLabel.alpha = 0;
                                 self.upArrowImage.alpha = 0;
                                 self.downArrowImage.alpha = 0;
                                 
                             }completion:^(BOOL finished) {
                                 
                                 self.versionsCarousel.hidden = true;
                                 self.carousel.currentItemView.hidden = false;
                                
                                 self.carousel.userInteractionEnabled = true;
                                 
                                 self.versionsLabel.hidden = true;
                                 self.versionsLabel.alpha = 1;
                                 
                                 self.upArrowImage.hidden = true;
                                 self.upArrowImage.alpha = .1;
                                 self.downArrowImage.hidden = true;
                                 self.downArrowImage.alpha = .1;
                                 
                                 [[FirebaseHelper sharedHelper] observeCurrentBoardVersions];
                                 
                                 [self.addBoardButton setImage:[UIImage imageNamed:@"newboard.png"] forState:UIControlStateNormal];
                                 [self.addBoardBackgroundImage setImage:[UIImage imageNamed:@"newboardbackground.png"]];
                                 
                                 [self.versionsButton setImage:[UIImage imageNamed:@"versions.png"] forState:UIControlStateNormal];
                                 self.versionsCountLabel.hidden = false;
                                 
                }];
        }
        else {
            
            self.versionsCarousel.hidden = true;
            self.carousel.currentItemView.hidden = false;
            self.carousel.hidden = false;
            
            self.carousel.userInteractionEnabled = true;
            
            self.versionsLabel.hidden = true;
            self.versionsLabel.alpha = 1;
            
            self.upArrowImage.hidden = true;
            self.upArrowImage.alpha = .1;
            self.downArrowImage.hidden = true;
            self.downArrowImage.alpha = .1;
            
        }

    }
    else {
        
        if (![[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:self.boardIDs[self.carousel.currentItemIndex]]) return;
        
        self.versioning = true;
        self.showButtons = true;
        
        [self.versionsCarousel reloadData];
        [self.versionsCarousel scrollToItemAtIndex:0 animated:NO];
        
        self.carousel.currentItemView.hidden = true;
        self.versionsCarousel.hidden = false;
        
        NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"];
        if (versionsArray.count > 1) self.versionsLabel.text = [NSString stringWithFormat:@"Original (Version 1 of %lu)", versionsArray.count];
        else self.versionsLabel.text = @"Original (Version 1)";
        self.versionsLabel.alpha = 0;
        self.versionsLabel.hidden = false;
        self.carousel.userInteractionEnabled = false;
        
        if (versionsArray.count > 1) {
            self.upArrowImage.hidden = false;
            self.upArrowImage.alpha = 0;
        }
        
        self.versionsCountLabel.hidden = true;
        [self.versionsButton setImage:[UIImage imageNamed:@"carousel.png"] forState:UIControlStateNormal];
        
        [UIView animateWithDuration:.1
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             
                             self.carousel.alpha = 0;
                             self.versionsLabel.alpha = 1;
                             self.upArrowImage.alpha = .1;
                             
                         }completion:^(BOOL finished) {
                             
                             self.carousel.hidden = true;
                             self.carousel.alpha = 1;
                             
                             [[FirebaseHelper sharedHelper] observeCurrentBoardVersions];
                             
                             [self.addBoardButton setImage:[UIImage imageNamed:@"newversion.png"] forState:UIControlStateNormal];
                             [self.addBoardBackgroundImage setImage:[UIImage imageNamed:@"buttonsbackground.png"]];
                             
                             if (![[NSUserDefaults standardUserDefaults] objectForKey:@"versionsTutorial"]) {
                             
                                 self.tutorialView.type = 3;
                                 [self.view bringSubviewToFront:self.tutorialView];
                                 [self.tutorialView updateTutorial];
                             }
                         }];
        
    }
}

- (IBAction)shareTapped:(id)sender {
    
    NSString *boardID;
    
    if (self.versioning) {
        
        NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"];
        boardID = versionsArray[self.versionsCarousel.currentItemIndex];
    }
    else boardID = self.boardIDs[self.carousel.currentItemIndex];
    
    if (![[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:boardID]) return;
    
    UIButton *shareButton = (UIButton *)sender;
    
    SharePopoverViewController *shareVC = [[SharePopoverViewController alloc] init];
    
    [shareVC setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popover = [shareVC popoverPresentationController];
    popover.sourceView = shareButton;
    popover.sourceRect = shareButton.bounds;
    popover.backgroundColor = nil;
    popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
    
    [self presentViewController:shareVC animated:NO completion:nil];
}

- (void)addUserTapped {
    
    [Flurry logEvent:@"Invite_User-Add_User_From_Project" withParameters:
     @{ @"userID":[FirebaseHelper sharedHelper].uid,
        @"teamID":[FirebaseHelper sharedHelper].teamID
        }];
    
    AddUserViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AddUser"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(105, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [self presentViewController:nav animated:YES completion:nil];
    
}

- (IBAction)openChatTapped:(id)sender {
    
    CGPoint chatCenter = self.chatOpenButton.center;
    self.chatOpenButton.frame = CGRectMake(0, 0, 51, 28);
    self.chatOpenButton.center = chatCenter;
    
    if (!self.activeBoardID) {
        
        [self.updatedElements setObject:@1 forKey:@"chat"];
        
        if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
        else if (self.userRole > 0) [self.chatTextField becomeFirstResponder];
        else [self openChat];
    }
    else [self openChat];
}

-(void)chatTableTapped {
 
    if (self.presentedViewController == nil && !self.activeBoardID && !self.editing) {
        
        CGPoint location = [chatTapRecognizer locationInView:self.view];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view];
        
        if (CGRectContainsPoint(self.chatTable.frame, location) && self.tutorialView.hidden) {
            
            if (![self.chatTextField isFirstResponder] && self.userRole > 0) [self.chatTextField becomeFirstResponder];
            else if (!self.chatOpen && self.userRole == 0) [self openChat];
        }
    }
}

- (IBAction)feedbackTapped:(id)sender {

    InstabugViewController *instabugVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Instabug"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instabugVC];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(195, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [self presentViewController:nav animated:YES completion:nil];
}

-(void) tappedOutside {
    
    if (self.handleOutsideTaps && self.presentedViewController && outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.presentedViewController.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.presentedViewController.view.frame, converted)) {
            [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
            self.handleOutsideTaps = false;
        }
    }
}

-(void)boardSwiped:(UISwipeGestureRecognizer *)swipe {

    if ([[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:self.boardIDs[self.carousel.currentItemIndex]] && !self.activeBoardID) {
        
        [self versionsTapped:nil];
    }
}

-(void)versionSwiped:(UISwipeGestureRecognizer *)swipe {
    
    if (!self.activeBoardID) [self versionsTapped:nil];
}

-(void)openChat {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];

    CGRect chatTableRect = self.chatTable.frame;
    CGRect titleRect = self.commentTitleView.frame;

    float tableHeight = -148;
    if (self.activeBoardID) tableHeight = 10;
    for (int i=0; i<self.messages.count; i++) {
        tableHeight += [self tableView:self.chatTable heightForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    float chatHeight = MAX(0,MIN(tableHeight,517));
    if (self.activeBoardID) chatHeight = MIN(384, MAX(tableHeight,156));
    
    if (self.activeBoardID) {
        
        if (self.userRole == 0) {
            
            if (self.chatOpen) {
                
                float titleOffset = 0;
                if (!self.commentTitleView.hidden) titleOffset = 41;
                
                self.chatOpenButton.center = CGPointMake(512, 754-chatHeight);
                self.chatFadeImage.center = CGPointMake(512, 772-chatHeight);
                self.commentTitleView.center = CGPointMake(512, 794-chatHeight);
                chatTableRect = CGRectMake(self.chatTable.frame.origin.x, 768-chatHeight+titleOffset, self.chatTable.frame.size.width, chatHeight-titleOffset);
            }
            else {
                
                self.chatFadeImage.center = CGPointMake(512, 98.5);
                self.chatOpenButton.center = CGPointMake(512, 81);
                self.commentTitleView.center = CGPointMake(512, 120);
                chatTableRect = CGRectMake(0, 95, 1024, 673);
            }
        }
        else {
            
            if (self.chatOpen) {
                self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y+keyboardDiff);
                self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+keyboardDiff);
                chatTableRect.size.height -= keyboardDiff;
                chatTableRect.origin.y += keyboardDiff;
                titleRect.origin.y += keyboardDiff;
            }
            else {
                self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y-keyboardDiff);
                self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-keyboardDiff);
                chatTableRect.size.height += keyboardDiff;
                chatTableRect.origin.y -= keyboardDiff;
                titleRect.origin.y -= keyboardDiff;
            }
            
            self.commentTitleView.frame = titleRect;
        }
    }
    else {
        
        if (self.chatOpen) {
            
            self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y+chatHeight);
            self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+chatHeight);
            chatTableRect.size.height -= chatHeight;
            chatTableRect.origin.y += chatHeight;
        }
        else {
            
            self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y-chatHeight);
            self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-chatHeight);
            chatTableRect.size.height += chatHeight;
            chatTableRect.origin.y -= chatHeight;
        }
    }
    
    self.chatTable.frame = chatTableRect;
    
    [self.view bringSubviewToFront:self.chatOpenButton];
    
    [UIView commitAnimations];
    
    if (self.chatOpen) [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
    else [self.chatOpenButton setImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
    
    self.chatOpen = !self.chatOpen;
}

-(void)keyboardWillShow:(NSNotification *)notification {
    
    if (self.keyboardHeight > 0) return;
    
    if ([self.chatTextField isFirstResponder] || [self.commentTitleTextField isFirstResponder]) {
    
        self.chatOpenButton.hidden = false;
        self.chatFadeImage.hidden = false;
        self.chatTable.hidden = false;
        self.chatView.hidden = false;
        
        [self showChat];
        
        self.keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
        keyboardDiff = 517-self.keyboardHeight;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        CGRect viewRect = self.chatView.frame;
        viewRect.origin.y -= self.keyboardHeight;
        self.chatView.frame = viewRect;
        
        CGRect fadeRect = self.chatFadeImage.frame;
        if(self.activeBoardID == nil) fadeRect.origin.y -= (self.keyboardHeight+keyboardDiff);
        else fadeRect.origin.y -= self.keyboardHeight;
        self.chatFadeImage.frame = fadeRect;
        
        CGRect titleRect = self.commentTitleView.frame;
        titleRect.origin.y -= self.keyboardHeight;
        self.commentTitleView.frame = titleRect;
        
        CGRect chatTableRect = self.chatTable.frame;
        if (self.activeBoardID == nil) {
            chatTableRect.size.height += keyboardDiff;
            chatTableRect.origin.y -= (self.keyboardHeight+keyboardDiff);
        }
        else chatTableRect.origin.y -= self.keyboardHeight;
        
        self.chatTable.frame = chatTableRect;
        
        if (self.activeBoardID && self.carouselOffset > 0) {
            
            CGRect carouselRect = self.carousel.frame;
            carouselRect.origin.y -= self.carouselOffset;
            self.carousel.frame = carouselRect;
            
            CGRect backgroundRect = self.currentBoardView.avatarBackgroundImage.frame;
            backgroundRect.origin.x += self.carouselOffset;
            self.currentBoardView.avatarBackgroundImage.frame = backgroundRect;
            
            CGRect labelRect = self.currentBoardView.userLabel.frame;
            labelRect.origin.x -= self.carouselOffset;
            self.currentBoardView.userLabel.frame = labelRect;
            
            for (AvatarButton *avatar in self.currentBoardView.avatarButtons) {
                
                CGRect avatarRect = avatar.frame;
                avatarRect.origin.x += self.carouselOffset;
                avatar.frame = avatarRect;
            }
        }
        else {
            
            CGRect projectsTableRect = self.masterView.projectsTable.frame;
            projectsTableRect.size.height -= (self.keyboardHeight-keyboardDiff);
            self.masterView.projectsTable.frame = projectsTableRect;
        }
        
        self.chatOpenButton.frame = CGRectMake(592, 584, 51, 28);
        
        if (!self.activeBoardID) {
            [self.chatOpenButton setImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
            self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-(self.keyboardHeight+keyboardDiff));
        }
        else {
            [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
            self.chatOpenButton.center = CGPointMake(self.view.center.x, self.chatOpenButton.center.y-self.keyboardHeight);
        }
        
        [self.view bringSubviewToFront:self.chatOpenButton];
        
        [UIView setAnimationDelegate:self];
        if ([self.chatTextField isFirstResponder] && self.activeBoardID) [UIView setAnimationDidStopSelector:@selector(openChat)];
        [UIView commitAnimations];
    }
}

-(void)keyboardWillHide:(NSNotification *)notification {

    if (!self.editing && self.boardNameLabel.text.length > 0 && [FirebaseHelper sharedHelper].loggedIn) {
        
        self.editBoardNameTextField.hidden = true;
        self.boardNameLabel.hidden = false;
        if (self.userRole > 0) self.boardNameEditButton.hidden = false;
    }
    
    if ([self.chatTextField isFirstResponder] || [self.commentTitleTextField isFirstResponder]) {
        
        if (self.activeCommentThreadID) self.chatTextField.text = nil;
        
        self.activeCommentThreadID = nil;
        
        keyboardDiff = 517-self.keyboardHeight;

        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        CGRect projectsTableRect = self.masterView.projectsTable.frame;
        projectsTableRect.size.height += (self.keyboardHeight-keyboardDiff);
        self.masterView.projectsTable.frame = projectsTableRect;

        CGRect titleRect = self.commentTitleView.frame;
        titleRect.origin.y += self.keyboardHeight;
        self.commentTitleView.frame = titleRect;

        CGRect viewRect = self.chatView.frame;
        viewRect.origin.y += self.keyboardHeight;
        self.chatView.frame = viewRect;
        
        CGRect fadeRect = self.chatFadeImage.frame;
        if(self.activeBoardID == nil) fadeRect.origin.y += (self.keyboardHeight+keyboardDiff);
        else fadeRect.origin.y += self.keyboardHeight;
        self.chatFadeImage.frame = fadeRect;
        
        CGRect chatTableRect = self.chatTable.frame;
        if (self.activeBoardID == nil) {
            chatTableRect.size.height -= keyboardDiff-self.chatDiff;
            chatTableRect.origin.y += (self.keyboardHeight+keyboardDiff);
        }
        else chatTableRect.origin.y += self.keyboardHeight;
        self.chatTable.frame = chatTableRect;
            
        if (self.activeBoardID && self.carouselOffset > 0) {
            
            iCarousel *carousel;
            
            if (self.versioning) carousel = self.versionsCarousel;
            else carousel = self.carousel;
            
            CGRect carouselRect = carousel.frame;
            carouselRect.origin.y += self.carouselOffset;
            carousel.frame = carouselRect;
            
            CGRect backgroundRect = self.currentBoardView.avatarBackgroundImage.frame;
            backgroundRect.origin.x -= self.carouselOffset;
            self.currentBoardView.avatarBackgroundImage.frame = backgroundRect;
            
            CGRect labelRect = self.currentBoardView.userLabel.frame;
            labelRect.origin.x -= self.carouselOffset;
            self.currentBoardView.userLabel.frame = labelRect;
            
            for (AvatarButton *avatar in self.currentBoardView.avatarButtons) {
                
                CGRect avatarRect = avatar.frame;
                avatarRect.origin.x -= self.carouselOffset;
                avatar.frame = avatarRect;
            }
        }
        else {
            
            CGRect projectsTableRect = self.masterView.projectsTable.frame;
            projectsTableRect.size.height += (self.keyboardHeight-keyboardDiff);
            self.masterView.projectsTable.frame = projectsTableRect;
        }

        if (self.activeBoardID) self.chatOpenButton.center = CGPointMake(self.view.center.x, self.chatOpenButton.center.y+self.keyboardHeight);
        else self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+(self.keyboardHeight+keyboardDiff));
        
        if (self.chatOpen) [self openChat];

        [self.view bringSubviewToFront:self.chatOpenButton];
        
        [UIView commitAnimations];
        
        self.keyboardHeight = 0;
        
        CGPoint chatCenter = self.chatOpenButton.center;
        self.chatOpenButton.frame = CGRectMake(0, 0, 51, 28);
        self.chatOpenButton.center = chatCenter;
        [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];

        if (self.activeBoardID) [self.currentBoardView hideChat];
    }
    
    [UIView setAnimationsEnabled:NO];
    
    if ([self.editBoardNameTextField isFirstResponder]) {
        
        [self.carousel setScrollEnabled:YES];
        [self.editBoardNameTextField resignFirstResponder];
        
        NSString *oldBoardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"name"];
        
        NSMutableArray *boardNames = [NSMutableArray array];
        
        for (NSString *boardID in self.boardIDs) {
            
            NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"name"];
            if (![boardName isEqualToString:oldBoardName] && ![boardName isEqualToString:@"Untitled"]) [boardNames addObject:boardName];
        }
        
        if ([boardNames containsObject:self.editBoardNameTextField.text]) {
            
            self.editBoardNameTextField.text = oldBoardName;
            
            GeneralAlertViewController *invalidVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Alert"];
            invalidVC.type = 1;
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:invalidVC];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            
            UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
            logoImageView.frame = CGRectMake(140, 8, 32, 32);
            logoImageView.tag = 800;
            [nav.navigationBar addSubview:logoImageView];
            
            [self presentViewController:nav animated:YES completion:nil];
        }
        else if (![self.editBoardNameTextField.text isEqualToString:oldBoardName]) {
            
            [Flurry logEvent:@"Board-Renamed" withParameters:@{@"teamID" : [FirebaseHelper sharedHelper].teamID}];
            
            NSString *name;
            
            NSString *noSpacesString = [self.editBoardNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if (noSpacesString.length == 0) {
                name = @"Untitled";
                self.boardNameLabel.alpha = .2;
            } else {
                name = self.editBoardNameTextField.text;
                self.boardNameLabel.alpha = 1;
            }
            self.boardNameLabel.text = name;
            [self.boardNameLabel sizeToFit];
            self.boardNameLabel.center = CGPointMake(self.carousel.center.x, self.boardNameLabel.center.y);
            
            NSString *boardNameString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/name", [FirebaseHelper sharedHelper].db, self.boardIDs[self.carousel.currentItemIndex]];
            Firebase *ref = [[Firebase alloc] initWithUrl:boardNameString];
            [ref setValue:name];
            [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] setObject:name forKey:@"name"];
            
            self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+17, self.boardNameLabel.center.y);
            
            NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
            [[FirebaseHelper sharedHelper] setBoard:self.boardIDs[self.carousel.currentItemIndex] UpdatedAt:dateString];
        }
    }
    
    if ([[self.view viewWithTag:104] isFirstResponder]) {
        
        UITextField *boardNameTextField = (UITextField *)[self.view viewWithTag:104];
        
        [boardNameTextField resignFirstResponder];
        
        UITextField *editBoardNameTextField = (UITextField *)[self.view viewWithTag:104];
        editBoardNameTextField.hidden = true;
        
        NSString *oldBoardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"name"];
        
        NSMutableArray *boardNames = [NSMutableArray array];
        
        for (NSString *boardID in self.boardIDs) {
            
            NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"name"];
            if (![boardName isEqualToString:oldBoardName] && ![boardName isEqualToString:@"Untitled"]) [boardNames addObject:boardName];
        }
        
        NSString *name;
        
        NSString *noSpacesString = [boardNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (noSpacesString.length == 0) name = @"Untitled";
        else name = editBoardNameTextField.text;
        
        if ([boardNames containsObject:name] && ![name isEqualToString:@"Untitled"]) {
            
            name = oldBoardName;
            
            GeneralAlertViewController *invalidVC = [self.storyboard instantiateViewControllerWithIdentifier:@"General"];
            invalidVC.type = 1;
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:invalidVC];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            
            UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
            logoImageView.frame = CGRectMake(140, 8, 32, 32);
            logoImageView.tag = 800;
            [nav.navigationBar addSubview:logoImageView];
            
            [self presentViewController:nav animated:YES completion:nil];
        }
        else if (![boardNameTextField.text isEqualToString:oldBoardName]) {
            
            [Flurry logEvent:@"Board-Renamed" withParameters:@{@"teamID" : [FirebaseHelper sharedHelper].teamID}];
            
            NSString *boardNameRefString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/name", [FirebaseHelper sharedHelper].db, self.boardIDs[self.carousel.currentItemIndex]];
            Firebase *ref = [[Firebase alloc] initWithUrl:boardNameRefString];
            [ref setValue:name];
            [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] setObject:name forKey:@"name"];

            if (self.activeBoardID) {
                
                NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
                [[FirebaseHelper sharedHelper] setBoard:self.activeBoardID UpdatedAt:dateString];
            }
        }
        
        UILabel *boardNameLabel = (UILabel *)[self.view viewWithTag:102];
        
        if ([name isEqualToString:@"Untitled"]) {
            boardNameLabel.alpha = .2;
            self.boardNameLabel.alpha = .2;
        }
        else {
            boardNameLabel.alpha = 1;
            self.boardNameLabel.alpha = 1;
        }
        
        NSString *boardNameString = [NSString stringWithFormat:@"|   %@", name];
        boardNameLabel.text = boardNameString;
        [boardNameLabel sizeToFit];
        boardNameLabel.hidden = false;
        
        self.boardNameLabel.text = name;
        [self.boardNameLabel sizeToFit];
        self.boardNameLabel.center = CGPointMake(self.carousel.center.x+105, self.boardNameLabel.center.y);
        self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+122, self.boardNameLabel.center.y);
        
        UIButton *editBoardNameButton = (UIButton *)[self.view viewWithTag:103];
        editBoardNameButton.frame = CGRectMake(boardNameLabel.frame.origin.x+boardNameLabel.frame.size.width-5, boardNameLabel.frame.origin.y-6, 36, 36);
        editBoardNameButton.hidden = false;

    }
    
    if ([self.editProjectNameTextField isFirstResponder]) {
        
        NSString *projectName = [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"name"];

        NSString *noSpacesString = [self.editProjectNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (noSpacesString.length == 0) self.editProjectNameTextField.text = projectName;
        else self.editProjectNameTextField.textColor = [UIColor blackColor];
        self.projectNameLabel.text = self.editProjectNameTextField.text;
        CGRect projectRect = [self.projectNameLabel.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.projectNameLabel.font} context:nil];
        self.editButton.center = CGPointMake(MIN(projectRect.size.width+292,650), self.projectNameLabel.center.y+3);
        self.projectNameEditButton.center = self.editButton.center;
        self.projectNameEditButton.hidden = false;
        self.editProjectNameTextField.userInteractionEnabled = false;
        
        self.projectNameLabel.hidden = false;
        self.projectNameEditButton.hidden = false;
        self.editProjectNameTextField.hidden = true;
    }
    
    [UIView setAnimationsEnabled:YES];
}

-(void)changeCommentHeight {
    
    
}

-(BOOL)canUndo {
    
    int undoCount = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    int undoTotal = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"total"] intValue];

    if (undoCount == undoTotal) return NO;
    else return YES;
}

-(BOOL)canRedo {
    
    int undoCount = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    
    if (undoCount == 0) return NO;
    else return YES;
}

-(BOOL) canClear {
    
    NSDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
    NSString *currentIndexDate = [undoDict objectForKey:@"currentIndexDate"];
    NSMutableDictionary *subpathsDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.activeBoardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid];
    NSMutableArray *dates = [[subpathsDict allKeys] mutableCopy];
    NSSortDescriptor *ascendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [dates sortUsingDescriptors:@[ascendingSorter]];
    int dateIndex = [dates indexOfObject:currentIndexDate];
    if (dateIndex > 0) {
        
        NSString *clearDate = [dates objectAtIndex:(dateIndex-1)];
        if ([[subpathsDict objectForKey:clearDate] respondsToSelector:@selector(isEqualToString:)] && [[subpathsDict objectForKey:clearDate] isEqualToString:@"clear"]) return NO;
        else return YES;
    }
    else return NO;
    
}

-(void) driveAlert {
    
    
}

#pragma mark -
#pragma mark iCarousel methods

- (CATransform3D)carousel:(iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform {
    
    CGFloat MAX_SCALE = 1.25f; //max scale of center item
    CGFloat MAX_SHIFT = 25.0f; //amount to shift items to keep spacing the same
    
    CGFloat shift = fminf(1.0f, fmaxf(-1.0f, offset));
    CGFloat scale = 1.0f + (1.0f - fabs(shift)) * (MAX_SCALE - 1.0f);
    transform = CATransform3DTranslate(transform, offset * _carousel.itemWidth * 1.08f + shift * MAX_SHIFT, 0.0f, 0.0f);
    return CATransform3DScale(transform, scale, scale, scale);
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
    
    if ([carousel isEqual:self.versionsCarousel]) {
        
        NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"];
        
        return versionsArray.count;
    }
    else return self.boardIDs.count;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view {
    
    if (view == nil) {
        
        BoardView *boardView = [[BoardView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
        view = boardView;
        CGAffineTransform tr = view.transform;
        tr = CGAffineTransformScale(tr, .5, .5);
        tr = CGAffineTransformRotate(tr, M_PI_2);
        view.transform = tr;
        
        UIImage *gradientImage = [UIImage imageNamed:@"board-versions1.png"];
        UIButton *gradientButton = [UIButton buttonWithType:UIButtonTypeCustom];
        gradientButton.frame = CGRectMake(0.0f, 0.0f, gradientImage.size.width, gradientImage.size.height);
        gradientButton.center = view.center;
        gradientButton.adjustsImageWhenHighlighted = NO;
        [gradientButton setBackgroundImage:gradientImage forState:UIControlStateNormal];
        [gradientButton addTarget:self action:@selector(boardTapped:) forControlEvents:UIControlEventTouchUpInside];
        if (((BoardView *)view).gradientButton == nil) [view addSubview:gradientButton];
            
        ((BoardView *)view).gradientButton = gradientButton;
        gradientButton.tag = 1;
    }
    
    if ([carousel isEqual:self.carousel]) {

        if (self.boardIDs.count <= index) return nil;
        
        ((BoardView *)view).boardID = self.boardIDs[index];
        
        int versionsNum = ((NSArray *)[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[index]] objectForKey:@"versions"]).count;
        
        if (versionsNum > 1 && versionsNum < 10) {
            
            NSString *boardString = [NSString stringWithFormat:@"board-versions%i.png", versionsNum];
            [((BoardView *)view).gradientButton setBackgroundImage:[UIImage imageNamed:boardString] forState:UIControlStateNormal];
        }
        else if (versionsNum >= 10) {
            
            [((BoardView *)view).gradientButton setBackgroundImage:[UIImage imageNamed:@"board-versions10.png"] forState:UIControlStateNormal];
        }
    }
    else {
        
        ((BoardView *)view).boardID = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"] objectAtIndex:index];
    }
    
    [((BoardView *)view).loadingView removeFromSuperview];
    
    if ([[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:((BoardView *)view).boardID]) {
        
        [self drawBoard:(BoardView *)view];
        [((BoardView *)view) layoutComments];
        
        for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
            
            if ([[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"inBoard"] isEqualToString:((BoardView *)view).boardID] && ![((BoardView *)view).activeUserIDs containsObject:userID])
                [((BoardView *)view).activeUserIDs addObject:userID];
        }
        [((BoardView *)view) layoutAvatars];
    }
    else {
        
        ((BoardView *)view).fadeView.hidden = false;
        ((BoardView *)view).loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        ((BoardView *)view).loadingView.transform = CGAffineTransformMakeScale(5, 5);
        [((BoardView *)view).loadingView setCenter:((BoardView *)view).center];
        [((BoardView *)view).loadingView startAnimating];
        [((BoardView *)view) addSubview:((BoardView *)view).loadingView];
    }
    
    return view;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel {
    
    self.carouselMoving = false;
    self.showButtons = false;
    
    if ([FirebaseHelper sharedHelper].currentProjectID) {
        
        self.buttonsBackgroundImage.hidden = false;
        self.shareButton.hidden = false;
        self.versionsButton.hidden = false;
        NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"];
        if (versionsArray.count > 1) self.versionsCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)versionsArray.count];
        else self.versionsCountLabel.text = @"";
        if (!self.versioning) self.versionsCountLabel.hidden = false;
        if (self.userRole > 0) self.deleteBoardButton.hidden = false;
    }
        
    if (newBoardCreated) [self boardTapped:[carousel.currentItemView viewWithTag:1]];
}

- (void)carouselDidScroll:(iCarousel *)carousel {
    
    if (self.carouselMoving && !self.showButtons) {
        
        self.buttonsBackgroundImage.hidden = true;
        self.shareButton.hidden = true;
        self.versionsButton.hidden = true;
        self.versionsCountLabel.hidden = true;
        self.deleteBoardButton.hidden = true;
    }
    
    self.carouselMoving = true;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    
    if ([carousel isEqual:self.carousel] && self.boardIDs.count <= carousel.currentItemIndex) return;
    
    NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"versions"];
    
    if ([carousel isEqual:self.carousel]) {
        
        if (carousel.currentItemIndex >= self.boardIDs.count) return;
        
        NSString *boardID = self.boardIDs[carousel.currentItemIndex];
        NSDictionary *boardDict = [[FirebaseHelper sharedHelper].boards objectForKey:boardID];
        
        NSString *boardName = [boardDict objectForKey:@"name"];
        
        if (boardName) {
        
            self.boardNameLabel.text = boardName;
            if ([boardName isEqualToString:@"Untitled"]) self.boardNameLabel.alpha = .2;
            else self.boardNameLabel.alpha = 1;
        }
        
        UIFont *labelFont;

        if ([[self.updatedElements objectForKey:@"boards"] containsObject:boardID]) labelFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:24];
        else labelFont = [UIFont fontWithName:@"SourceSansPro-Light" size:24];
        
        self.boardNameLabel.font = labelFont;
        [self.boardNameLabel sizeToFit];
        self.boardNameLabel.center = CGPointMake(self.carousel.center.x, self.boardNameLabel.center.y);
        
        if (versionsArray.count > 1) self.versionsCountLabel.text = [NSString stringWithFormat:@"%lu", versionsArray.count];
        else self.versionsCountLabel.text = @"";
        
        if (self.boardNameLabel.text.length > 0) self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+17, self.boardNameLabel.center.y);
        else self.boardNameEditButton.hidden = true;
    }
    else {
        
        if (self.versionsCarousel.currentItemIndex == 0) {
            
            if (versionsArray.count > 1) self.versionsLabel.text = [NSString stringWithFormat:@"Original (Version 1 of %lu)", versionsArray.count];
            else self.versionsLabel.text = @"Original (Version 1)";
        }
        else self.versionsLabel.text = [NSString stringWithFormat:@"Version %lu of %lu", self.versionsCarousel.currentItemIndex+1, versionsArray.count];
        
        if (versionsArray.count > 1) {
            
            if (carousel.currentItemIndex < versionsArray.count-1) self.upArrowImage.hidden = false;
            else self.upArrowImage.hidden = true;
            
            if (carousel.currentItemIndex > 0) self.downArrowImage.hidden = false;
            else self.downArrowImage.hidden = true;
        }
    }
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {

    if ([self.chatTextField isFirstResponder] && self.userRole > 0) [self.chatTextField resignFirstResponder];
    else if (self.chatOpen && self.userRole == 0) [self openChat];
    
    if ([self.editBoardNameTextField isFirstResponder]) {
        
        [self.carousel setScrollEnabled:YES];
        [self.editBoardNameTextField resignFirstResponder];
        self.editBoardNameTextField.text = nil;
    }
    
    if ([self.editProjectNameTextField isFirstResponder]) [self.editProjectNameTextField resignFirstResponder];
}

#pragma mark - Text field handling

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    
    if ([textField isEqual:self.chatTextField]) {
        
        if (textField.text.length == 0) return NO;
        
        NSString *chatString;
        NSMutableDictionary *chatDict;
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        
        if (self.activeCommentThreadID != nil) {
            
            NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"name"];
            NSString *pushText = [NSString stringWithFormat:@"%@ left a comment in %@: %@", [FirebaseHelper sharedHelper].userName, boardName, textField.text];
            NSMutableDictionary *pushDict = [@{ @"contents" : @{@"en" : pushText},
                                                @"tags"     : @[@{@"key"      : [FirebaseHelper sharedHelper].currentProjectID,
                                                                  @"relation" : @"=",
                                                                  @"value"    : @"projectID"
                                                                  }],
                                                @"data"     : @{@"projectID":[FirebaseHelper sharedHelper].currentProjectID}
                                                } mutableCopy];
            [OneSignalHelper sendPush:pushDict];
            
            [Flurry logEvent:@"Comment_Thread-Comment_Left" withParameters:
                                                            @{ @"userID":[FirebaseHelper sharedHelper].uid,
                                                               @"boardID":self.currentBoardView.boardID,
                                                               @"projectID":[FirebaseHelper sharedHelper].currentProjectID,
                                                               @"teamID":[FirebaseHelper sharedHelper].teamID
                                                               }];
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
            chatString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@/%@/messages", [FirebaseHelper sharedHelper].db, commentsID, self.activeCommentThreadID];
            
            chatDict = [[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"];
            [[FirebaseHelper sharedHelper] setCommentThread:self.activeCommentThreadID updatedAt:dateString];
        }
        else {
            
            NSString *projectName = [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"name"];
            NSString *pushText = [NSString stringWithFormat:@"%@ sent a message in %@: %@", [FirebaseHelper sharedHelper].userName, projectName, textField.text];
            NSMutableDictionary *pushDict = [@{ @"contents" : @{@"en" : pushText},
                                                @"tags"     : @[@{@"key"      : [FirebaseHelper sharedHelper].currentProjectID,
                                                                  @"relation" : @"=",
                                                                  @"value"    : @"projectID"
                                                                  }],
                                                @"data"     : @{@"projectID":[FirebaseHelper sharedHelper].currentProjectID}
                                                } mutableCopy];
            [OneSignalHelper sendPush:pushDict];
            
            [Flurry logEvent:@"Chat_Message-Posted" withParameters:
                 @{ @"userID":[FirebaseHelper sharedHelper].uid,
                    @"projectID":[FirebaseHelper sharedHelper].currentProjectID,
                    @"teamID":[FirebaseHelper sharedHelper].teamID
                    }];
            
            chatString = [NSString stringWithFormat:@"https://%@.firebaseio.com/chats/%@", [FirebaseHelper sharedHelper].db, self.chatID];
            chatDict = [[FirebaseHelper sharedHelper].chats objectForKey:self.chatID];
            [[FirebaseHelper sharedHelper] setProjectUpdatedAt:dateString];
        }
        
        Firebase *chatRef = [[Firebase alloc] initWithUrl:chatString];
        NSDictionary *messageDict = @{ @"user" : [FirebaseHelper sharedHelper].uid ,
                                       @"message" : textField.text,
                                       @"sentAt" : dateString
                                       };
        Firebase *messageRef = [chatRef childByAutoId];
        [messageRef setValue:messageDict];

        NSMutableDictionary *unsentDict = [messageDict mutableCopy];
        [unsentDict setObject:@1 forKey:@"unsent"];
        [chatDict setObject:unsentDict forKey:messageRef.key];
        
        [self updateMessages];
        [self.chatTable reloadData];
        
        self.chatTextField.text = nil;
    }
    
    if ([textField isEqual:self.editBoardNameTextField] || [textField isEqual:[self.view viewWithTag:104]] || [textField isEqual:self.editProjectNameTextField]) {
        
        [textField resignFirstResponder];
    }
    
    if ([textField isEqual:self.commentTitleTextField]) {
        
        NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
        [[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] setObject:self.commentTitleTextField.text forKey:@"title"];

        [self.currentBoardView layoutComments];
        
        NSString *titleString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@/%@/info/title", [FirebaseHelper sharedHelper].db, commentsID, self.activeCommentThreadID];
        Firebase *titleRef = [[Firebase alloc] initWithUrl:titleString];
        [titleRef setValue:self.commentTitleTextField.text];
        
        [self.chatTextField becomeFirstResponder];
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        [[FirebaseHelper sharedHelper] setCommentThread:self.activeCommentThreadID updatedAt:dateString];
        
        if (!self.chatOpen) [self openChat];
    }
    
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    textField.alpha = 1;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (![textField isEqual:self.editProjectNameTextField] && ![textField isEqual:self.editBoardNameTextField]) return YES;
    
    if(range.length + range.location > textField.text.length) return NO;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    NSUInteger limit;
    
    if ([textField isEqual:self.editProjectNameTextField]) limit = 21;
    else limit = 41;
    
    if (newLength > limit) return NO;
    else return YES;
}

#pragma mark - Chat table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.messages.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *messageDict = self.messages[self.messages.count-(indexPath.row+1)];
    
    if ([messageDict respondsToSelector:@selector(isEqualToString:)]) return 20;
    else {
        
        NSString *message = [messageDict objectForKey:@"message"];
        CGRect messageRect = [message boundingRectWithSize:CGSizeMake(-66+self.chatTable.frame.size.width,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Light" size:20]} context:nil];
        
        return messageRect.size.height+25;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell" forIndexPath:indexPath];
    
    for (int i=1; i<7; i++) {
        
        if ([cell.contentView viewWithTag:200+i]) [[cell.contentView viewWithTag:200+i] removeFromSuperview];
    }
    
    if (self.messages.count > indexPath.row) {
        
        [UIView setAnimationsEnabled:NO];
        [CATransaction setDisableActions:YES];
        
        NSDictionary *messageDict = self.messages[self.messages.count-(indexPath.row+1)];
        
        if ([messageDict respondsToSelector:@selector(isEqualToString:)]) {
         
            UILabel *newMessagesLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            newMessagesLabel.text = @"New Messages";
            newMessagesLabel.alpha = .2;
            newMessagesLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
            [newMessagesLabel sizeToFit];
            newMessagesLabel.center = CGPointMake(cell.frame.size.width/2, newMessagesLabel.center.y);
            newMessagesLabel.tag = 205;
            [cell.contentView addSubview:newMessagesLabel];
            
            UIImageView *dividerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newmessagesdivider.png"]];
            if ([cell.contentView viewWithTag:206]) [[cell.contentView viewWithTag:206] removeFromSuperview];
            dividerImage.alpha = .1;
            dividerImage.tag = 206;
            [cell.contentView addSubview:dividerImage];
        }
        else {
            
            NSString *userID = [messageDict objectForKey:@"user"];
            NSString *message = [messageDict objectForKey:@"message"];
            NSString *name = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setAMSymbol:@"am"];
            [dateFormatter setPMSymbol:@"pm"];
            [dateFormatter setDateFormat:@"MMM d, h:mma"];
            double dateDouble = [[messageDict objectForKey:@"sentAt"] doubleValue]/100000000;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:dateDouble];
            NSString *dateString = [dateFormatter stringFromDate:date];

            AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
            avatar.userID = userID;
            avatar.userInteractionEnabled = false;
            avatar.tag = 201;
            UIImage *avatarImage = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"avatar"];
            
            if ([avatarImage isKindOfClass:[UIImage class]]) {
                
                [avatar setImage:avatarImage forState:UIControlStateNormal];
                avatar.imageView.layer.cornerRadius = avatarImage.size.width/2;
                avatar.imageView.layer.masksToBounds = YES;
                
                if (avatarImage.size.height == 64) {
                    avatar.frame = CGRectMake(-7, -9, avatarImage.size.width, avatarImage.size.height);
                    avatar.transform = CGAffineTransformMakeScale(.56, .56);
                }
                else {
                    avatar.frame = CGRectMake(-39, -41.5, avatarImage.size.width, avatarImage.size.height);
                    avatar.transform = CGAffineTransformMakeScale(.28, .28);
                }
            }
            else {
                [avatar generateIdenticonWithShadow:false];
                avatar.frame = CGRectMake(-100, -101, avatar.userImage.size.width, avatar.userImage.size.height);
                avatar.transform = CGAffineTransformMakeScale(.16, .16);
            }
            [cell.contentView addSubview:avatar];

            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            nameLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
            nameLabel.text = name;
            [nameLabel sizeToFit];
            nameLabel.frame = CGRectMake(57, 2, nameLabel.frame.size.width, nameLabel.frame.size.height);
            nameLabel.tag = 202;
            [cell.contentView addSubview:nameLabel];
            
            UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            dateLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:12];
            dateLabel.textColor = [UIColor grayColor];
            dateLabel.text = dateString;
            [dateLabel sizeToFit];
            dateLabel.frame = CGRectMake(nameLabel.frame.size.width+60, 5, dateLabel.frame.size.width, dateLabel.frame.size.height);
            dateLabel.tag = 203;
            [cell.contentView addSubview:dateLabel];

            UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            messageLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:18];
            messageLabel.text = message;
            messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            messageLabel.numberOfLines = 0;
            CGRect messageRect = [message boundingRectWithSize:CGSizeMake(-66+self.chatTable.frame.size.width,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Light" size:20]} context:nil];
            messageLabel.frame = CGRectMake(57, 18, messageRect.size.width, messageRect.size.height);
            messageLabel.tag = 204;
            if ([messageDict objectForKey:@"unsent"]) messageLabel.alpha = .3;
            [cell.contentView addSubview:messageLabel];
        }
        
        [UIView setAnimationsEnabled:YES];
        [CATransaction setDisableActions:NO];
    }
        
    return cell;
}

#pragma mark -
#pragma mark UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.editBoardIDs.count;
}

-(CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
    
    if (option == iCarouselOptionOffsetMultiplier && [carousel isEqual:self.versionsCarousel]) value = 5.0f;
    //else if (option == iCarouselOptionSpacing && [carousel isEqual:self.carousel]) value = .7f;
    
    return value;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BoardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionCell" forIndexPath:indexPath];
    
    cell.boardView.boardID = self.editBoardIDs[indexPath.row];
    
    [cell updateSubpathsForBoardID:self.editBoardIDs[indexPath.row]];
    [cell updateBoardNameForBoardID:self.editBoardIDs[indexPath.row]];
    
    return cell;
}

- (BOOL)collectionView:(LSCollectionViewHelper *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    return YES;
}

- (void)collectionView:(LSCollectionViewHelper *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSString *fromID = [self.editBoardIDs objectAtIndex:fromIndexPath.item];
    [self.editBoardIDs removeObjectAtIndex:fromIndexPath.item];
    [self.editBoardIDs insertObject:fromID atIndex:toIndexPath.item];
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

#pragma mark - MFMailComposeViewController Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
