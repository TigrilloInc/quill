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

@implementation ProjectDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.chatTextField.delegate = self;
    self.editBoardNameTextField.delegate = self;
    self.carousel.delegate = self;
    
    self.carousel.type = iCarouselTypeCoverFlow2;
    self.carousel.bounceDistance = 0.1f;
    
    UIImageView *carouselFadeLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"carouselfade.png"]];
    [self.masterView addSubview:carouselFadeLeft];
    carouselFadeLeft.center = CGPointMake(295, 340);

    carouselFadeRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"carouselfade.png"]];
    [self.view addSubview:carouselFadeRight];
    carouselFadeRight.transform = CGAffineTransformMakeRotation(M_PI);
    carouselFadeRight.center = CGPointMake(974, 340);
    
    //self.nameLabel.font = [UIFont fontWithName:@"ZemestroStd-Bk" size:40];
    //self.chatTextField.font = [UIFont fontWithName:@"ZemestroStd-Bk" size:20];
    self.chatTable.transform = CGAffineTransformMakeRotation(M_PI);
    
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
    [closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    closeButton.hidden = true;
    [self.view addSubview:closeButton];
    closeButton.tag = 1;
    
    UIButton *undoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    undoButton.frame = CGRectMake(30, 680, 80, 80);
    [undoButton setTitle:@"Undo" forState:UIControlStateNormal];
    [undoButton addTarget:self action:@selector(undoTapped) forControlEvents:UIControlEventTouchUpInside];
    undoButton.hidden = true;
    [self.view addSubview:undoButton];
    undoButton.tag = 3;
    
    UIButton *redoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    redoButton.frame = CGRectMake(110, 680, 80, 80);
    [redoButton setTitle:@"Redo" forState:UIControlStateNormal];
    [redoButton addTarget:self action:@selector(redoTapped) forControlEvents:UIControlEventTouchUpInside];
    redoButton.hidden = true;
    [self.view addSubview:redoButton];
    redoButton.tag = 4;
    
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    clearButton.frame = CGRectMake(190, 680, 80, 80);
    [clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearTapped) forControlEvents:UIControlEventTouchUpInside];
    clearButton.hidden = true;
    [self.view addSubview:clearButton];
    clearButton.tag = 6;
    
    UIButton *eraseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    eraseButton.frame = CGRectMake(270, 680, 80, 80);
    [eraseButton setTitle:@"Erase" forState:UIControlStateNormal];
    [eraseButton addTarget:self action:@selector(eraseTapped) forControlEvents:UIControlEventTouchUpInside];
    eraseButton.hidden = true;
    [self.view addSubview:eraseButton];
    eraseButton.tag = 7;
    
    UIButton *drawButton = [UIButton buttonWithType:UIButtonTypeSystem];
    drawButton.frame = CGRectMake(350, 680, 80, 80);
    [drawButton setTitle:@"Draw" forState:UIControlStateNormal];
    [drawButton addTarget:self action:@selector(drawTapped) forControlEvents:UIControlEventTouchUpInside];
    drawButton.hidden = true;
    [self.view addSubview:drawButton];
    drawButton.tag = 8;
    
    UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    commentButton.frame = CGRectMake(430, 680, 80, 80);
    [commentButton setTitle:@"Comment" forState:UIControlStateNormal];
    [commentButton addTarget:self action:@selector(commentTapped) forControlEvents:UIControlEventTouchUpInside];
    commentButton.hidden = true;
    [self.view addSubview:commentButton];
    commentButton.tag = 9;
    
}

-(void) showDrawMenu {
    
    UIButton *closeButton = (UIButton *)[self.view viewWithTag:1];
    closeButton.hidden = false;
    [self.view bringSubviewToFront:closeButton];
    
    UIButton *undoButton = (UIButton *)[self.view viewWithTag:3];
    undoButton.hidden = false;
    [self.view bringSubviewToFront:undoButton];
    
    UIButton *redoButton = (UIButton *)[self.view viewWithTag:4];
    redoButton.hidden = false;
    [self.view bringSubviewToFront:redoButton];
    
    UIButton *clearButton = (UIButton *)[self.view viewWithTag:6];
    clearButton.hidden = false;
    [self.view bringSubviewToFront:clearButton];
    
    UIButton *eraseButton = (UIButton *)[self.view viewWithTag:7];
    eraseButton.hidden = false;
    [self.view bringSubviewToFront:eraseButton];
    
    UIButton *drawButton = (UIButton *)[self.view viewWithTag:8];
    drawButton.hidden = false;
    [self.view bringSubviewToFront:drawButton];
    
    UIButton *commentButton = (UIButton *)[self.view viewWithTag:9];
    commentButton.hidden = false;
    [self.view bringSubviewToFront:commentButton];
}

-(void) hideDrawMenu {
    
    UIButton *closeButton = (UIButton *)[self.view viewWithTag:1];
    closeButton.hidden = true;
    UIButton *undoButton = (UIButton *)[self.view viewWithTag:3];
    undoButton.hidden = true;
    UIButton *redoButton = (UIButton *)[self.view viewWithTag:4];
    redoButton.hidden = true;
    UIButton *clearButton = (UIButton *)[self.view viewWithTag:6];
    clearButton.hidden = true;
    UIButton *eraseButton = (UIButton *)[self.view viewWithTag:7];
    eraseButton.hidden = true;
    UIButton *drawButton = (UIButton *)[self.view viewWithTag:8];
    drawButton.hidden = true;
    UIButton *commentButton = (UIButton *)[self.view viewWithTag:9];
    commentButton.hidden = true;
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
}

-(void) updateDetails {
    
    self.projectNameLabel.text = self.projectName;
    [self.projectNameLabel sizeToFit];
    self.editButton.center = CGPointMake(self.projectNameLabel.frame.size.width+310, self.editButton.center.y);
    
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
        
        NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
        messageKeys = [[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] allKeys];
    }
    else messageKeys = [[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] allKeys];
    
    for (NSString *messageID in messageKeys) {
        
        NSString *date;
        
        if (self.activeCommentThreadID != nil) {
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
            
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
        if (![self.chatTextField isFirstResponder]) [self.chatOpenButton setTitle:@"OPEN" forState:UIControlStateNormal];
    }
    
    for (NSString *messageID in messageKeys) {
        
        NSString *date;
        
        if (self.activeCommentThreadID){
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
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
                    
                    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
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
    
    for (AvatarButton *avatar in self.avatars) {
        [avatar removeFromSuperview];
    }
    
    self.avatars = [NSMutableArray array];
    
    NSArray *userIDs = [self.roles.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for (int i=0; i<userIDs.count; i++) {
        
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.userID = userIDs[i];
        NSNumber *imageNumber = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"avatar"];
        NSString *imageString;
        if (imageNumber) imageString = [NSString stringWithFormat:@"user%@.png", imageNumber];
        else imageString = @"user.png";
        UIImage *image = [UIImage imageNamed:imageString];
        if(imageNumber != nil) [avatar setImage:image forState:UIControlStateNormal];
        avatar.frame = CGRectMake(870-(i*64), -60, image.size.width, image.size.height);
        [avatar addTarget:self action:@selector(avatarTapped:) forControlEvents:UIControlEventTouchUpInside];
        avatar.transform = CGAffineTransformScale(avatar.transform, .25, .25);
        [self.view addSubview:avatar];
        
        if (![[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"inProject"] isEqualToString:[FirebaseHelper sharedHelper].currentProjectID]) {
            avatar.alpha = 0.5;
        }
        
        self.addUserButton.center = CGPointMake(990-(userIDs.count*64), self.addUserButton.center.y);
        
        [self.view bringSubviewToFront:avatar];
        [self.avatars addObject:avatar];
    }
}

-(void) drawBoard:(DrawView *)drawView {
    
    [drawView clear];
    
    drawView.loadingView.hidden = true;
    if (![[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:drawView.boardID]) [[FirebaseHelper sharedHelper].loadedBoardIDs addObject:drawView.boardID];
    
    NSDictionary *allSubpathsDict = [[[FirebaseHelper sharedHelper].boards objectForKey:drawView.boardID] objectForKey:@"allSubpaths"];
    
    NSDictionary *dictRef = [[[FirebaseHelper sharedHelper].boards objectForKey:drawView.boardID] objectForKey:@"undo"];
    NSMutableDictionary *undoDict = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)dictRef, kCFPropertyListMutableContainers));
    
    NSMutableDictionary *subpathsToDraw = [NSMutableDictionary dictionary];
    
    for (NSString *uid in allSubpathsDict.allKeys) {
        
        NSDictionary *uidDict = [allSubpathsDict objectForKey:uid];
        
        NSMutableArray *userOrderedKeys = [uidDict.allKeys mutableCopy];
        NSSortDescriptor *descendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        [userOrderedKeys sortUsingDescriptors:@[descendingSorter]];
        
        BOOL undone = false;
        BOOL cleared = false;
        
        for (int i=0; i<userOrderedKeys.count; i++) {
            
            NSMutableDictionary *subpathValues = [[uidDict objectForKey:(NSString *)userOrderedKeys[i]] mutableCopy];
            
            if ([subpathValues respondsToSelector:@selector(objectForKey:)]){
                
                if (drawView.selectedAvatarUserID != nil && ![uid isEqualToString:drawView.selectedAvatarUserID]) [subpathValues setObject:@1 forKey:@"faded"];
                if (!undone && !cleared) [subpathsToDraw setObject:subpathValues forKey:userOrderedKeys[i]];
                
            } else if ([[uidDict objectForKey:(NSString *)userOrderedKeys[i]] respondsToSelector:@selector(isEqualToString:)]) {
                
                if ([[uidDict objectForKey:(NSString *)userOrderedKeys[i]] isEqualToString:@"penUp"]) {
                    
                    int undoCount = [(NSNumber *)[[undoDict objectForKey:uid] objectForKey:@"currentIndex"] intValue];
                    
                    if (undoCount > 0) {
                        
                        undone = true;
                        undoCount--;

                        [[undoDict objectForKey:uid] setObject:@(undoCount) forKey:@"currentIndex"];

                    } else {
                        
                        if (undone) {
                            
                            self.activeBoardUndoIndexDate = userOrderedKeys[i];

                        }
                        undone = false;
                    }
                    
                } else if ([[uidDict objectForKey:(NSString *)userOrderedKeys[i]] isEqualToString:@"clear"]) {
                    
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
        [drawView drawSubpath:subpathDict];
    }
    
}

- (IBAction)sendTapped:(id)sender {
    
    [self textFieldShouldReturn:self.chatTextField];
    
}

-(void) boardTapped:(id)sender {
    
    if (self.carouselMoving) {
        [self.carousel scrollToItemAtIndex:self.carousel.currentItemIndex animated:YES];
        return;
    }
    
    newBoardCreated = false;
    [self.carousel setScrollEnabled:NO];
    self.carouselOffset = 0;
    UIButton *button = (UIButton *)sender;
    currentDrawView = (DrawView *)button.superview;
    NSString *boardID = currentDrawView.boardID;
    self.boardNameLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [self.viewedBoardIDs addObject:boardID];
    boardButton = button;
    self.activeBoardID = boardID;
    
    [[FirebaseHelper sharedHelper] setInBoard];

    [currentDrawView.activeUserIDs addObject:[FirebaseHelper sharedHelper].uid];
    [currentDrawView layoutAvatars];
    
    self.chatTextField.placeholder = @"Leave a comment...";
    
    [self hideChat];
    
    for (AvatarButton *avatar in self.avatars) {
        
        [self.view sendSubviewToBack:avatar];
    }
    
    [UIView animateWithDuration:.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         self.carousel.center = CGPointMake(self.view.center.x, self.view.center.y);
                         CGAffineTransform tr = CGAffineTransformScale(self.carousel.transform, 2, 2);
                         self.carousel.transform = tr;
                         
                         self.masterView.center = CGPointMake(-200, self.masterView.center.y);
                         carouselFadeRight.center = CGPointMake(1174, carouselFadeRight.center.y);
                         
                         self.chatOpenButton.center = CGPointMake(self.view.center.x, self.chatOpenButton.center.y);
                         self.chatTextField.frame = CGRectMake(52, 102, 880, 30);
                         self.chatView.frame = CGRectMake(0, 626, 1024, 142);
                         self.chatTable.frame = CGRectMake(0, 768-self.chatView.frame.size.height, self.view.frame.size.width, self.chatTable.frame.size.height);
                         self.chatFadeImage.center = CGPointMake(self.view.center.x-100,self.chatFadeImage.center.y);
                         self.sendMessageButton.frame = CGRectMake(952, 102, 45, 30);
                         
                         boardButton.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         
                         boardButton.hidden = true;
                         
                         if (self.userRole > 0) [self showDrawMenu];
                     }
     ];
}

- (IBAction)editTapped:(id)sender {
    
    [self.draggableCollectionView reloadData];
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    if ([self.boardNameEditButton isFirstResponder]) [self.boardNameEditButton resignFirstResponder];
    
    self.editBoardIDs = [self.boardIDs mutableCopy];
    
    self.editProjectNameTextField.placeholder = self.projectName;
    
    self.editButton.hidden = true;
    self.carousel.hidden = true;
    self.draggableCollectionView.hidden = false;
    self.boardNameLabel.hidden = true;
    self.addBoardButton.hidden = true;
    
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
    
    [self presentViewController:avatarPopover animated:YES completion:nil];
}

-(IBAction) applyChangesTapped:(id)sender {
    
    [self cancelTapped:nil];
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info", [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    if (self.editProjectNameTextField.text.length > 0) {
        
        NSString *newName = self.editProjectNameTextField.text;
        
        [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:newName forKey:@"name"];
        
        [self.masterView updateProjects];        
        self.masterView.defaultRow = [NSIndexPath indexPathForRow:[self.masterView.orderedProjectNames indexOfObject:newName] inSection:0];
        
        [[ref childByAppendingPath:@"name"] setValue:newName];
        
    }
    
    if (![self.editBoardIDs isEqualToArray:self.boardIDs]) {
        
        NSMutableDictionary *boardsDict = [NSMutableDictionary dictionary];
        
        for (int i=0; i<self.editBoardIDs.count; i++) {
            
            [boardsDict setObject:self.editBoardIDs[i] forKey:[@(i) stringValue]];
        }
        
        [[ref childByAppendingPath:@"boards"] setValue:boardsDict];
        
        [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:boardsDict forKey:@"boards"];
        
        self.boardIDs = [self.editBoardIDs mutableCopy];
        
        [self.carousel reloadData];
    }
}

- (IBAction)cancelTapped:(id)sender {
    
    self.editButton.hidden = false;
    self.carousel.hidden = false;
    self.draggableCollectionView.hidden = true;
    self.boardNameLabel.hidden = false;
    self.addBoardButton.hidden = false;
    
    self.editProjectNameTextField.hidden = true;
    self.editBoardNameTextField.hidden = true;
    self.boardNameEditButton.hidden = false;
    self.applyChangesButton.hidden = true;
    self.cancelButton.hidden = true;
    
    self.chatFadeImage.hidden = false;
    self.chatView.hidden = false;
    self.chatTextField.hidden = false;
    self.chatTable.hidden = false;
    self.chatOpenButton.hidden = false;
}

-(void)closeTapped {
    
    boardButton.hidden = false;
    
    commentsOpen = false;
    
    [self hideDrawMenu];
    
    UIButton *closeButton = (UIButton *)[self.view viewWithTag:1];
    closeButton.hidden = true;

    self.activeBoardID = nil;
    self.activeCommentThreadID = nil;
    
    [[FirebaseHelper sharedHelper] setInBoard];
    
    [currentDrawView.activeUserIDs removeObject:[FirebaseHelper sharedHelper].uid];
    [currentDrawView layoutAvatars];
    currentDrawView.selectedAvatarUserID = nil;
    [self drawBoard:currentDrawView];
    currentDrawView = nil;
    
    [self.view bringSubviewToFront:self.masterView];
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    
    [UIView animateWithDuration:.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        
                        float masterWidth = self.masterView.frame.size.width;
                         
                        self.chatTextField.frame = CGRectMake(52, 102, 622, 30);
                        self.chatView.frame = CGRectMake(245,626,779,142);
                        self.sendMessageButton.frame = CGRectMake(709, 102, 45, 30);
                         self.chatOpenButton.frame = CGRectMake(512, 601, 260, 49);
                        self.chatFadeImage.frame = CGRectMake(245, 614, 1024, 25);
                        self.chatTable.frame = CGRectMake(masterWidth, 626, 779, 89);
                        
                         CGAffineTransform tr = CGAffineTransformScale(self.carousel.transform, .5, .5);
                         self.carousel.transform = tr;
                         self.carousel.center = CGPointMake(self.view.center.x+masterWidth/2, self.view.frame.size.height/2-64);
                        
                        self.masterView.center = CGPointMake(masterWidth/2, self.masterView.center.y);
                        carouselFadeRight.center = CGPointMake(974, carouselFadeRight.center.y);
                        [self.view bringSubviewToFront:carouselFadeRight];
                         
                        boardButton.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         
                         [self showChat];
                         
                         [self updateDetails];
                         
                         [self.carousel reloadData];
                         [self.carousel setScrollEnabled:YES];
                         
                         [self.masterView.projectsTable reloadData];
                         [self.masterView.projectsTable selectRowAtIndexPath:self.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
                     }];
}

- (void) undoTapped {
    
    int undoCount = [(NSNumber *)[[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    int undoTotal = [(NSNumber *)[[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"total"] intValue];
    
    if (undoCount < undoTotal)  {
        
        undoCount++;
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", currentDrawView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [[ref childByAppendingPath:@"currentIndex"] setValue:@(undoCount)];
        [[ref childByAppendingPath:@"currentIndexDate"] setValue:self.activeBoardUndoIndexDate];
        
        [self drawBoard:currentDrawView];
        
        NSMutableDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
        [undoDict setObject:@(undoCount) forKey:@"currentIndex"];
        [undoDict setObject:self.activeBoardUndoIndexDate forKey:@"currentIndexDate"];
        
    }
}

- (void) redoTapped {
    
    int undoCount = [(NSNumber *)[[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    
    if (undoCount > 0) {
        
        undoCount--;
        
        [[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@(undoCount) forKey:@"currentIndex"];
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@/currentIndex", currentDrawView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [ref setValue:@(undoCount)];
        
        [self drawBoard:currentDrawView];
    }
    
    if (undoCount == 0) {
        
        NSDictionary *allSubpathsDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"allSubpaths"] objectForKey:[FirebaseHelper sharedHelper].uid];
        
        NSMutableArray *orderedKeys = [allSubpathsDict.allKeys mutableCopy];
        NSSortDescriptor *descendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        [orderedKeys sortUsingDescriptors:@[descendingSorter]];
        
        self.activeBoardUndoIndexDate = orderedKeys[0];
        
        if (self.activeBoardID != nil) {
            
            NSString *currentIndexDateString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@/currentIndexDate", self.activeBoardID, [FirebaseHelper sharedHelper].uid];
            Firebase *ref = [[Firebase alloc] initWithUrl:currentIndexDateString];
            [ref setValue:self.activeBoardUndoIndexDate];
            
            [[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.activeBoardUndoIndexDate forKey:@"currentIndexDate"];
        }
    }
}

- (void) clearTapped {
    
    [[FirebaseHelper sharedHelper] resetUndo];
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSString *refString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", currentDrawView.boardID];
    Firebase *ref = [[Firebase alloc] initWithUrl:refString];
    NSDictionary *clearDict = @{ dateString  :  @"clear" };
    NSString *allSubpathsString = [NSString stringWithFormat:@"allSubpaths/%@", [FirebaseHelper sharedHelper].uid];
    [[ref childByAppendingPath:allSubpathsString] updateChildValues:clearDict];
    
    [[ref childByAppendingPath:@"lastSubpath"] setValue:@{ @"clear" : [FirebaseHelper sharedHelper].uid }];
    
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"allSubpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@"clear" forKey:dateString];
    
    [currentDrawView touchesEnded:nil withEvent:nil];
    
    [currentDrawView clear];
}

-(void) eraseTapped {
    
    currentDrawView.lineWidth = 150.0f;
    currentDrawView.lineColorNumber = @0;
}

-(void) drawTapped {
    
    currentDrawView.lineWidth = (arc4random() % 50) + 5;
    currentDrawView.lineColorNumber = @((arc4random() % 4) + 1);
}

-(void) commentTapped {
    
    currentDrawView.commenting = true;
}

- (IBAction)newBoardTapped:(id)sender {
    
    newBoardCreated = true;
    
    Firebase *boardRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/boards"];
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info/boards", [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    
    Firebase *commentsRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/comments"];
    Firebase *commentsRefWithID = [commentsRef childByAutoId];
    NSString *commentsID = commentsRefWithID.name;
    
    NSMutableDictionary *allSubpathsDict = [NSMutableDictionary dictionary];
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    for (NSString *uid in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        [allSubpathsDict setObject:[@{ dateString : @"penUp"} mutableCopy] forKey: uid];
    }
    
    NSString *boardNum = [NSString stringWithFormat:@"%lu", (unsigned long)self.boardIDs.count];
    NSDictionary *boardDict =  @{ @"name" : @"Untitled",
                                  @"project" : self.projectName,
                                  @"number" : boardNum,
                                  @"commentsID" : commentsID,
                                  @"lastSubpath" : [NSMutableDictionary dictionary],
                                  @"allSubpaths" : allSubpathsDict,
                                  @"updatedAt" : dateString,
                                  @"undo" :
                                      @{ [FirebaseHelper sharedHelper].uid :
                                             [@{ @"currentIndex" : @0,
                                                 @"total" : @0
                                                 } mutableCopy]
                                         }
                                  };
    
    Firebase *boardRefWithID = [boardRef childByAutoId];
    [boardRefWithID updateChildValues:boardDict];
    
    [projectRef updateChildValues:@{ boardNum : boardRefWithID.name }];
    
    self.activeBoardID = boardRefWithID.name;
    
    [self.boardIDs addObject:self.activeBoardID];
    
    [[FirebaseHelper sharedHelper].boards setObject:[boardDict mutableCopy] forKey:self.activeBoardID];
    [[[FirebaseHelper sharedHelper].projects objectForKey:@"boards"] setObject:self.activeBoardID forKey:boardNum];
    
    [[FirebaseHelper sharedHelper] observeBoardWithID:self.activeBoardID];
    
    [self.carousel reloadData];
    
    [self.carousel scrollByNumberOfItems:self.carousel.numberOfItems duration:.5];
    
}

- (IBAction)addUserTapped:(id)sender {
    
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
    
    if (commentsOpen) [self.chatOpenButton setTitle:@"v" forState:UIControlStateNormal];
    else [self.chatOpenButton setTitle:@"^" forState:UIControlStateNormal];
}

-(void)keyboardWillShow:(NSNotification *)notification {
    
    if (![self.chatTextField isFirstResponder]) return;
    
    [self showChat];
    
    CGFloat height = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    keyboardDiff = 530-height;
    
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
        
        for (AvatarButton *avatar in currentDrawView.avatarButtons) {
            
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
        [self.chatOpenButton setTitle:@"CLOSE" forState:UIControlStateNormal];
        self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-(height+keyboardDiff));
    }
    else {
        [self.chatOpenButton setTitle:@"^" forState:UIControlStateNormal];
        self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-height);
    }
    
    [self.view bringSubviewToFront:self.chatOpenButton];
    
    [UIView commitAnimations];
    
}

-(void)keyboardWillHide:(NSNotification *)notification {
    
    //[self hideChat];
    
    if (![self.chatTextField isFirstResponder]) return;
    
    CGFloat height = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    keyboardDiff = 530-height;
    
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
        
        for (AvatarButton *avatar in currentDrawView.avatarButtons) {
            
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
    
    [self.chatOpenButton setTitle:@"OPEN" forState:UIControlStateNormal];
    
    self.editBoardNameTextField.hidden = true;
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
        
        DrawView *drawView = [[DrawView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
        view = drawView;
        CGAffineTransform tr = view.transform;
        tr = CGAffineTransformScale(tr, .5, .5);
        tr = CGAffineTransformRotate(tr, M_PI_2);
        view.transform = tr;
    }
    
    UIImage *gradientImage = [UIImage imageNamed:@"board2.png"];
    UIButton *gradientButton = [UIButton buttonWithType:UIButtonTypeCustom];
    gradientButton.frame = CGRectMake(0.0f, 0.0f, gradientImage.size.width, gradientImage.size.height);
    [gradientButton setBackgroundImage:gradientImage forState:UIControlStateNormal];
    [gradientButton addTarget:self action:@selector(boardTapped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:gradientButton];
    gradientButton.tag = 2;
    
    ((DrawView *)view).boardID = self.boardIDs[index];
    
    if (![[FirebaseHelper sharedHelper].loadedBoardIDs containsObject:self.boardIDs[index]] && ![FirebaseHelper sharedHelper].projectCreated) {
        ((DrawView *)view).loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        ((DrawView *)view).loadingView.transform = CGAffineTransformMakeScale(5, 5);
        [((DrawView *)view).loadingView setCenter:((DrawView *)view).center];
        [((DrawView *)view).loadingView startAnimating];
        [((DrawView *)view) addSubview:((DrawView *)view).loadingView];
    }
    
    [self drawBoard:(DrawView *)view];
    [((DrawView *)view) layoutComments];
    
    return view;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel
{
    
    self.carouselMoving = false;
    
    if (newBoardCreated) {
        [self boardTapped:[carousel.currentItemView viewWithTag:2]];
    }
}

- (void)carouselDidScroll:(iCarousel *)carousel {
    
    self.carouselMoving = true;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    
    NSString *boardID = self.boardIDs[carousel.currentItemIndex];
    NSDictionary *boardDict = [[FirebaseHelper sharedHelper].boards objectForKey:boardID];
    
    self.boardNameLabel.text = [boardDict objectForKey:@"name"];
    [self.boardNameLabel sizeToFit];
    self.boardNameEditButton.center = CGPointMake(self.boardNameLabel.frame.size.width+400, self.boardNameEditButton.center.y);
    
    double viewedAt = [[[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid] doubleValue];
    double updatedAt = [[boardDict objectForKey:@"updatedAt"] doubleValue];
    
    if (updatedAt > viewedAt && ![self.viewedBoardIDs containsObject:boardID] && !newBoardCreated)
        self.boardNameLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
    else
        self.boardNameLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
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
}

#pragma mark - Text field handling

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    
    if ([textField isEqual:self.chatTextField]) {
        
        NSString *chatString;
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        
        if (self.activeCommentThreadID) {
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
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
        self.boardNameEditButton.center = CGPointMake(self.boardNameLabel.frame.size.width+400, self.boardNameEditButton.center.y);
        
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
    
    CGRect labelRect = [messageString boundingRectWithSize:CGSizeMake(self.chatTable.frame.size.width,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:20]} context:nil];
    
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.editBoardIDs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BoardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionCell" forIndexPath:indexPath];
    
    cell.drawView.boardID = self.editBoardIDs[indexPath.row];
    [cell updateSubpathsForBoardID:self.editBoardIDs[indexPath.row]];
    
    return cell;
}

- (BOOL)collectionView:(LSCollectionViewHelper *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    return YES;
}

- (void)collectionView:(LSCollectionViewHelper *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    
    //NSLog(@"BoardIDs is %@, EditBoardIDs is %@", self.boardIDs, self.editBoardIDs);
    
    NSString *fromID = [self.editBoardIDs objectAtIndex:fromIndexPath.item];
    [self.editBoardIDs removeObjectAtIndex:fromIndexPath.item];
    [self.editBoardIDs insertObject:fromID atIndex:toIndexPath.item];
    
    //NSLog(@"BoardIDs is %@, EditBoardIDs is %@", self.boardIDs, self.editBoardIDs);
}

@end
