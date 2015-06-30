//
//  RemoveUserAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "RemoveUserAlertViewController.h"
#import "FirebaseHelper.h"
#import "TeamSettingsViewController.h"

@implementation RemoveUserAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Remove User";
    
    self.removeButton.layer.borderWidth = 1;
    self.removeButton.layer.cornerRadius = 10;
    self.removeButton.layer.borderColor = [UIColor grayColor].CGColor;
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:self.userID] objectForKey:@"name"];
    
    UIFont *nameFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    UIFont *labelFont = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
    NSDictionary *nameAttrs = [NSDictionary dictionaryWithObjectsAndKeys: nameFont, NSFontAttributeName, nil];
    NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys: labelFont, NSFontAttributeName, nil];
   
    NSString *removeString = [NSString stringWithFormat:@"Are you sure you want to remove %@ from %@?", userName,[FirebaseHelper sharedHelper].teamName];
    NSMutableAttributedString *removeAttrString = [[NSMutableAttributedString alloc] initWithString:removeString attributes:labelAttrs];
    [removeAttrString setAttributes:nameAttrs range:NSMakeRange(32,userName.length)];
    [removeAttrString setAttributes:nameAttrs range:NSMakeRange(38+userName.length,[FirebaseHelper sharedHelper].teamName.length)];
    [self.removeLabel setAttributedText:removeAttrString];
    
    NSString *warnString = [NSString stringWithFormat:@"Once removed, %@ won't have access to any projects and will have to be invited again to continue collaborating.", userName];
    NSMutableAttributedString *warnAttrString = [[NSMutableAttributedString alloc] initWithString:warnString attributes:labelAttrs];
    [warnAttrString setAttributes:nameAttrs range:NSMakeRange(14, userName.length)];
    [self.warnLabel setAttributedText:warnAttrString];
}

-(void) viewDidAppear:(BOOL)animated {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.handleOutsideTaps = true;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.handleOutsideTaps = false;
}

- (IBAction)removeTapped:(id)sender {
    
    NSString *userString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/", [FirebaseHelper sharedHelper].db, self.userID];
    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
    [[userRef childByAppendingPath:@"avatar"] removeAllObservers];
    [[userRef childByAppendingPath:@"info"] removeAllObservers];
    [[userRef childByAppendingPath:@"status"] removeAllObservers];
    [[userRef childByAppendingPath:@"info/deleted"] setValue:@(1)];
    
    [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:self.userID] setObject:@(1) forKey:@"deleted"];
    
    TeamSettingsViewController *teamVC = (TeamSettingsViewController *)self.navigationController.viewControllers[0];
    [teamVC.usersDict removeObjectForKey:self.userID];
    [teamVC.usersTable reloadData];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
