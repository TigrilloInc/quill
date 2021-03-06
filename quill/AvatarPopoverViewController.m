//
//  AvatarPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 11/23/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "AvatarPopoverViewController.h"
#import "FirebaseHelper.h"
#import "LeaveProjectAlertViewController.h"
#import "TransferOwnerViewController.h"
#import "Flurry.h"

@implementation AvatarPopoverViewController

-(void)updateMenu {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:self.userID] objectForKey:@"name"];
    
    int roleNum = [[[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"roles"] objectForKey:self.userID] intValue];
    
    NSString *roleString;
    
    if (roleNum == 2) roleString = @"(Owner)";
    else if (roleNum == 1) roleString = @"(Collaborator)";
    else roleString = @"(Viewer)";

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 228, 25)];
    titleLabel.numberOfLines = 1;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    UIFont *nameFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    UIFont *roleFont = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
    
    NSDictionary *nameAttrs = [NSDictionary dictionaryWithObjectsAndKeys: nameFont, NSFontAttributeName, nil];
    NSDictionary *roleAttrs = [NSDictionary dictionaryWithObjectsAndKeys: roleFont, NSFontAttributeName, nil];
    NSRange roleRange = NSMakeRange(userName.length+1,roleString.length);
    
    NSString *titleString = [NSString stringWithFormat:@"%@ %@", userName, roleString];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:titleString attributes:nameAttrs];
    [attrString setAttributes:roleAttrs range:roleRange];
    
    [titleLabel setAttributedText:attrString];
    
    [self.view addSubview:titleLabel];
    
    int buttonCount = 0;
    
    if (projectVC.userRole == 2 && ![self.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
        
        if (roleNum == 0) {
            
            buttonCount++;
            
            UIButton *collabButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [collabButton setBackgroundImage:[UIImage imageNamed:@"collaborator.png"] forState:UIControlStateNormal];
            collabButton.tag = 1;
            collabButton.alpha = .5;
            [collabButton addTarget:self action:@selector(setRole:) forControlEvents:UIControlEventTouchUpInside];
            collabButton.frame = CGRectMake(20, 25+(40*buttonCount), 160, 20);
            [self.view addSubview:collabButton];
            
        }
        else {
            
            buttonCount++;
            
            UIButton *viewerButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [viewerButton setBackgroundImage:[UIImage imageNamed:@"viewer.png"] forState:UIControlStateNormal];
            viewerButton.tag = 0;
            viewerButton.alpha = .5;
            [viewerButton addTarget:self action:@selector(setRole:) forControlEvents:UIControlEventTouchUpInside];
            viewerButton.frame = CGRectMake(20, 25+(40*buttonCount), 126, 20);
            [self.view addSubview:viewerButton];

        }
        
        if (![self.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
            
            buttonCount++;
            
            UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [removeButton setBackgroundImage:[UIImage imageNamed:@"remove.png"] forState:UIControlStateNormal];
            removeButton.alpha = .5;
            [removeButton addTarget:self action:@selector(removeUser) forControlEvents:UIControlEventTouchUpInside];
            removeButton.frame = CGRectMake(20, 25+(40*buttonCount), 180, 20);
            [self.view addSubview:removeButton];
        }
    }
    else if ([self.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
        
        buttonCount++;
        
        UIButton *leaveButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [leaveButton setBackgroundImage:[UIImage imageNamed:@"leave.png"] forState:UIControlStateNormal];
        leaveButton.alpha = .5;
        [leaveButton addTarget:self action:@selector(removeUser) forControlEvents:UIControlEventTouchUpInside];
        leaveButton.frame = CGRectMake(20, 25+(40*buttonCount), 126, 20);
        [self.view addSubview:leaveButton];
    }
    
    if (buttonCount == 0) {
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.center = CGPointMake(titleLabel.frame.size.width/2, titleLabel.center.y);
        self.preferredContentSize = CGSizeMake(titleLabel.frame.size.width, 65);
    }
    else self.preferredContentSize = CGSizeMake(260, 70+(buttonCount*40));
}

-(void) setRole:(id)sender {
    
    UIButton *button = (UIButton *)sender;
    NSInteger role = button.tag;
    
    NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info/roles/%@", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID, self.userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    [ref setValue:@(role)];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) removeUser {
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    if ([self.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
        
        UINavigationController *nav;
        
        UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
        logoImageView.tag = 800;
        
        if (projectVC.userRole == 2) {
            
            if (projectVC.roles.allKeys.count == 1) {
            
                LeaveProjectAlertViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"LeaveProject"];
                vc.deleteProject = true;
                nav = [[UINavigationController alloc] initWithRootViewController:vc];
                logoImageView.frame = CGRectMake(150, 8, 32, 32);
            }
            else {
                
                TransferOwnerViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"TransferOwner"];
                nav = [[UINavigationController alloc] initWithRootViewController:vc];
                logoImageView.frame = CGRectMake(150, 8, 32, 32);
            }
        }
        else {
            
            LeaveProjectAlertViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"LeaveProject"];
            vc.deleteProject = false;
            nav = [[UINavigationController alloc] initWithRootViewController:vc];
            logoImageView.frame = CGRectMake(150, 8, 32, 32);
        }
        
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [nav.navigationBar addSubview:logoImageView];
        
        [projectVC presentViewController:nav animated:YES completion:nil];
    }
    else {
        
        [Flurry logEvent:@"User_Removed" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
        
        [[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"roles"] removeObjectForKey:self.userID];
        
        NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info/roles/%@", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID, self.userID];
        Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
        [ref removeValue];
        
        [projectVC layoutAvatars];
    }
}

@end
