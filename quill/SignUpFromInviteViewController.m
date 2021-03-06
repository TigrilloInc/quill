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
#import "ProjectDetailViewController.h"
#import "SignInViewController.h"
#import "NSDate+ServerDate.h"
#import "NSString+MD5.h"
#import "Flurry.h"

@implementation SignUpFromInviteViewController

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
    
    self.nextButton.layer.borderWidth = 1;
    self.nextButton.layer.cornerRadius = 10;
    self.nextButton.layer.borderColor = [UIColor grayColor].CGColor;
    self.emailField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.emailField.layer.borderWidth = 1;
    self.emailField.layer.cornerRadius = 10;
    self.passwordField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.passwordField.layer.borderWidth = 1;
    self.passwordField.layer.cornerRadius = 10;
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    UIFont *regFont = [UIFont fontWithName:@"SourceSansPro-Light" size:16];
    UIFont *boldFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:18];
    
    NSDictionary *regAttrs = [NSDictionary dictionaryWithObjectsAndKeys: regFont, NSFontAttributeName, nil];
    NSDictionary *boldAttrs = [NSDictionary dictionaryWithObjectsAndKeys: boldFont, NSFontAttributeName, nil];
    NSRange userRange = NSMakeRange(23,self.invitedBy.length);
    NSRange teamRange = NSMakeRange(32+self.invitedBy.length,[FirebaseHelper sharedHelper].teamName.length);
    
    NSString *teamString = [NSString stringWithFormat:@"You've been invited by %@ to join %@.", self.invitedBy, [FirebaseHelper sharedHelper].teamName];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:teamString attributes:regAttrs];
    [attrString setAttributes:boldAttrs range:userRange];
    [attrString setAttributes:boldAttrs range:teamRange];

    [self.teamLabel setAttributedText:attrString];
    
    self.emailField.text = [FirebaseHelper sharedHelper].email;
}

- (IBAction)signUpTapped:(id)sender {
    
    if (self.emailField.text.length == 0 && self.passwordField.text.length == 0) {
        [self.statusLabel setText:@"Please enter an email and password."];
        return;
    };
    if (self.emailField.text.length == 0) {
        [self.statusLabel setText:@"Please enter an email."];
        return;
    }
    if (self.passwordField.text.length == 0) {
        [self.statusLabel setText:@"Please enter a password."];
        return;
    }
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if ([emailTest evaluateWithObject:self.emailField.text] != true) {
        
        [self.statusLabel setText:@"Invalid email - try again."];
        return;
    }
    
    self.statusLabel.text = @"Creating user account...";
    
    self.nextButton.userInteractionEnabled = false;
    self.nextButton.alpha = .5;
    self.passwordField.userInteractionEnabled = false;
    self.passwordField.alpha = .5;
    self.emailField.userInteractionEnabled = false;
    self.emailField.alpha = .5;

    NSString *oldEmail = [FirebaseHelper sharedHelper].email;
    [FirebaseHelper sharedHelper].email = self.emailField.text;
    [[FirebaseHelper sharedHelper] setRoles];
    
    NSString *refString = [NSString stringWithFormat:@"https://%@.firebaseio.com/", [FirebaseHelper sharedHelper].db];
    Firebase *ref = [[Firebase alloc] initWithUrl:refString];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:ref];

    [authClient createUserWithEmail:self.emailField.text password:self.passwordField.text andCompletionBlock:^(NSError* error, FAUser* user) {
        
        if (error) {
            
            if (error.code == -9999) [self.statusLabel setText:@"That email is already in use."];
            else [self.statusLabel setText:@"Something went wrong - try again."];
            
            self.emailField.userInteractionEnabled = true;
            self.passwordField.userInteractionEnabled = true;
            self.emailField.alpha = 1;
            self.passwordField.alpha = 1;
            self.nextButton.userInteractionEnabled = true;
            self.nextButton.alpha = 1;
        }
        else {
        
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [[@"user:114d991ae058bf09173cf01d74fa4b80-us9" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]];
            NSString *urlString = [NSString stringWithFormat:@"https://us9.api.mailchimp.com/3.0/lists/9b9f0bf220/members/%@", [[oldEmail lowercaseString] MD5]];
            
            NSMutableURLRequest *removeRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
            [removeRequest setHTTPMethod:@"DELETE"];
            [removeRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            [removeRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            NSURLSessionDataTask *removeTask = [session dataTaskWithRequest:removeRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
            }];
            [removeTask resume];
            
            [FirebaseHelper sharedHelper].uid = user.uid;
            [FirebaseHelper sharedHelper].email = user.email;
            
            NSString *userString = [NSString stringWithFormat:@"users/%@/info", user.uid];
            
            [[ref childByAppendingPath:userString] updateChildValues: @{ @"team"    : [FirebaseHelper sharedHelper].teamID,
                                                                         @"email"   : [FirebaseHelper sharedHelper].email
                                                                        }];
            
            if ([FirebaseHelper sharedHelper].invitedProject != nil) {
                
                NSString *projectID = [FirebaseHelper sharedHelper].invitedProject.allKeys[0];
                NSString *boardsString = [NSString stringWithFormat:@"projects/%@/info/boards", projectID];
                NSString *rolesString = [NSString stringWithFormat:@"projects/%@/info/roles/%@", projectID, user.uid];
                
                NSNumber *roleNum = [[FirebaseHelper sharedHelper].invitedProject objectForKey:projectID];
                [[ref childByAppendingPath:rolesString] setValue:roleNum];
                
                NSString *roleString;

                if (roleNum.integerValue == 0) roleString = @"viewer";
                else roleString = @"collaborator";

                NSDictionary *flurryDict = @{ @"role"       : roleString,
                                              @"projectID"  : projectID,
                                              @"teamID"     : [FirebaseHelper sharedHelper].teamID
                                              };

                [Flurry logEvent:@"User_Added" withParameters:flurryDict];
                
                [[ref childByAppendingPath:boardsString] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                    
                    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
                    
                    for (NSString *boardID in snapshot.value) {
                        
                        NSString *subpathsString = [NSString stringWithFormat:@"boards/%@/subpaths", boardID];
                        NSString *undoString = [NSString stringWithFormat:@"boards/%@/undo", boardID];
                        
                        NSDictionary *subpathDict = @{ [FirebaseHelper sharedHelper].uid :
                                                           @{ dateString : @"penUp" }
                                                       };
                        NSDictionary *undoDict = @{ [FirebaseHelper sharedHelper].uid :
                                                        @{ @"currentIndex" : @0,
                                                           @"currentIndexDate" : dateString,
                                                           @"total" : @0
                                                           }
                                                    };
                        
                        [[ref childByAppendingPath:subpathsString] updateChildValues:subpathDict];
                        [[ref childByAppendingPath:undoString] updateChildValues:undoDict];
                    }
                }];
            }
            
            NSString *teamString = [NSString stringWithFormat:@"teams/%@/users/", [FirebaseHelper sharedHelper].teamID];
            [[ref childByAppendingPath:teamString] updateChildValues:@{ user.uid : @0 }];
            
            [authClient loginWithEmail:self.emailField.text andPassword:self.passwordField.text
                   withCompletionBlock:^(NSError* error, FAUser* user) {
                       
                   if (error != nil) {
                       
                       NSLog(@"%@", error);
                       
                   } else {
                       
                       [Flurry logEvent:@"New_User-Sign_up-Step_0-Email_Complete" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
                       
                       NameFromInviteViewController *nameVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NameFromInvite"];
                       [self.navigationController pushViewController:nameVC animated:YES];
                       
                       [FirebaseHelper sharedHelper].loggedIn = true;
                       
                       UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
                       logoImage.hidden = true;
                       logoImage.frame = CGRectMake(188, 8, 32, 32);
                       
                       [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
                   }
            }];
            

        }
    }];
}

- (IBAction)switchTapped:(id)sender {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    [projectVC dismissViewControllerAnimated:YES completion:^{
        
        SignInViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
        logoImageView.frame = CGRectMake(155, 8, 32, 32);
        logoImageView.tag = 800;
        [nav.navigationBar addSubview:logoImageView];
        
        [projectVC presentViewController:nav animated:YES completion:nil];
    }];
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
