//
//  DeleteProjectAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface DeleteProjectAlertViewController : UIViewController <UIGestureRecognizerDelegate> {
    
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property (weak, nonatomic) IBOutlet RoundedButton *deleteButton;
@property (weak, nonatomic) IBOutlet RoundedButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *projectLabel;


@end
