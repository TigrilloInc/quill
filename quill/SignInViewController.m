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

@implementation SignInViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.passwordField.secureTextEntry = true;
    
    self.navigationItem.title = @"Welcome to Quill!";
    
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
    
    _signingIn = [[[NSUserDefaults standardUserDefaults] objectForKey:@"registered"] integerValue];
    
    [self updateDetails];
}

-(void) updateDetails {
    
    [UIView setAnimationsEnabled:NO];
    
    if (_signingIn) {
        
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
    
    if (self.emailField.text.length == 0 && self.passwordField.text.length == 0) {
        [self.signInLabel setText:@"Enter your email and password."];
        return;
    };
    if (self.emailField.text.length == 0) {
        [self.signInLabel setText:@"Enter your email."];
        return;
    }
    if (self.passwordField.text.length == 0) {
        [self.signInLabel setText:@"Enter your password."];
        return;
    }
    
    self.emailField.userInteractionEnabled = false;
    self.passwordField.userInteractionEnabled = false;
    self.emailField.alpha = .5;
    self.passwordField.alpha = .5;
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:ref];
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
 
//    NewTeamViewController *newTeamVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NewTeam"];
//    [self.navigationController pushViewController:newTeamVC animated:YES];
    
    if ([emailTest evaluateWithObject:self.emailField.text] == true && self.passwordField.text.length > 0) {
        
        if (_signingIn == true) {
            
            [authClient loginWithEmail:self.emailField.text andPassword:self.passwordField.text
                   withCompletionBlock:^(NSError* error, FAUser* user) {
                       
                       if (error != nil) {
                           
                           [self.signInLabel setText:@"Something went wrong - try again."];
                           self.emailField.userInteractionEnabled = true;
                           self.passwordField.userInteractionEnabled = true;
                           self.emailField.alpha = 1;
                           self.passwordField.alpha = 1;
                           NSLog(@"%@", error);
                       }
                       else {
                           
                           [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"registered"];
                           [FirebaseHelper sharedHelper].loggedIn = true;
                           [FirebaseHelper sharedHelper].uid = user.uid;
                           [[FirebaseHelper sharedHelper] observeLocalUser];
                           
                           [self dismissViewControllerAnimated:YES completion:nil];
                       }
                   }];
        }
        else {
            
            ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
            
            NewNameViewController *newNameVC = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"NewName"];
            
            UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
            logoImage.hidden = true;
            logoImage.frame = CGRectMake(149, 2, 35, 35);
            
            [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
            [self.navigationController pushViewController:newNameVC animated:YES];
            
//            [authClient createUserWithEmail:self.emailField.text password:self.passwordField.text andCompletionBlock:^(NSError* error, FAUser* user) {
//                
//                if (error != nil) {
//                    
//                    [self.signInLabel setText:@"Something went wrong - try again."];
//                    
//                    NSLog(@"%@", error);
//                    
//                } else {
//                    
//                    [[ref childByAppendingPath:@"users"] updateChildValues:@{ user.uid :
//                                                                                  @{ @"email" : self.emailField.text}
//                                                                              }];
//                    
//                    [FirebaseHelper sharedHelper].uid = user.uid;
//                    
//                    [authClient loginWithEmail:self.emailField.text andPassword:self.passwordField.text
//                           withCompletionBlock:^(NSError* error, FAUser* user) {
//                               
//                        if (error != nil) {
//                                   
//                            [self.signInLabel setText:@"Something went wrong - try again."];
//                            NSLog(@"%@", error);
//                
//                        } else {
//                            
//                            [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"registered"];
//                            [FirebaseHelper sharedHelper].loggedIn = true;
//                            
//                            NewTeamViewController *newTeamVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NewTeam"];
//                            [self.navigationController pushViewController:newTeamVC animated:YES];
//                        }
//                    }];
//                }
//            }];
        }
        
    } else {
        
        [self.signInLabel setText:@"Invalid email - try again."];
        self.emailField.userInteractionEnabled = true;
        self.passwordField.userInteractionEnabled = true;
        self.emailField.alpha = 1;
        self.passwordField.alpha = 1;
    }
}

- (IBAction)switchTapped:(id)sender {

    _signingIn = !_signingIn;

    [self updateDetails];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{

    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

-(void)showLogo {
    
    UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
    
}

@end
