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
#import "NewTeamViewController.h"


@implementation SignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.passwordField.secureTextEntry = true;
    
    self.emailField.delegate = self;
    self.passwordField.delegate = self;
    self.passwordResetButton.hidden = true;
    
    _signingIn = false;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.emailField || textField == self.passwordField) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (IBAction)signInTapped:(id)sender {
    
    [self.emailField setUserInteractionEnabled:false];
    [self.passwordField setUserInteractionEnabled:false];
    
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
                           
                           [self.signInLabel setText:@"Hmm, shit's jacked up."];
                           NSLog(@"%@", error);
                           
                       } else {
                           
                           [FirebaseHelper sharedHelper].loggedIn = true;
                           [FirebaseHelper sharedHelper].uid = user.uid;
                           [[FirebaseHelper sharedHelper] observeLocalUser];
                           
                           [self dismissViewControllerAnimated:YES completion:nil];
                       }
                   }];
        
        } else {
            
            [authClient createUserWithEmail:self.emailField.text password:self.passwordField.text andCompletionBlock:^(NSError* error, FAUser* user) {
                
                if (error != nil) {
                    
                    [self.signInLabel setText:@"Hmm, shit's jacked up."];
                    NSLog(@"%@", error);
                    
                } else {
                    
                    [[ref childByAppendingPath:@"users"] updateChildValues:@{ user.uid : @0 }];
                    
                    [FirebaseHelper sharedHelper].uid = user.uid;
                    
                    [authClient loginWithEmail:self.emailField.text andPassword:self.passwordField.text
                           withCompletionBlock:^(NSError* error, FAUser* user) {
                               
                        if (error != nil) {
                                   
                            [self.signInLabel setText:@"Hmm, shit's jacked up."];
                            NSLog(@"%@", error);
                
                        } else {
                            
                            [FirebaseHelper sharedHelper].loggedIn = true;
                            
                            NewTeamViewController *newTeamVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NewTeam"];
                            [self.navigationController pushViewController:newTeamVC animated:YES];
                        }
                    }];
                }
            }];
        }
        
    } else {
        
        [self.signInLabel setText:@"But, like, actually enter them."];
    }
}

- (IBAction)switchTapped:(id)sender {

    if (_signingIn) {
        
        [self.switchButton setTitle:@"Already Registered?" forState:UIControlStateNormal];

        [self.signInButton setTitle:@"SIGN UP" forState:UIControlStateNormal];
        
        [self.signInLabel setText:@"Pick an email and password, yo."];
        
        self.passwordResetButton.hidden = true;
        
        _signingIn = false;
    
    } else {
        
        [self.switchButton setTitle:@"New User?" forState:UIControlStateNormal];
        
        [self.signInButton setTitle:@"SIGN IN" forState:UIControlStateNormal];
        
        [self.signInLabel setText:@"Sign in with your email, yo."];
        
        self.passwordResetButton.hidden = false;
        
        _signingIn = true;
        
    }
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{

    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

@end
