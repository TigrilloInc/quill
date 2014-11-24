//
//  AvatarPopoverViewController.h
//  quill
//
//  Created by Alex Costantini on 11/23/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AvatarPopoverViewController : UIViewController

@property (strong, nonatomic) NSString *userID;

-(void)updateMenu;

@end
