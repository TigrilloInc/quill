
//
//  FirebaseHelper.m
//  Quill
//
//  Created by Alex Costantini on 7/11/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//


#import "FirebaseHelper.h"
#import "MasterViewController.h"
#import "ProjectDetailViewController.h"
#import "SignInViewController.h"
#import "SignUpFromInviteViewController.h"
#import "BoardView.h"
#import "NSDate+ServerDate.h"
#import "AvatarButton.h"
#import "Reachability.h"
#import "UserDeletedAlertViewController.h"

@implementation FirebaseHelper

static FirebaseHelper *sharedHelper = nil;

+ (FirebaseHelper *) sharedHelper {
    
    if (!sharedHelper) {
        
        sharedHelper = [[FirebaseHelper alloc] init];
        sharedHelper.teamLoaded = false;
        sharedHelper.projectsLoaded = false;
        sharedHelper.team = [NSMutableDictionary dictionary];
        sharedHelper.projects = [NSMutableDictionary dictionary];
        sharedHelper.boards = [NSMutableDictionary dictionary];
        sharedHelper.chats = [NSMutableDictionary dictionary];
        sharedHelper.comments = [NSMutableDictionary dictionary];
        sharedHelper.visibleProjectIDs = [NSMutableArray array];
        sharedHelper.loadedBoardIDs = [NSMutableArray array];
        
        sharedHelper.projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    }
    return sharedHelper;
}

-(void) testConnection {
 
    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    
    reachability.reachableBlock = ^(Reachability*reach) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            weakSelf.connected = true;
            [NSDate serverDate];
            if (self.inviteURL) [self createUser];
            else if (!self.loggedIn) [self checkAuthStatus];
            
            NSLog(@"Yayyy, we have the interwebs!");
        });
    };
    
    reachability.unreachableBlock = ^(Reachability *reach) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            weakSelf.connected = false;
            NSLog(@"Someone broke the internet :(");
        });
    };
    
    [reachability startNotifier];
}

-(void) checkAuthStatus {
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:ref];
    
    if (self.projectVC.presentedViewController) [self.projectVC dismissViewControllerAnimated:YES completion:nil];
    
    //[authClient logout];
    
    [authClient checkAuthStatusWithBlock:^(NSError *error, FAUser *user) {
        
        if (error != nil) {
            NSLog(@"%@", error);
            [authClient logout];
            [self checkAuthStatus];
        }
        
        else if (user == nil) {
            
            SignInViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            nav.navigationBar.barTintColor = [UIColor whiteColor];
            nav.navigationBar.tintColor = [UIColor blackColor];
            [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"SourceSansPro-Light" size:24.0], NSFontAttributeName, nil]];
            [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:5 forBarMetrics:UIBarMetricsDefault];
            
            UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
            logoImageView.frame = CGRectMake(155, 8, 32, 32);
            logoImageView.tag = 800;
            [nav.navigationBar addSubview:logoImageView];
            
            [self.projectVC presentViewController:nav animated:YES completion:nil];
        }
        else {
            
            NSLog(@"User logged in as %@", user.uid);
            
            self.loggedIn = true;
            self.uid = user.uid;
            [self observeLocalUser];
        }
    }];
}

-(void) createUser {
    
    if (self.projectVC.presentedViewController) [self.projectVC dismissViewControllerAnimated:YES completion:nil];
    
    self.projectVC.masterView.teamButton.hidden = true;
    self.projectVC.masterView.teamMenuButton.hidden = true;
    self.projectVC.masterView.nameButton.hidden = true;
    self.projectVC.masterView.avatarButton.hidden = true;
    self.projectVC.projectNameLabel.hidden = true;
    self.projectVC.editButton.hidden = true;
    self.projectVC.carousel.hidden = true;
    self.projectVC.chatAvatar.hidden = true;
    self.projectVC.sendMessageButton.hidden = true;
    self.projectVC.boardNameLabel.hidden = true;
    self.projectVC.boardNameEditButton.hidden = true;
    self.projectVC.editBoardNameTextField.hidden = true;
    for (AvatarButton *avatar in self.projectVC.avatars) avatar.hidden = true;
    self.projectVC.avatarBackgroundImage.hidden = true;
    self.projectVC.addUserButton.hidden = true;
    self.projectVC.chatTextField.hidden = true;
    self.projectVC.addBoardBackgroundImage.hidden = true;
    self.projectVC.addBoardButton.hidden = true;
    self.projectVC.chatOpenButton.hidden = true;
    
    [[FirebaseHelper sharedHelper] removeAllObservers];
    [[FirebaseHelper sharedHelper] clearData];
    
    NSString *tokenString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/tokens/%@", [self.inviteURL.host stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    Firebase *tokenRef = [[Firebase alloc] initWithUrl:tokenString];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:tokenRef];
    
    [authClient logout];
    
    [tokenRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        self.inviteURL = nil;
        
        self.teamID = [snapshot.value objectForKey:@"teamID"];
        self.teamName = [snapshot.value objectForKey:@"teamName"];
        self.email = [snapshot.value objectForKey:@"email"];
        if ([snapshot.value objectForKey:@"project"]) self.invitedProject = [snapshot.value objectForKey:@"project"];
        
        SignUpFromInviteViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignUpFromInvite"];
        vc.invitedBy = [snapshot.value objectForKey:@"invitedBy"];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        nav.navigationBar.barTintColor = [UIColor whiteColor];
        nav.navigationBar.tintColor = [UIColor blackColor];
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"SourceSansPro-Light" size:24.0], NSFontAttributeName, nil]];
        [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:5 forBarMetrics:UIBarMetricsDefault];
        
        UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
        logoImageView.frame = CGRectMake(155, 8, 32, 32);
        logoImageView.tag = 800;
        [nav.navigationBar addSubview:logoImageView];
        
        [self.projectVC presentViewController:nav animated:YES completion:nil];
    }];
}


-(void) observeLocalUser {

    NSString *uidString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@", self.uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:uidString];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        self.userName = [snapshot.value objectForKey:@"name"];
        self.teamID = [snapshot.value objectForKey:@"team"];
        self.email = [snapshot.value objectForKey:@"email"];
        
        if ([[snapshot.value objectForKey:@"deleted"] integerValue] == 1) {
            
            UserDeletedAlertViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"UserDeleted"];
            
            NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@/name", self.teamID];
            Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
            
            [teamRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                
                self.teamName = snapshot.value;
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                nav.modalPresentationStyle = UIModalPresentationFormSheet;
                nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                nav.navigationBar.barTintColor = [UIColor whiteColor];
                nav.navigationBar.tintColor = [UIColor blackColor];
                [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"SourceSansPro-Light" size:24.0], NSFontAttributeName, nil]];
                [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:5 forBarMetrics:UIBarMetricsDefault];
                
                UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
                logoImageView.frame = CGRectMake(155, 8, 32, 32);
                logoImageView.tag = 800;
                [nav.navigationBar addSubview:logoImageView];
                
                [self.projectVC presentViewController:nav animated:YES completion:nil];
            }];
        }
        
        else {
         
            [self.team setObject:[@{self.uid:[snapshot.value mutableCopy]} mutableCopy] forKey:@"users"];
            
            [self observeTeam];
            [self observeProjects];
        }
    }];
}

- (void) observeUserWithID:(NSString *)userID {
    
    NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/", userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:userString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
 
        NSDictionary *oldUserDict = CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)[[self.team objectForKey:@"users"] objectForKey:userID], kCFPropertyListMutableContainers));
        NSMutableDictionary *newUserDict = snapshot.value;
        
        for (NSString *key in newUserDict.allKeys) {
            
            [[[self.team objectForKey:@"users"] objectForKey:userID] setObject:[newUserDict objectForKey:key] forKey:key];
        }
        
        if (!self.teamLoaded && [[self.team objectForKey:@"users"] allKeys].count == userChildrenCount) {
            
            self.teamLoaded = true;
            if (self.projectsLoaded) [self updateMasterView];
        }
        
        if ([userID isEqualToString:self.uid]) return;
        
        NSString *newProjectID = [newUserDict objectForKey:@"inProject"];
        NSString *oldProjectID = [oldUserDict objectForKey:@"inProject"];

        if ([self.currentProjectID isEqualToString:newProjectID] || [self.currentProjectID isEqualToString:oldProjectID]) [self.projectVC layoutAvatars];
        else return;
        
        NSString *newBoardID = [newUserDict objectForKey:@"inBoard"];
        NSString *oldBoardID = [oldUserDict objectForKey:@"inBoard"];
        
        NSString *boardID;
        BOOL inBoard;
        
        if (![newBoardID isEqualToString:oldBoardID]) {
            
            if ([oldBoardID isEqualToString:@"none"]) {
                boardID = newBoardID;
                inBoard = true;
            }
            else {
                boardID = oldBoardID;
                inBoard = false;
            }
            
        } else {
            
            boardID = newBoardID;
            
            if ([newBoardID isEqualToString:@"none"]) inBoard = false;
            else inBoard = true;
        }
        
        NSArray *currentProjectBoardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        
        if ([currentProjectBoardIDs containsObject:boardID]){
            
            NSInteger boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            
            if (inBoard && ![boardView.activeUserIDs containsObject:userID]) [boardView.activeUserIDs addObject:userID];
            else if (!inBoard) [boardView.activeUserIDs removeObject:userID];
            
            [boardView layoutAvatars];
            
        }
    }];
}

- (void) observeProjects {
    
    NSString *projectsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@/projects", self.teamID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectsString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        projectChildrenCount = snapshot.childrenCount;
        
        if (projectChildrenCount > 0) {
            
            for (FDataSnapshot *child in snapshot.children) {
                
                if (![self.projects.allKeys containsObject:child.key]) [self observeProjectWithID:child.key];
            }
        }
        else {

            self.projectsLoaded = true;
            if (self.teamLoaded) [self updateMasterView];
        }
    }];
}

-(void) observeProjectWithID:(NSString *)projectID {
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@", projectID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    [[ref childByAppendingPath:@"info"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value == [NSNull null]) return;
        
        NSMutableDictionary *projectDict;
        
        if ([self.projects objectForKey:projectID]) projectDict = [self.projects objectForKey:projectID];
        else projectDict = [NSMutableDictionary dictionary];
        
        if ([((NSDictionary *)[snapshot.value objectForKey:@"roles"]).allKeys containsObject:self.uid]) {
            
            if (![self.visibleProjectIDs containsObject:projectID] && [[[snapshot.value objectForKey:@"roles"] objectForKey:self.uid] integerValue] != -1) [self.visibleProjectIDs addObject:projectID];
            
            if ([self.visibleProjectIDs containsObject:projectID] && [[[snapshot.value objectForKey:@"roles"] objectForKey:self.uid] integerValue] == -1) [self.visibleProjectIDs removeObject:projectID];
        }
        
        for (FDataSnapshot *child in snapshot.children) {
            
            [projectDict setObject:child.value forKey:child.key];
            
            if ([child.key isEqualToString:@"boards"]) {
                
                for (NSString *boardID in child.value) {
                    
                    if (![self.boards objectForKey:boardID]) {

                        [self loadBoardWithID:boardID];

                        if ([self.currentProjectID isEqualToString:projectID]) {
                            
                            if (![self.projectVC.boardIDs containsObject:boardID]) [self.projectVC.boardIDs addObject:boardID];
                            if (self.projectVC.activeBoardID == nil) [self.projectVC.carousel reloadData];
                        }
                    }
                }
            }
        }
        
        [self.projects setObject:projectDict forKey:projectID];
        
        [self observeChatWithID:[projectDict objectForKey:@"chatID"]];
        
        if (!self.teamLoaded || !self.projectsLoaded) self.projectVC.masterView.defaultRow = [self getLastViewedProjectIndexPath];
        
        if (self.projectVC.activeBoardID == nil && self.projects.allKeys.count == projectChildrenCount) {
            
            self.projectsLoaded = true;
            if (self.teamLoaded) [self updateMasterView];
        }
    }];
    
    [[ref childByAppendingPath:@"viewedAt"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.projects objectForKey:projectID] setObject:snapshot.value forKey:@"viewedAt"];
    }];
    
    [[ref childByAppendingPath:@"updatedAt"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value == [NSNull null]) return;
        
        [[self.projects objectForKey:projectID] setObject:snapshot.value forKey:@"updatedAt"];
        if (self.projectsLoaded && self.userName) {
            
            [self.projectVC.masterView.projectsTable reloadData];
            [self.projectVC.masterView.projectsTable selectRowAtIndexPath:self.projectVC.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
}

-(void) updateMasterView {
    
    NSLog(@"master view updated");
    
    self.projectVC.masterView.nameButton.titleLabel.numberOfLines = 1;
    self.projectVC.masterView.nameButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.projectVC.masterView.nameButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    self.projectVC.masterView.teamButton.titleLabel.numberOfLines = 1;
    self.projectVC.masterView.teamButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.projectVC.masterView.teamButton.titleLabel.lineBreakMode = NSLineBreakByClipping;

    [UIView setAnimationsEnabled:NO];
    [self.projectVC.masterView.nameButton setTitle:self.userName forState:UIControlStateNormal];
    self.projectVC.masterView.nameButton.center = CGPointMake(self.projectVC.masterView.nameButton.center.x, 107-60/self.projectVC.masterView.nameButton.titleLabel.font.pointSize);
    [self.projectVC.masterView.teamButton setTitle:[FirebaseHelper sharedHelper].teamName forState:UIControlStateNormal];
    [self.projectVC.masterView.nameButton layoutIfNeeded];
    [self.projectVC.masterView.teamButton layoutIfNeeded];
    CGRect teamRect = [[FirebaseHelper sharedHelper].teamName boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: self.projectVC.masterView.teamMenuButton.titleLabel.font} context:nil];
    self.projectVC.masterView.teamMenuButton.center = CGPointMake(MIN(teamRect.size.width+40,185), self.projectVC.masterView.teamMenuButton.center.y);
    self.projectVC.masterView.nameButton.hidden = false;
    self.projectVC.masterView.teamButton.hidden = false;
    self.projectVC.masterView.teamMenuButton.hidden = false;
    [UIView setAnimationsEnabled:YES];
    
    [self.projectVC.masterView.avatarButton removeFromSuperview];
    self.projectVC.masterView.avatarButton = [AvatarButton buttonWithType:UIButtonTypeCustom];
    [self.projectVC.masterView.avatarButton addTarget:self.projectVC.masterView action:@selector(settingsTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.projectVC.masterView.avatarButton.userID = self.uid;
    [self.projectVC.masterView.avatarButton generateIdenticonWithShadow:true];
    self.projectVC.masterView.avatarButton.frame = CGRectMake(-87, -16, self.projectVC.masterView.avatarButton.userImage.size.width, self.projectVC.masterView.avatarButton.userImage.size.height);
    self.projectVC.masterView.avatarButton.transform = CGAffineTransformMakeScale(.25, .25);
    [self.projectVC.masterView addSubview:self.projectVC.masterView.avatarButton];
    
    [self.projectVC.chatAvatar removeFromSuperview];
    self.projectVC.chatAvatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
    self.projectVC.chatAvatar.userID = self.uid;
    [self.projectVC.chatAvatar generateIdenticonWithShadow:false];
    self.projectVC.chatAvatar.frame = CGRectMake(-100,4, self.projectVC.chatAvatar.userImage.size.width, self.projectVC.chatAvatar.userImage.size.height);
    self.projectVC.chatAvatar.transform = CGAffineTransformMakeScale(.16, .16);
    [self.projectVC.chatView addSubview:self.projectVC.chatAvatar];
    self.projectVC.chatAvatar.hidden = true;
    [self.projectVC.masterView.projectsTable reloadData];
    
    if (self.projectVC.masterView.defaultRow.row != [FirebaseHelper sharedHelper].visibleProjectIDs.count)
        [self.projectVC.masterView tableView:self.projectVC.masterView.projectsTable didSelectRowAtIndexPath:self.projectVC.masterView.defaultRow];
}

-(void) observeTeam {
    
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@", self.teamID];

    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        self.teamName = [snapshot.value objectForKey:@"name"];
        [self.team setObject:[snapshot.value objectForKey:@"name"] forKey:@"name"];
        
        NSDictionary *projectsDict = [snapshot.value objectForKey:@"projects"];
        
        if (projectsDict) [self.team setObject:projectsDict forKey:@"projects"];
        
        userChildrenCount = [[snapshot.value objectForKey:@"users"] allKeys].count;
        
        for (NSString *userID in [[snapshot.value objectForKey:@"users"] allKeys]) {
            
            if (![userID isEqualToString:self.uid]) [[self.team objectForKey:@"users"] setObject:[NSMutableDictionary dictionary] forKey:userID];
            
            [[[self.team objectForKey:@"users"] objectForKey:userID] setObject:[[snapshot.value objectForKey:@"users"] objectForKey:userID] forKey:@"teamOwner"];
            
            [self observeUserWithID:userID];
        }
    }];
}

-(void) observeBoardWithID:(NSString *)boardID {

    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", boardID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [[ref childByAppendingPath:@"commentsID"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:@"commentsID"];
        [self.comments setObject:[NSMutableDictionary dictionary] forKey:snapshot.value];
        [self observeCommentsOnBoardWithID:boardID];
    }];
    
    [[ref childByAppendingPath:@"name"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value == [NSNull null]) return;
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:@"name"];

        if (self.projectVC.carousel.currentItemIndex == [self.projectVC.boardIDs indexOfObject:boardID]) {

            self.projectVC.boardNameLabel.text = snapshot.value;
            if ([self.projectVC.boardNameLabel.text isEqualToString:@"Untitled"]) self.projectVC.boardNameLabel.alpha = .2;
            else self.projectVC.boardNameLabel.alpha = 1;
            [self.projectVC.boardNameLabel sizeToFit];
            
            if ([self.projectVC.activeBoardID isEqualToString:boardID]) {
                
                UILabel *boardLevelNameLabel = (UILabel *)[self.projectVC.view viewWithTag:102];
                NSString *boardNameString = [NSString stringWithFormat:@"|  %@", snapshot.value];
                boardLevelNameLabel.text = boardNameString;
                if ([boardLevelNameLabel.text isEqualToString:@"Untitled"]) boardLevelNameLabel.alpha = .2;
                else boardLevelNameLabel.alpha = 1;
                [boardLevelNameLabel sizeToFit];
                
                UIButton *editBoardNameButton = (UIButton *)[self.projectVC.view viewWithTag:103];
                editBoardNameButton.frame = CGRectMake(boardLevelNameLabel.frame.origin.x+boardLevelNameLabel.frame.size.width+6, boardLevelNameLabel.frame.origin.y+4, 17, 17);
                
                self.projectVC.boardNameLabel.center = CGPointMake(self.projectVC.carousel.center.x+105, self.projectVC.boardNameLabel.center.y);
                self.projectVC.boardNameEditButton.center = CGPointMake(self.projectVC.carousel.center.x+self.projectVC.boardNameLabel.frame.size.width/2+122, self.projectVC.boardNameLabel.center.y);
            }
            else if (self.currentProjectID) {
                
                self.projectVC.boardNameLabel.center = CGPointMake(self.projectVC.carousel.center.x, self.projectVC.boardNameLabel.center.y);
                self.projectVC.boardNameEditButton.center = CGPointMake(self.projectVC.carousel.center.x+self.projectVC.boardNameLabel.frame.size.width/2+17, self.projectVC.boardNameLabel.center.y);
            }
        }
    }];
    
    [[ref childByAppendingPath:@"undo"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        for (NSString *userID in [snapshot.value allKeys]) {
            
            [self observeUndoForUser:userID onBoard:boardID];
        }
    }];
    
    [[ref childByAppendingPath:@"subpaths"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        for (NSString *userID in [snapshot.value allKeys]) {
            
            if ([userID isEqualToString:self.uid]) continue;
            [self observeSubpathsForUser:userID onBoard:boardID];
        }
    }];
    
    [[ref childByAppendingPath:@"updatedAt"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:@"updatedAt"];
    }];
}

-(void) observeSubpathsForUser:(NSString *)userID onBoard:(NSString *)boardID {
    
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/subpaths/%@", boardID, userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSMutableDictionary *subpathsDict = [[[self.boards objectForKey:boardID] objectForKey:@"subpaths"] objectForKey:userID];
        
        NSMutableArray *orderedKeys = [NSMutableArray arrayWithArray:subpathsDict.allKeys];
        NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [orderedKeys sortUsingDescriptors:@[sorter]];
        
        NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];

        if ([boardIDs containsObject:boardID] && ![orderedKeys containsObject:snapshot.key]) {
            
            [subpathsDict setObject:snapshot.value forKey:snapshot.key];
            [[[[self.boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:userID] setObject:snapshot.key forKey:@"currentIndexDate"];
            
            for (NSString *dateString in orderedKeys) {

                if ([dateString doubleValue] > [snapshot.key doubleValue]) [subpathsDict removeObjectForKey:dateString];
            }
            
            NSInteger boardIndex = [boardIDs indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];

            if (boardView.drawingUserID && ![boardView.drawingUserID isEqualToString:userID]) {
                
                boardView.shouldRedraw = true;
            }
            else {
                
                if([snapshot.value respondsToSelector:@selector(objectForKey:)]) [boardView drawSubpath:snapshot.value];
                else [boardView drawSubpath:@{snapshot.key : snapshot.value}];
                
                [boardView addUserDrawing:userID];
            }
        }
    }];
}

-(void) observeUndoForUser:(NSString *)userID onBoard:(NSString *)boardID {

    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", boardID, userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value == [NSNull null]) return;

        NSMutableDictionary *oldSubpathsDict = [[[self.boards objectForKey:boardID] objectForKey:@"subpaths"] objectForKey:userID];
        NSMutableArray *oldOrderedKeys = [NSMutableArray arrayWithArray:oldSubpathsDict.allKeys];
        NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [oldOrderedKeys sortUsingDescriptors:@[sorter]];
        
        double oldLastSubpathDate = [[oldOrderedKeys lastObject] doubleValue];
        
        NSMutableDictionary *undoDict = [[self.boards objectForKey:boardID] objectForKey:@"undo"];
        
        double oldIndexDate = [[[undoDict objectForKey:userID] objectForKey:@"currentIndexDate"] doubleValue];
        
        [undoDict setObject:[snapshot.value mutableCopy] forKey:userID];
        
        NSInteger newIndex = [[snapshot.value objectForKey:@"currentIndex"] integerValue];
        double newIndexDate = [[snapshot.value objectForKey:@"currentIndexDate"] doubleValue];
        
        NSMutableDictionary *newSubpathsDict = [[[self.boards objectForKey:boardID] objectForKey:@"subpaths"] objectForKey:userID];
        NSMutableArray *newOrderedKeys = [NSMutableArray arrayWithArray:newSubpathsDict.allKeys];
        [newOrderedKeys sortUsingDescriptors:@[sorter]];

        for (NSString *dateString in newOrderedKeys) {
            
            if (oldIndexDate > 0 && [dateString doubleValue] > oldIndexDate && newIndex == 0 && oldLastSubpathDate != newIndexDate) [newSubpathsDict removeObjectForKey:dateString];
        }
        
        NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        if ([boardIDs containsObject:boardID]) {
            
            NSUInteger boardIndex = [boardIDs indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            [self.projectVC drawBoard:boardView];
        }
        
        if ([userID isEqualToString:self.uid]) [ref removeAllObservers];
    }];
}

-(void) observeCurrentProjectBoards {
    
    NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
    
    for (NSString *boardID in boardIDs) {
        
        if (![self.loadedBoardIDs containsObject:boardID]) [self loadBoardWithID:boardID];
    }
}

-(void) loadBoardWithID:(NSString *)boardID {
    
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", boardID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [self.boards setObject:snapshot.value forKey:boardID];
        [self observeBoardWithID:boardID];
    }];
}

-(void)observeChatWithID:(NSString *)chatID {
    
    NSString *chatString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/chats/%@", chatID];
    
    Firebase *ref = [[Firebase alloc] initWithUrl:chatString];

    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSMutableDictionary *chatDict = [NSMutableDictionary dictionaryWithDictionary:[self.chats objectForKey:chatID]];
        [chatDict setObject:snapshot.value forKey:snapshot.key];
    
        [self.chats setObject:chatDict forKey:chatID];
        
        [self.projectVC updateMessages];
        [self.projectVC.chatTable reloadData];
        
    }];
}

-(void)observeCommentsOnBoardWithID:(NSString *)boardID {
    
    NSString *commentsID = [[self.boards objectForKey:boardID] objectForKey:@"commentsID"];
    
    NSString *commentsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@", commentsID];
    Firebase *ref = [[Firebase alloc] initWithUrl:commentsString];

    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value != [NSNull null]) {
        
            for (NSString *commentThreadID in [snapshot.value allKeys]) {
                
                NSDictionary *infoDict = [[snapshot.value objectForKey:commentThreadID] objectForKey:@"info"];
                NSDictionary *commentDict = @{ @"location" : [infoDict objectForKey:@"location"],
                                               @"owner" : [infoDict objectForKey:@"owner"],
                                               @"title" : [infoDict objectForKey:@"title"]
                                               };
                
                [[self.comments objectForKey:commentsID] setObject:[commentDict mutableCopy] forKey:commentThreadID];
                
                [self observeCommentThreadWithID:commentThreadID boardID:boardID];
            }
        }
        
        NSArray *currentProjectBoardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        
        if (![self.loadedBoardIDs containsObject:boardID] && [currentProjectBoardIDs containsObject:boardID]) {
            
            [self.loadedBoardIDs addObject:boardID];
            NSInteger boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            boardView.loadingView.hidden = true;
            boardView.fadeView.hidden = true;
            [boardView layoutComments];
            [self.projectVC drawBoard:boardView];
            
            for (NSString *userID in [[self.team objectForKey:@"users"] allKeys]) {
                
                if ([[[[self.team objectForKey:@"users"] objectForKey:userID] objectForKey:@"inBoard"] isEqualToString:boardID] && ![boardView.activeUserIDs containsObject:userID]) [boardView.activeUserIDs addObject:userID];
            }
            [boardView layoutAvatars];
        }
    }];
    
    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {

        if ([[[snapshot.value objectForKey:@"info"] objectForKey:@"owner"] isEqualToString:self.uid]) return;
        
        if (![[self.comments objectForKey:commentsID] objectForKey:snapshot.key]){
            
            NSDictionary *infoDict = [snapshot.value objectForKey:@"info"];
            NSDictionary *commentDict = @{ @"location" : [infoDict objectForKey:@"location"],
                                           @"owner" : [infoDict objectForKey:@"owner"]
                                           };
            
            [[self.comments objectForKey:commentsID] setObject:[commentDict mutableCopy] forKey:snapshot.key];
            [self observeCommentThreadWithID:snapshot.key boardID:boardID];
        }
    }];
    
    [ref observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        if ([[[snapshot.value objectForKey:@"info"] objectForKey:@"owner"] isEqualToString:self.uid]) return;
        
        [[self.comments objectForKey:commentsID] removeObjectForKey:snapshot.key];
        
        NSArray *currentProjectBoardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        
        if ([currentProjectBoardIDs containsObject:boardID]) {
            
            NSInteger boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            [boardView layoutComments];
        }
        
        [[ref childByAppendingPath:snapshot.key] removeAllObservers];
    }];
}

-(void) observeCommentThreadWithID:(NSString *)commentThreadID boardID:(NSString *)boardID {
    
    NSString *commentsID = [[self.boards objectForKey:boardID] objectForKey:@"commentsID"];
    
    NSString *commentsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@", commentsID];
    Firebase *ref = [[Firebase alloc] initWithUrl:commentsString];
    
    NSMutableDictionary *threadDict = [[self.comments objectForKey:commentsID] objectForKey:commentThreadID];
    
    NSString *infoString = [NSString stringWithFormat:@"%@/info", commentThreadID];
    
    [[ref childByAppendingPath:infoString] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot){
        
        if (snapshot.value == [NSNull null] || [[snapshot.value objectForKey:@"owner"] isEqualToString:self.uid]) return;
        
        [threadDict setObject:[snapshot.value objectForKey:@"location"] forKey:@"location"];
        [threadDict setObject:[snapshot.value objectForKey:@"title"] forKey:@"title"];
        
        NSArray *currentProjectBoardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];

        if ([currentProjectBoardIDs containsObject:boardID]) {
            
            NSInteger boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            [boardView layoutComments];
            
            NSString *titleString = [snapshot.value objectForKey:@"title"];
            
            if ([self.projectVC.activeCommentThreadID isEqualToString:commentThreadID] && titleString.length > 0) {
                self.projectVC.commentTitleTextField.text = titleString;
                self.projectVC.commentTitleTextField.hidden = false;
            }
        }
    }];
    
    NSString *messageString = [NSString stringWithFormat:@"%@/messages", commentThreadID];
    
    [[ref childByAppendingPath:messageString] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        if(![threadDict objectForKey:@"messages"]) [threadDict setObject:[NSMutableDictionary dictionary] forKey:@"messages"];
        
        [[threadDict objectForKey:@"messages"] setObject:snapshot.value forKey:snapshot.key];
        
        if ([self.projectVC.activeCommentThreadID isEqualToString:commentThreadID]) {
            [self.projectVC updateMessages];
            [self.projectVC.chatTable reloadData];
        }
    }];
}

-(void) resetUndo {
    
    int currentIndex = [(NSNumber *)[[[[self.boards objectForKey:self.projectVC.activeBoardID] objectForKey:@"undo"] objectForKey:self.uid] objectForKey:@"currentIndex"] intValue];
    
    if (currentIndex == 0) return;
    
    NSMutableDictionary *undoDict = [[[self.boards objectForKey:self.projectVC.activeBoardID] objectForKey:@"undo"] objectForKey:self.uid];
    
    [undoDict setObject:@0 forKey:@"currentIndex"];
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", self.projectVC.activeBoardID, self.uid];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    [[boardRef childByAppendingPath:@"currentIndex"] setValue:@0];
    
    int total = [(NSNumber *)[undoDict objectForKey:@"total"] intValue];
    total -= currentIndex;
    [undoDict setObject:@(total) forKey:@"total"];
    [[boardRef childByAppendingPath:@"total"] setValue:@(total)];
    
    NSMutableDictionary *subpathsDict = [[[self.boards objectForKey:self.projectVC.activeBoardID] objectForKey:@"subpaths"] objectForKey:self.uid];
    
    for (NSString *dateString in subpathsDict.allKeys) {
        
        if ([dateString doubleValue] > [self.projectVC.activeBoardUndoIndexDate doubleValue]) {
            
            [subpathsDict removeObjectForKey:dateString];
            
            NSString *subpathString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/subpaths/%@/%@", self.projectVC.activeBoardID, self.uid, dateString];
            Firebase *subpathRef = [[Firebase alloc] initWithUrl:subpathString];
            [subpathRef removeValue];
        }
    }
}

-(void) setInProject:(NSString *)projectID {
    
    if (!self.uid) return;
    
    if (self.currentProjectID) [[[self.team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.currentProjectID forKey:@"inProject"];
    
    NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/inProject", self.uid];
    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
    [userRef setValue:projectID];
}

-(void) setInBoard:(NSString *)boardID {
    
    if (!self.uid) return;
    
    [[[self.team objectForKey:@"users"] objectForKey:self.uid] setObject:boardID forKey:@"inBoard"];
    
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@",self.uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    [[ref childByAppendingPath:@"inBoard"] setValue:boardID];
}

-(void) setProjectViewedAt {
    
    if (!self.currentProjectID) return;
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];

    [[[self.projects objectForKey:self.currentProjectID] objectForKey:@"viewedAt"] setObject:dateString forKey:self.uid];

    NSString *oldProjectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/viewedAt/%@", self.currentProjectID, self.uid];
    Firebase *oldProjectRef = [[Firebase alloc] initWithUrl:oldProjectString];
    [oldProjectRef setValue:dateString];
}

-(void) setProjectUpdatedAt {
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    [[self.projects objectForKey:self.currentProjectID] setObject:dateString forKey:@"updatedAt"];
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/updatedAt", self.currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    [projectRef setValue:dateString];
}

-(void) setActiveBoardUpdatedAt {

    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/updatedAt", self.projectVC.activeBoardID];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    [boardRef setValue:dateString];
    [[self.boards objectForKey:self.projectVC.activeBoardID] setObject:dateString forKey:@"updatedAt"];
}

-(NSIndexPath *) getLastViewedProjectIndexPath {
    
    double viewedAt = 0;
    NSString *defaultProjectName;
    NSMutableArray *projectNames = [NSMutableArray array];
    
    for (NSString *projectID in self.visibleProjectIDs) {
        
        double newViewedAt = [[[[self.projects objectForKey:projectID] objectForKey:@"viewedAt"] objectForKey:self.uid] doubleValue];
        NSString *projectName = [[self.projects objectForKey:projectID] objectForKey:@"name"];
        [projectNames addObject:projectName];
        
        if (newViewedAt > viewedAt) {
            viewedAt = newViewedAt;
            defaultProjectName = projectName;
        }
    }
    
    NSArray *orderedProjectNames = [projectNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSInteger projectIndex = [orderedProjectNames indexOfObject:defaultProjectName];

    return [NSIndexPath indexPathForItem:projectIndex inSection:0];
}

- (void) removeAllObservers {
    
    NSString *uidString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@", self.uid];
    Firebase *uidRef = [[Firebase alloc] initWithUrl:uidString];
    [uidRef removeAllObservers];
    
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@", self.teamID];
    Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
    [teamRef removeAllObservers];
    
    for (NSString *userID in [[self.team objectForKey:@"users"] allKeys]) {

        NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/", userID];
        Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
        [userRef removeAllObservers];
    }
    
    for (NSString *projectID in self.projects.allKeys) {
        
        NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@", projectID];
        Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
        [[projectRef childByAppendingPath:@"info"] removeAllObservers];
        [[projectRef childByAppendingPath:@"viewedAt"] removeAllObservers];
        [[projectRef childByAppendingPath:@"updatedAt"] removeAllObservers];
    }
    
    for (NSString *boardID in self.boards.allKeys) {
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", boardID];
        Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
        [[boardRef childByAppendingPath:@"name"] removeAllObservers];
        [[boardRef childByAppendingPath:@"updatedAt"] removeAllObservers];
        
        for (NSString *userID in [[[self.boards objectForKey:boardID] objectForKey:@"undo"] allKeys]) {
            
            NSString *undoString = [NSString stringWithFormat:@"undo/%@", userID];
            [[boardRef childByAppendingPath:undoString] removeAllObservers];
        }
        
        for (NSString *userID in [[[self.boards objectForKey:boardID] objectForKey:@"subpaths"] allKeys]) {
            
            NSString *subpathsString = [NSString stringWithFormat:@"subpaths/%@", userID];
            [[boardRef childByAppendingPath:subpathsString] removeAllObservers];
        }
    }

    for (NSString *commentsID in self.comments.allKeys) {
        
        NSString *commentsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@", commentsID];
        Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
        [commentsRef removeAllObservers];
        
        for (NSString *commentThreadID in [[self.comments objectForKey:commentsID] allKeys]) {
            
            NSString *infoString = [NSString stringWithFormat:@"%@/info", commentThreadID];
            [[commentsRef childByAppendingPath:infoString] removeAllObservers];
            
            NSString *messageString = [NSString stringWithFormat:@"%@/messages", commentThreadID];
            [[commentsRef childByAppendingPath:messageString] removeAllObservers];
        }
    }
    
    for (NSString *chatID in self.chats.allKeys) {
     
        NSString *chatString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/chats/%@", chatID];
        Firebase *chatRef = [[Firebase alloc] initWithUrl:chatString];
        [chatRef removeAllObservers];
    }
    
}

- (void) clearData {
    
    [self setInBoard:@"none"];
    [self setInProject:@"none"];
    
    self.uid = nil;
    self.email = nil;
    self.userName = nil;
    self.teamID = nil;
    self.teamName = nil;
    self.team = [NSMutableDictionary dictionary];
    self.projects = [NSMutableDictionary dictionary];
    self.visibleProjectIDs = [NSMutableArray array];
    self.loadedBoardIDs = [NSMutableArray array];
    self.comments = [NSMutableDictionary dictionary];
    self.chats = [NSMutableDictionary dictionary];
    self.teamLoaded = false;
    self.projectsLoaded = false;
    
    projectChildrenCount = 0;
    userChildrenCount = 0;
    
    [self.projectVC.masterView.projectsTable reloadData];
    self.projectVC.messages = [NSMutableArray array];
    [self.projectVC.chatTable reloadData];
}

@end
