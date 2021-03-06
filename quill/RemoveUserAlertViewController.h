//
//  RemoveUserAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface RemoveUserAlertViewController : UIViewController

@property (strong, nonatomic) NSString *userID;
@property (weak, nonatomic) IBOutlet RoundedButton *removeButton;
@property (weak, nonatomic) IBOutlet UILabel *removeLabel;
@property (weak, nonatomic) IBOutlet UILabel *warnLabel;

@end
