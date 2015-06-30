//
//  ChangePasswordViewController.h
//  quill
//
//  Created by Alex Costantini on 2/4/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface ChangePasswordViewController : UIViewController <UITextFieldDelegate> {
    
    UIImageView *logoImage;
    NSArray *textFieldArray;
}

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmTextField;
@property (weak, nonatomic) IBOutlet UITextField *currentTextField;
@property (weak, nonatomic) IBOutlet RoundedButton *applyButton;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;

@end
