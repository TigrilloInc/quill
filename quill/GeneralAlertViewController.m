//
//  GeneralAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 3/16/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "GeneralAlertViewController.h"

@implementation GeneralAlertViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.okButton.layer.borderWidth = 1;
    self.okButton.layer.cornerRadius = 10;
    self.okButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.type == 1) {
        
        self.navigationItem.title = @"Invalid Board Name";
        self.generalLabel.text = @"There is already a board with that name in this project.";
    }
    else if (self.type == 2) {
        
        self.navigationItem.title = @"Board Sent to Dropbox";
        
        UIFont *boardFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
        UIFont *labelFont = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
        NSDictionary *boardAttrs = [NSDictionary dictionaryWithObjectsAndKeys: boardFont, NSFontAttributeName, nil];
        NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys: labelFont, NSFontAttributeName, nil];
        
        NSString *boardString = [NSString stringWithFormat:@"An image of %@ has been uploaded to your Dropbox.", self.boardName];
        NSMutableAttributedString *boardAttrString = [[NSMutableAttributedString alloc] initWithString:boardString attributes:labelAttrs];
        [boardAttrString setAttributes:boardAttrs range:NSMakeRange(12,self.boardName.length)];
        [self.generalLabel setAttributedText:boardAttrString];
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
