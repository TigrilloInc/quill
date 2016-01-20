//
//  NameFromInviteViewController.m
//  quill
//
//  Created by Alex Costantini on 2/16/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "NameFromInviteViewController.h"
#import "FirebaseHelper.h"
#import "ProjectDetailViewController.h"
#import "Flurry.h"

@implementation NameFromInviteViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Your Name";
    [self.navigationItem setHidesBackButton:YES];
    
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

- (IBAction)doneTapped:(id)sender {

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
    
    NSMutableArray *nameArray = [NSMutableArray array];

    for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];
        [nameArray addObject:userName];
    }

    if ([nameArray containsObject:self.nameTextField.text]) {
        
        self.nameLabel.text = @"That name is already in use.";
        return;
    }
    
    [Flurry logEvent:@"New_User-Sign_up-Step_1-Username_Complete" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
    
    NSString *nameString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/info/name", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].uid];
    Firebase *nameRef = [[Firebase alloc] initWithUrl:nameString];
    [nameRef setValue:self.nameTextField.text];
    
    
    
    
    [FirebaseHelper sharedHelper].userName = self.nameTextField.text;
    [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.nameTextField.text forKey:@"name"];
    
    [[FirebaseHelper sharedHelper] observeLocalUser];
    
    [[FirebaseHelper sharedHelper].projectVC dismissViewControllerAnimated:YES completion:nil];
    
    
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [[@"user:114d991ae058bf09173cf01d74fa4b80-us9" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]];
    NSMutableURLRequest *newsletterRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://us9.api.mailchimp.com/3.0/lists/6c83cbdb47/members"]];
    [newsletterRequest setHTTPMethod:@"POST"];
    [newsletterRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
    [newsletterRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *newsletterDataDict = @{ @"email_address" : [FirebaseHelper sharedHelper].email,
                                          @"status"        : @"subscribed",
                                          @"merge_fields"  : @{ @"ISADMIN"        : @0,
                                                                @"USERNAME"       : [FirebaseHelper sharedHelper].userName,
                                                                @"TEAMNAME"       : [FirebaseHelper sharedHelper].teamName,
                                                                @"TEAMID"         : [FirebaseHelper sharedHelper].teamID
                                                                }
                                          };
    
    NSData *newsletterData = [NSJSONSerialization dataWithJSONObject:newsletterDataDict  options:0 error:nil];
    [newsletterRequest setHTTPBody:newsletterData];
    
    NSURLSession *newsletterSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *newsletterTask = [newsletterSession dataTaskWithRequest:newsletterRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
    [newsletterTask resume];

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
