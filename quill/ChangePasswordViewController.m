//
//  ChangePasswordViewController.m
//  quill
//
//  Created by Alex Costantini on 2/4/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "FirebaseHelper.h"

@implementation ChangePasswordViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Change Password";
    
    textFieldArray = @[self.passwordTextField, self.confirmTextField, self.currentTextField];
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
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
    
    if (self.passwordTextField.text.length == 0 || self.confirmTextField.text.length == 0 || self.currentTextField.text.length == 0)
        self.passwordLabel.text = @"Please enter a password in all fields";
    else if (![self.passwordTextField.text isEqualToString:self.confirmTextField.text])
        self.passwordLabel.text = @"The passwords entered don't match.";
    else if (self.passwordTextField.text.length < 6 || [self.passwordTextField.text rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound || [self.passwordTextField.text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) self.passwordLabel.text = @"Passwords must be 6-20 characters in length,\n and must contain at least one letter and one number.";
    else {
        
        self.passwordTextField.userInteractionEnabled = false;
        self.passwordTextField.alpha = .5;
        self.confirmTextField.userInteractionEnabled = false;
        self.confirmTextField.alpha = .5;
        self.currentTextField.userInteractionEnabled = false;
        self.currentTextField.alpha = .5;
        self.applyButton.userInteractionEnabled = false;
        self.applyButton.alpha = .5;
        
        NSString *urlString = [NSString stringWithFormat:@"https://%@.firebaseio.com/", [FirebaseHelper sharedHelper].db];
        Firebase *ref = [[Firebase alloc] initWithUrl:urlString];
        [ref changePasswordForUser:[FirebaseHelper sharedHelper].uid fromOld:self.currentTextField.text toNew:self.passwordTextField.text withCompletionBlock:^(NSError *error) {
            
            if (error) {
                
                self.passwordTextField.userInteractionEnabled = true;
                self.passwordTextField.alpha = 1;
                self.confirmTextField.userInteractionEnabled = true;
                self.confirmTextField.alpha = 1;
                self.currentTextField.userInteractionEnabled = true;
                self.currentTextField.alpha = 1;
                self.applyButton.userInteractionEnabled = true;
                self.applyButton.alpha = 1;
                
                NSLog(@"%@", error);
                
                if (error.code == -6) self.passwordLabel.text = @"The current password entered is incorrect.";
                else self.passwordLabel.text = @"Something went wrong - try again.";
            }
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

#pragma mark - UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (![textField isEqual:self.passwordTextField] && ![textField isEqual:self.confirmTextField]) return YES;
    
    if(range.length + range.location > textField.text.length) return NO;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if (newLength > 21) {
        
        self.passwordLabel.text = @"Passwords must be 20 characters or less.";
        return NO;
    }
    else {
        
        self.passwordLabel.text = @"";
        return YES;
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
