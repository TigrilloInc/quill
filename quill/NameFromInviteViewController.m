//
//  NameFromInviteViewController.m
//  quill
//
//  Created by Alex Costantini on 2/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "NameFromInviteViewController.h"
#import "FirebaseHelper.h"
#import "ProjectDetailViewController.h"

@interface NameFromInviteViewController ()

@end

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

    if (self.nameTextField.text.length > 0) {
        
        NSString *nameString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/name/", [FirebaseHelper sharedHelper].uid];
        Firebase *nameRef = [[Firebase alloc] initWithUrl:nameString];
        [nameRef setValue:self.nameTextField.text];
        
        [FirebaseHelper sharedHelper].userName = self.nameTextField.text;
        [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.nameTextField.text forKey:@"name"];
        
        [[FirebaseHelper sharedHelper] observeLocalUser];
        
        [[FirebaseHelper sharedHelper].projectVC dismissViewControllerAnimated:YES completion:nil];
    }
}


@end
