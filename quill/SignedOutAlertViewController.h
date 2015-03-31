//
//  SignedOutAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 3/30/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface SignedOutAlertViewController : UIViewController


@property (strong, nonatomic) NSString *email;
@property (weak, nonatomic) IBOutlet UILabel *signedOutLabel;
@property (weak, nonatomic) IBOutlet RoundedButton *okButton;

@end
