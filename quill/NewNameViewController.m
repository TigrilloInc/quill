//
//  NewNameViewController.m
//  quill
//
//  Created by Alex Costantini on 1/30/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "NewNameViewController.h"
#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"
#import "NewTeamViewController.h"

@implementation NewNameViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Step 1: Your Name";
    [self.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Your Name"
                                   style: UIBarButtonItemStyleBordered
                                   target:self action: @selector(backTapped)];
    [self.navigationItem setBackBarButtonItem: backButton];
    
    
    self.nameButton.layer.borderWidth = 1;
    self.nameButton.layer.cornerRadius = 10;
    self.nameButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [self.nameTextField setLeftViewMode:UITextFieldViewModeAlways];
    [self.nameTextField setLeftView:spacerView];
    self.nameTextField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.nameTextField.layer.borderWidth = 1;
    self.nameTextField.layer.cornerRadius = 10;
}

-(IBAction)nextTapped:(id)sender {
    
    if (self.nameTextField.text.length == 0) {
        
        self.nameLabel.text = @"Please enter your name.";
        return;
    }
    
    if (self.nameTextField.text.length == 1) {
        
        self.nameLabel.text = @"Names must be at least 2 letters long.";
        return;
    }
    
    if ([self.nameTextField.text rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound || [self.nameTextField.text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound || [self.nameTextField.text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        
        self.nameLabel.text = @"Names cannot contain spaces, numbers, or special characters.";
        return;
    }
    
    [FirebaseHelper sharedHelper].userName = self.nameTextField.text;
    
    UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(149, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    NewTeamViewController *newTeamVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NewTeam"];
    [self.navigationController pushViewController:newTeamVC animated:YES];
}

-(void)backTapped {
    
    UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(154, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
}

-(void)showLogo {
    
    UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if(range.length + range.location > textField.text.length) return NO;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if (newLength > 16) {
        
        self.nameLabel.text = @"Names must be 15 characters or less.";
        return NO;
    }
    else {
        
        self.nameLabel.text = @"What do people call you?";
        return YES;
    }
}

@end
