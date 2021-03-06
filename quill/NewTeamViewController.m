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
#import "Flurry.h"

@implementation NewTeamViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Step 2: Team Name";

    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Team Name"
                                   style: UIBarButtonItemStylePlain
                                   target: nil action: nil];
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

-(void) viewWillAppear:(BOOL)animated {
    
    [self.teamField becomeFirstResponder];
}

- (IBAction)createTeamTapped:(id)sender {
    
    if (self.teamField.text.length == 0) {
        
        self.teamLabel.text = @"Please enter a team name.";
        return;
    }
    
    if (self.teamField.text.length == 1) {
        
        self.teamLabel.text = @"Team names must be at least 2 characters long.";
        return;
    }

    [Flurry logEvent:@"New_Owner-Sign_up-Step_2-Team_Name_Complete" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
    
    [FirebaseHelper sharedHelper].teamName = self.teamField.text;
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(149, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    InviteToTeamViewController *inviteVC = [self.storyboard instantiateViewControllerWithIdentifier:@"InviteToTeam"];
    inviteVC.creatingTeam = true;
    [self.navigationController pushViewController:inviteVC animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {

        [Flurry logEvent:@"New_Owner-Sign_up-Step_2-Back_to_Username" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
        
        logoImage.hidden = true;
        logoImage.frame = CGRectMake(154, 8, 32, 32);
        
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if(range.length + range.location > textField.text.length) return NO;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if (newLength > 21) {
        
        self.teamLabel.text = @"Team names must be 20 characters or less.";
        return NO;
    }
    else {
        
        self.teamLabel.text = @"Pick a name for your team.";
        return YES;
    }
}


@end
