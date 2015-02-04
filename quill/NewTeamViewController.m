//
//  NewTeamViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/7/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "NewTeamViewController.h"
#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"
#import "InviteToTeamViewController.h"

@implementation NewTeamViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Step 2: Team Name";

    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Team Name"
                                   style: UIBarButtonItemStyleBordered
                                   target: nil action: nil];
    [backButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont fontWithName:@"SourceSansPro-Semibold" size:16],NSFontAttributeName,
                                        nil] forState:UIControlStateNormal];
    [self.navigationItem setBackBarButtonItem: backButton];
    
    self.createTeamButton.layer.borderWidth = 1;
    self.createTeamButton.layer.cornerRadius = 10;
    self.createTeamButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [self.teamField setLeftViewMode:UITextFieldViewModeAlways];
    [self.teamField setLeftView:spacerView];
    self.teamField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.teamField.layer.borderWidth = 1;
    self.teamField.layer.cornerRadius = 10;
}

- (IBAction)createTeamTapped:(id)sender {
    
//    Firebase *teamRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/teams"];
//    
//    NSDictionary *newTeamValues = @{ teamName :
//                                         @{ @"users" :
//                                                @{ [FirebaseHelper sharedHelper].uid : @1 }
//                                            }
//                                     };
//    
//    [teamRef updateChildValues:newTeamValues];
//    
//    NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@", [FirebaseHelper sharedHelper].uid];
//    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
//    
//    [userRef updateChildValues:@{ @"team" : teamName }];
//    
//    [self dismissViewControllerAnimated:YES completion:nil];
//    
//    [[FirebaseHelper sharedHelper] observeLocalUser];

    
    if (self.teamField.text.length == 0) return;
    
    [FirebaseHelper sharedHelper].teamName = self.teamField.text;
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(145, 2, 35, 35);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    InviteToTeamViewController *inviteVC = [self.storyboard instantiateViewControllerWithIdentifier:@"InviteToTeam"];
    [self.navigationController pushViewController:inviteVC animated:YES];
    
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {

        logoImage.hidden = true;
        logoImage.frame = CGRectMake(149, 2, 35, 35);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    }
    [super viewWillDisappear:animated];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;

    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

@end
