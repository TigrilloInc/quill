//
//  FirebaseHelper.h
//  Quill
//
//  Created by Alex Costantini on 7/11/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import "ProjectDetailViewController.h"
#import "MasterView.h"

@interface FirebaseHelper : NSObject {
    
    NSInteger projectChildrenCount;
}

@property (strong, nonatomic) ProjectDetailViewController *projectVC;
@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *teamName;
@property (strong, nonatomic) NSMutableDictionary *team;
@property (strong, nonatomic) NSMutableDictionary *projects;
@property (strong, nonatomic) NSMutableDictionary *boards;
@property (strong, nonatomic) NSMutableDictionary *chats;
@property (strong, nonatomic) NSMutableDictionary *comments;
@property (strong, nonatomic) NSString *currentProjectID;
@property (strong, nonatomic) NSMutableArray *visibleProjectIDs;
@property (strong, nonatomic) NSMutableArray *loadedBoardIDs;
@property BOOL firstLoad;
@property BOOL projectCreated;

+ (FirebaseHelper *)sharedHelper;
- (void) observeLocalUser;
- (void) clearData;
- (void) observeBoardWithID:(NSString *)boardID;
- (void) observeCurrentProjectBoards;
- (void) removeCurrentProjectBoardObservers;
- (void) updateCurrentProjectBoards;
- (void) observeCommentThreadWithID:(NSString *)commentThreadID boardID:(NSString *)boardID;
- (void) setInProject;
- (void) setInBoard;
- (void) setProjectViewedAt;
- (void) setProjectUpdatedAt;
- (void) setActiveBoardUpdatedAt;
- (void) resetUndo;
- (NSIndexPath *) getLastViewedProjectIndexPath;

@end

