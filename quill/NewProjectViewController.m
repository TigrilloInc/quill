//
//  NewProjectViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/8/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "NewProjectViewController.h"
#import "NSDate+ServerDate.h"

#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"

@implementation NewProjectViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nameField.placeholder = @"Project Name";
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
}

- (void) viewDidAppear:(BOOL)animated
{
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

- (IBAction)createProjectTapped:(id)sender {
    
    if (self.nameField.text.length <= 0) return;
        
    NSString *teamRefString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@/projects", [FirebaseHelper sharedHelper].teamName];
    Firebase *teamRef = [[Firebase alloc] initWithUrl:teamRefString];
    
    Firebase *projectRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/projects"];
    Firebase *projectRefWithID = [projectRef childByAutoId];
    NSString *projectID = projectRefWithID.name;
    
    Firebase *boardRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/boards"];
    Firebase *boardRefWithID = [boardRef childByAutoId];
    NSString *boardID = boardRefWithID.name;
    
    Firebase *chatRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/chats"];
    Firebase *chatRefWithID = [chatRef childByAutoId];
    NSString *chatID = chatRefWithID.name;
    
    Firebase *commentsRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/comments"];
    Firebase *commentsRefWithID = [commentsRef childByAutoId];
    NSString *commentsID = commentsRefWithID.name;
    
    NSString *projectName = self.nameField.text;
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSDictionary *projectDict =  @{ @"info" : @{ @"name" :   projectName,
                                                 @"boards" : @{ @"0" : boardID },
                                                 @"chatID" : chatID,
                                                 @"roles" : @{ [FirebaseHelper sharedHelper].uid : @2 }
                                                 },
                                    @"viewedAt" :  @{ [FirebaseHelper sharedHelper].uid : dateString },
                                    @"updatedAt" : dateString
                                    };
    
    NSDictionary *localProjectDict =  @{ @"name" :   projectName,
                                         @"boards" : [@[ boardID ] mutableCopy],
                                         @"chatID" : chatID,
                                         @"roles" : [@{ [FirebaseHelper sharedHelper].uid : @2 } mutableCopy],
                                         @"viewedAt" :  [@{ [FirebaseHelper sharedHelper].uid : dateString } mutableCopy],
                                         @"updatedAt" : dateString
                                         };
    
    NSDictionary *boardDict =  @{ @"name" : @"Untitled",
                                  @"project" : projectID,
                                  @"number" : @0,
                                  @"commentsID" : commentsID,
                                  @"subpaths" : [@{ [FirebaseHelper sharedHelper].uid :
                                                        [@{ dateString : @"penUp" } mutableCopy]
                                                    } mutableCopy],
                                  @"updatedAt" : dateString,
                                  @"undo" : [@{ [FirebaseHelper sharedHelper].uid :
                                                    [@{ @"currentIndex" : @0,
                                                        @"currentIndexDate" : dateString,
                                                        @"total" : @0
                                                        } mutableCopy]
                                                } mutableCopy]
                                };
    
    [[FirebaseHelper sharedHelper].boards setObject:[boardDict mutableCopy] forKey:boardRefWithID.name];
    [[FirebaseHelper sharedHelper].loadedBoardIDs addObject:boardRefWithID.name];
    
    [[FirebaseHelper sharedHelper].comments setObject:[NSMutableDictionary dictionary] forKey:commentsID];
    [[FirebaseHelper sharedHelper] observeCommentsOnBoardWithID:boardID];
    
    [[FirebaseHelper sharedHelper].projects setObject:[localProjectDict mutableCopy] forKey:projectRefWithID.name];
    [FirebaseHelper sharedHelper].currentProjectID = projectID;
    [[FirebaseHelper sharedHelper].visibleProjectIDs addObject:projectID];
    [[FirebaseHelper sharedHelper] observeProjectWithID:projectID];
    
    [projectRefWithID updateChildValues:projectDict];
    [teamRef updateChildValues:@{ projectID : @0 }];
    [boardRefWithID updateChildValues:boardDict];
    [chatRefWithID updateChildValues:@{}];
    
    NSIndexPath *mostRecent = [[FirebaseHelper sharedHelper] getLastViewedProjectIndexPath];
    [projectVC.masterView.projectsTable reloadData];
    [projectVC.masterView tableView:projectVC.masterView.projectsTable didSelectRowAtIndexPath:mostRecent];
    
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)){
            
            [outsideTapRecognizer setDelegate:nil];
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
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
