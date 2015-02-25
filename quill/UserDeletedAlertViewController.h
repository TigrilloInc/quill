//
//  UserDeletedAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 2/24/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface UserDeletedAlertViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *emailLabel;
@property (strong, nonatomic) IBOutlet RoundedButton *okButton;


@end
