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
#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"
#import "NSDate+ServerDate.h"
#import "MasterView.h"
#import "ChatTableViewCell.h"
#import "AvatarPopoverViewController.h"
#import "ColorPopoverViewController.h"
#import "PenTypePopoverViewController.h"
#import "CommentPopoverViewController.h"
#import "InstabugViewController.h"
#import "DeleteProjectAlertViewController.h"

@implementation ProjectDetailViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [[UITextField appearance] setTintColor:[UIColor grayColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"SourceSansPro-Light" size:24.0], NSFontAttributeName, nil]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:5 forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    
    self.chatTextField.delegate = self;
    self.editBoardNameTextField.delegate = self;
    self.carousel.delegate = self;
    
    self.carousel.type = iCarouselTypeCoverFlow2;
    self.carousel.bounceDistance = 0.1f;
    
    carouselFadeLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"carouselfadeleft.png"]];
    [self.carousel addSubview:carouselFadeLeft];
    carouselFadeLeft.frame = CGRectMake(0, -5, 30, 400);
    
    carouselFadeRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"carouselfaderight.png"]];
    [self.carousel addSubview:carouselFadeRight];
    carouselFadeRight.frame = CGRectMake(784, -5, 30, 400);
    
    editFadeLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"editfadeleft.png"]];
    [self.view addSubview:editFadeLeft];
    editFadeLeft.frame = CGRectMake(210, 0, 21, 768);

    editFadeRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"editfaderight.png"]];
    [self.view addSubview:editFadeRight];
    editFadeRight.frame = CGRectMake(1003, 0, 21, 768);
    
    self.chatTable.transform = CGAffineTransformMakeRotation(M_PI);
    [self showChat];
    
    self.masterView.projectsTable.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"projectsshadow.png"]];

    self.editBoardNameTextField.hidden = true;
    self.viewedCommentThreadIDs = [NSMutableArray array];
    
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
    [self.view.window addGestureRecognizer:chatTapRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];

    [chatTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:chatTapRecognizer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

//- (BOOL)canBecomeFirstResponder {
//    return YES;
//}

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
            
            if (![presentedNav.viewControllers[0] isKindOfClass:[InstabugViewController class]]) [self.presentedViewController presentViewController:nav animated:YES completion:nil];
        }
        else [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void) setUpDrawMenu {
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(10, 28, 30, 30);
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
    
    self.drawButtons = @[ @"undo",
                          @"redo",
                          @"clear",
                          @"pen",
                          @"erase",
                          @"color",
                          @"comment"
                        ];
    
    for (int i=0; i<self.drawButtons.count; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *imageName;
        if (i==5) imageName = @"black.png";
        else imageName = [NSString stringWithFormat:@"%@.png",self.drawButtons[i]];
        UIImage *buttonImage = [UIImage imageNamed:imageName];
        if (i>2 && i!=5) {
            UIImageView *selectedImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selected.png"]];
            selectedImage.frame = CGRectMake(-7.5, -7.5, 75, 75);
            selectedImage.tag = 50;
            [button addSubview:selectedImage];
            if (i!=3) selectedImage.hidden = true;
        }
        button.frame = CGRectMake(0, 0, 60, 60);
        [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
        button.center = CGPointMake(272+i*80, 720);
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
    
    if (self.userRole > 0) {
        
        UIButton *editBoardNameButton = (UIButton *)[self.view viewWithTag:103];
        editBoardNameButton.frame = CGRectMake(boardNameLabel.frame.origin.x+boardNameLabel.frame.size.width-5, boardNameLabel.frame.origin.y-6, 36, 36);
        editBoardNameButton.hidden = false;
        [self.view bringSubviewToFront:editBoardNameButton];
        
        for (int i=0; i<self.drawButtons.count; i++) {
            
            UIButton *button = (UIButton *)[self.view viewWithTag:i+2];
            button.hidden = false;
            [self.view bringSubviewToFront:button];
        }
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
    self.editButton.hidden = true;
    self.editProjectNameTextField.hidden = true;
    self.editBoardNameTextField.hidden = true;
    
    self.boardNameLabel.hidden = true;
    self.boardNameEditButton.hidden = true;
    self.editBoardNameTextField.hidden = true;
    
    self.carousel.hidden = true;
    carouselFadeLeft.hidden = false;
    carouselFadeRight.hidden = false;
    
    for (AvatarButton *avatar in self.avatars) avatar.hidden = true;
    self.avatarBackgroundImage.hidden = true;
    self.addUserButton.hidden = true;
    
    [self updateMessages];
    [self.chatTable reloadData];
    self.chatView.hidden = false;
    self.chatFadeImage.hidden = false;
    self.chatTable.hidden = false;
    self.chatOpenButton.hidden = true;
    self.chatTextField.hidden = true;
    self.chatAvatar.hidden = true;
    self.sendMessageButton.hidden = true;
    
    self.addBoardBackgroundImage.hidden = true;
    self.addBoardButton.hidden = true;
    self.projectNameEditButton.hidden = true;
    self.draggableCollectionView.hidden = true;
    
    self.applyChangesButton.hidden = true;
    self.cancelButton.hidden = true;
    self.deleteProjectButton.hidden = true;
    editFadeLeft.hidden = true;
    editFadeRight.hidden = true;
    self.editing = false;
}

-(void) updateDetails {
    
    self.chatTextField.hidden = false;
    self.sendMessageButton.hidden = false;
    self.chatAvatar.hidden = false;
    self.chatOpenButton.hidden = false;
    
    if  (self.userRole > 0) self.chatDiff = 0;
    else self.chatDiff = self.chatView.frame.size.height;
    
    if (![self.chatTextField isFirstResponder]) {
        
        self.chatView.center = CGPointMake(617, 743.5);
        self.chatOpenButton.center = CGPointMake(617.5, 598);
        self.chatFadeImage.center = CGPointMake(722, 615.5);
        self.chatTable.frame = CGRectMake(210, 612, self.view.frame.size.width-210, 107+self.chatDiff);
    }
    
    self.projectNameLabel.text = self.projectName;
    [self.projectNameLabel sizeToFit];
    self.editButton.center = CGPointMake(self.projectNameLabel.frame.size.width+292, self.projectNameLabel.center.y+3);
    self.projectNameEditButton.center = self.editButton.center;
    
    UIButton *projectNameButton = (UIButton *)[self.view viewWithTag:101];
    [projectNameButton setTitle:self.projectName forState:UIControlStateNormal];
    [projectNameButton sizeToFit];
    
    [self updateMessages];
    [self.chatTable reloadData];
    [self.carousel reloadData];
    [self.draggableCollectionView reloadData];
    
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
    [self.messages addObject:viewedAt];
    
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [self.messages sortUsingDescriptors:@[sorter]];
    
    if ([self.messages.lastObject isEqualToString:viewedAt] || (self.activeBoardID && [self.messages.firstObject isEqualToString:viewedAt]) || (!self.activeCommentThreadID && self.chatViewed) || ([self.viewedCommentThreadIDs containsObject:self.activeCommentThreadID])) {
        
        [self.messages removeObject:viewedAt];
        self.chatViewed = true;
        if (![self.chatTextField isFirstResponder]) {
            CGPoint chatCenter = self.chatOpenButton.center;
            self.chatOpenButton.frame = CGRectMake(0, 0, 51, 28);
            self.chatOpenButton.center = chatCenter;
            if (self.chatOpen) [self.chatOpenButton setImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
            else [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
        }
    }
    
    for (NSString *messageID in messageKeys) {
        
        NSString *date;
        
        if (self.activeCommentThreadID){
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
            date = [[[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] objectForKey:messageID] objectForKey:@"sentAt"];
        }
        else date = [[[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] objectForKey:messageID]  objectForKey:@"sentAt"];
        
        for (int i=0; i<self.messages.count; i++) {
            
            if ([viewedAt isEqualToString:self.messages[i]]) {
                
                [self.messages replaceObjectAtIndex:i withObject:@"new messages"];
                if (!self.chatViewed && ![self.chatTextField isFirstResponder]) {
                    
                    self.chatOpenButton.frame = CGRectMake(0, 0, 150, 31);
                    self.chatOpenButton.center = CGPointMake(617.9, 598);
                    [self.chatOpenButton setImage:[UIImage imageNamed:@"newmessages.png"] forState:UIControlStateNormal];
                }
            }
            
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
    self.avatarBackgroundImage.transform = CGAffineTransformScale(self.avatarBackgroundImage.transform, .25, .25);
    self.avatarBackgroundImage.frame = CGRectMake(1024-self.avatarBackgroundImage.frame.size.width, 18, self.avatarBackgroundImage.frame.size.width, self.avatarBackgroundImage.frame.size.height);
    [self.view addSubview:self.avatarBackgroundImage];
    
    for (int i=0; i<userIDs.count; i++) {
        
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.userID = userIDs[i];
        [avatar generateIdenticonWithShadow:true];
        avatar.frame = CGRectMake(850-(i*66), -70, avatar.userImage.size.width, avatar.userImage.size.height);
        [avatar addTarget:self action:@selector(avatarTapped:) forControlEvents:UIControlEventTouchUpInside];
        avatar.transform = CGAffineTransformScale(avatar.transform, .25, .25);
        [self.view insertSubview:avatar aboveSubview:self.avatarBackgroundImage];
        
        NSString *inProjectID = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"inProject"];

        if (![inProjectID isEqualToString:[FirebaseHelper sharedHelper].currentProjectID] && ![avatar.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
            avatar.alpha = 0.5;
        }
        [self.avatars addObject:avatar];
    }
    
    [self.addUserButton removeFromSuperview];
    self.addUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.addUserButton addTarget:self action:@selector(addUserTapped) forControlEvents:UIControlEventTouchUpInside];
    UIImage *plusImage = [UIImage imageNamed:@"plus1.png"];
    [self.addUserButton setImage:plusImage forState:UIControlStateNormal];
    self.addUserButton.frame = CGRectMake(858-(userIDs.count*66), -63, plusImage.size.width, plusImage.size.height);
    self.addUserButton.transform = CGAffineTransformScale(self.addUserButton.transform, .25, .25);
    [self.view insertSubview:self.addUserButton aboveSubview:self.avatarBackgroundImage];
    
    if (self.activeBoardID) [self hideAvatars];
}

-(void) createBoard {
    
    Firebase *boardRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/boards"];
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info/boards", [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    
    Firebase *commentsRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/comments"];
    Firebase *commentsRefWithID = [commentsRef childByAutoId];
    NSString *commentsID = commentsRefWithID.key;
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSMutableDictionary *subpathsDict = [NSMutableDictionary dictionary];
    
    NSMutableArray *userIDs = [self.roles.allKeys mutableCopy];

    for (NSString *userID in userIDs) {
        
        [subpathsDict setObject:[@{ dateString : @"penUp"} mutableCopy] forKey:userID];
    }
    
    NSString *boardNum = [NSString stringWithFormat:@"%lu", (unsigned long)self.boardIDs.count];
    NSDictionary *boardDict =  @{ @"name" : @"Untitled",
                                  @"project" : self.projectName,
                                  @"number" : boardNum,
                                  @"commentsID" : commentsID,
                                  @"subpaths" : subpathsDict,
                                  @"updatedAt" : dateString,
                                  @"undo" :  [@{ [FirebaseHelper sharedHelper].uid :
                                                     [@{ @"currentIndex" : @0,
                                                         @"currentIndexDate" : dateString,
                                                         @"total" : @0
                                                         } mutableCopy]
                                                 } mutableCopy]
                                  };
    
    Firebase *boardRefWithID = [boardRef childByAutoId];
    [boardRefWithID updateChildValues:boardDict];
    
    [projectRef updateChildValues:@{ boardNum : boardRefWithID.key}];
    
    NSString *boardID = boardRefWithID.key;
    
    [self.boardIDs addObject:boardID];
    [self.viewedBoardIDs addObject:boardID];
    [[FirebaseHelper sharedHelper].loadedBoardIDs addObject:boardID];
    [[FirebaseHelper sharedHelper].boards setObject:[boardDict mutableCopy] forKey:boardID];
    [[FirebaseHelper sharedHelper].comments setObject:[NSMutableDictionary dictionary] forKey:commentsID];
    [[[FirebaseHelper sharedHelper].projects objectForKey:@"boards"] setObject:boardID forKey:boardNum];
    
    [[FirebaseHelper sharedHelper] setProjectUpdatedAt:dateString];
    [[FirebaseHelper sharedHelper] observeBoardWithID:boardID];
}

-(void) drawBoard:(BoardView *)boardView {
    
    [boardView clear];
    
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
        
        for (int i=0; i<subpathsOrderedKeys.count; i++) {
            
            NSDictionary *subpathDict = [pathDict objectForKey:subpathsOrderedKeys[i]];
            [boardView drawSubpath:subpathDict];
        }
    }
}

- (IBAction)sendTapped:(id)sender {
    
    if (![self.chatTextField isFirstResponder]) [self.chatTextField becomeFirstResponder];
    else [self textFieldShouldReturn:self.chatTextField];
}

-(void) boardTapped:(id)sender {
    
    if([self.editBoardNameTextField isFirstResponder]) {
        [self.editBoardNameTextField resignFirstResponder];
        return;
    }
    
    if (self.carouselMoving) {
        [self.carousel scrollToItemAtIndex:self.carousel.currentItemIndex animated:YES];
        return;
    }
    
    UIButton *button = (UIButton *)sender;
    self.currentBoardView = (BoardView *)button.superview;
    
    if (![[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:self.currentBoardView.boardID]) return;
    
    [self.carousel setScrollEnabled:NO];
    self.carouselOffset = 0;
    NSString *boardID = self.currentBoardView.boardID;
    self.boardNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:24];
    [self.boardNameLabel sizeToFit];
    self.boardNameLabel.center = CGPointMake(self.carousel.center.x, self.boardNameLabel.center.y);
    self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+17, self.boardNameLabel.center.y);
    boardButton = button;
    self.activeBoardID = boardID;
    self.activeBoardUndoIndexDate = [[[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndexDate"];
    
    [[FirebaseHelper sharedHelper] setInBoard:boardID];

    [self.currentBoardView.activeUserIDs addObject:[FirebaseHelper sharedHelper].uid];
    [self.currentBoardView layoutAvatars];
    
    NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"name"];
    NSString *labelString = [NSString stringWithFormat:@"|   %@", boardName];
    UILabel *boardNameLabel = (UILabel *)[self.view viewWithTag:102];
    boardNameLabel.text = labelString;
    if ([boardName isEqualToString:@"Untitled"]) boardNameLabel.alpha = .2;
    else boardNameLabel.alpha = 1;
    [boardNameLabel sizeToFit];
    CGRect projectNameRect = [self.view viewWithTag:101].frame;
    boardNameLabel.frame = CGRectMake(projectNameRect.size.width+46, projectNameRect.origin.y+5.5, boardNameLabel.frame.size.width, boardNameLabel.frame.size.height);
    
    self.messages = [NSMutableArray array];
    [self.chatTable reloadData];
    [self hideChat];
    [self.view sendSubviewToBack:self.addBoardButton];
    [self.view sendSubviewToBack:self.addBoardBackgroundImage];
    [self hideAvatars];
    
    [UIView animateWithDuration:.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         self.carousel.center = CGPointMake(self.view.center.x, self.view.center.y);
                         CGAffineTransform tr = CGAffineTransformScale(self.carousel.transform, 2, 2);
                         self.carousel.transform = tr;
                         
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
                         
                         if (newBoardCreated) {
                             
                             [self showEditBoardName];
                             newBoardCreated = false;
                         }
                     }
     ];
}

-(void)closeTapped {
    
    boardButton.hidden = false;
    self.currentBoardView.commenting = false;
    self.chatOpen = false;
    
    self.currentBoardView.lineColorNumber = @0;
    [(UIButton *)[self.view viewWithTag:7] setBackgroundImage:[UIImage imageNamed:@"black.png"] forState:UIControlStateNormal];
    self.currentBoardView.penType = 0;
    [(UIButton *)[self.view viewWithTag:5] setBackgroundImage:[UIImage imageNamed:@"pen.png"] forState:UIControlStateNormal];
    [self hideDrawMenu];
    
    [self.viewedBoardIDs addObject:self.activeBoardID];
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
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    if ([[self.view viewWithTag:104] isFirstResponder]) [[self.view viewWithTag:104] resignFirstResponder];
    if ([self.commentTitleTextField isFirstResponder]) [self.commentTitleTextField resignFirstResponder];
    
    self.commentTitleView.hidden = true;
    self.messages = [NSMutableArray array];
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
                         
                         CGAffineTransform tr = CGAffineTransformScale(self.carousel.transform, .5, .5);
                         self.carousel.transform = tr;
                         self.carousel.center = CGPointMake(self.view.center.x+masterWidth/2, self.view.frame.size.height/2-44);
                         
                         self.masterView.center = CGPointMake(masterWidth/2, self.masterView.center.y);
                         
                         boardButton.alpha = 1;
                     }
                     completion:^(BOOL finished) {

                         [self.carousel setScrollEnabled:YES];
                         [self updateDetails];
                         
                         [self showChat];
                         [self.view bringSubviewToFront:self.addBoardBackgroundImage];
                         [self.view bringSubviewToFront:self.addBoardButton];
                         
                         if ([[FirebaseHelper sharedHelper].projects.allKeys containsObject:[FirebaseHelper sharedHelper].currentProjectID]) {

                             [self.masterView.projectsTable reloadData];
                             [self.masterView.projectsTable selectRowAtIndexPath:self.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
                         }
                         else {
                             
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
                     }
     ];
}

- (IBAction)editTapped:(id)sender {
    
    self.editing = true;
    
    [self.draggableCollectionView reloadData];
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    if ([self.boardNameEditButton isFirstResponder]) [self.boardNameEditButton resignFirstResponder];
    
    self.editBoardIDs = [self.boardIDs mutableCopy];
    
    self.editProjectNameTextField.text = self.projectName;
    
    editFadeLeft.hidden = false;
    editFadeRight.hidden = false;
    
    self.editButton.hidden = true;
    self.carousel.hidden = true;
    self.draggableCollectionView.hidden = false;
    self.boardNameLabel.hidden = true;
    self.addBoardButton.hidden = true;
    self.addBoardBackgroundImage.hidden = true;
    
    self.projectNameEditButton.hidden = false;
    self.editBoardNameTextField.hidden = true;
    self.boardNameEditButton.hidden = true;
    self.applyChangesButton.hidden = false;
    self.cancelButton.hidden = false;
    self.deleteProjectButton.hidden = false;
    
    self.chatFadeImage.hidden = true;
    self.chatView.hidden = true;
    self.chatTextField.hidden = true;
    self.chatTable.hidden = true;
    self.chatOpenButton.hidden = true;
    
    for (int i=0; i<self.boardIDs.count; i++) {
        [self collectionView:self.draggableCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    [self.view bringSubviewToFront:self.applyChangesButton];
    [self.view bringSubviewToFront:self.cancelButton];
    [self.view bringSubviewToFront:self.deleteProjectButton];
}

- (IBAction)projectNameEditTapped:(id)sender {

    self.editProjectNameTextField.text = self.projectNameLabel.text;
    
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
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info", [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    
    if (self.editProjectNameTextField.text.length > 0) {
        
        NSString *newName = self.editProjectNameTextField.text;
        [self.projectNameLabel setText:newName];
        [self.projectNameLabel sizeToFit];
        self.editButton.center = CGPointMake(self.projectNameLabel.frame.size.width+292, self.projectNameLabel.center.y+3);
        
        [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:newName forKey:@"name"];
        
        [self.masterView updateProjects];        
        self.masterView.defaultRow = [NSIndexPath indexPathForRow:[self.masterView.orderedProjectNames indexOfObject:newName] inSection:0];
        [self.masterView.projectsTable reloadData];
        [self.masterView tableView:self.masterView.projectsTable didSelectRowAtIndexPath:self.masterView.defaultRow];
     
        [[projectRef childByAppendingPath:@"name"] setValue:newName];
        
        if (![self.editBoardIDs isEqualToArray:self.boardIDs]) {

            NSMutableDictionary *boardsDict = [NSMutableDictionary dictionary];
            
            for (int i=0; i<self.editBoardIDs.count; i++) [boardsDict setObject:self.editBoardIDs[i] forKey:[@(i) stringValue]];
            
            [[projectRef childByAppendingPath:@"boards"] setValue:boardsDict];
            
            [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:boardsDict forKey:@"boards"];
            
            for (NSString *boardID in self.boardIDs) {
                
                if (![self.editBoardIDs containsObject:boardID]) {
                    
                    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"commentsID"];
                    NSString *commentsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@", commentsID];
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
                    
                    [[FirebaseHelper sharedHelper].comments removeObjectForKey:commentsID];
                    
                    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", boardID];
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
                    
                    [boardRef removeValue];
                    [[FirebaseHelper sharedHelper].boards removeObjectForKey:boardID];
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
}

- (IBAction)cancelTapped:(id)sender {
    
    editFadeLeft.hidden = true;
    editFadeRight.hidden = true;
    
    self.projectNameLabel.hidden = false;
    self.projectNameEditButton.hidden = true;
    self.carousel.hidden = false;
    self.draggableCollectionView.hidden = true;
    self.boardNameLabel.hidden = false;
    
    if (self.userRole > 0) {

        if (self.userRole > 1) self.editButton.hidden = false;
        else self.editButton.hidden = true;
        self.addBoardButton.hidden = false;
        self.addBoardBackgroundImage.hidden = false;
        self.chatView.hidden = false;
        if (self.boardNameLabel.text.length > 0) self.boardNameEditButton.hidden = false;
    }
    else {
        
        self.editButton.hidden = true;
        self.addBoardButton.hidden = true;
        self.addBoardBackgroundImage.hidden = true;
        self.chatView.hidden = true;
        self.boardNameEditButton.hidden = true;
    }
    
    self.editProjectNameTextField.hidden = true;
    self.editBoardNameTextField.hidden = true;
    self.applyChangesButton.hidden = true;
    self.cancelButton.hidden = true;
    self.deleteProjectButton.hidden = true;
    
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
    
    int undoCount = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    int undoTotal = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"total"] intValue];
    
    if (undoCount < undoTotal)  {
        
        undoCount++;
        
        NSMutableDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
        [undoDict setObject:@(undoCount) forKey:@"currentIndex"];
        
        [self drawBoard:self.currentBoardView];
        
        [self.currentBoardView addUserDrawing:[FirebaseHelper sharedHelper].uid];
        
        [undoDict setObject:self.activeBoardUndoIndexDate forKey:@"currentIndexDate"];
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", self.currentBoardView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [ref setValue:undoDict];
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        [[FirebaseHelper sharedHelper] setBoard:self.activeBoardID UpdatedAt:dateString];
    }
}

- (void) redoTapped:(id)sender {
    
    self.currentBoardView.commenting = false;
    
    int undoCount = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    
    if (undoCount > 0) {
        
        undoCount--;
        
        NSMutableDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
        [undoDict setObject:@(undoCount) forKey:@"currentIndex"];
        
        [self drawBoard:self.currentBoardView];
        
        [self.currentBoardView addUserDrawing:[FirebaseHelper sharedHelper].uid];
        
        [undoDict setObject:self.activeBoardUndoIndexDate forKey:@"currentIndexDate"];
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@/", self.currentBoardView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [ref setValue:undoDict];
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        [[FirebaseHelper sharedHelper] setBoard:self.activeBoardID UpdatedAt:dateString];
    }
}

- (void) clearTapped:(id)sender {
    
    self.currentBoardView.commenting = false;
    
    NSDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
    
    if ([[undoDict objectForKey:@"total"] integerValue] == [[undoDict objectForKey:@"currentIndex"] integerValue]) return;
    
    [[FirebaseHelper sharedHelper] resetUndo];
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSString *refString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/subpaths/%@", self.currentBoardView.boardID, [FirebaseHelper sharedHelper].uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:refString];
    NSDictionary *clearDict = @{ dateString : @"clear" };
    [ref updateChildValues:clearDict];
    
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@"clear" forKey:dateString];
    
    [self.currentBoardView touchesEnded:nil withEvent:nil];
    [self drawBoard:self.currentBoardView];
    
    [self.currentBoardView addUserDrawing:[FirebaseHelper sharedHelper].uid];
}

-(void) eraseTapped:(id)sender {

    self.currentBoardView.commenting = false;
    self.erasing = true;
    
    [self.view bringSubviewToFront:self.eraserCursor];
    
    for (int i=5; i<=8; i++) {
        
        if (i==7) continue;
        
        UIView *button = [self.view viewWithTag:i];
        if (i==6) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
}

-(void) colorTapped:(id)sender {
    
    self.currentBoardView.commenting = false;
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
    self.currentBoardView.commenting = false;
    
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
    
    for (int i=5; i<=8; i++) {
        
        if (i==7) continue;
        
        UIView *button = [self.view viewWithTag:i];
        if (i==5) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
}

-(void) commentTapped:(id)sender {
    
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

- (IBAction)newBoardTapped:(id)sender {
    
    newBoardCreated = true;

    [self createBoard];
    
    self.activeBoardID = [self.boardIDs lastObject];
    
    [self.carousel reloadData];
    [self.carousel scrollByNumberOfItems:self.carousel.numberOfItems duration:.5];
}

- (void)addUserTapped {
    
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
        
        if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
        else if (self.userRole > 0) [self.chatTextField becomeFirstResponder];
        else [self openChat];
    }
    else [self openChat];
}

-(void)chatTableTapped {
 
    if (self.presentedViewController == nil && !self.activeBoardID && !self.editing) {
        
        CGPoint location = [chatTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (CGRectContainsPoint(self.chatTable.frame, converted)) {
            
            if (![self.chatTextField isFirstResponder] && self.userRole > 0) [self.chatTextField becomeFirstResponder];
            else if (!self.chatOpen && self.userRole == 0) [self openChat];
        }
    }
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
    
    if ([self.chatTextField isFirstResponder] || [self.commentTitleTextField isFirstResponder]) {
    
        [self showChat];
        
        CGFloat height = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
        keyboardDiff = 517-height;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        CGRect viewRect = self.chatView.frame;
        viewRect.origin.y -= height;
        self.chatView.frame = viewRect;
        
        CGRect fadeRect = self.chatFadeImage.frame;
        if(self.activeBoardID == nil) fadeRect.origin.y -= (height+keyboardDiff);
        else fadeRect.origin.y -= height;
        self.chatFadeImage.frame = fadeRect;
        
        CGRect titleRect = self.commentTitleView.frame;
        titleRect.origin.y -= height;
        self.commentTitleView.frame = titleRect;
        
        CGRect chatTableRect = self.chatTable.frame;
        if (self.activeBoardID == nil) {
            chatTableRect.size.height += keyboardDiff;
            chatTableRect.origin.y -= (height+keyboardDiff);
        }
        else chatTableRect.origin.y -= height;
        
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
            projectsTableRect.size.height -= (height-keyboardDiff);
            self.masterView.projectsTable.frame = projectsTableRect;
        }
        
        self.chatOpenButton.frame = CGRectMake(592, 584, 51, 28);
        
        if (!self.activeBoardID) {
            [self.chatOpenButton setImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
            self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-(height+keyboardDiff));
        }
        else {
            [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
            self.chatOpenButton.center = CGPointMake(self.view.center.x, self.chatOpenButton.center.y-height);
        }
        
        [self.view bringSubviewToFront:self.chatOpenButton];
        
        [UIView commitAnimations];
    }
}

-(void)keyboardWillHide:(NSNotification *)notification {

    if (!self.editing && self.boardNameLabel.text.length > 0) {
        
        self.editBoardNameTextField.hidden = true;
        self.boardNameLabel.hidden = false;
        if (self.userRole > 0) self.boardNameEditButton.hidden = false;
    }
    
    if ([self.chatTextField isFirstResponder] || [self.commentTitleTextField isFirstResponder]) {
        
        self.chatTextField.text = nil;
        
        if (self.activeCommentThreadID) [self.viewedCommentThreadIDs addObject:self.activeCommentThreadID];
        self.activeCommentThreadID = nil;
        
        CGFloat height = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
        keyboardDiff = 517-height;

        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        CGRect projectsTableRect = self.masterView.projectsTable.frame;
        projectsTableRect.size.height += (height-keyboardDiff);
        self.masterView.projectsTable.frame = projectsTableRect;

        CGRect titleRect = self.commentTitleView.frame;
        titleRect.origin.y += height;
        self.commentTitleView.frame = titleRect;

        CGRect viewRect = self.chatView.frame;
        viewRect.origin.y += height;
        self.chatView.frame = viewRect;
        
        CGRect fadeRect = self.chatFadeImage.frame;
        if(self.activeBoardID == nil) fadeRect.origin.y += (height+keyboardDiff);
        else fadeRect.origin.y += height;
        self.chatFadeImage.frame = fadeRect;
        
        CGRect chatTableRect = self.chatTable.frame;
        if (self.activeBoardID == nil) {
            chatTableRect.size.height -= keyboardDiff-self.chatDiff;
            chatTableRect.origin.y += (height+keyboardDiff);
        }
        else chatTableRect.origin.y += height;
        self.chatTable.frame = chatTableRect;
            
        if (self.activeBoardID && self.carouselOffset > 0) {
            
            CGRect carouselRect = self.carousel.frame;
            carouselRect.origin.y += self.carouselOffset;
            self.carousel.frame = carouselRect;
            
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
            projectsTableRect.size.height += (height-keyboardDiff);
            self.masterView.projectsTable.frame = projectsTableRect;
        }

        if (self.activeBoardID) self.chatOpenButton.center = CGPointMake(self.view.center.x, self.chatOpenButton.center.y+height);
        else self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+(height+keyboardDiff));
        
        if (self.chatOpen) [self openChat];

        [self.view bringSubviewToFront:self.chatOpenButton];
        
        [UIView commitAnimations];
        
        CGPoint chatCenter = self.chatOpenButton.center;
        self.chatOpenButton.frame = CGRectMake(0, 0, 51, 28);
        self.chatOpenButton.center = chatCenter;
        [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];

        if (self.activeBoardID) [self.currentBoardView hideChat];
    }
    
    if ([[self.view viewWithTag:104] isFirstResponder]) {
        
        UILabel *label = (UILabel *)[self.view viewWithTag:102];
        UIButton *editBoardNameButton = (UIButton *)[self.view viewWithTag:103];
        UITextField *textField = (UITextField *)[self.view viewWithTag:104];
        
        if (self.activeBoardID){
            
            NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.activeBoardID] objectForKey:@"name"];
            NSString *labelString = [NSString stringWithFormat:@"|   %@", boardName];
            label.text = labelString;
            if ([boardName isEqualToString:@"Untitled"]) label.alpha = .2;
            else label.alpha = 1;
            
            label.hidden = false;
            editBoardNameButton.hidden = false;
            textField.hidden = true;
        }
        else {
            label.hidden = true;
            editBoardNameButton.hidden = true;
            textField.hidden = true;
        }
    }
    
    if ([self.editProjectNameTextField isFirstResponder]) {
        
        self.projectNameLabel.hidden = false;
        self.projectNameEditButton.hidden = false;
        self.editProjectNameTextField.hidden = true;
    }
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
    
    return self.boardIDs.count;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view {
    
    if (view == nil) {
        
        BoardView *boardView = [[BoardView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
        view = boardView;
        CGAffineTransform tr = view.transform;
        tr = CGAffineTransformScale(tr, .5, .5);
        tr = CGAffineTransformRotate(tr, M_PI_2);
        view.transform = tr;
    }
    
    UIImage *gradientImage = [UIImage imageNamed:@"board8.png"];
    UIButton *gradientButton = [UIButton buttonWithType:UIButtonTypeCustom];
    gradientButton.frame = CGRectMake(0.0f, 0.0f, gradientImage.size.width, gradientImage.size.height);
    gradientButton.center = view.center;
    gradientButton.adjustsImageWhenHighlighted = NO;
    [gradientButton setBackgroundImage:gradientImage forState:UIControlStateNormal];
    [gradientButton addTarget:self action:@selector(boardTapped:) forControlEvents:UIControlEventTouchUpInside];
    if (((BoardView *)view).gradientButton == nil) [view addSubview:gradientButton];
    ((BoardView *)view).gradientButton = gradientButton;
    gradientButton.tag = 1;
    
    ((BoardView *)view).boardID = self.boardIDs[index];

    if ([[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:self.boardIDs[index]]) {
        
        [self drawBoard:(BoardView *)view];
        [((BoardView *)view) layoutComments];
        
        for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
            
            if ([[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"inBoard"] isEqualToString:((BoardView *)view).boardID])
                [((BoardView *)view).activeUserIDs addObject:userID];
        }
        [((BoardView *)view) layoutAvatars];
    }
    else {
        
        ((BoardView *)view).fadeView.hidden = false;
        
        [((BoardView *)view).loadingView removeFromSuperview];
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
    
    if (newBoardCreated) [self boardTapped:[carousel.currentItemView viewWithTag:1]];
}

- (void)carouselDidScroll:(iCarousel *)carousel {
    
    self.carouselMoving = true;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    
    if (self.boardIDs.count == 0) return;
    
    NSString *boardID = self.boardIDs[carousel.currentItemIndex];
    NSDictionary *boardDict = [[FirebaseHelper sharedHelper].boards objectForKey:boardID];
    
    NSString *boardName = [boardDict objectForKey:@"name"];
    
    if (boardName) {
    
        self.boardNameLabel.text = boardName;
        if ([boardName isEqualToString:@"Untitled"]) self.boardNameLabel.alpha = .2;
        else self.boardNameLabel.alpha = 1;
    }
    
    double viewedAt = [[[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid] doubleValue];
    double updatedAt = [[boardDict objectForKey:@"updatedAt"] doubleValue];
    
    UIFont *labelFont;
    
    if (updatedAt > viewedAt && ![self.viewedBoardIDs containsObject:boardID] && !newBoardCreated) {
        
        labelFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:24];
    }
    else
        labelFont = [UIFont fontWithName:@"SourceSansPro-Light" size:24];
    
    self.boardNameLabel.font = labelFont;
    [self.boardNameLabel sizeToFit];
    self.boardNameLabel.center = CGPointMake(self.carousel.center.x, self.boardNameLabel.center.y);

    self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+17, self.boardNameLabel.center.y);
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
    
    if (textField.text.length == 0) return NO;
    
    if ([textField isEqual:self.chatTextField]) {
        
        NSString *chatString;
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        
        if (self.activeCommentThreadID != nil) {
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
            chatString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@/%@/messages", commentsID, self.activeCommentThreadID];
            [[FirebaseHelper sharedHelper] setCommentThread:self.activeCommentThreadID updatedAt:dateString];
        }
        else {
            
            chatString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/chats/%@", self.chatID];
            [[FirebaseHelper sharedHelper] setProjectUpdatedAt:dateString];
        }
        
        Firebase *chatRef = [[Firebase alloc] initWithUrl:chatString];
        NSDictionary *messageDict = @{ @"user" : [FirebaseHelper sharedHelper].uid ,
                                       @"message" : textField.text,
                                       @"sentAt" : dateString
                                       };
        [[chatRef childByAutoId] setValue:messageDict];
        
        self.chatTextField.text = nil;
    }
    
    if ([textField isEqual:self.editBoardNameTextField]) {
        
        [self.carousel setScrollEnabled:YES];
        [textField resignFirstResponder];

        NSString *oldBoardName = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"name"];
        
        if (![textField.text isEqualToString:oldBoardName]) {
            
            NSString *boardNameString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/name", self.boardIDs[self.carousel.currentItemIndex]];
            Firebase *ref = [[Firebase alloc] initWithUrl:boardNameString];
            [ref setValue:self.editBoardNameTextField.text];
            [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] setObject:self.editBoardNameTextField.text forKey:@"name"];
            
            self.boardNameLabel.text = self.editBoardNameTextField.text;
            if ([self.boardNameLabel.text isEqualToString:@"Untitled"]) self.boardNameLabel.alpha = .2;
            else self.boardNameLabel.alpha = 1;
            [self.boardNameLabel sizeToFit];
            self.boardNameLabel.center = CGPointMake(self.carousel.center.x, self.boardNameLabel.center.y);
            
            self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+17, self.boardNameLabel.center.y);
            
            NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
            [[FirebaseHelper sharedHelper] setBoard:self.boardIDs[self.carousel.currentItemIndex] UpdatedAt:dateString];
        }

        [self cancelTapped:nil];
    }
    
    if ([textField isEqual:[self.view viewWithTag:104]]) {
        
        [textField resignFirstResponder];
        
        UITextField *editBoardNameTextField = (UITextField *)[self.view viewWithTag:104];
        editBoardNameTextField.hidden = true;
        
        UILabel *boardNameLabel = (UILabel *)[self.view viewWithTag:102];
        NSString *boardNameString = [NSString stringWithFormat:@"|   %@", editBoardNameTextField.text];
        boardNameLabel.text = boardNameString;
        if ([boardNameLabel.text isEqualToString:@"Untitled"]) boardNameLabel.alpha = .2;
        else boardNameLabel.alpha = 1;
        [boardNameLabel sizeToFit];
        boardNameLabel.hidden = false;
        
        self.boardNameLabel.text = editBoardNameTextField.text;
        if ([self.boardNameLabel.text isEqualToString:@"Untitled"]) self.boardNameLabel.alpha = .2;
        else self.boardNameLabel.alpha = 1;
        [self.boardNameLabel sizeToFit];
        self.boardNameLabel.center = CGPointMake(self.carousel.center.x+105, self.boardNameLabel.center.y);
        self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+122, self.boardNameLabel.center.y);
        
        UIButton *editBoardNameButton = (UIButton *)[self.view viewWithTag:103];
        editBoardNameButton.frame = CGRectMake(boardNameLabel.frame.origin.x+boardNameLabel.frame.size.width-5, boardNameLabel.frame.origin.y-6, 36, 36);
        editBoardNameButton.hidden = false;
        
        NSString *boardNameRefString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/name", self.boardIDs[self.carousel.currentItemIndex]];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardNameRefString];
        [ref setValue:editBoardNameTextField.text];
        [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] setObject:editBoardNameTextField.text forKey:@"name"];
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        [[FirebaseHelper sharedHelper] setBoard:self.activeBoardID UpdatedAt:dateString];
    }
    
    if ([textField isEqual:self.editProjectNameTextField]) {
        
        [UIView setAnimationsEnabled:NO];
        self.projectNameLabel.text = self.editProjectNameTextField.text;
        [self.projectNameLabel sizeToFit];
        self.projectNameEditButton.center = CGPointMake(self.projectNameLabel.frame.size.width+292, self.projectNameLabel.center.y+3);
        [UIView setAnimationsEnabled:YES];
        
        [textField resignFirstResponder];
    }
    
    if ([textField isEqual:self.commentTitleTextField]) {
        
        NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
        [[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] setObject:self.commentTitleTextField.text forKey:@"title"];

        NSString *titleString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@/%@/info/title", commentsID, self.activeCommentThreadID];
        Firebase *titleRef = [[Firebase alloc] initWithUrl:titleString];
        [titleRef setValue:self.commentTitleTextField.text];
        
        [self.chatTextField becomeFirstResponder];
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        [[FirebaseHelper sharedHelper] setCommentThread:self.activeCommentThreadID updatedAt:dateString];
    }
    
    return NO;
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
            [avatar generateIdenticonWithShadow:false];
            avatar.frame = CGRectMake(-100, -101, avatar.userImage.size.width, avatar.userImage.size.height);
            avatar.transform = CGAffineTransformMakeScale(.16, .16);
            avatar.userInteractionEnabled = false;
            avatar.tag = 201;
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

@end
