//
//  DeleteProjectAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "DeleteProjectAlertViewController.h"
#import "FirebaseHelper.h"
#import "ProjectDetailViewController.h"
#import "Flurry.h"


@implementation DeleteProjectAlertViewController

-(void) viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Delete Project";
    
    self.deleteButton.layer.borderWidth = 1;
    self.deleteButton.layer.cornerRadius = 10;
    self.deleteButton.layer.borderColor = [UIColor grayColor].CGColor;
    
}

-(void) viewWillAppear:(BOOL)animated {
    
    NSString *projectName = [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"name"];
    
    UIFont *regFont = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
    UIFont *projectFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    
    NSDictionary *regAttrs = [NSDictionary dictionaryWithObjectsAndKeys: regFont, NSFontAttributeName, nil];
    NSDictionary *projectAttrs = [NSDictionary dictionaryWithObjectsAndKeys: projectFont, NSFontAttributeName, nil];
    
    NSString *projectString = [NSString stringWithFormat:@"Are you sure you want to delete %@?", projectName];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:projectString attributes:regAttrs];
    [attrString setAttributes:projectAttrs range:NSMakeRange(32, projectName.length)];
    
    [self.projectLabel setAttributedText:attrString];
}

-(void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void) viewWillDisappear:(BOOL)animated {
    
    [outsideTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)) [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)deleteTapped:(id)sender {

    if (![FirebaseHelper sharedHelper].isAdmin && ![FirebaseHelper sharedHelper].isDev)
    [Flurry logEvent:@"Delete_Project" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSString *chatID = [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID ] objectForKey:@"chatID"];
    
    NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
    [projectRef removeValue];
    [projectRef removeAllObservers];
    [[projectRef childByAppendingPath:@"info"] removeAllObservers];
    [[projectRef childByAppendingPath:@"viewedAt"] removeAllObservers];
    [[projectRef childByAppendingPath:@"updatedAt"] removeAllObservers];
    
    NSString *teamString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams/%@/projects/%@", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].teamID, [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
    [teamRef removeValue];
    
    for (NSString *boardID in projectVC.boardIDs) {
        
        NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"commentsID"];

        NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", [FirebaseHelper sharedHelper].db, boardID];
        Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
        [boardRef removeValue];
        
        [[boardRef childByAppendingPath:@"name"] removeAllObservers];
        [[boardRef childByAppendingPath:@"updatedAt"] removeAllObservers];
        
        NSDictionary *boardDict = [[FirebaseHelper sharedHelper].boards objectForKey:boardID];
        
        for (NSString *userID in [[boardDict objectForKey:@"undo"] allKeys]) {
            
            NSString *undoString = [NSString stringWithFormat:@"undo/%@", userID];
            [[boardRef childByAppendingPath:undoString] removeAllObservers];
        }
        
        for (NSString *userID in [[boardDict objectForKey:@"subpaths"] allKeys]) {
            
            NSString *subpathsString = [NSString stringWithFormat:@"subpaths/%@", userID];
            [[boardRef childByAppendingPath:subpathsString] removeAllObservers];
        }
        
        NSString *commentsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@", [FirebaseHelper sharedHelper].db, commentsID];
        Firebase *commentsRef = [[Firebase alloc] initWithUrl:commentsString];
        [commentsRef removeAllObservers];
        
        for (NSString *commentThreadID in [[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] allKeys]) {
            
            NSString *infoString = [NSString stringWithFormat:@"%@/info", commentThreadID];
            [[commentsRef childByAppendingPath:infoString] removeAllObservers];
            
            NSString *messageString = [NSString stringWithFormat:@"%@/messages", commentThreadID];
            [[commentsRef childByAppendingPath:messageString] removeAllObservers];
        }
        
        [[FirebaseHelper sharedHelper].boards removeObjectForKey:boardID];
        [[FirebaseHelper sharedHelper].loadedBoardIDs removeObject:boardID];
        [[FirebaseHelper sharedHelper].comments removeObjectForKey:commentsID];
    }

    NSString *chatString = [NSString stringWithFormat:@"https://%@.firebaseio.com/chats/%@", [FirebaseHelper sharedHelper].db, chatID];
    Firebase *chatRef = [[Firebase alloc] initWithUrl:chatString];
    [chatRef removeValue];
    [chatRef removeAllObservers];
    
    [[FirebaseHelper sharedHelper].projects removeObjectForKey:[FirebaseHelper sharedHelper].currentProjectID];
    [[FirebaseHelper sharedHelper].visibleProjectIDs removeObject:[FirebaseHelper sharedHelper].currentProjectID];
    [[[FirebaseHelper sharedHelper].team objectForKey:@"projects"] removeObjectForKey:[FirebaseHelper sharedHelper].currentProjectID];
    [[FirebaseHelper sharedHelper].chats removeObjectForKey:chatID];
    
    [projectVC.masterView.projectsTable reloadData];
    
    if ([FirebaseHelper sharedHelper].visibleProjectIDs.count > 0) {
        
        NSIndexPath *mostRecent = [[FirebaseHelper sharedHelper] getLastViewedProjectIndexPath];
        [projectVC.masterView tableView:projectVC.masterView.projectsTable didSelectRowAtIndexPath:mostRecent];
    }
    else {
        
        [projectVC hideAll];
        [FirebaseHelper sharedHelper].currentProjectID = nil;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
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
