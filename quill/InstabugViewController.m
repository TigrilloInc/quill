//
//  InstabugViewController.m
//  quill
//
//  Created by Alex Costantini on 3/4/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "InstabugViewController.h"
#import <Instabug/Instabug.h>

@implementation InstabugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Feedback";
    
    self.bugButton.layer.borderWidth = 1;
    self.bugButton.layer.cornerRadius = 10;
    self.bugButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.featureButton.layer.borderWidth = 1;
    self.featureButton.layer.cornerRadius = 10;
    self.featureButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void) viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    outsideTapRecognizer.delegate = nil;
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

- (IBAction)reportBugTapped:(id)sender {

    [self dismissViewControllerAnimated:YES completion:^{
        
        [Instabug invokeBugReporter];
    }];
}

- (IBAction)suggestFeatureTapped:(id)sender {

    [self dismissViewControllerAnimated:YES completion:^{
        
        [Instabug invokeFeedbackSender];
    }];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)){
            
            [outsideTapRecognizer setDelegate:nil];
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

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
