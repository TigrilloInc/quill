
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
#import "DrawView.h"
#import "NSDate+ServerDate.h"
#import "AvatarButton.h"

@implementation FirebaseHelper

static FirebaseHelper *sharedHelper = nil;

+ (FirebaseHelper *) sharedHelper {
    
    if (!sharedHelper) {
        sharedHelper = [[FirebaseHelper alloc] init];
        sharedHelper.firstLoad = true;
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

- (void) observeLocalUser {
    
    NSString *uidString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@", self.uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:uidString];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        for (FDataSnapshot *child in snapshot.children) {
            
            if ([child.name isEqualToString:@"name"]) self.userName = child.value;
            if ([child.name isEqualToString:@"team"]) self.teamName = child.value;
        }
        
        [self.team setObject:[@{self.uid:[snapshot.value mutableCopy]} mutableCopy] forKey:@"users"];

        [self observeProjects];
        [self observeTeam];
    }];
}

- (void) observeUserWithID:(NSString *)userID {
    
    NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/", userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:userString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
 
        NSDictionary *oldUserDict = CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)[[self.team objectForKey:@"users"] objectForKey:userID], kCFPropertyListMutableContainers));
        NSMutableDictionary *newUserDict = snapshot.value;
        
        [[self.team objectForKey:@"users"] setObject:newUserDict forKey:userID];
        
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
            
            int boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            
            if (inBoard && ![drawView.activeUserIDs containsObject:userID]) [drawView.activeUserIDs addObject:userID];
            else if (!inBoard) [drawView.activeUserIDs removeObject:userID];
            
            [drawView layoutAvatars];
            
            NSArray *userIDs = [drawView.activeUserIDs sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            
            if ([userIDs containsObject:userID]) {
                
                int avatarIndex = [userIDs indexOfObject:userID];
                AvatarButton *avatar = (AvatarButton *)drawView.avatarButtons[avatarIndex];
                
                if ([[newUserDict objectForKey:@"isDrawing"] integerValue] > 0 ) avatar.drawingImage.hidden = false;
                else avatar.drawingImage.hidden = true;
            }
        }
    }];
}

- (void) observeProjects {
    
    NSString *projectsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@/projects", self.teamName];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectsString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        projectChildrenCount = snapshot.childrenCount;
        
        if (projectChildrenCount > 0) {
            
            for (FDataSnapshot *child in snapshot.children) {
                
                if (![self.projects.allKeys containsObject:child.name]) [self observeProjectWithID:child.name];
            }
        }
        else [self updateMasterViewController];
    }];
}

-(void) observeProjectWithID:(NSString *)projectID {
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@", projectID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    [[ref childByAppendingPath:@"info"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSMutableDictionary *projectDict;
        
        if ([self.projects objectForKey:projectID]) projectDict = [self.projects objectForKey:projectID];
        else projectDict = [NSMutableDictionary dictionary];
        
        if ([((NSDictionary *)[snapshot.value objectForKey:@"roles"]).allKeys containsObject:self.uid] && ![self.visibleProjectIDs containsObject:projectID]) [self.visibleProjectIDs addObject:projectID];
        
        for (FDataSnapshot *child in snapshot.children) {
            
            [projectDict setObject:child.value forKey:child.name];
            
            if ([child.name isEqualToString:@"boards"]) {
                
                for (NSString *boardID in child.value) {
                    
                    if (![self.boards objectForKey:boardID]) {
                        
                        [self.boards setObject:[NSMutableDictionary dictionary] forKey:boardID];
                        if (self.projectVC.activeBoardID == nil && [self.currentProjectID isEqualToString:projectID]) { [self.projectVC.carousel reloadData];
                        }
                    }
                }
            }
        }
        
        [self.projects setObject:projectDict forKey:projectID];
        
        [self observeChatWithID:[projectDict objectForKey:@"chatID"]];
        
        if (self.firstLoad) self.projectVC.masterView.defaultRow = [self getLastViewedProjectIndexPath];
        
        if (self.projectVC.activeBoardID == nil && self.projects.allKeys.count == projectChildrenCount) [self updateMasterViewController];
        
    }];
    
    [[ref childByAppendingPath:@"viewedAt"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.projects objectForKey:projectID] setObject:snapshot.value forKey:@"viewedAt"];
    }];
    
    [[ref childByAppendingPath:@"updatedAt"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.projects objectForKey:projectID] setObject:snapshot.value forKey:@"updatedAt"];
        if (!self.firstLoad) {
            [self.projectVC.masterView.projectsTable reloadData];
            [self.projectVC.masterView.projectsTable selectRowAtIndexPath:self.projectVC.masterView.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
}

-(void) updateMasterViewController {
    
    NSLog(@"masterView updated");
    
    self.firstLoad = false;

    [self.projectVC.masterView.nameButton setTitle:self.userName forState:UIControlStateNormal];
    [self.projectVC.masterView.teamButton setTitle:self.teamName forState:UIControlStateNormal];
    
    self.projectVC.masterView.avatarButton = [AvatarButton buttonWithType:UIButtonTypeCustom];
    [self.projectVC.masterView.avatarButton addTarget:self.projectVC.masterView action:@selector(settingsTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.projectVC.masterView.avatarButton.userID = self.uid;
    [self.projectVC.masterView.avatarButton generateIdenticon];
    self.projectVC.masterView.avatarButton.frame = CGRectMake(-87, -33, self.projectVC.masterView.avatarButton.userImage.size.width, self.projectVC.masterView.avatarButton.userImage.size.height);
    self.projectVC.masterView.avatarButton.transform = CGAffineTransformMakeScale(.25, .25);
    [self.projectVC.masterView addSubview:self.projectVC.masterView.avatarButton];
    
    self.projectVC.chatAvatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
    self.projectVC.chatAvatar.userID = self.uid;
    [self.projectVC.chatAvatar generateIdenticon];
    self.projectVC.chatAvatar.frame = CGRectMake(-100,-7, self.projectVC.chatAvatar.userImage.size.width, self.projectVC.chatAvatar.userImage.size.height);
    self.projectVC.chatAvatar.transform = CGAffineTransformMakeScale(.16, .16);
    [self.projectVC.chatView addSubview:self.projectVC.chatAvatar];
    
    [self.projectVC.masterView.projectsTable reloadData];
    
    [self.projectVC.masterView tableView:self.projectVC.masterView.projectsTable didSelectRowAtIndexPath:self.projectVC.masterView.defaultRow];
    
}

-(void) observeTeam {
    
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@", self.teamName];
    
    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *projectsDict = [snapshot.value objectForKey:@"projects"];
        
        if (projectsDict) [self.team setObject:projectsDict forKey:@"projects"];
        
        for (NSString *userID in [[snapshot.value objectForKey:@"users"] allKeys]) {
            
            if (![userID isEqualToString:self.uid]) [[self.team objectForKey:@"users"] setObject:[NSMutableDictionary dictionary] forKey:userID];
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
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:@"name"];
        
        if (self.projectVC.carousel.currentItemIndex == [self.projectVC.boardIDs indexOfObject:boardID]) self.projectVC.boardNameLabel.text = snapshot.value;
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
    
    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot){

        NSMutableDictionary *subpathsDict = [[[self.boards objectForKey:boardID] objectForKey:@"subpaths"] objectForKey:userID];
        [subpathsDict setObject:snapshot.value forKey:snapshot.name];

        [[[[self.boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:userID] setObject:snapshot.name forKey:@"currentIndexDate"];
        
        NSMutableArray *orderedKeys = [NSMutableArray arrayWithArray:subpathsDict.allKeys];
        NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [orderedKeys sortUsingDescriptors:@[sorter]];

        for (NSString *dateString in orderedKeys) {

            if ([dateString doubleValue] > [snapshot.name doubleValue]) [subpathsDict removeObjectForKey:dateString];
        }
        
        NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        
        if ([boardIDs containsObject:boardID] && [snapshot.value respondsToSelector:@selector(objectForKey:)]) {
            
            int boardIndex = [boardIDs indexOfObject:boardID];
            DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            [drawView drawSubpath:snapshot.value];
        }
    }];
}

-(void) observeUndoForUser:(NSString *)userID onBoard:(NSString *)boardID {

    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", boardID, userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSMutableDictionary *oldSubpathsDict = [[[self.boards objectForKey:boardID] objectForKey:@"subpaths"] objectForKey:userID];
        NSMutableArray *oldOrderedKeys = [NSMutableArray arrayWithArray:oldSubpathsDict.allKeys];
        NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [oldOrderedKeys sortUsingDescriptors:@[sorter]];
        
        double oldLastSubpathDate = [[oldOrderedKeys lastObject] doubleValue];
        
        NSMutableDictionary *undoDict = [[self.boards objectForKey:boardID] objectForKey:@"undo"];
        
        double oldIndexDate = [[[undoDict objectForKey:userID] objectForKey:@"currentIndexDate"] doubleValue];
        
        [undoDict setObject:[snapshot.value mutableCopy] forKey:userID];
        
        int newIndex = [[snapshot.value objectForKey:@"currentIndex"] integerValue];
        double newIndexDate = [[snapshot.value objectForKey:@"currentIndexDate"] doubleValue];
        
        NSMutableDictionary *newSubpathsDict = [[[self.boards objectForKey:boardID] objectForKey:@"subpaths"] objectForKey:userID];
        NSMutableArray *newOrderedKeys = [NSMutableArray arrayWithArray:newSubpathsDict.allKeys];
        [newOrderedKeys sortUsingDescriptors:@[sorter]];

        for (NSString *dateString in newOrderedKeys) {
            
            if (oldIndexDate > 0 && [dateString doubleValue] > oldIndexDate && newIndex == 0 && oldLastSubpathDate != newIndexDate) [newSubpathsDict removeObjectForKey:dateString];
        }
        
        NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        if ([boardIDs containsObject:boardID]) {
            
            int boardIndex = [boardIDs indexOfObject:boardID];
            DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            [self.projectVC drawBoard:drawView];
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
        [chatDict setObject:snapshot.value forKey:snapshot.name];
    
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

        NSArray *currentProjectBoardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        
        if (![self.loadedBoardIDs containsObject:boardID] && [currentProjectBoardIDs containsObject:boardID]) {
            
            [self.loadedBoardIDs addObject:boardID];
            NSInteger boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            drawView.loadingView.hidden = true;
            [drawView layoutComments];
        }
        
        if (snapshot.value == [NSNull null]) return;
        
        for (NSString *commentThreadID in [snapshot.value allKeys]) {
            
            NSDictionary *infoDict = [[snapshot.value objectForKey:commentThreadID] objectForKey:@"info"];
            NSDictionary *commentDict = @{ @"location" : [infoDict objectForKey:@"location"],
                                           @"owner" : [infoDict objectForKey:@"owner"]
                                           };
            
            [[self.comments objectForKey:commentsID] setObject:[commentDict mutableCopy] forKey:commentThreadID];
            
            [self observeCommentThreadWithID:commentThreadID boardID:boardID];
        }
    }];
    
    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {

        if ([[[snapshot.value objectForKey:@"info"] objectForKey:@"owner"] isEqualToString:self.uid]) return;
        
        if (![[self.comments objectForKey:commentsID] objectForKey:snapshot.name]){
            
            NSDictionary *infoDict = [snapshot.value objectForKey:@"info"];
            NSDictionary *commentDict = @{ @"location" : [infoDict objectForKey:@"location"],
                                           @"owner" : [infoDict objectForKey:@"owner"]
                                           };
            
            [[self.comments objectForKey:commentsID] setObject:[commentDict mutableCopy] forKey:snapshot.name];
            [self observeCommentThreadWithID:snapshot.name boardID:boardID];
        }
    }];
    
    [ref observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        
        if ([[[snapshot.value objectForKey:@"info"] objectForKey:@"owner"] isEqualToString:self.uid]) return;
        
        [[self.comments objectForKey:commentsID] removeObjectForKey:snapshot.name];
        
        NSArray *currentProjectBoardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        
        if ([currentProjectBoardIDs containsObject:boardID]) {
            
            NSInteger boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            [drawView layoutComments];
        }
        
        [[ref childByAppendingPath:snapshot.name] removeAllObservers];
    }];
}

-(void) observeCommentThreadWithID:(NSString *)commentThreadID boardID:(NSString *)boardID {
    
    NSString *commentsID = [[self.boards objectForKey:boardID] objectForKey:@"commentsID"];
    
    NSString *commentsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@", commentsID];
    Firebase *ref = [[Firebase alloc] initWithUrl:commentsString];
    
    NSString *infoString = [NSString stringWithFormat:@"%@/info", commentThreadID];
    
    NSMutableDictionary *threadDict = [[self.comments objectForKey:commentsID] objectForKey:commentThreadID];
    
    [[ref childByAppendingPath:infoString] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot){
        
        if (snapshot.value == [NSNull null] || [[snapshot.value objectForKey:@"owner"] isEqualToString:self.uid]) return;
        
        [threadDict setObject:[snapshot.value objectForKey:@"location"] forKey:@"location"];
        
        NSArray *currentProjectBoardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];

        if ([currentProjectBoardIDs containsObject:boardID]) {
            
            NSInteger boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            [drawView layoutComments];
            NSLog(@"layoutComments 2");
        }
    }];
    
    NSString *messageString = [NSString stringWithFormat:@"%@/messages", commentThreadID];
    
    [[ref childByAppendingPath:messageString] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        if(![threadDict objectForKey:@"messages"]) [threadDict setObject:[NSMutableDictionary dictionary] forKey:@"messages"];
        
        [[threadDict objectForKey:@"messages"] setObject:snapshot.value forKey:snapshot.name];
        
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
    
    [[[self.team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.currentProjectID forKey:@"inProject"];
    
    NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/inProject", self.uid];
    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
    [userRef setValue:projectID];
}

-(void) setInBoard:(NSString *)boardID {
    
    [[[self.team objectForKey:@"users"] objectForKey:self.uid] setObject:boardID forKey:@"inBoard"];
    
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@",self.uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    [[ref childByAppendingPath:@"inBoard"] setValue:boardID];
}

-(void) setProjectViewedAt {
    
    if (!self.currentProjectID) return;
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];

    [[[self.projects objectForKey:self.currentProjectID] objectForKey:@"viewedAt"] setObject:dateString forKey:self.uid];
    
    NSLog(@"NEW PROJECT VIEWEDAT IS %@", [self.projects objectForKey:self.currentProjectID]);
    
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
    int projectIndex = [orderedProjectNames indexOfObject:defaultProjectName];

    return [NSIndexPath indexPathForItem:projectIndex inSection:0];
}

- (void) clearData {
    
    self.uid = nil;
    self.email = nil;
    self.userName = nil;
    self.teamName = nil;
    self.team = nil;
    self.projects = nil;

    [self.projectVC.masterView.projectsTable reloadData];

}

@end
