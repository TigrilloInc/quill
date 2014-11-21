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
    
    self.firstLoad = true;
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        for (FDataSnapshot *child in snapshot.children) {
            
            if ([child.name isEqualToString:@"name"]) self.userName = child.value;
            if ([child.name isEqualToString:@"team"]) self.teamName = child.value;
        }
        
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
        
        NSString *currentProject = [newUserDict objectForKey:@"inProject"];
        
        if ([self.currentProjectID isEqualToString:currentProject]) {
            
            ///project level user presence code goes here
            
        }
        
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
        
        for (NSString *projectID in self.projects.allKeys) [[ref childByAppendingPath:projectID] removeAllObservers];
        self.projects = [NSMutableDictionary dictionary];
        
        projectChildrenCount = snapshot.childrenCount;
        
        if (projectChildrenCount > 0) {
            
            for (FDataSnapshot *child in snapshot.children) {
                
                //[self.projects setObject:[NSMutableDictionary dictionary] forKey:child.name];
                [self observeProjectWithID:child.name];
            }
        }
        
        else [self updateMasterViewController];
        
    }];
}

-(void) observeProjectWithID:(NSString *)projectID {
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@", projectID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    NSMutableDictionary *projectDict = [NSMutableDictionary dictionary];
    
    Firebase *infoRef = [ref childByAppendingPath:@"info"];
    [infoRef removeAllObservers];
    [infoRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if ([((NSDictionary *)[snapshot.value objectForKey:@"roles"]).allKeys containsObject:self.uid] && ![self.visibleProjectIDs containsObject:projectID]) [self.visibleProjectIDs addObject:projectID];
        
        for (FDataSnapshot *child in snapshot.children) {
            
            [projectDict setObject:child.value forKey:child.name];
            
            if ([child.name isEqualToString:@"boards"]) {
                
                for (NSString *boardID in child.value) {
                    
                    if (![self.boards objectForKey:boardID]) [self.boards setObject:[NSMutableDictionary dictionary] forKey:boardID];
                }
            }
        }
        
        [self.projects setObject:projectDict forKey:projectID];
        
        [self observeChatWithID:[projectDict objectForKey:@"chatID"]];
        
        if (self.firstLoad) self.projectVC.masterView.defaultRow = [self getLastViewedProjectIndexPath];
        
        if (self.projectVC.activeBoardID == nil && self.projects.allKeys.count == projectChildrenCount && !self.projectCreated) [self updateMasterViewController];
        
    }];
    
    Firebase *viewedAtRef = [ref childByAppendingPath:@"viewedAt"];
    [viewedAtRef removeAllObservers];
    [viewedAtRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.projects objectForKey:projectID] setObject:snapshot.value forKey:@"viewedAt"];
        
    }];
    
    Firebase *updatedAtRef = [ref childByAppendingPath:@"updatedAt"];
    [updatedAtRef removeAllObservers];
    [updatedAtRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.projects objectForKey:projectID] setObject:snapshot.value forKey:@"updatedAt"];
        
    }];
}

-(void) updateMasterViewController {
    
    NSLog(@"masterView updated");
    
    self.firstLoad = false;

    [self.projectVC.masterView.nameButton setTitle:self.userName forState:UIControlStateNormal];
    [self.projectVC.masterView.teamButton setTitle:self.teamName forState:UIControlStateNormal];
    self.projectVC.masterView.avatarButton.hidden = false;
    
    [self.projectVC.masterView.projectsTable reloadData];
    
    [self.projectVC.masterView tableView:self.projectVC.masterView.projectsTable didSelectRowAtIndexPath:self.projectVC.masterView.defaultRow];
    
}

-(void) observeTeam {
    
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@", self.teamName];
    
    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        self.team = snapshot.value;
        
        for (NSString *userID in [[self.team objectForKey:@"users"] allKeys]) {
            
            [[self.team objectForKey:@"users"] setObject:[NSMutableDictionary dictionary] forKey:userID];
            [self observeUserWithID:userID];
        }
    }];
}

-(void) observeBoardWithID:(NSString *)boardID {
    

    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", boardID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [[ref childByAppendingPath:@"lastSubpath"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (![snapshot.value respondsToSelector:@selector(objectForKey:)]) return;
        
        if ([snapshot.value objectForKey:@"penUp"] && ![[snapshot.value objectForKey:@"penUp"] isEqualToString:self.uid]) {
            
            [[[[self.boards objectForKey:boardID] objectForKey:@"allSubpaths"] objectForKey:[snapshot.value objectForKey:@"penUp"]] setObject:@"penUp" forKey:[NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000]];
            
        } else {
            
            NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
            int boardIndex = [boardIDs indexOfObject:boardID];
            
            NSMutableDictionary *subpathValues = [NSMutableDictionary dictionary];
            for (FDataSnapshot *child in snapshot.children) {
                [subpathValues setObject:child.value forKey:child.name];
            }
            
            if (![[subpathValues objectForKey:@"uid"] isEqualToString:self.uid]) {
                
                DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
                
                NSMutableDictionary *allSubpathsDict = [[[self.boards objectForKey:boardID] objectForKey:@"allSubpaths"] objectForKey:[subpathValues objectForKey:@"uid"]];
                NSMutableDictionary *undoDict = [[[self.boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:[subpathValues objectForKey:@"uid"]];
                
                long long currentIndexDate = [(NSNumber *)[undoDict objectForKey:@"currentIndexDate"] longLongValue];
                
                NSMutableArray *orderedKeys = [NSMutableArray arrayWithArray:allSubpathsDict.allKeys];
                NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
                [orderedKeys sortUsingDescriptors:@[sorter]];
                
                for (NSString *dateString in orderedKeys) {
                    
                    if (currentIndexDate > 0 && [dateString longLongValue] > currentIndexDate) {
                        
                        //NSLog(@"currentIndexDate is %lld, key being removed is %@", currentIndexDate, dateString);
                        [allSubpathsDict removeObjectForKey:dateString];
                    }
                }
                
                NSMutableDictionary *subpathValuesWithoutUID = [subpathValues mutableCopy];
                [subpathValuesWithoutUID removeObjectForKey:@"uid"];
                
                [allSubpathsDict setObject:subpathValuesWithoutUID forKey:[NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000]];
                
                [[[[self.boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:[subpathValues objectForKey:@"uid"]] setObject:@([[NSDate serverDate] timeIntervalSince1970]*100000000) forKey:@"currentIndexDate"];
                
                [drawView drawSubpath:subpathValues];
                
            }
        }
        //if (projectVC.activeBoardID == nil) [projectVC.carousel reloadData];
    }];
    
    [[ref childByAppendingPath:@"undo"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        ///Update local currentIndex and total
        for (FDataSnapshot *child in snapshot.children) {
            
            if ([child.name isEqualToString:self.uid] || ![child.value objectForKey:@"currentIndex"] || ![child.value objectForKey:@"total"]) continue;
            
            [[[[self.boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:child.name] setObject:[child.value objectForKey:@"currentIndex"] forKey:@"currentIndex"];
            [[[[self.boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:child.name] setObject:[child.value objectForKey:@"total"] forKey:@"total"];
            [[[[self.boards objectForKey:boardID] objectForKey:@"undo"] objectForKey:child.name] setObject:@([[NSDate serverDate] timeIntervalSince1970]*100000000) forKey:@"currentIndexDate"];
        }
        
        NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        if ([boardIDs containsObject:boardID]) {
            
            int boardIndex = [boardIDs indexOfObject:boardID];
            
            DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            
            //NSLog(@"boardIDs is %@", boardIDs);
            //NSLog(@"drawView is %@", drawView);
            //NSLog(@"boardIndex is %i", boardIndex);
            //NSLog(@"projectVC carousel is %@", self.projectVC.carousel);
            
            [self.projectVC drawBoard:drawView];
        }
    }];
    
    [[ref childByAppendingPath:@"name"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:@"name"];
        
        if (self.projectVC.carousel.currentItemIndex == [self.projectVC.boardIDs indexOfObject:boardID]) {
            self.projectVC.boardNameLabel.text = snapshot.value;
        }
    }];
    
    [[ref childByAppendingPath:@"updatedAt"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:@"updatedAt"];
    }];
    
    [[ref childByAppendingPath:@"commentsID"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:@"commentsID"];
        
        [self observeCommentsOnBoardWithID:boardID];
    }];
}

-(void) observeCurrentProjectBoards {
    
    NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
    
    for (NSString *boardID in boardIDs) {
        
        [self updateBoard:boardID andRedraw:YES];
        
        [self observeBoardWithID:boardID];
    }
}

-(void) updateCurrentProjectBoards {
    
    NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
    
    for (NSString *boardID in boardIDs) {
        
        [self updateBoard:boardID andRedraw:NO];
    }
}

-(void) updateBoard:(NSString *)boardID andRedraw:(BOOL)shouldRedraw {
    
    NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
    
    int boardIndex = [boardIDs indexOfObject:boardID];
    DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
    if (shouldRedraw) [drawView clear];
    
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", boardID];
    Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
    
    [[ref childByAppendingPath:@"allSubpaths"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSMutableDictionary *subpathsDict = [NSMutableDictionary dictionary];
        
        for (FDataSnapshot *child in snapshot.children) {
            [subpathsDict setObject:child.value forKey:child.name];
            
            for (FDataSnapshot *subpath in child.children) {
                if (shouldRedraw && [subpath.value respondsToSelector:@selector(objectForKey:)])
                    [drawView drawSubpath:subpath.value];
                
            }
        }
        
        [[self.boards objectForKey:boardID] setObject:subpathsDict forKey:@"allSubpaths"];
    }];
    
    [[ref childByAppendingPath:@"undo"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        [[self.boards objectForKey:boardID] setObject:snapshot.value forKey:snapshot.name];
        
    }];
    
}

-(void) removeCurrentProjectBoardObservers {
    
    NSArray *boardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
    
    for (NSString *boardID in boardIDs) {
        
        NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", boardID];
        Firebase *ref = [[Firebase alloc] initWithUrl:boardString];
        
        [[ref childByAppendingPath:@"lastSubpath"] removeAllObservers];
        [[ref childByAppendingPath:@"undo"] removeAllObservers];
        [[ref childByAppendingPath:@"name"] removeAllObservers];
        [[ref childByAppendingPath:@"updatedAt"] removeAllObservers];
        [[ref childByAppendingPath:@"commentsID"] removeAllObservers];
    }
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
    
    [ref removeAllObservers];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.value == [NSNull null]) return;
        
        NSDictionary *commentThreadsDict = snapshot.value;
        
        [self.comments setObject:commentThreadsDict forKey:commentsID];
        
        for (NSString *commentThreadID in commentThreadsDict.allKeys) {
            
            [self observeCommentThreadWithID:commentThreadID boardID:boardID];
        }
        
    }];
    
    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        if  (![self.comments objectForKey:commentsID]) {
            
            NSMutableDictionary *commentThreadDict = [@{ snapshot.name : snapshot.value } mutableCopy];
            [self.comments setObject:commentThreadDict forKey:commentsID];
        }
        else [[self.comments objectForKey:commentsID] setObject:snapshot.value forKey:snapshot.name];
        
        [self observeCommentThreadWithID:snapshot.name boardID:boardID];
    }];
}

-(void) observeCommentThreadWithID:(NSString *)commentThreadID boardID:(NSString *)boardID {
    
    NSString *commentsID = [[self.boards objectForKey:boardID] objectForKey:@"commentsID"];
    
    NSString *commentsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@", commentsID];
    Firebase *ref = [[Firebase alloc] initWithUrl:commentsString];
    
    NSMutableDictionary *threadDict = [[self.comments objectForKey:commentsID] objectForKey:commentThreadID];
    
    if (!threadDict) {
        
        threadDict = [@{ @"location" : [NSMutableDictionary dictionary],
                         @"messages" : [NSMutableDictionary dictionary],
                         @"owner" : @""
                         } mutableCopy];
        [[self.comments objectForKey:commentsID] setObject:threadDict forKey:commentThreadID];
    }
    
    if (![threadDict objectForKey:@"messages"]) [threadDict setObject:[NSMutableDictionary dictionary] forKey:@"messages"];
    
    NSString *owner = [threadDict objectForKey:@"owner"];
    
    NSString *locationString = [NSString stringWithFormat:@"%@/location", commentThreadID];
    
    [[ref childByAppendingPath:locationString] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot){
        
        [threadDict setObject:snapshot.value forKey:@"location"];
        
        NSArray *currentProjectBoardIDs = [[self.projects objectForKey:self.currentProjectID] objectForKey:@"boards"];
        
        if ([currentProjectBoardIDs containsObject:boardID] && ![owner isEqualToString:self.uid]) {
            
            int boardIndex = [currentProjectBoardIDs indexOfObject:boardID];
            DrawView *drawView = (DrawView *)[self.projectVC.carousel itemViewAtIndex:boardIndex];
            
            [drawView layoutComments];
        }
    }];
    
    NSString *messageString = [NSString stringWithFormat:@"%@/messages", commentThreadID];
    
    [[ref childByAppendingPath:messageString] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        [[threadDict objectForKey:@"messages"] setObject:snapshot.value forKey:snapshot.name];
        
        if ([self.projectVC.activeCommentThreadID isEqualToString:commentThreadID]) {
            [self.projectVC updateMessages];
            [self.projectVC.chatTable reloadData];
        }
    }];
    
}

-(void) setInProject {
    
    [[[self.team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.currentProjectID forKey:@"inProject"];
    
    NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/inProject", self.uid];
    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
    [userRef setValue:self.currentProjectID];
}

-(void) setInBoard {
    
    NSString *boardID;
    if (self.projectVC.activeBoardID == nil) boardID = @"none";
    else boardID = self.projectVC.activeBoardID;
    
    [[[self.team objectForKey:@"users"] objectForKey:self.uid] setObject:boardID forKey:@"inBoard"];
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@",self.uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    [[ref childByAppendingPath:@"inBoard"] setValue:boardID];
}

-(void) setProjectViewedAt {
    
    if (!self.currentProjectID) return;
    
    [[[self.projects objectForKey:self.currentProjectID] objectForKey:@"viewedAt"] setObject:@([[NSDate serverDate] timeIntervalSince1970]*100000000) forKey:self.uid];
    NSString *oldProjectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/viewedAt/%@", self.currentProjectID, self.uid];
    Firebase *oldProjectRef = [[Firebase alloc] initWithUrl:oldProjectString];
    [oldProjectRef setValue:@([[NSDate serverDate] timeIntervalSince1970]*100000000)];
    
    //NSLog(@"project %@ viewed at set to %@", self.currentProjectID, [[[self.projects objectForKey:self.currentProjectID] objectForKey:@"viewedAt"] objectForKey:self.uid]);
}

-(void) setProjectUpdatedAt {
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/updatedAt", self.currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    [projectRef setValue:@([[NSDate serverDate] timeIntervalSince1970]*100000000)];
    [[self.projects objectForKey:self.currentProjectID] setObject:@([[NSDate serverDate] timeIntervalSince1970]*100000000) forKey:@"updatedAt"];
}

-(void) setActiveBoardUpdatedAt {

    
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/updatedAt", self.projectVC.activeBoardID];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    [boardRef setValue:@([[NSDate serverDate] timeIntervalSince1970]*100000000)];
    [[self.boards objectForKey:self.projectVC.activeBoardID] setObject:@([[NSDate serverDate] timeIntervalSince1970]*100000000) forKey:@"updatedAt"];
    
//    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/updatedAt", [self getProjectDetailViewController].activeBoardID];
//    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
//    [boardRef setValue:@([[NSDate serverDate] timeIntervalSince1970]*100000000)];
//    [[self.boards objectForKey:[self getProjectDetailViewController].activeBoardID] setObject:@([[NSDate serverDate] timeIntervalSince1970]*100000000) forKey:@"updatedAt"];
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
    
    NSLog(@"last viewed project is %@", defaultProjectName);
    
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
