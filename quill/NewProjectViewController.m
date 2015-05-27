//
//  NewProjectViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/8/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "NewProjectViewController.h"
#import "NSDate+ServerDate.h"
#import "FirebaseHelper.h"
#import "Flurry.h"

@implementation NewProjectViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [self.nameField setLeftViewMode:UITextFieldViewModeAlways];
    [self.nameField setLeftView:spacerView];
    self.nameField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.nameField.layer.borderWidth = 1;
    self.nameField.layer.cornerRadius = 10;

    self.createButton.layer.borderWidth = 1;
    self.createButton.layer.cornerRadius = 10;
    self.createButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void)keyboardWillShow:(NSNotification *)notification {
    
    keyboardShowing = YES;
}

-(void)keyboardDidShow:(NSNotification *)notification {
    
    keyboardShowing = NO;
}

- (IBAction)createProjectTapped:(id)sender {
    
    if (self.nameField.text.length <= 0) return;
    
    [Flurry logEvent:@"New_Project-Created" withParameters:@{@"teamID" : [FirebaseHelper sharedHelper].teamID}];
    
    for (NSString *projectID in [FirebaseHelper sharedHelper].projects.allKeys) {
        
        NSString *projectName = [[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"name"];
        
        if ([self.nameField.text isEqualToString:projectName]) {
            
            self.projectLabel.text = @"Your team already has a project with that name.";
            return;
        }
    }
    
    NSString *teamRefString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams/%@/projects", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].teamID];
    Firebase *teamRef = [[Firebase alloc] initWithUrl:teamRefString];
    
    NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects", [FirebaseHelper sharedHelper].db];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    Firebase *projectRefWithID = [projectRef childByAutoId];
    NSString *projectID = projectRefWithID.key;
    
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards", [FirebaseHelper sharedHelper].db];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    Firebase *boardRefWithID = [boardRef childByAutoId];
    NSString *boardID = boardRefWithID.key;
    
    NSString *chatString = [NSString stringWithFormat:@"https://%@.firebaseio.com/chats", [FirebaseHelper sharedHelper].db];
    Firebase *chatRef = [[Firebase alloc] initWithUrl:chatString];
    Firebase *chatRefWithID = [chatRef childByAutoId];
    NSString *chatID = chatRefWithID.key;
    
    NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments", [FirebaseHelper sharedHelper].db];
    Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
    Firebase *commentsRefWithID = [commentsRef childByAutoId];
    NSString *commentsID = commentsRefWithID.key;
    
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
                                                } mutableCopy],
                                  @"versions" : [@[boardID] mutableCopy]
                                };
    
    [[FirebaseHelper sharedHelper].boards setObject:[boardDict mutableCopy] forKey:boardRefWithID.key];
    [[FirebaseHelper sharedHelper].loadedBoardIDs addObject:boardRefWithID.key];
    
    [[FirebaseHelper sharedHelper].comments setObject:[NSMutableDictionary dictionary] forKey:commentsID];
    [[FirebaseHelper sharedHelper] observeCommentsOnBoardWithID:boardID];
    
    [[FirebaseHelper sharedHelper].projects setObject:[localProjectDict mutableCopy] forKey:projectRefWithID.key];
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
        CGPoint converted = [self.view convertPoint:CGPointMake(location.y,location.x) fromView:self.view.window];

        if (!CGRectContainsPoint(self.view.bounds, converted) && !keyboardShowing){
            
            [outsideTapRecognizer setDelegate:nil];
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if(range.length + range.location > textField.text.length) return NO;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if (newLength > 21) {
        
        self.projectLabel.text = @"Project names must be 20 characters or less.";
        return NO;
    }
    else {
        
        self.projectLabel.text = @"Pick a name for this project.";
        return YES;
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
