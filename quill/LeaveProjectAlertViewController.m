//
//  LeaveProjectAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "LeaveProjectAlertViewController.h"
#import "FirebaseHelper.h"
#import "Flurry.h"

@implementation LeaveProjectAlertViewController

-(void) viewDidLoad {
    
    [super viewDidLoad];
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    self.navigationItem.title = @"Leave Project";
    
    self.leaveButton.layer.borderWidth = 1;
    self.leaveButton.layer.cornerRadius = 10;
    self.leaveButton.layer.borderColor = [UIColor grayColor].CGColor;

}

-(void) viewWillAppear:(BOOL)animated {
    
    NSString *projectName = [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"name"];
    
    UIFont *regFont = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
    UIFont *projectFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    
    NSDictionary *regAttrs = [NSDictionary dictionaryWithObjectsAndKeys: regFont, NSFontAttributeName, nil];
    NSDictionary *projectAttrs = [NSDictionary dictionaryWithObjectsAndKeys: projectFont, NSFontAttributeName, nil];
    NSRange projectRange = NSMakeRange(33, projectName.length);
    
    NSString *projectString = [NSString stringWithFormat:@"Are you sure you'd like to leave %@?", projectName];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:projectString attributes:regAttrs];
    [attrString setAttributes:projectAttrs range:projectRange];
    
    [self.projectLabel setAttributedText:attrString];
    
    if (self.deleteProject) [self.leaveLabel setText:@"The project and all its content will be deleted."];
    else [self.leaveLabel setText:@"You'll have to be invited back to continue collaborating."];
    
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

- (IBAction)leaveTapped:(id)sender {
    
    if (![FirebaseHelper sharedHelper].isAdmin && ![FirebaseHelper sharedHelper].isDev)
    [Flurry logEvent:@"Leave_Project" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
    
    [[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"roles"] setObject:@(-1) forKey:[FirebaseHelper sharedHelper].uid];
    [[FirebaseHelper sharedHelper].visibleProjectIDs removeObject:[FirebaseHelper sharedHelper].currentProjectID];
    
    NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info/roles/%@",[FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID, [FirebaseHelper sharedHelper].uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    [ref setValue:@(-1)];
    
    [FirebaseHelper sharedHelper].currentProjectID = nil;
    
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

-(void) tappedOutside {

    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)) [self dismissViewControllerAnimated:YES completion:nil];
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
