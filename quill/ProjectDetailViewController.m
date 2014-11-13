//
//  ProjectDetailViewController.m
//  chalk
//
//  Created by Alex Costantini on 7/18/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "ProjectDetailViewController.h"
#import "MasterViewController.h"
#import "BoardCollectionViewCell.h"
#import "AddUserViewController.h"
#import "AvatarButton.h"

#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"
#import "NSDate+ServerDate.h"

@implementation ProjectDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.splitViewController.delegate = self;
    self.chatTextField.delegate = self;
    self.editBoardNameTextField.delegate = self;
    self.carousel.delegate = self;
    
    self.carousel.type = iCarouselTypeCoverFlow2;
    self.carousel.bounceDistance = 0.1f;
    
    //self.nameLabel.font = [UIFont fontWithName:@"ZemestroStd-Bk" size:40];
    //self.chatTextField.font = [UIFont fontWithName:@"ZemestroStd-Bk" size:20];
    self.chatTable.transform = CGAffineTransformMakeRotation(M_PI);
    
    self.editBoardNameTextField.hidden = true;
    //self.commentTextView.hidden = true;
    
    self.viewedCommentThreadIDs = [NSMutableArray array];
    
    UISplitViewController *splitVC = (UISplitViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    masterVC = (MasterViewController *)[splitVC.viewControllers objectAtIndex:0];
    
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
    //[self.view bringSubviewToFront:self.chatOpenButton];
}

-(void) hideChat {
    
    [self.view sendSubviewToBack:self.chatView];
    [self.view sendSubviewToBack:self.chatTable];
    [self.view sendSubviewToBack:self.chatFadeImage];
    //[self.view sendSubviewToBack:self.chatOpenButton];
}

-(void) updateDetails {
    
    self.projectNameLabel.text = self.projectName;
    
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

-(void) layoutAvatars {
    
    for (AvatarButton *avatar in self.avatars) {
        [avatar removeFromSuperview];
    }
    
    self.avatars = [NSMutableArray array];
    
    NSArray *userIDs = [self.roles.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for (int i=0; i<userIDs.count; i++) {
        
        UIImage *image = [UIImage imageNamed:@"user.png"];
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.frame = CGRectMake(550-(i*70), -50, image.size.width, image.size.height);
        [avatar setImage:image forState:UIControlStateNormal];
        [avatar addTarget:self action:@selector(avatarTapped:) forControlEvents:UIControlEventTouchUpInside];
        avatar.userID = userIDs[i];
        avatar.transform = CGAffineTransformScale(avatar.transform, .25, .25);
        [self.view addSubview:avatar];
        
        if (![[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"inProject"] isEqualToString:[FirebaseHelper sharedHelper].currentProjectID]) {
            avatar.alpha = 0.5;
        }
        
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
                    
                    //NSLog(@"UID IS %@", uid);
                    //if ([uid isEqualToString:[FirebaseHelper sharedHelper].uid]) NSLog(@"UNDO COUNT FROM DRAWBOARD IS %i", undoCount);
                    
                    if (undoCount > 0) {
                        
                        undone = true;
                        undoCount--;
                        //NSLog(@"HELPER UNDO DICT BEFORE is %@", [[[FirebaseHelper sharedHelper].boards objectForKey:drawView.boardID] objectForKey:@"undo"]);
                        [[undoDict objectForKey:uid] setObject:@(undoCount) forKey:@"currentIndex"];
                        //NSLog(@"HELPER UNDO DICT AFTER is %@", [[[FirebaseHelper sharedHelper].boards objectForKey:drawView.boardID] objectForKey:@"undo"]);
                        
                        
                    } else {
                        
                        if (undone) {
                            
                            self.activeBoardUndoIndexDate = userOrderedKeys[i];
                            //if ([uid isEqualToString:[FirebaseHelper sharedHelper].uid]) NSLog(@"NEW UNDO INDEX IS %@", self.activeBoardUndoIndexDate);
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

-(void) resetUndo {
    
    int currentIndex = [(NSNumber *)[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.activeBoardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    
    if (currentIndex == 0) return;
    
    NSMutableDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.activeBoardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
    
    [undoDict setObject:@0 forKey:@"currentIndex"];
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", self.activeBoardID, [FirebaseHelper sharedHelper].uid];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    [[boardRef childByAppendingPath:@"currentIndex"] setValue:@0];
    
    int total = [(NSNumber *)[undoDict objectForKey:@"total"] intValue];
    total -= currentIndex;
    [undoDict setObject:@(total) forKey:@"total"];
    [[boardRef childByAppendingPath:@"total"] setValue:@(total)];
    
    NSMutableDictionary *allSubpathsDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.activeBoardID] objectForKey:@"allSubpaths"] objectForKey:[FirebaseHelper sharedHelper].uid];
    
    for (NSString *dateString in allSubpathsDict.allKeys) {
        
        if ([dateString longLongValue] > [self.activeBoardUndoIndexDate longLongValue]) {
            
            [allSubpathsDict removeObjectForKey:dateString];
            
            NSString *subpathString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/allSubpaths/%@/%@", self.activeBoardID, [FirebaseHelper sharedHelper].uid, dateString];
            Firebase *subpathRef = [[Firebase alloc] initWithUrl:subpathString];
            [subpathRef removeValue];
        }
    }
}

- (IBAction)sendTapped:(id)sender {
    
}

-(void) boardTapped:(id)sender {
    
    if (self.carouselMoving) {
        [self.carousel scrollToItemAtIndex:self.carousel.currentItemIndex animated:YES];
        return;
    }
    
    newBoardCreated = false;
    [self.carousel setScrollEnabled:NO];
    
    UIButton *button = (UIButton *)sender;
    currentDrawView = (DrawView *)button.superview;
    NSString *boardID = currentDrawView.boardID;
    
    self.boardNameLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    
    [self.viewedBoardIDs addObject:boardID];
    
    boardButton = button;
    
    self.activeBoardID = boardID;
    
    [[FirebaseHelper sharedHelper] setInBoard];
    
    hideMaster = !hideMaster;
    
    [self.view bringSubviewToFront:self.carousel];
    
    [currentDrawView.activeUserIDs addObject:[FirebaseHelper sharedHelper].uid];
    [currentDrawView layoutAvatars];
    
    self.chatTextField.placeholder = @"Leave a comment...";
    
    //    [self.chatTextField setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatView setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatFadeImage setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatTable setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.sendMessageButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatOpenButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    [UIView animateWithDuration:.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         [self.splitViewController willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0];
                         [self.splitViewController willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
                         [self.splitViewController didRotateFromInterfaceOrientation:self.interfaceOrientation];
                         [self.splitViewController viewWillLayoutSubviews];
                         [self.splitViewController viewDidLayoutSubviews];
                         [self.splitViewController.view layoutSubviews];
                         
                         CGAffineTransform tr = CGAffineTransformScale(self.carousel.transform, 2, 2);
                         self.carousel.center = CGPointMake(0, 0);
                         self.carousel.transform = tr;
                         
                         self.chatOpenButton.center = CGPointMake(self.view.center.x, self.chatOpenButton.center.y);
                         self.chatTextField.frame = CGRectMake(52, 102, 880, 30);
                         self.chatView.frame = CGRectMake(0, 626, 1024, 142);
                         self.sendMessageButton.frame = CGRectMake(952, 102, 45, 30);
                         
                         boardButton.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         
                         boardButton.hidden = true;
                         
                         if (self.userRole > 0) [self showDrawMenu];
                         
                         //[self.carousel setTranslatesAutoresizingMaskIntoConstraints:YES];
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
}

- (IBAction)boardNameEditTapped:(id)sender {
    
    self.editBoardNameTextField.hidden = false;
    self.editBoardNameTextField.placeholder = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardIDs[self.carousel.currentItemIndex]] objectForKey:@"name"];
    [self.editBoardNameTextField becomeFirstResponder];
    
}

-(void) avatarTapped:(id)sender {
    
    AvatarButton *avatar = (AvatarButton *)sender;
    NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"name"];
    tappedUserID = avatar.userID;
    
    int roleNum = [[self.roles objectForKey:avatar.userID] intValue];
    NSString *roleString;
    if (roleNum == 2) roleString = @"Owner";
    else if (roleNum == 1) roleString = @"Collaborator";
    else roleString = @"Viewer";
    
    NSString *titleString = [NSString stringWithFormat:@"%@ (%@)", userName, roleString];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:titleString delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    if (self.userRole == 2 && ![avatar.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
        
        if (roleNum == 0) [actionSheet addButtonWithTitle:@"Make Collaborator"];
        else [actionSheet addButtonWithTitle:@"Make Viewer"];
        
        if (![avatar.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) [actionSheet addButtonWithTitle:@"Remove from project"];
    }
    else [actionSheet addButtonWithTitle:@"Leave project"];
    
    [actionSheet showFromRect:avatar.frame inView:self.view animated:YES];
}

-(IBAction) applyChangesTapped:(id)sender {
    
    [self cancelTapped:nil];
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info", [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    if (self.editProjectNameTextField.text.length > 0) {
        
        [[ref childByAppendingPath:@"name"] setValue:self.editProjectNameTextField.text];
        
        [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] setObject:self.editProjectNameTextField.text forKey:@"name"];
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
    
    hideMaster = !hideMaster;
    
    self.activeBoardID = nil;
    self.activeCommentThreadID = nil;
    
    [[FirebaseHelper sharedHelper] setInBoard];
    
    [currentDrawView.activeUserIDs removeObject:[FirebaseHelper sharedHelper].uid];
    [currentDrawView layoutAvatars];
    currentDrawView.selectedAvatarUserID = nil;
    [self drawBoard:currentDrawView];
    currentDrawView = nil;
    
    if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
    [self.chatTable reloadData];
    
    //[self.carousel setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [UIView animateWithDuration:.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         [self.splitViewController willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0];
                         [self.splitViewController willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
                         [self.splitViewController didRotateFromInterfaceOrientation:self.interfaceOrientation];
                         [self.splitViewController viewWillLayoutSubviews];
                         [self.splitViewController.view layoutSubviews];
                         
                         CGAffineTransform tr = CGAffineTransformScale(self.carousel.transform, .5, .5);
                         self.carousel.center= CGPointMake(0, 0);
                         self.carousel.transform = tr;
                         
                         self.chatTextField.frame = CGRectMake(52, 102, 622, 30);
                         self.chatView.frame = CGRectMake(self.chatView.frame.origin.x, self.chatView.frame.origin.y, 1024, self.chatView.frame.size.height);
                         self.sendMessageButton.frame = CGRectMake(693, 102, 45, 30);
                         //self.chatOpenButton.center = CGPointMake(self.chatView.center.x, self.chatOpenButton.center.y);
                         
                         boardButton.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         
                         //                         [self.chatTextField setTranslatesAutoresizingMaskIntoConstraints:NO];
                         //                         [self.chatView setTranslatesAutoresizingMaskIntoConstraints:NO];
                         //                         [self.chatFadeImage setTranslatesAutoresizingMaskIntoConstraints:NO];
                         //                         [self.chatTable setTranslatesAutoresizingMaskIntoConstraints:NO];
                         //                         [self.sendMessageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
                         //                         [self.chatOpenButton setTranslatesAutoresizingMaskIntoConstraints:NO];
                         
                         [self.view bringSubviewToFront:self.chatView];
                         [self.view bringSubviewToFront:self.chatTable];
                         [self.view bringSubviewToFront:self.chatFadeImage];
                         [self.view bringSubviewToFront:self.chatOpenButton];
                         
                         [self updateDetails];
                         
                         [self.carousel setScrollEnabled:YES];
                         
                         [masterVC.projectsTable reloadData];
                         [masterVC.projectsTable selectRowAtIndexPath:masterVC.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
                     }];
    
    [self.splitViewController viewDidLayoutSubviews];
    
}

- (void) undoTapped {
    
    int undoCount = [(NSNumber *)[[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndex"] intValue];
    int undoTotal = [(NSNumber *)[[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"total"] intValue];
    
    if (undoCount < undoTotal)  {
        
        undoCount++;
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", currentDrawView.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        [[ref childByAppendingPath:@"currentIndex"] setValue:@(undoCount)];
        [[ref childByAppendingPath:@"currentIndexDate"] setValue:@([self.activeBoardUndoIndexDate longLongValue])];
        
        [self drawBoard:currentDrawView];
        
        NSMutableDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
        [undoDict setObject:@(undoCount) forKey:@"currentIndex"];
        [undoDict setObject:@([self.activeBoardUndoIndexDate longLongValue]) forKey:@"currentIndexDate"];
        
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
            [ref setValue:@([self.activeBoardUndoIndexDate longLongValue])];
            
            [[[[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@([self.activeBoardUndoIndexDate longLongValue]) forKey:@"currentIndexDate"];
        }
    }
}

- (void) clearTapped {
    
    [self resetUndo];
    
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
    
    for (NSString *uid in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        [allSubpathsDict setObject:[@{[NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000]: @"penUp"} mutableCopy] forKey: uid];
    }
    
    NSString *boardNum = [NSString stringWithFormat:@"%lu", (unsigned long)self.boardIDs.count];
    NSDictionary *boardDict =  @{ @"name" : @"Untitled",
                                  @"project" : self.projectName,
                                  @"number" : boardNum,
                                  @"commentsID" : commentsID,
                                  @"lastSubpath" : [NSMutableDictionary dictionary],
                                  @"allSubpaths" : allSubpathsDict,
                                  @"updatedAt" : @([[NSDate serverDate] timeIntervalSince1970]*100000000),
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
    [self.splitViewController presentViewController:vc animated:YES completion:nil];
    
}

- (IBAction)openChatTapped:(id)sender {
    
    if (!self.activeBoardID) {
        
        if ([self.chatTextField isFirstResponder]) [self.chatTextField resignFirstResponder];
        else [self.chatTextField becomeFirstResponder];
    }
    else [self openComments];
}

-(void)openComments {
    
    //    [self.chatView setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatFadeImage setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatTable setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatOpenButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    if (commentsOpen) self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y+180.0);
    else self.chatFadeImage.center = CGPointMake(self.chatFadeImage.center.x, self.chatFadeImage.center.y-180.0);
    
    CGRect chatTableRect = self.chatTable.frame;
    if (commentsOpen) {
        chatTableRect.size.height -= 180.0;
        chatTableRect.origin.y += 180.0;
    }
    else {
        chatTableRect.size.height += 180.0;
        chatTableRect.origin.y -= 180.0;
    }
    self.chatTable.frame = chatTableRect;
    
    if (!commentsOpen) self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-180.0);
    else self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+180.0);
    
    [self.view bringSubviewToFront:self.chatOpenButton];
    
    [UIView commitAnimations];
    
    commentsOpen = !commentsOpen;
    
    if (commentsOpen) [self.chatOpenButton setTitle:@"v" forState:UIControlStateNormal];
    else [self.chatOpenButton setTitle:@"^" forState:UIControlStateNormal];
}

-(void)keyboardWillShow:(NSNotification *)notification {
    
    if (![self.chatTextField isFirstResponder]) return;
    
    [self showChat];
    
    //    [self.chatTextField setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatView setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatFadeImage setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatTable setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.sendMessageButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    [self.chatOpenButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect viewRect = self.chatView.frame;
    viewRect.origin.y -= 352.0;
    self.chatView.frame = viewRect;
    
    CGRect fadeRect = self.chatFadeImage.frame;
    if(self.activeBoardID == nil) fadeRect.origin.y -= 532.0;
    else fadeRect.origin.y -= 352.0;
    self.chatFadeImage.frame = fadeRect;
    
    CGRect chatTableRect = self.chatTable.frame;
    if (self.activeBoardID == nil) {
        chatTableRect.size.height += 180.0;
        chatTableRect.origin.y -= 532.0;
    }
    else chatTableRect.origin.y -= 352.0;
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
        
        CGRect projectsTableRect = masterVC.projectsTable.frame;
        projectsTableRect.size.height -= 262.0;
        masterVC.projectsTable.frame = projectsTableRect;
    }
    
    if (!self.activeBoardID) {
        [self.chatOpenButton setTitle:@"CLOSE" forState:UIControlStateNormal];
        self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-532.0);
    }
    else {
        [self.chatOpenButton setTitle:@"^" forState:UIControlStateNormal];
        self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y-352.0);
    }
    
    [self.view bringSubviewToFront:self.chatOpenButton];
    
    [UIView commitAnimations];
    
}

-(void)keyboardWillHide:(NSNotification *)notification {
    
    //[self hideChat];
    
    if (![self.chatTextField isFirstResponder]) return;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect viewRect = self.chatView.frame;
    viewRect.origin.y += 352.0;
    self.chatView.frame = viewRect;
    
    CGRect projectsTableRect = masterVC.projectsTable.frame;
    projectsTableRect.size.height += 262.0;
    masterVC.projectsTable.frame = projectsTableRect;
    
    CGRect fadeRect = self.chatFadeImage.frame;
    if(self.activeBoardID == nil) fadeRect.origin.y += 532.0;
    else fadeRect.origin.y += 352.0;
    self.chatFadeImage.frame = fadeRect;
    
    CGRect chatTableRect = self.chatTable.frame;
    if (self.activeBoardID == nil) {
        chatTableRect.size.height -= 180.0;
        chatTableRect.origin.y += 532.0;
    }
    else chatTableRect.origin.y += 352.0;
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
        
        CGRect projectsTableRect = masterVC.projectsTable.frame;
        projectsTableRect.size.height += 262.0;
        masterVC.projectsTable.frame = projectsTableRect;
    }
    
    if (self.activeBoardID) self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+352.0);
    else self.chatOpenButton.center = CGPointMake(self.chatOpenButton.center.x, self.chatOpenButton.center.y+532.0);
    
    if (commentsOpen) [self openComments];
    
    [self.view bringSubviewToFront:self.chatOpenButton];
    
    [UIView commitAnimations];
    
    [self.chatOpenButton setTitle:@"OPEN" forState:UIControlStateNormal];
    
    self.editBoardNameTextField.hidden = true;
}

#pragma mark -
#pragma mark UISplitViewController

- (BOOL)splitViewController: (UISplitViewController*)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return hideMaster;
}


#pragma mark -
#pragma mark iCarousel methods

- (CATransform3D)carousel:(iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    CGFloat MAX_SCALE = 1.2f; //max scale of center item
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
        
        if (self.activeCommentThreadID) {
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
            chatString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@/%@/messages", commentsID, self.activeCommentThreadID];
        }
        else chatString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/chats/%@", self.chatID];
        
        Firebase *chatRef = [[Firebase alloc] initWithUrl:chatString];
        NSDictionary *messageDict = @{ @"name" : [FirebaseHelper sharedHelper].userName ,
                                       @"message" : textField.text,
                                       @"sentAt" : @([[NSDate serverDate] timeIntervalSince1970]*100000000)
                                       };
        [[chatRef childByAutoId] setValue:messageDict];
        
        //[[FirebaseHelper sharedHelper] setProjectViewedAt];
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
    int rows;
    
    if (self.activeCommentThreadID) {
        NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
        rows = [[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] allKeys].count;
        
    }
    else {
        rows = [[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] allKeys].count;
    }
    
    //if (rows > 2) self.chatOpenButton.hidden = false;
    //else self.chatOpenButton.hidden = true;
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell" forIndexPath:indexPath];
    
    cell.transform = CGAffineTransformMakeRotation(M_PI);
    
    NSMutableArray *orderedMessages = [NSMutableArray array];
    
    NSArray *messageKeys;
    
    if (self.activeCommentThreadID) {
        
        NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
        messageKeys = [[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] allKeys];
    }
    else messageKeys = [[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] allKeys];
    
    for (NSString *messageID in messageKeys) {
        
        NSNumber *date;
        
        if (self.activeCommentThreadID != nil) {
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
            
            date = [[[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] objectForKey:messageID] objectForKey:@"sentAt"];
            
        }
        else date = [[[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] objectForKey:messageID]  objectForKey:@"sentAt"];
        
        
        [orderedMessages addObject:date];
    }
    
    NSNumber *viewedAt = [[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid];
    if (!viewedAt) viewedAt = @([[NSDate serverDate] timeIntervalSince1970]*100000000);
    [orderedMessages addObject:viewedAt];
    
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [orderedMessages sortUsingDescriptors:@[sorter]];
    
    if ([orderedMessages.lastObject isEqualToNumber:viewedAt] || (!self.activeCommentThreadID && self.chatViewed) || [self.viewedCommentThreadIDs containsObject:self.activeCommentThreadID]) {
        [orderedMessages removeObject:viewedAt];
        self.chatViewed = true;
        if (![self.chatTextField isFirstResponder]) [self.chatOpenButton setTitle:@"OPEN" forState:UIControlStateNormal];
    }
    
    for (NSString *messageID in messageKeys) {
        
        NSNumber *date;
        
        if (self.activeCommentThreadID){
            
            NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:currentDrawView.boardID] objectForKey:@"commentsID"];
            date = [[[[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:self.activeCommentThreadID] objectForKey:@"messages"] objectForKey:messageID] objectForKey:@"sentAt"];
        }
        else date = [[[[FirebaseHelper sharedHelper].chats objectForKey:self.chatID] objectForKey:messageID]  objectForKey:@"sentAt"];
        
        for (int i=0; i<[orderedMessages count]; i++) {
            
            if (viewedAt == orderedMessages[i]) { [orderedMessages replaceObjectAtIndex:i withObject:@"---------------------------------------<NEW MESSAGES>---------------------------------------"];
                if (!self.chatViewed && ![self.chatTextField isFirstResponder]) [self.chatOpenButton setTitle:@"NEW MESSAGES!" forState:UIControlStateNormal];
            }
            
            else if (date == orderedMessages[i]) {
                
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
                NSLog(@"messageString is %@", messageString);
                
                [orderedMessages replaceObjectAtIndex:i withObject:messageString];
            }
        }
    }
    
    //NSLog(@"orderedMessages is %@", orderedMessages);
    //NSLog(@"viewedAt is %@", [[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid]);
    
    if (orderedMessages.count > indexPath.row) {
        
        cell.textLabel.text = orderedMessages[orderedMessages.count-(indexPath.row+1)];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
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
    
    NSLog(@"BoardIDs is %@, EditBoardIDs is %@", self.boardIDs, self.editBoardIDs);
    
    NSString *fromID = [self.editBoardIDs objectAtIndex:fromIndexPath.item];
    [self.editBoardIDs removeObjectAtIndex:fromIndexPath.item];
    [self.editBoardIDs insertObject:fromID atIndex:toIndexPath.item];
    
    //NSLog(@"BoardIDs is %@, EditBoardIDs is %@", self.boardIDs, self.editBoardIDs);
}

#pragma mark -
#pragma mark UIActionSheet

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex) return;
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info/roles/%@", [FirebaseHelper sharedHelper].currentProjectID, tappedUserID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    if  ([buttonTitle isEqualToString:@"Leave project"] || [buttonTitle isEqualToString:@"Remove from project"] ) [ref removeValue];
    if  ([buttonTitle isEqualToString:@"Make Collaborator"]) [ref setValue:@1];
    if  ([buttonTitle isEqualToString:@"Make Viewer"]) [ref setValue:@0];
    
    tappedUserID = nil;
}

@end
