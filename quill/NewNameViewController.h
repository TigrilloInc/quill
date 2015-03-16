//
//  NewNameViewController.h
//  quill
//
//  Created by Alex Costantini on 1/30/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface NewNameViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet RoundedButton *nameButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
