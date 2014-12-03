//
//  AvatarPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 11/23/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "AvatarPopoverViewController.h"
#import "FirebaseHelper.h"

@implementation AvatarPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

-(void)updateMenu {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:self.userID] objectForKey:@"name"];
    
    int roleNum = [[[[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"info"] objectForKey:@"roles"] objectForKey:self.userID] intValue];
    
    NSString *roleString;
    
    if (roleNum == 2) roleString = @"Owner";
    else if (roleNum == 1) roleString = @"Collaborator";
    else roleString = @"Viewer";
    
    NSString *titleString = [NSString stringWithFormat:@"%@ (%@)", userName, roleString];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 100, 20)];
    [titleLabel setText:titleString];
    [titleLabel sizeToFit];
    [self.view addSubview:titleLabel];
    
    int buttonCount = 0;
    
    if (projectVC.userRole == 2 && ![self.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
        
        if (roleNum == 0) {
            
            buttonCount++;
            
            UIButton *collabButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [collabButton setTitle:@"Make Collaborator" forState:UIControlStateNormal];
            collabButton.tag = 1;
            [collabButton addTarget:self action:@selector(setRole:) forControlEvents:UIControlEventTouchUpInside];
            [collabButton sizeToFit];
            collabButton.frame = CGRectMake(40, 20+(40*buttonCount), collabButton.frame.size.width, collabButton.frame.size.height);
            [self.view addSubview:collabButton];
            
        }
        else {
            
            buttonCount++;
            
            UIButton *collabButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [collabButton setTitle:@"Make Viewer" forState:UIControlStateNormal];
            collabButton.tag = 0;
            [collabButton addTarget:self action:@selector(setRole:) forControlEvents:UIControlEventTouchUpInside];
            [collabButton sizeToFit];
            collabButton.frame = CGRectMake(40, 20+(40*buttonCount), collabButton.frame.size.width, collabButton.frame.size.height);
            [self.view addSubview:collabButton];

        }
        
        if (![self.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
            
            buttonCount++;
            
            UIButton *collabButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [collabButton setTitle:@"Remove from project" forState:UIControlStateNormal];
            [collabButton addTarget:self action:@selector(removeUser) forControlEvents:UIControlEventTouchUpInside];
            [collabButton sizeToFit];
            collabButton.frame = CGRectMake(40, 20+(40*buttonCount), collabButton.frame.size.width, collabButton.frame.size.height);
            [self.view addSubview:collabButton];

        }
    }
    else {
        
        buttonCount++;
        
        UIButton *collabButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [collabButton setTitle:@"Leave project" forState:UIControlStateNormal];
        [collabButton addTarget:self action:@selector(removeUser) forControlEvents:UIControlEventTouchUpInside];
        [collabButton sizeToFit];
        collabButton.frame = CGRectMake(40, 20+(40*buttonCount), collabButton.frame.size.width, collabButton.frame.size.height);
        [self.view addSubview:collabButton];

    }
    
    self.preferredContentSize = CGSizeMake(260, 70+(buttonCount*40));
}

-(void) setRole:(id)sender {
    
    UIButton *button = (UIButton *)sender;
    NSInteger role = button.tag;
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info/roles/%@", [FirebaseHelper sharedHelper].currentProjectID, self.userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    [ref setValue:@(role)];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) removeUser {
    
    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info/roles/%@", [FirebaseHelper sharedHelper].currentProjectID, self.userID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    [ref removeValue];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
