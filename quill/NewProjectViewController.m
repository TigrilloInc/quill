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
    
    NSDictionary *projectDict =  @{ @"info" : @{ @"name" :   projectName,
                                                 @"boards" : @{ @"0" : boardID },
                                                 @"chatID" : chatID,
                                                 @"roles" : @{ [FirebaseHelper sharedHelper].uid : @2 }
                                                 },
                                    @"viewedAt" :  @{ [FirebaseHelper sharedHelper].uid : @([[NSDate serverDate] timeIntervalSince1970]*100000000) },
                                    @"updatedAt" : @([[NSDate serverDate] timeIntervalSince1970]*100000000)
                                    };
    
    NSMutableDictionary *allSubpathsDict = [NSMutableDictionary dictionary];
    for (NSString *uid in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        [allSubpathsDict setObject:@{[NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000]: @"penUp"} forKey: uid];
    }
    
    NSDictionary *boardDict =  @{ @"name" : @"Untitled",
                                  @"project" : projectID,
                                  @"number" : @0,
                                  @"commentsID" : commentsID,
                                  @"lastSubpath" : @{},
                                  @"allSubpaths" : allSubpathsDict,
                                  @"updatedAt" : @([[NSDate serverDate] timeIntervalSince1970]*100000000),
                                  @"undo" :
                                      @{ [FirebaseHelper sharedHelper].uid :
                                             @{ @"currentIndex" : @0,
                                                @"total" : @0
                                                }
                                         }
                                };
    
    [FirebaseHelper sharedHelper].projectCreated = true;
    [FirebaseHelper sharedHelper].currentProjectID = projectID;
    
    [projectRefWithID updateChildValues:projectDict withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        [teamRef updateChildValues:@{ projectID : @0 } withCompletionBlock:^(NSError *error, Firebase *ref) {
            
            [boardRefWithID updateChildValues:boardDict withCompletionBlock:^(NSError *error, Firebase *ref) {
                
                [chatRefWithID updateChildValues:@{} withCompletionBlock:^(NSError *error, Firebase *ref) {
                    
                    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
                    [FirebaseHelper sharedHelper].projectCreated = false;
                    
                    NSIndexPath *mostRecent = [[FirebaseHelper sharedHelper] getLastViewedProjectIndexPath];
                    
                    [self dismissViewControllerAnimated:YES completion:^{
                        
                        [projectVC.masterView.projectsTable reloadData];
                        [projectVC.masterView tableView:projectVC.masterView.projectsTable didSelectRowAtIndexPath:mostRecent];
                        
                    }];
                
                }];
            }];
        }];
    }];
}

-(void) tappedOutside
{
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]){
            
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

@end
