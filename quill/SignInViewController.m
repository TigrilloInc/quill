//
//  SignInViewController.m
//  chalk
//
//  Created by Alex Costantini on 7/7/14.
//  Copyright (c) 2014 chalk. All rights reserved.
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
    
    self.emailField.placeholder = @"email";
    self.passwordField.placeholder = @"password";
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
    
    if ([emailTest evaluateWithObject:self.emailField.text] == true && self.passwordField.text.length > 0) {
    
        if (_signingIn == true) {

            [authClient loginWithEmail:self.emailField.text andPassword:self.passwordField.text
                   withCompletionBlock:^(NSError* error, FAUser* user) {
                       
                       if (error != nil) {
                           
                           [self.signInLabel setText:@"Hmm, shit's jacked up."];
                           NSLog(@"%@", error);
                           
                       } else {
                           
                           [FirebaseHelper sharedHelper].uid = user.uid;
                           
                           [self dismissViewControllerAnimated:YES completion:nil];
                           
                           [[FirebaseHelper sharedHelper] observeLocalUser];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
