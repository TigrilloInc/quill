//
//  FirebaseHelper.h
//  Quill
//
//  Created by Alex Costantini on 7/11/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "ProjectDetailViewController.h"
#import "MasterView.h"

@interface FirebaseHelper : NSObject {
    
    NSInteger userChildrenCount;
    NSInteger projectChildrenCount;
}

@property (strong, nonatomic) ProjectDetailViewController *projectVC;
@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *teamID;
@property (strong, nonatomic) NSString *teamName;
@property (strong, nonatomic) NSMutableDictionary *team;
@property (strong, nonatomic) NSMutableDictionary *projects;
@property (strong, nonatomic) NSMutableDictionary *boards;
@property (strong, nonatomic) NSMutableDictionary *chats;
@property (strong, nonatomic) NSMutableDictionary *comments;
@property (strong, nonatomic) NSString *currentProjectID;
@property (strong, nonatomic) NSMutableArray *visibleProjectIDs;
@property (strong, nonatomic) NSMutableArray *loadedBoardIDs;
@property (strong, nonatomic) NSDictionary *invitedProject;
@property (strong, nonatomic) NSURL *inviteURL;
@property BOOL teamLoaded;
@property BOOL projectsLoaded;
@property BOOL connected;
@property BOOL loggedIn;

+ (FirebaseHelper *)sharedHelper;
- (void) testConnection;
- (void) createUser;
- (void) observeLocalUser;
- (void) observeCurrentProjectBoards;
- (void) observeProjectWithID:(NSString *)projectID;
- (void) observeBoardWithID:(NSString *)boardID;
- (void) observeSubpathsForUser:(NSString *)userID onBoard:(NSString *)boardID;
- (void) observeUndoForUser:(NSString *)userID onBoard:(NSString *)boardID;
- (void) observeCommentsOnBoardWithID:(NSString *)boardID;
- (void) observeCommentThreadWithID:(NSString *)commentThreadID boardID:(NSString *)boardID;
- (void) setInProject:(NSString *)projectID;
- (void) setInBoard:(NSString *)boardID;
- (void) setProjectViewedAt;
- (void) setProjectUpdatedAt:(NSString *)dateString;
- (void) setBoard:(NSString *)boardID UpdatedAt:(NSString *)dateString;
- (void) setCommentThread:(NSString *)commentThreadID updatedAt:(NSString *)dateString;
- (void) resetUndo;
- (NSIndexPath *) getLastViewedProjectIndexPath;
- (void) removeAllObservers;
- (void) clearData;
- (void) updateMasterView;

@end

