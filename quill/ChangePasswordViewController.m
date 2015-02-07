//
//  ChangePasswordViewController.m
//  quill
//
//  Created by Alex Costantini on 2/4/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "FirebaseHelper.h"
@implementation ChangePasswordViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Change Password";
    
    textFieldArray = @[self.passwordTextField, self.confirmTextField, self.currentTextField];

    for (UITextField *textField in textFieldArray) {
    
        textField.secureTextEntry = true;
        
        UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [textField setLeftViewMode:UITextFieldViewModeAlways];
        [textField setLeftView:spacerView];
        textField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
        textField.layer.borderWidth = 1;
        textField.layer.cornerRadius = 10;
    }
    
    self.applyButton.layer.borderWidth = 1;
    self.applyButton.layer.cornerRadius = 10;
    self.applyButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void) viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
        logoImage.hidden = true;
        logoImage.frame = CGRectMake(155, 8, 32, 32);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    }
    
    for (UITextField *textField in textFieldArray) {
        
        textField.delegate = nil;
    }
    
    outsideTapRecognizer.delegate = nil;
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    
    [super viewWillDisappear:animated];
}

- (IBAction)applyTapped:(id)sender {
    
    if (![self.passwordTextField.text isEqualToString:self.confirmTextField.text])
        self.passwordLabel.text = @"Passwords don't match - try again.";
    else if (self.currentTextField.text > 0) {
        
        Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
        [ref changePasswordForUser:[FirebaseHelper sharedHelper].uid fromOld:self.currentTextField.text toNew:self.passwordTextField.text withCompletionBlock:^(NSError *error) {
            
            if (error) self.passwordLabel.text = @"Something went wrong - try again.";
            else {
                
                self.passwordLabel.text = @"Password updated!";
                [self performSelector:@selector(passwordChanged) withObject:nil afterDelay:.5];
            }
        }];
    }
}

-(void)passwordChanged {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showLogo {
    
    UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)){
            
            [outsideTapRecognizer setDelegate:nil];
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

@end
