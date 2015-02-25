//
//  SignUpFromInviteViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/21/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface SignUpFromInviteViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSString *invitedBy;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *teamLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet RoundedButton *nextButton;

@end
