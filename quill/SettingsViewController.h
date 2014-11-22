//
//  SettingsViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/16/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"

@interface SettingsViewController : UIViewController <UIGestureRecognizerDelegate> {
    
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property (strong, nonatomic) NSMutableArray *avatars;
@property int selectedAvatar;

@end
