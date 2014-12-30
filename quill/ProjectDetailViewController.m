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

@implementation ProjectDetailViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.chatTextField.delegate = self;
    self.editBoardNameTextField.delegate = self;
    self.carousel.delegate = self;
    
    self.carousel.type = iCarouselTypeCoverFlow2;
    self.carousel.bounceDistance = 0.1f;
    
    carouselFadeLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"carouselfadeleft.png"]];
    [self.carousel addSubview:carouselFadeLeft];
    carouselFadeLeft.frame = CGRectMake(0, -5, 50, 400);

    carouselFadeRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"carouselfaderight.png"]];
    [self.carousel addSubview:carouselFadeRight];
    carouselFadeRight.frame = CGRectMake(764, -5, 50, 400);
    
    self.projectNameLabel.font = [UIFont fontWithName:@"SourceSansPro-ExtraLight" size:48];
    self.editProjectNameTextField.frame = CGRectMake(self.projectNameLabel.frame.origin.x-8, self.projectNameLabel.frame.origin.y-3, 500, 65);
    self.chatTextField.font = [UIFont fontWithName:@"SourceSansPro-ExtraLight" size:20];
    self.chatTable.transform = CGAffineTransformMakeRotation(M_PI);
    [self showChat];
    
    self.masterView.projectsTable.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"projectsshadow.png"]];
    
    self.editBoardNameTextField.hidden = true;
    self.viewedCommentThreadIDs = [NSMutableArray array];
    
    [self setUpDrawMenu];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.chatTextField.placeholder = @"Send a message...";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void) setUpDrawMenu {
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(10, 20, 60, 30);
    [closeButton setTitle:@"< Back" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
    closeButton.hidden = true;
    [self.view addSubview:closeButton];
    closeButton.tag = 100;
    
    drawButtons = @[ @"undo",
                     @"redo",
                     @"clear",
                     @"erase",
                     @"color",
                     @"pen",
                     @"comment"
                    ];
    
    for (int i = 0; i<drawButtons.count; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",drawButtons[i]]];
        if (i == 5) buttonImage = [UIImage imageNamed:@"penselected.png"];
        button.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        [button setImage:buttonImage forState:UIControlStateNormal];
        button.transform = CGAffineTransformMakeScale(.1, .1);
        button.center = CGPointMake(272+i*80, 720);
        [button addTarget:self action:NSSelectorFromString([NSString stringWithFormat:@"%@Tapped:", drawButtons[i]]) forControlEvents:UIControlEventTouchUpInside];
        button.hidden = true;
        [self.view addSubview:button];
        button.tag = i+2;
    }
}

-(void) showDrawMenu {
    
    UIButton *closeButton = (UIButton *)[self.view viewWithTag:100];
    closeButton.hidden = false;
    [self.view bringSubviewToFront:closeButton];
    
    for (int i=0; i<drawButtons.count; i++) {
        
        UIButton *button = (UIButton *)[self.view viewWithTag:i+2];
        button.hidden = false;
        [self.view bringSubviewToFront:button];
    }
}

-(void) hideDrawMenu {
    
    for (int i=0; i<=drawButtons.count; i++) {
        
        UIButton *button = (UIButton *)[self.view viewWithTag:i+2];
        button.hidden = true;
    }
    
    [(UIButton *)[self.view viewWithTag:7] setImage:[UIImage imageNamed:@"penselected.png"] forState:UIControlStateNormal];
}

-(void) showChat {
    
    [self.view bringSubviewToFront:self.chatView];
    [self.view bringSubviewToFront:self.chatTable];
    [self.view bringSubviewToFront:self.chatFadeImage];
    [self.view bringSubviewToFront:self.chatOpenButton];
}

-(void) hideChat {
    
    [self.view sendSubviewToBack:self.chatOpenButton];
    [self.view sendSubviewToBack:self.chatTable];
    [self.view sendSubviewToBack:self.chatFadeImage];
    [self.view sendSubviewToBack:self.chatView];
    [self.view sendSubviewToBack:self.backgroundImage];
}

-(void) updateDetails {
    
    self.projectNameLabel.text = self.projectName;
    [self.projectNameLabel sizeToFit];
    self.editButton.center = CGPointMake(self.projectNameLabel.frame.size.width+280, self.projectNameLabel.center.y+5);
    
    [self updateMessages];
    [self.chatTable reloadData];
    [self.carousel reloadData];
    [self.draggableCollectionView reloadData];

    
    [self layoutAvatars];
    
    if (self.userRole > 0) self.editButton.hidden = false;
    else self.editButton.hidden = true;
    
    if (self.userRole == 0) {
        
        self.chatView.hidden = true;
        self.addBoardButton.hidden = true;
    }
    else {
        self.chatView.hidden = false;
        self.addBoardButton.hidden = false;
    }
    
    [self carouselCurrentItemIndexDidChange:self.carousel];
    
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
    
    if ([self.messages.lastObject isEqualToString:viewedAt] || (!self.activeCommentThreadID && self.chatViewed) || [self.viewedCommentThreadIDs containsObject:self.activeCommentThreadID]) {
        [self.messages removeObject:viewedAt];
        self.chatViewed = true;
        if (![self.chatTextField isFirstResponder]) [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
    }
    
    for (NSString *messageID in messageKeys) {
        
        NSString *date;
        
        if (self.activeCommentThreadID){
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
            date = [[[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] objectForKey:messageID] objectForKey:@"sentAt"];
        }
        else date = [[[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] objectForKey:messageID]  objectForKey:@"sentAt"];
        
        for (int i=0; i<self.messages.count; i++) {
            
            if ([viewedAt isEqualToString:self.messages[i]]) { [self.messages replaceObjectAtIndex:i withObject:@"---------------------------------------<NEW MESSAGES>---------------------------------------"];
                if (!self.chatViewed && ![self.chatTextField isFirstResponder]) [self.chatOpenButton setTitle:@"NEW MESSAGES!" forState:UIControlStateNormal];
            }
            
            else if ([date isEqualToString:self.messages[i]]) {
                
                NSString *text;
                NSString *name;
                
                if (self.activeCommentThreadID) {
                    
                    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
                    NSDictionary *messageDict = [[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] objectForKey:messageID];
                    
                    text = [messageDict objectForKey:@"message"];
                    name = [messageDict objectForKey:@"name"];
                }
                else {
                    
                    NSDictionary *messageDict = [[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] objectForKey:messageID];
                    
                    text = [messageDict objectForKey:@"message"];
                    name = [messageDict objectForKey:@"name"];
                }
                
                NSString *messageString = [NSString stringWithFormat:@"%@: %@", name, text];
                
                [self.messages replaceObjectAtIndex:i withObject:messageString];
            }
        }
    }
}

-(void) layoutAvatars {

    for (AvatarButton *avatar in self.avatars) [avatar removeFromSuperview];
    
    self.avatars = [NSMutableArray array];
    
    NSArray *userIDs = [self.roles.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    [self.avatarBackgroundImage removeFromSuperview];
    CGRect imageRect = CGRectMake(0, 0, 345+userIDs.count*(66*4), 280);
    CGImageRef imageRef = CGImageCreateWithImageInRect([[UIImage imageNamed:@"avatarbackground.png"] CGImage], imageRect);
    self.avatarBackgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:imageRef]];
    self.avatarBackgroundImage.transform = CGAffineTransformScale(self.avatarBackgroundImage.transform, .25, .25);
    self.avatarBackgroundImage.frame = CGRectMake(1024-self.avatarBackgroundImage.frame.size.width, 18, self.avatarBackgroundImage.frame.size.width, self.avatarBackgroundImage.frame.size.height);
    [self.view insertSubview:self.avatarBackgroundImage aboveSubview:self.backgroundImage];
    
    for (int i=0; i<userIDs.count; i++) {
        
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.userID = userIDs[i];
        [avatar generateIdenticon];
        avatar.frame = CGRectMake(850-(i*66), -70, avatar.userImage.size.width, avatar.userImage.size.height);
        [avatar addTarget:self action:@selector(avatarTapped:) forControlEvents:UIControlEventTouchUpInside];
        avatar.transform = CGAffineTransformScale(avatar.transform, .25, .25);
        [self.view insertSubview:avatar aboveSubview:self.avatarBackgroundImage];
        
        if (![[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"inProject"] isEqualToString:[FirebaseHelper sharedHelper].currentProjectID] && ![avatar.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
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
}

-(void) createBoard {
    
    Firebase *boardRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/boards"];
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info/boards", [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    
    Firebase *commentsRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/comments"];
    Firebase *commentsRefWithID = [commentsRef childByAutoId];
    NSString *commentsID = commentsRefWithID.name;
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSMutableDictionary *subpathsDict = [NSMutableDictionary dictionary];
    
    for (NSString *userID in self.roles.allKeys) {
        
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
    
    [projectRef updateChildValues:@{ boardNum : boardRefWithID.name }];
    
    NSString *boardID = boardRefWithID.name;
    
    [self.boardIDs addObject:boardID];
    [[FirebaseHelper sharedHelper].loadedBoardIDs addObject:boardID];
    [[FirebaseHelper sharedHelper].boards setObject:[boardDict mutableCopy] forKey:boardID];
    [[FirebaseHelper sharedHelper].comments setObject:[NSMutableDictionary dictionary] forKey:commentsID];
    [[[FirebaseHelper sharedHelper].projects objectForKey:@"boards"] setObject:boardID forKey:boardNum];
    
    [[FirebaseHelper sharedHelper] observeBoardWithID:boardID];
}

-(void) drawBoard:(BoardView *)boardView {
    
    [boardView clear];
    
    NSDictionary *subpathsDict = [[[FirebaseHelper sharedHelper].boards objectForKey:boardView.boardID] objectForKey:@"subpaths"];
    
    NSDictionary *dictRef = [[[FirebaseHelper sharedHelper].boards objectForKey:boardView.boardID] objectForKey:@"undo"];
    NSMutableDictionary *undoDict = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)dictRef, kCFPropertyListMutableContainers));
    
    NSMutableDictionary *subpathsToDraw = [NSMutableDictionary dictionary];
    
    for (NSString *uid in subpathsDict.allKeys) {
        
        NSDictionary *uidDict = [subpathsDict objectForKey:uid];

        NSMutableArray *userOrderedKeys = [uidDict.allKeys mutableCopy];
        NSSortDescriptor *descendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        [userOrderedKeys sortUsingDescriptors:@[descendingSorter]];
        
        BOOL undone = true;
        BOOL cleared = false;
        int undoCount = [[[undoDict objectForKey:uid] objectForKey:@"currentIndex"] intValue];
        
        for (int i=0; i<userOrderedKeys.count; i++) {
            
            NSMutableDictionary *subpathValues = [[uidDict objectForKey:userOrderedKeys[i]] mutableCopy];
            
            if ([subpathValues respondsToSelector:@selector(objectForKey:)]){
                
                if (boardView.selectedAvatarUserID != nil && ![uid isEqualToString:boardView.selectedAvatarUserID]) [subpathValues setObject:@1 forKey:@"faded"];
                if (!undone && !cleared) [subpathsToDraw setObject:subpathValues forKey:userOrderedKeys[i]];
                
            } else if ([[uidDict objectForKey:userOrderedKeys[i]] respondsToSelector:@selector(isEqualToString:)]) {
                
                if ([[uidDict objectForKey:userOrderedKeys[i]] isEqualToString:@"penUp"]) {
                    
                    [subpathsToDraw setObject:@{userOrderedKeys[i] : @"penUp"} forKey:userOrderedKeys[i]];
                    
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
    
    NSMutableArray *allOrderedKeys = [subpathsToDraw.allKeys mutableCopy];
    NSSortDescriptor *ascendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [allOrderedKeys sortUsingDescriptors:@[ascendingSorter]];
    
    for (int i=0; i<allOrderedKeys.count; i++) {
        
        NSDictionary *subpathDict = [subpathsToDraw objectForKey:allOrderedKeys[i]];
        [boardView drawSubpath:subpathDict];
    }
    
}

- (IBAction)sendTapped:(id)sender {
    
    [self textFieldShouldReturn:self.chatTextField];
    
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
    
    newBoardCreated = false;
    [self.carousel setScrollEnabled:NO];
    self.carouselOffset = 0;
    NSString *boardID = self.currentBoardView.boardID;
    self.boardNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:24];
    [self.viewedBoardIDs addObject:boardID];
    boardButton = button;
    self.activeBoardID = boardID;
    self.activeBoardUndoIndexDate = [[[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndexDate"];
    
    [[FirebaseHelper sharedHelper] setInBoard:boardID];

    [self.currentBoardView.activeUserIDs addObject:[FirebaseHelper sharedHelper].uid];
    [self.currentBoardView layoutAvatars];
    
    self.chatTextField.placeholder = @"Leave a comment...";

    [self hideChat];
    
    [self.view sendSubviewToBack:self.boardNameLabel];
    [self.view sendSubviewToBack:self.addBoardButton];
    [self.view sendSubviewToBack:self.addBoardBackgroundImage];
    [self.view sendSubviewToBack:self.avatarBackgroundImage];
    for (AvatarButton *avatar in self.avatars) [self.view sendSubviewToBack:avatar];
    [self.view sendSubviewToBack:self.addUserButton];
    [self.view sendSubviewToBack:self.backgroundImage];
    
    [UIView animateWithDuration:.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         self.carousel.center = CGPointMake(self.view.center.x, self.view.center.y);
                         CGAffineTransform tr = CGAffineTransformScale(self.carousel.transform, 2, 2);
                         self.carousel.transform = tr;
                         
                         self.masterView.center = CGPointMake(-105, self.masterView.center.y);
                         
                         self.chatOpenButton.center = CGPointMake(self.view.center.x, self.chatOpenButton.center.y);
                         self.chatTextField.frame = CGRectMake(51, 113, 877, 30);
                         self.chatView.frame = CGRectMake(0, 616, 1024, 152);
                         self.chatTable.frame = CGRectMake(0, 616, self.view.frame.size.width, 103);
                         self.chatFadeImage.center = CGPointMake(self.view.center.x,self.chatFadeImage.center.y);
                         self.sendMessageButton.frame = CGRectMake(936, 112, 80, 30);
                         
                         boardButton.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         
                         boardButton.hidden = true;
                         
                         if (self.userRole > 0) [self showDrawMenu];
                     }
     ];
}

- (IBAction)editTapped:(id)sender {
    
    self.editing = true;
    
    [self.draggableCollectionView reloadData];
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    if ([self.boardNameEditButton isFirstResponder]) [self.boardNameEditButton resignFirstResponder];
    
    self.editBoardIDs = [self.boardIDs mutableCopy];
    
    self.editProjectNameTextField.placeholder = self.projectName;
    
    self.projectNameLabel.hidden = true;
    self.editButton.hidden = true;
    self.carousel.hidden = true;
    self.draggableCollectionView.hidden = false;
    self.boardNameLabel.hidden = true;
    self.addBoardButton.hidden = true;
    self.addBoardBackgroundImage.hidden = true;
    
    self.editProjectNameTextField.hidden = false;
    self.editBoardNameTextField.hidden = true;
    self.boardNameEditButton.hidden = true;
    self.applyChangesButton.hidden = false;
    self.cancelButton.hidden = false;
    
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
}

- (IBAction)boardNameEditTapped:(id)sender {
    
    self.editBoardNameTextField.hidden = false;
    self.boardNameLabel.hidden = true;
    self.boardNameEditButton.hidden = true;
    
    self.editBoardNameTextField.placeholder = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"name"];
    
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
    
    [self cancelTapped:nil];
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info", [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    if (self.editProjectNameTextField.text.length > 0) {
        
        NSString *newName = self.editProjectNameTextField.text;
        self.projectNameLabel.text = newName;
        
        [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:newName forKey:@"name"];
        
        [self.masterView updateProjects];        
        self.masterView.defaultRow = [NSIndexPath indexPathForRow:[self.masterView.orderedProjectNames indexOfObject:newName] inSection:0];
        
        [[ref childByAppendingPath:@"name"] setValue:newName];
        self.editProjectNameTextField.text = nil;
    }
    
    if (![self.editBoardIDs isEqualToArray:self.boardIDs]) {
        
        NSMutableDictionary *boardsDict = [NSMutableDictionary dictionary];
        
        for (int i=0; i<self.editBoardIDs.count; i++) {
            
            [boardsDict setObject:self.editBoardIDs[i] forKey:[@(i) stringValue]];
        }
        
        [[ref childByAppendingPath:@"boards"] setValue:boardsDict];
        
        [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:boardsDict forKey:@"boards"];
        
        self.boardIDs = [self.editBoardIDs mutableCopy];
        
        if (self.boardIDs.count == 0) [self createBoard];
        
        [self.carousel reloadData];
    }
}

- (IBAction)cancelTapped:(id)sender {
    
    self.projectNameLabel.hidden = false;
    self.editButton.hidden = false;
    self.carousel.hidden = false;
    self.draggableCollectionView.hidden = true;
    self.boardNameLabel.hidden = false;
    if (self.editing) self.boardNameEditButton.hidden = false;
    self.addBoardButton.hidden = false;
    self.addBoardBackgroundImage.hidden = false;
    
    self.editProjectNameTextField.hidden = true;
    self.editBoardNameTextField.hidden = true;
    self.applyChangesButton.hidden = true;
    self.cancelButton.hidden = true;
    
    self.chatFadeImage.hidden = false;
    self.chatView.hidden = false;
    self.chatTextField.hidden = false;
    self.chatTable.hidden = false;
    self.chatOpenButton.hidden = false;
    
    self.editing = false;
}

-(void)closeTapped:(id)sender {
    
    boardButton.hidden = false;
    self.currentBoardView.commenting = false;
    commentsOpen = false;
    
    [self hideDrawMenu];
    
    UIButton *closeButton = (UIButton *)[self.view viewWithTag:100];
    closeButton.hidden = true;

    self.activeBoardID = nil;
    self.activeCommentThreadID = nil;
    
    [[FirebaseHelper sharedHelper] setInBoard:@"none"];
    
    [self.currentBoardView.activeUserIDs removeObject:[FirebaseHelper sharedHelper].uid];
    [self.currentBoardView layoutAvatars];
    self.currentBoardView.selectedAvatarUserID = nil;
    [self drawBoard:self.currentBoardView];
    self.currentBoardView = nil;
    
    [self.view bringSubviewToFront:self.masterView];
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    
    [UIView animateWithDuration:.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        
                        float masterWidth = self.masterView.frame.size.width;
                         
                        self.chatTextField.frame = CGRectMake(51, 113, 667, 30);
                        self.chatTable.frame = CGRectMake(masterWidth, 616, self.view.frame.size.width, 103);
                        self.chatView.frame = CGRectMake(masterWidth, 616, 814, 152);
                        self.sendMessageButton.frame = CGRectMake(726, 112, 80, 30);
                        self.chatOpenButton.center = CGPointMake(self.chatView.center.x, 602);
                        self.chatFadeImage.frame = CGRectMake(210, 610, 1024, 25);
                        
                        
                        CGAffineTransform tr = CGAffineTransformScale(self.carousel.transform, .5, .5);
                        self.carousel.transform = tr;
                        self.carousel.center = CGPointMake(self.view.center.x+masterWidth/2, self.view.frame.size.height/2-56);
                        
                        self.masterView.center = CGPointMake(masterWidth/2, self.masterView.center.y);

                        boardButton.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         
                         [self showChat];
                         [self.view bringSubviewToFront:self.addBoardBackgroundImage];
                         [self.view bringSubviewToFront:self.addBoardButton];
                         
                         [self updateDetails];
                         
                         [self.carousel setScrollEnabled:YES];
                         
                         [self.masterView.projectsTable reloadData];
                         [self.masterView.projectsTable selectRowAtIndexPath:self.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
                     }
     ];
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
        
        [undoDict setObject:self.activeBoardUndoIndexDate forKey:@"currentIndexDate"];
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", self.currentBoardView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [ref setValue:undoDict];
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
        
        [undoDict setObject:self.activeBoardUndoIndexDate forKey:@"currentIndexDate"];
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@/", self.currentBoardView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [ref setValue:undoDict];
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
}

-(void) eraseTapped:(id)sender {

    self.currentBoardView.commenting = false;
    self.erasing = true;
    
    UIButton *eraseButton = (UIButton *)[self.view viewWithTag:5];
    CGPoint centerPoint = eraseButton.center;
    UIImage *buttonImage = [UIImage imageNamed:@"eraseselected.png"];
    
    [eraseButton setImage:buttonImage forState:UIControlStateNormal];
    eraseButton.frame = CGRectMake(0, 0, buttonImage.size.width*.1, buttonImage.size.height*.1);
    eraseButton.center = centerPoint;

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
    
    UIButton *widthButton = (UIButton *)sender;
    
    PenTypePopoverViewController *penTypePopover = [[PenTypePopoverViewController alloc] init];
    
    [penTypePopover setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popover = [penTypePopover popoverPresentationController];
    popover.sourceView = widthButton;
    popover.sourceRect = widthButton.bounds;
    popover.backgroundColor = nil;
    popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
    
    [self presentViewController:penTypePopover animated:NO completion:nil];
}

-(void) commentTapped:(id)sender {
    
    self.currentBoardView.commenting = true;
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
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)openChatTapped:(id)sender {
    
    if (!self.activeBoardID) {
        
        if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
        else [self.chatTextField becomeFirstResponder];
    }
    else [self openComments];
}

-(void)openComments {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    if (commentsOpen) self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y+keyboardDiff);
    else self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y-keyboardDiff);
    
    CGRect chatTableRect = self.chatTable.frame;
    if (commentsOpen) {
        chatTableRect.size.height -= keyboardDiff;
        chatTableRect.origin.y += keyboardDiff;
    }
    else {
        chatTableRect.size.height += keyboardDiff;
        chatTableRect.origin.y -= keyboardDiff;
    }
    self.chatTable.frame = chatTableRect;
    
    if (!commentsOpen) self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-keyboardDiff);
    else self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+keyboardDiff);
    
    [self.view bringSubviewToFront:self.chatOpenButton];
    
    [UIView commitAnimations];
    
    commentsOpen = !commentsOpen;
    
    if (commentsOpen) [self.chatOpenButton setImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
    else [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
}

-(void)keyboardWillShow:(NSNotification *)notification {
    
//    if ([self.editBoardNameTextField isFirstResponder]) {
//        
//        self.boardNameEditButton.hidden = true;
//        //self.boardNameLabel.hidden = true;
//        
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
//        [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
//        [UIView setAnimationBeginsFromCurrentState:YES];
//        
//        self.boardNameLabel.center = CGPointMake(self.boardNameLabel.center.x, 110);
//        self.editBoardNameTextField.center = CGPointMake(self.editBoardNameTextField.center.x, 110);
//        
//        [UIView commitAnimations];
//    }
    
    if ([self.chatTextField isFirstResponder]) {
    
        [self showChat];
        
        CGFloat height = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
        keyboardDiff = 522-height;
        
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
        
        if (!self.activeBoardID) {
            [self.chatOpenButton setImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
            self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-(height+keyboardDiff));
        }
        else {
            [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
            self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-height);
        }
        
        [self.view bringSubviewToFront:self.chatOpenButton];
        
        [UIView commitAnimations];
    }
}

-(void)keyboardWillHide:(NSNotification *)notification {

    if ([self.boardNameEditButton isFirstResponder]) {
        
        self.editBoardNameTextField.hidden = true;
        self.boardNameLabel.hidden = false;
        self.boardNameEditButton.hidden = false;
    }
    
//    if ([self.editBoardNameTextField isFirstResponder]) {
//        
//        self.boardNameEditButton.hidden = false;
//        self.editBoardNameTextField.hidden = true;
//        
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
//        [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
//        [UIView setAnimationBeginsFromCurrentState:YES];
//        
//        self.boardNameLabel.center = CGPointMake(self.carousel.center.x, 540);
//        self.editBoardNameTextField.center = CGPointMake(self.editBoardNameTextField.center.x, 540);
//        
//        [UIView commitAnimations];
//    }
    
    if ([self.chatTextField isFirstResponder]) {
    
        CGFloat height = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
        keyboardDiff = 522-height;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        CGRect viewRect = self.chatView.frame;
        viewRect.origin.y += height;
        self.chatView.frame = viewRect;
        
        CGRect projectsTableRect = self.masterView.projectsTable.frame;
        projectsTableRect.size.height += (height-keyboardDiff);
        self.masterView.projectsTable.frame = projectsTableRect;
        
        CGRect fadeRect = self.chatFadeImage.frame;
        if(self.activeBoardID == nil) fadeRect.origin.y += (height+keyboardDiff);
        else fadeRect.origin.y += height;
        self.chatFadeImage.frame = fadeRect;
        
        CGRect chatTableRect = self.chatTable.frame;
        if (self.activeBoardID == nil) {
            chatTableRect.size.height -= keyboardDiff;
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
        
        if (self.activeBoardID) self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+height);
        else self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+(height+keyboardDiff));
        
        if (commentsOpen) [self openComments];
        
        [self.view bringSubviewToFront:self.chatOpenButton];
        
        [UIView commitAnimations];
        
        [self.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
        
    }
}

#pragma mark -
#pragma mark iCarousel methods

- (CATransform3D)carousel:(iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    CGFloat MAX_SCALE = 1.25f; //max scale of center item
    CGFloat MAX_SHIFT = 25.0f; //amount to shift items to keep spacing the same
    
    CGFloat shift = fminf(1.0f, fmaxf(-1.0f, offset));
    CGFloat scale = 1.0f + (1.0f - fabs(shift)) * (MAX_SCALE - 1.0f);
    transform = CATransform3DTranslate(transform, offset * _carousel.itemWidth * 1.08f + shift * MAX_SHIFT, 0.0f, 0.0f);
    return CATransform3DScale(transform, scale, scale, scale);
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return self.boardIDs.count;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    if (view == nil) {
        
        BoardView *boardView = [[BoardView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
        view = boardView;
        CGAffineTransform tr = view.transform;
        tr = CGAffineTransformScale(tr, .5, .5);
        tr = CGAffineTransformRotate(tr, M_PI_2);
        view.transform = tr;
    }
    
    UIImage *gradientImage = [UIImage imageNamed:@"board7.png"];
    UIButton *gradientButton = [UIButton buttonWithType:UIButtonTypeCustom];
    gradientButton.frame = CGRectMake(0.0f, 0.0f, gradientImage.size.width, gradientImage.size.height);
    gradientButton.center = view.center;
    gradientButton.adjustsImageWhenHighlighted = NO;
    [gradientButton setBackgroundImage:gradientImage forState:UIControlStateNormal];
    [gradientButton addTarget:self action:@selector(boardTapped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:gradientButton];
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
        self.boardNameEditButton.hidden = false;
    }
    else self.boardNameEditButton.hidden = true;
    
    
    double viewedAt = [[[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid] doubleValue];
    double updatedAt = [[boardDict objectForKey:@"updatedAt"] doubleValue];
    
    UIFont *labelFont;
    
    if (updatedAt > viewedAt && ![self.viewedBoardIDs containsObject:boardID] && !newBoardCreated)
        labelFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:24];
    else
        labelFont = [UIFont fontWithName:@"SourceSansPro-Light" size:24];
    
    self.boardNameLabel.font = labelFont;
    [self.boardNameLabel sizeToFit];
    self.boardNameLabel.center = CGPointMake(self.carousel.center.x, self.boardNameLabel.center.y);

    self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+20, self.boardNameLabel.center.y);
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{

    if ([self.chatTextField isFirstResponder]) {
        [self.chatTextField resignFirstResponder];
        self.activeCommentThreadID = nil;
    }
    if ([self.editBoardNameTextField isFirstResponder]) {
        [self.editBoardNameTextField resignFirstResponder];
    }
    if ([self.editProjectNameTextField isFirstResponder]) {
        [self.editProjectNameTextField resignFirstResponder];
    }
}

#pragma mark - Text field handling

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    
    if ([textField isEqual:self.chatTextField]) {
        
        NSString *chatString;
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        
        if (self.activeCommentThreadID) {
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.currentBoardView.boardID] objectForKey:@"commentsID"];
            chatString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@/%@/messages", commentsID, self.activeCommentThreadID];
        }
        else chatString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/chats/%@", self.chatID];
        
        Firebase *chatRef = [[Firebase alloc] initWithUrl:chatString];
        NSDictionary *messageDict = @{ @"name" : [FirebaseHelper sharedHelper].userName ,
                                       @"message" : textField.text,
                                       @"sentAt" : dateString
                                       };
        [[chatRef childByAutoId] setValue:messageDict];
        
        [[FirebaseHelper sharedHelper] setProjectUpdatedAt];
        
        self.chatTextField.text = nil;
    }
    
    if ([textField isEqual:self.editBoardNameTextField]) {
        
        [textField resignFirstResponder];
        
        NSString *boardNameString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/name", self.boardIDs[self.carousel.currentItemIndex]];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardNameString];
        [ref setValue:self.editBoardNameTextField.text];
        [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] setObject:self.editBoardNameTextField.text forKey:@"name"];
        
        self.boardNameLabel.text = self.editBoardNameTextField.text;
        [self.boardNameLabel sizeToFit];
        self.boardNameLabel.center = CGPointMake(self.carousel.center.x, self.boardNameLabel.center.y);
        
        self.boardNameEditButton.center = CGPointMake(self.carousel.center.x+self.boardNameLabel.frame.size.width/2+20, self.boardNameLabel.center.y);
        
        self.editBoardNameTextField.text = nil;
        
        [self cancelTapped:nil];
    }
    
    return NO;
}

#pragma mark - Chat table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *messageString = self.messages[self.messages.count-(indexPath.row+1)];
    
    CGRect labelRect = [messageString boundingRectWithSize:CGSizeMake(self.chatTable.frame.size.width,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Light" size:20]} context:nil];
    
    return labelRect.size.height+20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell" forIndexPath:indexPath];
    
    if (self.messages.count > indexPath.row) {
        
        cell.textLabel.text = self.messages[self.messages.count-(indexPath.row+1)];
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

@end
