//
//  DeleteProjectAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "DeleteProjectAlertViewController.h"

@interface DeleteProjectAlertViewController ()

@end

@implementation DeleteProjectAlertViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    
}


#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end
