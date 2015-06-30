//
//  DeleteProjectAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface DeleteProjectAlertViewController : UIViewController

@property (weak, nonatomic) IBOutlet RoundedButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *projectLabel;


@end
