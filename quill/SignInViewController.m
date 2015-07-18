//
//  SignInViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/7/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "SignInViewController.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "FirebaseHelper.h"
#import "NewNameViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NameFromInviteViewController.h"
#import "ResetPasswordViewController.h"
#import "Flurry.h"

@implementation SignInViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.passwordField.secureTextEntry = true;
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    self.navigationItem.title = @"Welcome to Quill!";
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Sign In"
                                   style: UIBarButtonItemStylePlain
                                   target: nil action: nil];
    [self.navigationItem setBackBarButtonItem: backButton];
    
    self.emailField.delegate = self;
    self.passwordField.delegate = self;
    
    UIView *emailSpacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    UIView *passwordSpacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [self.emailField setLeftViewMode:UITextFieldViewModeAlways];
    [self.emailField setLeftView:emailSpacerView];
    [self.passwordField setLeftViewMode:UITextFieldViewModeAlways];
    [self.passwordField setLeftView:passwordSpacerView];
    
    self.signInButton.layer.borderWidth = 1;
    self.signInButton.layer.cornerRadius = 10;
    self.signInButton.layer.borderColor = [UIColor grayColor].CGColor;
    self.emailField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.emailField.layer.borderWidth = 1;
    self.emailField.layer.cornerRadius = 10;
    self.passwordField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.passwordField.layer.borderWidth = 1;
    self.passwordField.layer.cornerRadius = 10;
    
    if ([FirebaseHelper sharedHelper].email) {
        
        self.signingIn = false;
        self.switchButton.hidden = false;
        self.emailField.text = [FirebaseHelper sharedHelper].email;
    }
    else self.signingIn = true;
    
    self.signingIn = [[[NSUserDefaults standardUserDefaults] objectForKey:@"registered"] integerValue];
    
    [self updateDetails];

}

-(void) updateDetails {
    
    [UIView setAnimationsEnabled:NO];
    
    if (self.signingIn) {
        
        [self.switchButton setTitle:@"Want to create an account?" forState:UIControlStateNormal];
        [self.signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
        [self.signInLabel setText:@"Sign in with your email."];
        self.passwordResetButton.hidden = false;
        
    } else {
        
        [self.switchButton setTitle:@"Already have an account?" forState:UIControlStateNormal];
        [self.signInButton setTitle:@"Sign Up" forState:UIControlStateNormal];
        [self.signInLabel setText:@"Pick an email and password to begin creating a team."];
        self.passwordResetButton.hidden = true;
    }
    
    [UIView setAnimationsEnabled:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.emailField || textField == self.passwordField) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (IBAction)signInTapped:(id)sender {
    
//    [self accountCreated];
//    return;
    
    if (self.emailField.text.length == 0 && self.passwordField.text.length == 0) {
        [self.signInLabel setText:@"Please enter an email and password."];
        return;
    };
    if (self.emailField.text.length == 0) {
        [self.signInLabel setText:@"Please enter an email."];
        return;
    }
    if (self.passwordField.text.length == 0) {
        [self.signInLabel setText:@"Please enter a password."];
        return;
    }
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if ([emailTest evaluateWithObject:self.emailField.text] != true) {
        
        [self.signInLabel setText:@"Please enter a valid email."];
        return;
    }
    
    self.emailField.userInteractionEnabled = false;
    self.emailField.alpha = .5;
    self.passwordField.userInteractionEnabled = false;
    self.passwordField.alpha = .5;
    self.signInButton.userInteractionEnabled = false;
    self.signInButton.alpha = .5;
    self.passwordResetButton.userInteractionEnabled = false;
    self.passwordResetButton.alpha = .5;
    
    [FirebaseHelper sharedHelper].email = self.emailField.text;
    [[FirebaseHelper sharedHelper] setRoles];
    
    NSString *refString = [NSString stringWithFormat:@"https://%@.firebaseio.com/", [FirebaseHelper sharedHelper].db];
    Firebase *ref = [[Firebase alloc] initWithUrl:refString];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:ref];
    
    if (self.signingIn == true) {
        
        self.signInLabel.text = @"Authenticating user...";
        
        [authClient loginWithEmail:self.emailField.text andPassword:self.passwordField.text
               withCompletionBlock:^(NSError* error, FAUser* user) {
                   
                   if (error != nil) {
                       
                       if (error.code == -2) [self.signInLabel setText:@"Incorrect password - try again."];
                       else if (error.code == -1) [self.signInLabel setText:@"There is no user account with that email."];
                       else [self.signInLabel setText:@"Something went wrong - try again."];
                       
                       NSLog(@"%@", error);
                       
                       self.emailField.userInteractionEnabled = true;
                       self.passwordField.userInteractionEnabled = true;
                       self.emailField.alpha = 1;
                       self.passwordField.alpha = 1;
                       self.signInButton.userInteractionEnabled = true;
                       self.signInButton.alpha = 1;
                       self.passwordResetButton.userInteractionEnabled = true;
                       self.passwordResetButton.alpha = 1;
                   }
                   else {
                       
                        [Flurry logEvent:@"Sign_in-Complete"];
                       
                       [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"registered"];
                       [FirebaseHelper sharedHelper].loggedIn = true;
                       [FirebaseHelper sharedHelper].uid = user.uid;
                       [FirebaseHelper sharedHelper].email = user.email;
                       [[FirebaseHelper sharedHelper] setRoles];
                       [[FirebaseHelper sharedHelper] observeLocalUser];
                   }
               }];
    }
    else {
        
        if (self.passwordField.text.length < 6 || [self.passwordField.text rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound || [self.passwordField.text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) {
            
            self.signInLabel.text = @"Passwords must be 6-20 characters in length,\n and must contain at least one letter and one number.";
            
            self.emailField.userInteractionEnabled = true;
            self.passwordField.userInteractionEnabled = true;
            self.emailField.alpha = 1;
            self.passwordField.alpha = 1;
            self.signInButton.userInteractionEnabled = true;
            self.signInButton.alpha = 1;
            self.passwordResetButton.userInteractionEnabled = true;
            self.passwordResetButton.alpha = 1;
            
            return;
        }
        
        self.signInLabel.text = @"Creating user account...";
        
        [authClient createUserWithEmail:self.emailField.text password:self.passwordField.text andCompletionBlock:^(NSError* error, FAUser* user) {
            
            if (error != nil) {
                
                if (error.code == -9999) [self.signInLabel setText:@"That email is already in use."];
                else [self.signInLabel setText:@"Something went wrong - try again."];
                
                self.emailField.userInteractionEnabled = true;
                self.emailField.alpha = 1;
                self.passwordField.userInteractionEnabled = true;
                self.passwordField.alpha = 1;
                self.signInButton.userInteractionEnabled = true;
                self.signInButton.alpha = 1;
            }
            else {
                
                NSString *userString = [NSString stringWithFormat:@"users/%@/info", user.uid];
                
                [[ref childByAppendingPath:userString] updateChildValues:@{@"email":self.emailField.text}];
                
                [FirebaseHelper sharedHelper].uid = user.uid;
                
                [authClient loginWithEmail:self.emailField.text andPassword:self.passwordField.text
                       withCompletionBlock:^(NSError* error, FAUser* user) {
                           
                    if (error != nil) {
                               
                        [self.signInLabel setText:@"Something went wrong - try again."];
                        NSLog(@"%@", error);
            
                    } else {
                        
                        self.signInLabel.text = @"User account created!";
                        
                        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"registered"];
                        [FirebaseHelper sharedHelper].loggedIn = true;
                        [FirebaseHelper sharedHelper].uid = user.uid;
                        [FirebaseHelper sharedHelper].email = user.email;
                        
                        NSString *teamString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams", [FirebaseHelper sharedHelper].db];
                        Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
                        if (![FirebaseHelper sharedHelper].teamID) [FirebaseHelper sharedHelper].teamID = [teamRef childByAutoId].key;
                        
                        [self performSelector:@selector(accountCreated) withObject:nil afterDelay:.5];
                    }
                }];
            }
        }];
    }
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

-(void)accountCreated {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NewNameViewController *newNameVC = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"NewName"];
//    NameFromInviteViewController *newNameVC = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"NameFromInvite"];
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(154, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    [self.navigationController pushViewController:newNameVC animated:YES];
}

- (IBAction)passwordResetTapped:(id)sender {

    ResetPasswordViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ResetPassword"];
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(163, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)switchTapped:(id)sender {

    self.signingIn = !self.signingIn;

    [self updateDetails];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{

    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (![textField isEqual:self.passwordField]) return YES;
    
    if(range.length + range.location > textField.text.length) return NO;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if (newLength > 21) {
        
        self.signInLabel.text = @"Passwords must be 20 characters or less.";
        return NO;
    }
    else {
        
        if (self.signingIn) self.signInLabel.text = @"Sign in with your email.";
        else self.signInLabel.text = @"Pick an email and password to begin creating a team.";
        return YES;
    }
}

@end
