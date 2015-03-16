//
//  PersonalSettingsViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/16/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"
#import "RoundedButton.h"

@interface PersonalSettingsViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate> {
    
    UIImageView *logoImage;
    UITapGestureRecognizer *outsideTapRecognizer;
    NSMutableArray *teamNames;
    NSMutableArray *teamEmails;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet RoundedButton *passwordButton;
@property (weak, nonatomic) IBOutlet RoundedButton *applyButton;
@property (strong, nonatomic) AvatarButton *avatarButton;
@property (weak, nonatomic) IBOutlet UILabel *settingsLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end
