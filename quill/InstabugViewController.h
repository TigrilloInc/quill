//
//  InstabugViewController.h
//  quill
//
//  Created by Alex Costantini on 3/4/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface InstabugViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet RoundedButton *bugButton;
@property (weak, nonatomic) IBOutlet RoundedButton *featureButton;

@end
