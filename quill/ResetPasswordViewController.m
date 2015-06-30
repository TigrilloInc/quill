//
//  ResetPasswordViewController.m
//  quill
//
//  Created by Alex Costantini on 4/6/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "ResetPasswordViewController.h"
#import "FirebaseHelper.h"

@implementation ResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.navigationItem.title = @"Reset Password";
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    self.resetLabel.text = @"Enter your email to reset your password.\nThen check your email for further instructions.";
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [self.emailTextField setLeftViewMode:UITextFieldViewModeAlways];
    [self.emailTextField setLeftView:spacerView];
    self.emailTextField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.emailTextField.layer.borderWidth = 1;
    self.emailTextField.layer.cornerRadius = 10;
    
    self.sendButton.layer.borderWidth = 1;
    self.sendButton.layer.cornerRadius = 10;
    self.sendButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void)viewWillDisappear:(BOOL)animated {
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(155, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
}

- (IBAction)sendTapped:(id)sender {

    if (self.emailTextField.text.length == 0) {
        [self.resetLabel setText:@"Please enter an email."];
        return;
    }
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if ([emailTest evaluateWithObject:self.emailTextField.text] != true) {
        
        [self.resetLabel setText:@"Please enter a valid email."];
        return;
    }
    
    self.sendButton.alpha = .5;
    self.sendButton.userInteractionEnabled = false;
    self.emailTextField.alpha = .5;
    self.emailTextField.userInteractionEnabled = false;
    self.resetLabel.text = @"Sending email...";

    
    NSString *refString = [NSString stringWithFormat:@"https://%@.firebaseio.com/", [FirebaseHelper sharedHelper].db];
    Firebase *ref = [[Firebase alloc] initWithUrl:refString];
    [ref resetPasswordForUser:self.emailTextField.text withCompletionBlock:^(NSError *error) {
        
        if (error) {
            
            if (error) {
                
                self.emailTextField.userInteractionEnabled = true;
                self.emailTextField.alpha = 1;
                self.sendButton.userInteractionEnabled = true;
                self.sendButton.alpha = 1;
                
                NSLog(@"%@", error);
                
                if (error.code == -8) self.resetLabel.text = @"There is no user account with that email.";
                else self.resetLabel.text = @"Something went wrong - try again.";
            }
        }
        else {
            self.resetLabel.text = @"Email sent!";
            [self performSelector:@selector(emailSent) withObject:nil afterDelay:.5];
        }
    }];
}

-(void) emailSent {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

@end
