
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
#import "NameFromInviteViewController.h"
#import "UserDeletedAlertViewController.h"
#import "SignedOutAlertViewController.h"
#import "OfflineAlertViewController.h"
#import <Instabug/Instabug.h>
#import "Flurry.h"

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
        sharedHelper.viewedProjectIDs = [NSMutableArray array];
        sharedHelper.loadedBoardIDs = [NSMutableArray array];
        sharedHelper.loadedUsers = [NSMutableDictionary dictionary];
        
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
            else if (self.loggedIn && [((UINavigationController *)self.projectVC.presentedViewController).viewControllers[0] isKindOfClass:[OfflineAlertViewController class]]) {
                
                OfflineAlertViewController *vc = (OfflineAlertViewController *)((UINavigationController *)self.projectVC.presentedViewController).viewControllers[0];
                vc.offlineLabel.alpha = .5;
                vc.offlineLabel.text = @"Reconnecting...";
                
                [self checkAuthStatus];
            }
            
            NSLog(@"Yayyy, we have the interwebs!");
        });
    };
    
    reachability.unreachableBlock = ^(Reachability *reach) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            weakSelf.connected = false;
            NSLog(@"Someone broke the internet :(");
            
            if (self.loggedIn) {
                
                if (self.projectVC.activeBoardID) [self.projectVC closeTapped];
                    
                else {
                    
                    [self clearData];
                    
                    [self.projectVC hideAll];
                    self.projectVC.masterView.teamButton.hidden = true;
                    self.projectVC.masterView.teamMenuButton.hidden = true;
                    self.projectVC.masterView.nameButton.hidden = true;
                    self.projectVC.masterView.avatarButton.hidden = true;
                    self.projectVC.masterView.avatarShadow.hidden = true;
                    
                    OfflineAlertViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"Offline"];
                    
                    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                    nav.modalPresentationStyle = UIModalPresentationFormSheet;
                    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    
                    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
                    logoImageView.frame = CGRectMake(162, 8, 32, 32);
                    [nav.navigationBar addSubview:logoImageView];
                    
                    [self.projectVC presentViewController:nav animated:YES completion:nil];
                }
            }
        });
    };
    
    [reachability startNotifier];
}

-(void) checkAuthStatus {
    
    Firebase *prodRef = [[Firebase alloc] initWithUrl:@"https://quillapp.firebaseio.com/"];
    FirebaseSimpleLogin *prodAuthClient = [[FirebaseSimpleLogin alloc] initWithRef:prodRef];
    
    Firebase *devRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
    FirebaseSimpleLogin *devAuthClient = [[FirebaseSimpleLogin alloc] initWithRef:devRef];
    [devAuthClient logout];
    
    //if (self.projectVC.presentedViewController) [self.projectVC dismissViewControllerAnimated:YES completion:nil];
    
    //[prodAuthClient logout];
    
    [prodAuthClient checkAuthStatusWithBlock:^(NSError *error, FAUser *user) {
        
        if (error != nil) {
            NSLog(@"%@", error);
            [prodAuthClient logout];
            [self checkAuthStatus];
        }
        else if (user == nil) {
            
            SignInViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
            //SignUpFromInviteViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignUpFromInvite"];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

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
            self.email = user.email;
            [self setRoles];
            [self observeLocalUser];
        }
    }];
}

-(void) setRoles {
    
    NSArray *adminEmails = @[ @"cos@tigrillo.co",
                              @"max@tigrillo.co",
                              ];
    
    self.isAdmin = [adminEmails containsObject:self.email];

    if (!self.isDev) {

        NSArray *devEmails = @[ @"therealcos@gmail.com",
                                @"drecos1@gmail.com",
                                @"cos+testing@tigrillo.co",
                                @"max+testing@tigrillo.co",
                                @"max.engel@me.com",
                                ];
        
        self.isDev = [devEmails containsObject:self.email];
    }
    
    if (self.isDev) self.db = @"chalkto";
    else self.db = @"quillapp";
}

-(void) createUser {
    
    if (self.projectVC.presentedViewController) [self.projectVC dismissViewControllerAnimated:YES completion:nil];
    
    BOOL isDev;
    
    NSString *token = [self.inviteURL.host stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if ([token isEqualToString:@"tEsTtOkEn"]) isDev = true;
    else isDev = false;

    self.isDev = isDev;
    [self setRoles];
    
    [self removeAllObservers];
    [self clearData];
    
    self.isDev = isDev;
    [self setRoles];
    
    [self.projectVC hideAll];
    
    NSString *tokenString = [NSString stringWithFormat:@"https://%@.firebaseio.com/tokens/%@", self.db, token];
    Firebase *tokenRef = [[Firebase alloc] initWithUrl:tokenString];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:tokenRef];
    
    [authClient logout];
    
    [tokenRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        self.inviteURL = nil;

        if ([[snapshot.value allKeys] containsObject:@"newOwner"]) {
            
            self.email = [snapshot.value objectForKey:@"newOwner"];
            self.teamID = [snapshot.value objectForKey:@"teamID"];
            
            SignInViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
            vc.switchButton.hidden = false;
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            
            UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
            logoImageView.frame = CGRectMake(155, 8, 32, 32);
            logoImageView.tag = 800;
            [nav.navigationBar addSubview:logoImageView];
            
            [self.projectVC presentViewController:nav animated:YES completion:nil];
        }
        else {
            
            self.teamID = [snapshot.value objectForKey:@"teamID"];
            self.teamName = [snapshot.value objectForKey:@"teamName"];
            self.email = [snapshot.value objectForKey:@"email"];
            
            [Flurry logEvent:@"Invite_User-Invite_Used" withParameters: @{@"teamID" : self.teamID}];
            
            [self.team setObject:[NSMutableDictionary dictionary] forKey:@"users"];
            
            for (NSString *userID in [[snapshot.value objectForKey:@"users"] allKeys]) {
                
                NSString *userName = [[snapshot.value objectForKey:@"users"] objectForKey:userID];
                NSMutableDictionary *nameDict = [@{@"name" : userName} mutableCopy];
                [[self.team objectForKey:@"users"] setObject:nameDict forKey:userID];
            }

            if ([snapshot.value objectForKey:@"project"]) self.invitedProject = [snapshot.value objectForKey:@"project"];
            
            [Instabug setDefaultEmail:self.email];
            
            SignUpFromInviteViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignUpFromInvite"];
            vc.invitedBy = [snapshot.value objectForKey:@"invitedBy"];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            
            UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
            logoImageView.frame = CGRectMake(155, 8, 32, 32);
            logoImageView.tag = 800;
            [nav.navigationBar addSubview:logoImageView];
            
            [self.projectVC presentViewController:nav animated:YES completion:nil];
        }
    }];
}

-(void) observeLocalUser {
    
    NSString *uidString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@", self.db, self.uid];
    Firebase *userRef = [[Firebase alloc] initWithUrl:uidString];
    
    NSDictionary *statusDict = @{ @"device" : [[UIDevice currentDevice] identifierForVendor].UUIDString,
                                  @"inProject" : @"none",
                                  @"inBoard" : @"none"
                                 };
    
    [[userRef childByAppendingPath:@"status"] setValue:statusDict withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            NSString *deviceID = [snapshot.value objectForKey:@"device"];
            
            if (deviceID && ![deviceID isEqualToString:[[UIDevice currentDevice] identifierForVendor].UUIDString] && ![deviceID isEqualToString:@"none"]) {
                
                if (self.projectVC.presentedViewController && ![((UINavigationController *)self.projectVC.presentedViewController).viewControllers[0] isKindOfClass:[SignedOutAlertViewController class]]) [self.projectVC.presentedViewController dismissViewControllerAnimated:YES completion:nil];
                
                if (self.projectVC.activeBoardID) [self.projectVC closeTapped];
                else if (self.uid) {
                    
                    NSString *email = self.email;
                    
                    [self signOut];
                    
                    SignedOutAlertViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignedOut"];
                    vc.email = email;
                    
                    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                    nav.modalPresentationStyle = UIModalPresentationFormSheet;
                    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    
                    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
                    logoImageView.frame = CGRectMake(162, 8, 32, 32);
                    logoImageView.tag = 800;
                    [nav.navigationBar addSubview:logoImageView];
                    
                    [self.projectVC presentViewController:nav animated:YES completion:nil];
                }
            }
        }];
    }];
    
    [userRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *infoDict = [snapshot.value objectForKey:@"info"];
        
        self.userName = [infoDict objectForKey:@"name"];
        self.teamID = [infoDict objectForKey:@"team"];
        self.email = [infoDict objectForKey:@"email"];
        
        [Instabug setDefaultEmail:self.email];
        
        UINavigationController *nav = (UINavigationController *)self.projectVC.presentedViewController;
        SignInViewController *signInVC = (SignInViewController *)nav.viewControllers[0];
        
        if (!self.teamID) {
            
            [signInVC accountCreated];
        }
        else if (!self.userName) {
            
            NameFromInviteViewController *newNameVC = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"NameFromInvite"];
            
            UIImageView *logoImage = (UIImageView *)[signInVC.navigationController.navigationBar viewWithTag:800];
            logoImage.hidden = true;
            logoImage.frame = CGRectMake(154, 8, 32, 32);
            
            [signInVC performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
            [signInVC.navigationController pushViewController:newNameVC animated:YES];
        }
        else if ([[infoDict objectForKey:@"deleted"] integerValue] == 1) {
            
            UserDeletedAlertViewController *vc = [self.projectVC.storyboard instantiateViewControllerWithIdentifier:@"UserDeleted"];
            
            NSString *teamString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams/%@/name", self.db, self.teamID];
            Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
            
            [teamRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                
                self.teamName = snapshot.value;
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                nav.modalPresentationStyle = UIModalPresentationFormSheet;
                nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                
                UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
                logoImageView.frame = CGRectMake(155, 8, 32, 32);
                logoImageView.tag = 800;
                [nav.navigationBar addSubview:logoImageView];
                
                [self.projectVC presentViewController:nav animated:YES completion:nil];
            }];
        }
        else {
         
            //[signInVC dismissViewControllerAnimated:YES completion:nil];
            
            [self.team setObject:[@{self.uid:[NSMutableDictionary dictionary]} mutableCopy] forKey:@"users"];
            
            for (NSString *key1 in snapshot.value) {
                
                if ([key1 isEqualToString:@"info"] || [key1 isEqualToString:@"status"]) {
                 
                    NSDictionary *dict = [snapshot.value objectForKey:key1];
                    
                    for (NSString *key2 in dict) {
                        
                        [[[self.team objectForKey:@"users"] objectForKey:self.uid] setObject:[dict objectForKey:key2] forKey:key2];
                    }
                }
                else if ([key1 isEqualToString:@"avatar"]) {
                    
                    NSString *imgString = [snapshot.value objectForKey:key1];
                    
                    if ([snapshot.value objectForKey:key1] == [NSNull null] || [imgString isEqualToString:@"none"]) {
                        self.avatarImage = nil;
                    }
                    else {
                        NSData *data = [[NSData alloc] initWithBase64EncodedString:imgString options:0];
                        UIImage *image = [UIImage imageWithData:data];
                        [[[self.team objectForKey:@"users"] objectForKey:self.uid] setObject:image forKey:@"avatar"];
                        self.avatarImage = image;
                    }
                    
                }
            }

            [self.loadedUsers setObject:[@{@"avatar":@1,@"info":@1,@"status":@1} mutableCopy] forKey:self.uid];

            [self observeTeam];
            [self observeProjects];
        }
    }];
}

-(void) observeUserWithID:(NSString *)userID {
    
    NSString *userString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/", self.db, userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:userString];

    [[ref childByAppendingPath:@"status"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {

        NSDictionary *oldUserDict = [[[self.team objectForKey:@"users"] objectForKey:userID] copy];
        NSMutableDictionary *newUserDict = snapshot.value;

        for (NSString *key in newUserDict.allKeys) {
            
            [[[self.team objectForKey:@"users"] objectForKey:userID] setObject:[snapshot.value objectForKey:key] forKey:key];
        }
        
        [[self.loadedUsers objectForKey:userID] setObject:@1 forKey:@"status"];
        
        if (!self.teamLoaded) [self checkUsersLoaded];
        
        if ([userID isEqualToString:self.uid]) {
            [[ref childByAppendingPath:@"status"] removeAllObservers];
            return;
        }
        
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

        NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
        
        if ([versionsArray containsObject:boardID]) {
            
            NSInteger boardIndex = [versionsArray indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.versionsCarousel itemViewAtIndex:boardIndex];
            
            if (inBoard && ![boardView.activeUserIDs containsObject:userID]) [boardView.activeUserIDs addObject:userID];
            else if (!inBoard) [boardView.activeUserIDs removeObject:userID];
            
            [boardView layoutAvatars];
        }
        
        if ([self.projectVC.boardIDs containsObject:boardID]){
            
            NSInteger boardIndex = [self.projectVC.boardIDs indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            
            if (inBoard && ![boardView.activeUserIDs containsObject:userID]) [boardView.activeUserIDs addObject:userID];
            else if (!inBoard) [boardView.activeUserIDs removeObject:userID];
            
            [boardView layoutAvatars];
        }
    }];

    [[ref childByAppendingPath:@"info"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        for (NSString *key in [snapshot.value allKeys]) {
            
            [[[self.team objectForKey:@"users"] objectForKey:userID] setObject:[snapshot.value objectForKey:key] forKey:key];
        }

        [[self.loadedUsers objectForKey:userID] setObject:@1 forKey:@"info"];
        
        if (!self.teamLoaded) [self checkUsersLoaded];
        
        if ([userID isEqualToString:self.uid]) [[ref childByAppendingPath:@"info"] removeAllObservers];

    }];
    
    [[ref childByAppendingPath:@"avatar"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value == [NSNull null] || [snapshot.value isEqualToString:@"none"]) {
            if ([userID isEqualToString:self.uid]) self.avatarImage = nil;
        }
        else {
            NSData *data = [[NSData alloc] initWithBase64EncodedString:snapshot.value options:0];
            UIImage *image = [UIImage imageWithData:data];
            [[[self.team objectForKey:@"users"] objectForKey:userID] setObject:image forKey:@"avatar"];
            if ([userID isEqualToString:self.uid]) self.avatarImage = image;
        }
        
        if (self.currentProjectID && [[[[self.projects objectForKey:self.currentProjectID] objectForKey:@"roles"] allKeys] containsObject:userID]) {
            
            [self.projectVC layoutAvatars];
            
            for (NSDictionary *messageDict in self.projectVC.messages) {
                
                if ([[messageDict objectForKey:@"user"] isEqualToString:userID]) {
                    [self.projectVC.chatTable reloadData];
                    break;
                }
            }
            
            if (self.projectVC.activeBoardID && [[[[self.boards objectForKey:self.projectVC.activeBoardID] objectForKey:@"subpaths"] allKeys] containsObject:userID]) {
                
                NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
                
                if ([self.projectVC.boardIDs containsObject:self.projectVC.activeBoardID]){
                    
                    NSInteger boardIndex = [self.projectVC.boardIDs indexOfObject:self.projectVC.activeBoardID];
                    BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
 
                    [boardView layoutAvatars];
                }
                
                if ([versionsArray containsObject:self.projectVC.activeBoardID]) {
                    
                    NSInteger boardIndex = [versionsArray indexOfObject:self.projectVC.activeBoardID];
                    BoardView *boardView = (BoardView *)[self.projectVC.versionsCarousel itemViewAtIndex:boardIndex];
                    
                    [boardView layoutAvatars];
                }
            }
        }
        
        [[self.loadedUsers objectForKey:userID] setObject:@1 forKey:@"avatar"];
        
        if (!self.teamLoaded) [self checkUsersLoaded];
        
        if ([userID isEqualToString:self.uid]) [[ref childByAppendingPath:@"avatar"] removeAllObservers];

    }];
}

- (void) observeProjects {
    
    NSString *projectsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams/%@/projects", self.db,self.teamID];
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
    
    NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@", self.db, projectID];
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
            
            if ([child.key isEqualToString:@"boards"]) {
                
                for (NSString *boardID in child.value) {
                    
                    if (![self.boards objectForKey:boardID] && [self.currentProjectID isEqualToString:projectID] && self.projectVC.activeBoardID == nil) {

                            if (![self.projectVC.boardIDs containsObject:boardID]) [self.projectVC.boardIDs addObject:boardID];

                            [self.projectVC.carousel reloadData];
                    }
                }
                
                for (NSString *boardID in [projectDict objectForKey:@"boards"]) {
                    
                    if (![child.value containsObject:boardID]) {
                        
                        if ([self.projectVC.activeBoardID isEqualToString:boardID]) {
                            
                            [self.projectVC.boardIDs removeObject:boardID];
                            [self.projectVC closeTapped];
                        }
                        else {
                            
                            [self.boards removeObjectForKey:boardID];
                            
                            NSLog(@"boardID is %@", boardID);
                            
                            NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", self.db, boardID];
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
                            
                            NSString *commentsID = [[self.boards objectForKey:boardID] objectForKey:@"commentsID"];
                            
                            if ([self.comments.allKeys containsObject:commentsID]) [self.comments removeObjectForKey:commentsID];
                            
                            NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@", self.db, commentsID];
                            Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
                            [commentsRef removeAllObservers];
                            
                            [self.projectVC.carousel reloadData];
                        }
                    }
                }
            }
            
            [projectDict setObject:child.value forKey:child.key];
        }
        
        [self.projects setObject:projectDict forKey:projectID];
        
        if (![self.chats.allKeys containsObject:[projectDict objectForKey:@"chatID"]]) [self observeChatWithID:[projectDict objectForKey:@"chatID"]];
        
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
        if (self.projectsLoaded && self.teamLoaded && self.userName) {
            
            [self.projectVC.masterView.projectsTable reloadData];
            [self.projectVC.masterView.projectsTable selectRowAtIndexPath:self.projectVC.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
}

-(void) updateMasterView {
    
    NSLog(@"master view updated");

    if (self.projectVC.presentedViewController) [self.projectVC.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
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
    
    [self.projectVC.chatAvatar removeFromSuperview];
    self.projectVC.chatAvatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
    self.projectVC.chatAvatar.userID = self.uid;
    
    if (self.avatarImage == nil) {
        
        self.projectVC.masterView.avatarShadow.hidden = true;
        [self.projectVC.masterView.avatarButton generateIdenticonWithShadow:true];
        self.projectVC.masterView.avatarButton.frame = CGRectMake(0, 0, self.projectVC.masterView.avatarButton.userImage.size.width, self.projectVC.masterView.avatarButton.userImage.size.height);
        self.projectVC.masterView.avatarButton.transform = CGAffineTransformMakeScale(.25, .25);
        self.projectVC.masterView.avatarButton.center = CGPointMake(40, 109);
        
        [self.projectVC.chatAvatar generateIdenticonWithShadow:false];
        self.projectVC.chatAvatar.frame = CGRectMake(-100,-100, self.projectVC.chatAvatar.userImage.size.width, self.projectVC.chatAvatar.userImage.size.height);
        self.projectVC.chatAvatar.transform = CGAffineTransformMakeScale(.16, .16);
    }
    else {
        
        [self.projectVC.masterView.avatarButton setImage:self.avatarImage forState:UIControlStateNormal];
        self.projectVC.masterView.avatarButton.frame = CGRectMake(0, 0, self.avatarImage.size.width, self.avatarImage.size.height);
        self.projectVC.masterView.avatarButton.transform = CGAffineTransformMakeScale(.86*64/self.avatarImage.size.width, .86*64/self.avatarImage.size.width);
        
        self.projectVC.masterView.avatarShadow.hidden = false;
        self.projectVC.masterView.avatarButton.imageView.layer.cornerRadius = self.avatarImage.size.width/2;
        self.projectVC.masterView.avatarButton.imageView.layer.masksToBounds = YES;
        self.projectVC.masterView.avatarButton.center = CGPointMake(40, 107);
        
        [self.projectVC.chatAvatar setImage:self.avatarImage forState:UIControlStateNormal];
        self.projectVC.chatAvatar.imageView.layer.cornerRadius = self.avatarImage.size.width/2;
        self.projectVC.chatAvatar.imageView.layer.masksToBounds = YES;
        
        if (self.avatarImage.size.height == 64) {
            
            self.projectVC.chatAvatar.frame = CGRectMake(-7, -8, self.avatarImage.size.width, self.avatarImage.size.height);
            self.projectVC.chatAvatar.transform = CGAffineTransformMakeScale(.56, .56);
        }
        else {
            
            self.projectVC.chatAvatar.frame = CGRectMake(-39, -40, self.avatarImage.size.width, self.avatarImage.size.height);
            self.projectVC.chatAvatar.transform = CGAffineTransformMakeScale(.28, .28);
        }
    }
    
    [self.projectVC.masterView addSubview:self.projectVC.masterView.avatarButton];
    [self.projectVC.chatView addSubview:self.projectVC.chatAvatar];
    self.projectVC.chatAvatar.hidden = true;

    [self.projectVC.masterView.projectsTable reloadData];
    [self.projectVC.masterView.projectsTable selectRowAtIndexPath:self.projectVC.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    if (self.projectVC.masterView.defaultRow.row != [FirebaseHelper sharedHelper].visibleProjectIDs.count)
        [self.projectVC.masterView tableView:self.projectVC.masterView.projectsTable didSelectRowAtIndexPath:self.projectVC.masterView.defaultRow];
}

-(void) observeTeam {
    
    NSString *teamString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams/%@", self.db, self.teamID];

    Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];

    [teamRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        self.teamName = [snapshot.value objectForKey:@"name"];
        [self.team setObject:[snapshot.value objectForKey:@"name"] forKey:@"name"];
        
        NSDictionary *projectsDict = [snapshot.value objectForKey:@"projects"];
        
        if ([[[snapshot.value objectForKey:@"users"] allKeys] isEqual:@[self.uid]]) {
            [self checkUsersLoaded];
            [[[self.team objectForKey:@"users"] objectForKey:self.uid] setObject:[[snapshot.value objectForKey:@"users"] objectForKey:self.uid] forKey:@"teamOwner"];
            return;
        }
        
        if (!self.teamLoaded) {
            for (NSString *userID in [[snapshot.value objectForKey:@"users"] allKeys]) {
                if (![userID isEqualToString:self.uid]) [self.loadedUsers setObject:[NSMutableDictionary dictionary] forKey:userID];
            }
        }
        
        for (NSString *userID in [[snapshot.value objectForKey:@"users"] allKeys]) {
            
            if (![userID isEqualToString:self.uid]) [[self.team objectForKey:@"users"] setObject:[NSMutableDictionary dictionary] forKey:userID];
            
            [[[self.team objectForKey:@"users"] objectForKey:userID] setObject:[[snapshot.value objectForKey:@"users"] objectForKey:userID] forKey:@"teamOwner"];
            
            if (![userID isEqualToString:self.uid]) [self observeUserWithID:userID];
        }
    }];
    
    [[teamRef childByAppendingPath:@"projects"] observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        NSString *projectID = snapshot.key;
        
        if (![self.projects.allKeys containsObject:projectID]) return;
        
        NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@", self.db,projectID];
        Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
        [[projectRef childByAppendingPath:@"info"] removeAllObservers];
        [[projectRef childByAppendingPath:@"viewedAt"] removeAllObservers];
        [[projectRef childByAppendingPath:@"updatedAt"] removeAllObservers];
        
        for (NSString *boardID in [[self.projects objectForKey:projectID] objectForKey:@"boards"]) {
            
            NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", self.db,boardID];
            Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
            [[boardRef childByAppendingPath:@"name"] removeAllObservers];
            [[boardRef childByAppendingPath:@"updatedAt"] removeAllObservers];
            
            NSDictionary *boardDict = [self.boards objectForKey:boardID];
            
            for (NSString *userID in [[boardDict objectForKey:@"undo"] allKeys]) {
                
                NSString *undoString = [NSString stringWithFormat:@"undo/%@", userID];
                [[boardRef childByAppendingPath:undoString] removeAllObservers];
            }
            
            for (NSString *userID in [[boardDict objectForKey:@"subpaths"] allKeys]) {
                
                NSString *subpathsString = [NSString stringWithFormat:@"subpaths/%@", userID];
                [[boardRef childByAppendingPath:subpathsString] removeAllObservers];
            }
            
            NSString *commentsID = [[self.boards objectForKey:boardID] objectForKey:@"commentsID"];
            NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@",self.db, commentsID];
            Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
            [commentsRef removeAllObservers];
            
            for (NSString *commentThreadID in [[self.comments objectForKey:commentsID] allKeys]) {
                
                NSString *infoString = [NSString stringWithFormat:@"%@/info", commentThreadID];
                [[commentsRef childByAppendingPath:infoString] removeAllObservers];
                
                NSString *messageString = [NSString stringWithFormat:@"%@/messages", commentThreadID];
                [[commentsRef childByAppendingPath:messageString] removeAllObservers];
            }
            
            [self.boards removeObjectForKey:boardID];
            [self.loadedBoardIDs removeObject:boardID];
            if (commentsID) [self.comments removeObjectForKey:commentsID];
        }
        
        NSString *chatID = [[self.projects objectForKey:projectID] objectForKey:@"chatID"];
        NSString *chatString = [NSString stringWithFormat:@"https://%@.firebaseio.com/chats/%@", self.db, chatID];
        Firebase *chatRef = [[Firebase alloc] initWithUrl:chatString];
        [chatRef removeAllObservers];
        
        
        [self.projects removeObjectForKey:projectID];
        [self.visibleProjectIDs removeObject:projectID];
        [[self.team objectForKey:@"projects"] removeObjectForKey:projectID];
        [self.chats removeObjectForKey:chatID];
        
        
        if ([self.currentProjectID isEqualToString:projectID]) {
            
            if (self.projectVC.activeBoardID) [self.projectVC closeTapped];
            else {
                
                [self.projectVC.masterView.projectsTable reloadData];
                [self.projectVC.masterView.projectsTable selectRowAtIndexPath:self.projectVC.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
                
                if (self.visibleProjectIDs.count > 0) {
                    
                    NSIndexPath *mostRecent = [self getLastViewedProjectIndexPath];
                    [self.projectVC.masterView tableView:self.projectVC.masterView.projectsTable didSelectRowAtIndexPath:mostRecent];
                }
                else {
                    [self.projectVC hideAll];
                    self.currentProjectID = nil;
                }
            }
        }
    }];
}

-(void) observeBoardWithID:(NSString *)boardID {

    //NSLog(@"observing Board %@", boardID);
    
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", self.db, boardID];
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
                NSString *boardNameString = [NSString stringWithFormat:@"|   %@", snapshot.value];
                boardLevelNameLabel.text = boardNameString;
                if ([boardLevelNameLabel.text isEqualToString:@"Untitled"]) boardLevelNameLabel.alpha = .2;
                else boardLevelNameLabel.alpha = 1;
                [boardLevelNameLabel sizeToFit];
                
                UIButton *editBoardNameButton = (UIButton *)[self.projectVC.view viewWithTag:103];
                editBoardNameButton.frame = CGRectMake(boardLevelNameLabel.frame.origin.x+boardLevelNameLabel.frame.size.width-5, boardLevelNameLabel.frame.origin.y-6, 36, 36);
                
                self.projectVC.boardNameLabel.center = CGPointMake(self.projectVC.carousel.center.x+105, self.projectVC.boardNameLabel.center.y);
                self.projectVC.boardNameEditButton.center = CGPointMake(self.projectVC.carousel.center.x+self.projectVC.boardNameLabel.frame.size.width/2+122, self.projectVC.boardNameLabel.center.y);
            }
            else if (self.currentProjectID) {
                
                self.projectVC.boardNameLabel.center = CGPointMake(self.projectVC.carousel.center.x, self.projectVC.boardNameLabel.center.y);
                
                if (self.projectVC.boardNameLabel.text.length > 0 && !self.projectVC.boardNameLabel.hidden && self.projectVC.userRole > 0) self.projectVC.boardNameEditButton.hidden = false;
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
    
    [[ref childByAppendingPath:@"versions"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value == [NSNull null]) return;

        NSArray *versionsArray = [[self.boards objectForKey:boardID] objectForKey:@"versions"];
        
        for (NSString *boardID in versionsArray) {
            
            if (![snapshot.value containsObject:boardID]) {
                
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
                
                [self.comments removeObjectForKey:commentsID];
                
                NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", [FirebaseHelper sharedHelper].db, boardID];
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
                
                [[boardRef childByAppendingPath:@"versions"] removeAllObservers];
                
                [self.boards removeObjectForKey:boardID];
            }
        }
        
        [[self.boards objectForKey:boardID] setValue:snapshot.value forKey:@"versions"];
        versionsArray = snapshot.value;
        
        if ([self.projectVC.boardIDs containsObject:boardID]) {
            
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:[self.projectVC.boardIDs indexOfObject:boardID]];
            
            if (versionsArray.count < 10) {
                
                NSString *boardString = [NSString stringWithFormat:@"board-versions%lu.png", (unsigned long)versionsArray.count];
                [boardView.gradientButton setBackgroundImage:[UIImage imageNamed:boardString] forState:UIControlStateNormal];
            }
            else if (versionsArray.count >= 10) {
                
                [boardView.gradientButton setBackgroundImage:[UIImage imageNamed:@"board-versions10.png"] forState:UIControlStateNormal];
            }
            
            if ([self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex] isEqualToString:boardID] && self.projectVC.versioning) {
                
                for (NSString *boardID in versionsArray) {
                    if (![self.loadedBoardIDs containsObject:boardID]) [self loadBoardWithID:boardID];
                }
                
                if (self.projectVC.activeBoardID == nil) {
                    
                    [self.projectVC.versionsCarousel reloadData];
                    self.projectVC.showButtons = true;
       
                    if ([[[self.boards objectForKey:boardID] objectForKey:@"versions"] count] > 1) {
                        
                        if (self.projectVC.versionsCarousel.currentItemIndex < versionsArray.count) self.projectVC.upArrowImage.hidden = false;
                        else self.projectVC.upArrowImage.hidden = true;
                        
                        if (self.projectVC.versionsCarousel.currentItemIndex > 0) self.projectVC.downArrowImage.hidden = false;
                        else self.projectVC.downArrowImage.hidden = true;
                        
                    }
                    else {
                        
                        self.projectVC.downArrowImage.hidden = true;
                        self.projectVC.upArrowImage.hidden = true;
                    }
                    
                    if (self.projectVC.versionsCarousel.currentItemIndex == 0) {
                        
                        if (versionsArray.count > 1) self.projectVC.versionsLabel.text = [NSString stringWithFormat:@"Original (Version 1 of %lu)", versionsArray.count];
                        else self.projectVC.versionsLabel.text = @"Original (Version 1)";
                    }
                    else self.projectVC.versionsLabel.text = [NSString stringWithFormat:@"Version %lu of %lu", self.projectVC.versionsCarousel.currentItemIndex+1, versionsArray.count];
                    
                }
                else if (![versionsArray containsObject:self.projectVC.activeBoardID]) {
                    
                    [self.projectVC closeTapped];
                }
            }
        }
    }];
    
    [[ref childByAppendingPath:@"updatedAt"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:@"updatedAt"];
    }];
}

-(void) observeSubpathsForUser:(NSString *)userID onBoard:(NSString *)boardID {
    
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/subpaths/%@", self.db,boardID, userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSMutableDictionary *subpathsDict = [[[self.boards objectForKey:boardID] objectForKey:@"subpaths"] objectForKey:userID];
        
        NSMutableArray *orderedKeys = [NSMutableArray arrayWithArray:subpathsDict.allKeys];
        NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [orderedKeys sortUsingDescriptors:@[sorter]];
        
        if(![orderedKeys containsObject:snapshot.key]) {
            
            [subpathsDict setObject:snapshot.value forKey:snapshot.key];
        
            [[[[self.boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:userID] setObject:snapshot.key forKey:@"currentIndexDate"];
            
            for (NSString *dateString in orderedKeys) {
                
                if ([dateString doubleValue] > [snapshot.key doubleValue]) [subpathsDict removeObjectForKey:dateString];
            }
            
            if ([self.projectVC.boardIDs containsObject:boardID]) {
                
                NSInteger boardIndex = [self.projectVC.boardIDs indexOfObject:boardID];
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
            
            
            NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
            
            if ([versionsArray containsObject:boardID] && ![self.projectVC.boardIDs containsObject:boardID]) {
                
                NSInteger boardIndex = [versionsArray indexOfObject:boardID];
                BoardView *boardView = (BoardView *)[self.projectVC.versionsCarousel itemViewAtIndex:boardIndex];
                
                if (boardView.drawingUserID && ![boardView.drawingUserID isEqualToString:userID]) {
                    
                    boardView.shouldRedraw = true;
                }
                else {
                    
                    if([snapshot.value respondsToSelector:@selector(objectForKey:)]) {
                         NSLog(@"draw 2");
                        [boardView drawSubpath:snapshot.value];
                    }
                    else [boardView drawSubpath:@{snapshot.key : snapshot.value}];
                    
                    [boardView addUserDrawing:userID];
                }
            }
        }
    }];
}

-(void) observeUndoForUser:(NSString *)userID onBoard:(NSString *)boardID {

    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/undo/%@", self.db,boardID, userID];
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
        
        NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
        if ([versionsArray containsObject:boardID]) {
            
            NSUInteger boardIndex = [versionsArray indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.versionsCarousel itemViewAtIndex:boardIndex];
            [self.projectVC drawBoard:boardView];
        }
        
        if ([userID isEqualToString:self.uid]) [ref removeAllObservers];
    }];
}

-(void) observeCurrentProjectBoards {
    
    NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
    
    for (NSString *boardID in boardIDs) {
        
        if (![self.loadedBoardIDs containsObject:boardID])[self loadBoardWithID:boardID];
    }
}

-(void) observeCurrentBoardVersions {
    
    NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
    
    for (NSString *boardID in versionsArray) {
        
        if (![self.loadedBoardIDs containsObject:boardID])[self loadBoardWithID:boardID];
    }
}

-(void) loadBoardWithID:(NSString *)boardID {
    
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", self.db, boardID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [self.boards setObject:snapshot.value forKey:boardID];
        [self observeBoardWithID:boardID];
    }];
}

-(void)observeChatWithID:(NSString *)chatID {
    
    [self.chats setObject:[NSMutableDictionary dictionary] forKey:chatID];
    
    NSString *chatString = [NSString stringWithFormat:@"https://%@.firebaseio.com/chats/%@", self.db, chatID];
    Firebase *ref = [[Firebase alloc] initWithUrl:chatString];

    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        NSMutableDictionary *chatDict = [NSMutableDictionary dictionaryWithDictionary:[self.chats objectForKey:chatID]];
        [chatDict setObject:snapshot.value forKey:snapshot.key];
    
        [self.chats setObject:chatDict forKey:chatID];

        if (!self.projectVC.activeBoardID) {
            
            NSString *projectID;
            for (NSString *pid in self.projects.allKeys) {
                if ([[[self.projects objectForKey:pid] objectForKey:@"chatID"] isEqualToString:chatID]) {
                    projectID = pid;
                    break;
                }
            }
            
            if ([projectID isEqualToString:self.currentProjectID]) {
                [self.projectVC updateMessages];
                [self.projectVC.chatTable reloadData];
                if (self.projectVC.chatOpen) [self.projectVC updateChatHeight];
            }
        }
    }];
}

-(void)observeCommentsOnBoardWithID:(NSString *)boardID {
    
    NSString *commentsID = [[self.boards objectForKey:boardID] objectForKey:@"commentsID"];
    
    NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@", self.db, commentsID];
    Firebase *ref = [[Firebase alloc] initWithUrl:commentsString];

    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value != [NSNull null]) {
        
            for (NSString *commentThreadID in [snapshot.value allKeys]) {
                
                NSDictionary *infoDict = [[snapshot.value objectForKey:commentThreadID] objectForKey:@"info"];
                NSMutableDictionary *commentDict = [@{ @"location" : [infoDict objectForKey:@"location"],
                                                       @"owner" : [infoDict objectForKey:@"owner"],
                                                       @"title" : [infoDict objectForKey:@"title"],
                                                       @"updatedAt" : [[snapshot.value objectForKey:commentThreadID] objectForKey:@"updatedAt"],
                                                       } mutableCopy];
                
                if ([[snapshot.value objectForKey:commentThreadID] objectForKey:@"messages"]) [commentDict setObject:[[snapshot.value objectForKey:commentThreadID] objectForKey:@"messages"] forKey:@"messages"];
                
                [[self.comments objectForKey:commentsID] setObject:commentDict forKey:commentThreadID];
                
                [self observeCommentThreadWithID:commentThreadID boardID:boardID];
            }
        }
        
        NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
        
        if (![self.loadedBoardIDs containsObject:boardID] && ([self.projectVC.boardIDs containsObject:boardID] || [versionsArray containsObject:boardID])) {
            
            [self.loadedBoardIDs addObject:boardID];
            BoardView *boardView;
            if ([self.projectVC.boardIDs containsObject:boardID]) {
                boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:[self.projectVC.boardIDs indexOfObject:boardID]];
            }
            else {
                boardView = (BoardView *)[self.projectVC.versionsCarousel itemViewAtIndex:[versionsArray indexOfObject:boardID]];
            }
            boardView.loadingView.hidden = true;
            boardView.fadeView.hidden = true;
            [boardView layoutComments];
            [self.projectVC drawBoard:boardView];
            
            int versionsNum = ((NSArray *)[[self.boards objectForKey:boardID] objectForKey:@"versions"]).count;
            
            if (versionsNum > 1 && versionsNum < 10) {
                
                NSString *boardString = [NSString stringWithFormat:@"board-versions%i.png", versionsNum];
                [boardView.gradientButton setBackgroundImage:[UIImage imageNamed:boardString] forState:UIControlStateNormal];
            }
            else if (versionsNum >= 10) {
                
                [boardView.gradientButton setBackgroundImage:[UIImage imageNamed:@"board-versions10.png"] forState:UIControlStateNormal];
            }
            
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
        
        NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
        
        if ([versionsArray containsObject:boardID]) {
            
            NSInteger boardIndex = [versionsArray indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.versionsCarousel itemViewAtIndex:boardIndex];
            [boardView layoutComments];
        }
        
        [[ref childByAppendingPath:snapshot.key] removeAllObservers];
    }];
}

-(void) observeCommentThreadWithID:(NSString *)commentThreadID boardID:(NSString *)boardID {
    
    NSString *commentsID = [[self.boards objectForKey:boardID] objectForKey:@"commentsID"];
    
    NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@/%@", self.db,commentsID, commentThreadID];
    Firebase *ref = [[Firebase alloc] initWithUrl:commentsString];
    
    NSMutableDictionary *threadDict = [[self.comments objectForKey:commentsID] objectForKey:commentThreadID];
    
    [[ref childByAppendingPath:@"info"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot){
        
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
                self.projectVC.commentTitleView.hidden = false;
            }
        }
        
        NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
        
        if ([versionsArray containsObject:boardID]) {
            
            NSInteger boardIndex = [versionsArray indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.versionsCarousel itemViewAtIndex:boardIndex];
            [boardView layoutComments];
            
            NSString *titleString = [snapshot.value objectForKey:@"title"];
            
            if ([self.projectVC.activeCommentThreadID isEqualToString:commentThreadID] && titleString.length > 0) {
                
                self.projectVC.commentTitleTextField.text = titleString;
                self.projectVC.commentTitleView.hidden = false;
            }
        }
    }];
    
    [[ref childByAppendingPath:@"messages"] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        if(![threadDict objectForKey:@"messages"]) [threadDict setObject:[NSMutableDictionary dictionary] forKey:@"messages"];
        
        [[threadDict objectForKey:@"messages"] setObject:snapshot.value forKey:snapshot.key];
        
        if ([self.projectVC.activeCommentThreadID isEqualToString:commentThreadID]) {
            [self.projectVC updateMessages];
            [self.projectVC.chatTable reloadData];
            if (!self.projectVC.chatOpen && self.projectVC.userRole == 0) {
                [self.projectVC updateChatHeight];

            }
        }
    }];
    
    [[ref childByAppendingPath:@"updatedAt"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [threadDict setObject:snapshot.value forKey:@"updatedAt"];
        
        if ([self.projectVC.boardIDs containsObject:boardID]) {
            
            NSInteger boardIndex = [self.projectVC.boardIDs indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            [boardView layoutComments];
        }
        
        NSArray *versionsArray = [[self.boards objectForKey:self.projectVC.boardIDs[self.projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
        
        if ([versionsArray containsObject:boardID]) {
            
            NSInteger boardIndex = [versionsArray indexOfObject:boardID];
            BoardView *boardView = (BoardView *)[self.projectVC.versionsCarousel itemViewAtIndex:boardIndex];
            [boardView layoutComments];
        }
    }];
}

-(void) resetUndo {
    
    int currentIndex = [(NSNumber *)[[[[self.boards objectForKey:self.projectVC.activeBoardID] objectForKey:@"undo"] objectForKey:self.uid] objectForKey:@"currentIndex"] intValue];
    
    if (currentIndex == 0) return;
    
    NSMutableDictionary *undoDict = [[[self.boards objectForKey:self.projectVC.activeBoardID] objectForKey:@"undo"] objectForKey:self.uid];
    
    [undoDict setObject:@0 forKey:@"currentIndex"];
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/undo/%@", self.db, self.projectVC.activeBoardID, self.uid];
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
            
            NSString *subpathString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/subpaths/%@/%@", self.db, self.projectVC.activeBoardID, self.uid, dateString];
            Firebase *subpathRef = [[Firebase alloc] initWithUrl:subpathString];
            [subpathRef removeValue];
        }
    }
}

-(void) setInProject:(NSString *)projectID {
    
    if (!self.uid) return;
    
    if (self.currentProjectID) [[[self.team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.currentProjectID forKey:@"inProject"];
    
    NSString *userString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/status/inProject", self.db, self.uid];
    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
    [userRef setValue:projectID];
}

-(void) setInBoard:(NSString *)boardID {
    
    if (!self.uid) return;
    
    [[[self.team objectForKey:@"users"] objectForKey:self.uid] setObject:boardID forKey:@"inBoard"];
    
    NSString *teamString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/status",self.db,self.uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    [[ref childByAppendingPath:@"inBoard"] setValue:boardID];
}

-(void) setProjectViewedAt {
    
    if (!self.currentProjectID) return;
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];

    [[[self.projects objectForKey:self.currentProjectID] objectForKey:@"viewedAt"] setObject:dateString forKey:self.uid];

    NSString *oldProjectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/viewedAt/%@", self.db, self.currentProjectID, self.uid];
    Firebase *oldProjectRef = [[Firebase alloc] initWithUrl:oldProjectString];
    [oldProjectRef setValue:dateString];
}

-(void) setProjectUpdatedAt:(NSString *)dateString {
    
    [[self.projects objectForKey:self.currentProjectID] setObject:dateString forKey:@"updatedAt"];
    
    NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/updatedAt", self.db, self.currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    [projectRef setValue:dateString];
}

-(void) setBoard:(NSString *)boardID UpdatedAt:(NSString *)dateString {

    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/updatedAt", self.db,boardID];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    [boardRef setValue:dateString];
    [[self.boards objectForKey:boardID] setObject:dateString forKey:@"updatedAt"];
    
    [self setProjectUpdatedAt:dateString];
}

-(void) setCommentThread:(NSString *)commentThreadID updatedAt:(NSString *)dateString {
    
    NSString *commentsID = [[self.boards objectForKey:self.projectVC.currentBoardView.boardID] objectForKey:@"commentsID"];
    
    NSString *commentString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@/%@/updatedAt", self.db, commentsID, commentThreadID];
    Firebase *commentRef = [[Firebase alloc] initWithUrl:commentString];
    [commentRef setValue:dateString];
    [[[self.comments objectForKey:commentsID] objectForKey:commentThreadID] setObject:dateString forKey:@"updatedAt"];
    
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/updatedAt", self.db, self.projectVC.activeBoardID];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    [boardRef setValue:dateString];
    [[self.boards objectForKey:self.projectVC.activeBoardID] setObject:dateString forKey:@"updatedAt"];
    
    [self setBoard:self.projectVC.activeBoardID UpdatedAt:dateString];
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

-(void) checkUsersLoaded {
    
    BOOL usersLoaded = true;

    for (NSString *userID in self.loadedUsers.allKeys) {
        
        if ([[[self.loadedUsers objectForKey:userID] objectForKey:@"avatar"] integerValue] == 0) usersLoaded = false;
        if ([[[self.loadedUsers objectForKey:userID] objectForKey:@"info"] integerValue] == 0) usersLoaded = false;
        if ([[[self.loadedUsers objectForKey:userID] objectForKey:@"status"] integerValue] == 0) usersLoaded = false;
    }
    
    if (usersLoaded) {

        self.teamLoaded = true;
        if (self.projectsLoaded) [self updateMasterView];
    }
}

- (void) signOut {
    
    [self.projectVC hideAll];
    self.projectVC.masterView.teamButton.hidden = true;
    self.projectVC.masterView.teamMenuButton.hidden = true;
    self.projectVC.masterView.nameButton.hidden = true;
    self.projectVC.masterView.avatarButton.hidden = true;
    self.projectVC.masterView.avatarShadow.hidden = true;
    
    NSString *userString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/status", self.db, self.uid];
    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
    
    NSDictionary *statusDict = @{ @"device" : @"none",
                                  @"inProject" : @"none",
                                  @"inBoard" : @"none"
                                  };
    
    [userRef setValue:statusDict];
    
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:userRef];
    [authClient logout];
    
    self.loggedIn = false;
    
    [self removeAllObservers];
    [self clearData];
    
}

-(void) removeAllObservers {

    NSString *uidString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@", self.db, self.uid];
    Firebase *uidRef = [[Firebase alloc] initWithUrl:uidString];
    [uidRef removeAllObservers];
    
    NSString *teamString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams/%@", self.db, self.teamID];
    Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
    [teamRef removeAllObservers];
    [[teamRef childByAppendingPath:@"projects"] removeAllObservers];
    
    for (NSString *userID in [[self.team objectForKey:@"users"] allKeys]) {

        NSString *userString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/", self.db, userID];
        Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
        [[userRef childByAppendingPath:@"avatar"] removeAllObservers];
        [[userRef childByAppendingPath:@"info"] removeAllObservers];
        [[userRef childByAppendingPath:@"status"] removeAllObservers];
    }
    
    for (NSString *projectID in self.projects.allKeys) {
        
        NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@", self.db, projectID];
        Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
        [[projectRef childByAppendingPath:@"info"] removeAllObservers];
        [[projectRef childByAppendingPath:@"viewedAt"] removeAllObservers];
        [[projectRef childByAppendingPath:@"updatedAt"] removeAllObservers];
    }
    
    for (NSString *boardID in self.boards.allKeys) {
        
        NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", self.db, boardID];
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
        
        NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@", self.db, commentsID];
        Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
        [commentsRef removeAllObservers];
        
        for (NSString *commentThreadID in [[self.comments objectForKey:commentsID] allKeys]) {
            
            NSString *infoString = [NSString stringWithFormat:@"%@/info", commentThreadID];
            [[commentsRef childByAppendingPath:infoString] removeAllObservers];
            
            NSString *messageString = [NSString stringWithFormat:@"%@/messages", commentThreadID];
            [[commentsRef childByAppendingPath:messageString] removeAllObservers];
            
            NSString *updatedString = [NSString stringWithFormat:@"%@/updatedAt", commentThreadID];
            [[commentsRef childByAppendingPath:updatedString] removeAllObservers];
        }
    }
    
    for (NSString *chatID in self.chats.allKeys) {
     
        NSString *chatString = [NSString stringWithFormat:@"https://%@.firebaseio.com/chats/%@", self.db, chatID];
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
    self.avatarImage = nil;
    self.teamID = nil;
    self.teamName = nil;
    self.db = nil;
    self.team = [NSMutableDictionary dictionary];
    self.projects = [NSMutableDictionary dictionary];
    self.visibleProjectIDs = [NSMutableArray array];
    self.loadedBoardIDs = [NSMutableArray array];
    self.comments = [NSMutableDictionary dictionary];
    self.chats = [NSMutableDictionary dictionary];
    self.loadedUsers = [NSMutableDictionary dictionary];
    self.teamLoaded = false;
    self.projectsLoaded = false;
    self.isAdmin = false;
    
    projectChildrenCount = 0;
    
    [self.projectVC.masterView.projectsTable reloadData];
    self.projectVC.messages = [NSMutableArray array];
    [self.projectVC.chatTable reloadData];
}

@end
