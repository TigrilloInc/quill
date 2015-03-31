//
//  LeaveProjectAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"
#import "RoundedButton.h"

@interface LeaveProjectAlertViewController : UIViewController <UIGestureRecognizerDelegate> {
    
    ProjectDetailViewController *projectVC;
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property BOOL deleteProject;
@property (weak, nonatomic) IBOutlet UILabel *projectLabel;
@property (weak, nonatomic) IBOutlet UILabel *leaveLabel;
@property (weak, nonatomic) IBOutlet RoundedButton *leaveButton;

@end
