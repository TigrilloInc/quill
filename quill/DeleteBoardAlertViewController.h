//
//  DeleteBoardAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 5/18/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"
#import "ProjectDetailViewController.h"

@interface DeleteBoardAlertViewController : UIViewController <UIGestureRecognizerDelegate> {
    
    UITapGestureRecognizer *outsideTapRecognizer;
    ProjectDetailViewController *projectVC;
}

@property (weak, nonatomic) IBOutlet RoundedButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *boardLabel;

@end
