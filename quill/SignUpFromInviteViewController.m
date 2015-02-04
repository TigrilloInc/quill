//
//  SignUpFromInviteViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/21/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "SignUpFromInviteViewController.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "FirebaseHelper.h"
#import "NameFromInviteViewController.h"

@interface SignUpFromInviteViewController ()

@end

@implementation SignUpFromInviteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIFont *regFont = [UIFont fontWithName:@"SourceSansPro-Light" size:16];
    UIFont *boldFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18];
    
    NSDictionary *regAttrs = [NSDictionary dictionaryWithObjectsAndKeys: regFont, NSFontAttributeName, nil];
    NSDictionary *boldAttrs = [NSDictionary dictionaryWithObjectsAndKeys: boldFont, NSFontAttributeName, nil];
    NSRange userRange = NSMakeRange(23,self.invitedBy.length);
    NSRange teamRange = NSMakeRange(32+self.invitedBy.length,self.teamName.length);
    
    NSString *teamString = [NSString stringWithFormat:@"You've been invited by %@ to join %@.", self.invitedBy, self.teamName];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:teamString attributes:regAttrs];
    [attrString setAttributes:boldAttrs range:userRange];
    [attrString setAttributes:boldAttrs range:teamRange];
    
    [self.teamLabel setAttributedText:attrString];
    [self.teamLabel sizeToFit];
    self.teamLabel.center = CGPointMake(self.statusLabel.center.x, self.teamLabel.center.y);
    
    self.emailField.text = self.email;
    self.passwordField.secureTextEntry = true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signUpTapped:(id)sender {
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:ref];
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if ([emailTest evaluateWithObject:self.emailField.text] == true && self.passwordField.text.length > 0) {
        
        [authClient createUserWithEmail:self.emailField.text password:self.passwordField.text andCompletionBlock:^(NSError* error, FAUser* user) {
            
            if (error != nil) {
                
                NSLog(@"%@", error);
                
            } else {
                
                [[ref childByAppendingPath:@"users"] updateChildValues:@{ user.uid :
                                                                              @{ @"team" : [FirebaseHelper sharedHelper].teamName }
                                                                          }];
                
                NSString *teamString = [NSString stringWithFormat:@"teams/%@/users/", [FirebaseHelper sharedHelper].teamName];
                [[ref childByAppendingPath:teamString] updateChildValues:@{ user.uid : @1 }];
                
                [authClient loginWithEmail:self.emailField.text andPassword:self.passwordField.text
                       withCompletionBlock:^(NSError* error, FAUser* user) {
                           
                       if (error != nil) {
                           
                           NSLog(@"%@", error);
                           
                       } else {
                                                      
                           [FirebaseHelper sharedHelper].uid = user.uid;
                           [[FirebaseHelper sharedHelper] observeLocalUser];
                           
                           NameFromInviteViewController *nameVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NameFromInvite"];
                           [self.navigationController pushViewController:nameVC animated:YES];
                       
                       }
                }];
            }
        }];
    }
}

@end
