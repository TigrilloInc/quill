//
//  NewProjectViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/8/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MasterViewController.h"
#import "ProjectDetailViewController.h"
#import "RoundedButton.h"

@interface NewProjectViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate> {

    BOOL projectDone;
    BOOL teamDone;
    BOOL boardDone;
    BOOL chatDone;
    BOOL keyboardShowing;
    
    UITapGestureRecognizer *outsideTapRecognizer;
    ProjectDetailViewController *projectVC;
}

@property (weak, nonatomic) IBOutlet RoundedButton *createButton;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UILabel *projectLabel;

@end
