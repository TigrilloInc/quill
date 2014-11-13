//
//  NewProjectViewController.h
//  chalk
//
//  Created by Alex Costantini on 7/8/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MasterViewController.h"
#import "ProjectDetailViewController.h"

@interface NewProjectViewController : UIViewController {

    UITapGestureRecognizer *outsideTapRecognizer;
    MasterViewController *masterVC;
    ProjectDetailViewController *projectVC;
}

@property (weak, nonatomic) IBOutlet UITextField *nameField;

@end
