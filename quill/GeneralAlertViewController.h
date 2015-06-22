//
//  GeneralAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 3/16/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface GeneralAlertViewController : UIViewController <UIGestureRecognizerDelegate> {
    
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property int type;
@property (strong, nonatomic) NSString *boardName;
@property (weak, nonatomic) IBOutlet UILabel *generalLabel;
@property (weak, nonatomic) IBOutlet RoundedButton *okButton;

@end
