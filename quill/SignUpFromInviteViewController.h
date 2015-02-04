//
//  SignUpFromInviteViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/21/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignUpFromInviteViewController : UIViewController


@property (strong, nonatomic) NSString *invitedBy;
@property (strong, nonatomic) NSString *teamName;
@property (strong, nonatomic) NSString *email;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *teamLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end
