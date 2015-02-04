//
//  NewTeamViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/7/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewTeamViewController : UIViewController <UITextFieldDelegate> {
    
    UIImageView *logoImage;
}

@property (weak, nonatomic) IBOutlet UITextField *teamField;
@property (weak, nonatomic) IBOutlet UIButton *createTeamButton;

@end
