//
//  InvalidNameAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 3/16/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "InvalidNameAlertViewController.h"

@implementation InvalidNameAlertViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.okButton.layer.borderWidth = 1;
    self.okButton.layer.cornerRadius = 10;
    self.okButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.project) {
        
        self.navigationItem.title = @"Invalid Project Name";
        self.invalidLabel.text = @"Project names cannot be blank.";
    }
    else {
        
        self.navigationItem.title = @"Invalid Board Name";
        self.invalidLabel.text = @"There is already a board with that name in this project.";
    }
}

-(void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [outsideTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)) [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)okTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
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
