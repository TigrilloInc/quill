//
//  GeneralAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 3/16/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "GeneralAlertViewController.h"
#import "ProjectDetailViewController.h"

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
    else if (self.type > 1 && self.type < 3) {
        
        UIFont *boardFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
        UIFont *labelFont = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
        NSDictionary *boardAttrs = [NSDictionary dictionaryWithObjectsAndKeys: boardFont, NSFontAttributeName, nil];
        NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys: labelFont, NSFontAttributeName, nil];
        
        NSString *boardString;
        
        if (self.type == 2) {
            self.navigationItem.title = @"Board Sent to Dropbox";
            boardString = [NSString stringWithFormat:@"An image of %@ has been uploaded to your Dropbox.", self.boardName];
        }
        else {
            self.navigationItem.title = @"Board Sent to Google Drive";
            boardString = [NSString stringWithFormat:@"An image of %@ has been uploaded to Google Drive.", self.boardName];
        }
        
        NSMutableAttributedString *boardAttrString = [[NSMutableAttributedString alloc] initWithString:boardString attributes:labelAttrs];
        [boardAttrString setAttributes:boardAttrs range:NSMakeRange(12,self.boardName.length)];
        [self.generalLabel setAttributedText:boardAttrString];
    }
}

-(void) viewDidAppear:(BOOL)animated {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.handleOutsideTaps = true;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.handleOutsideTaps = false;
}

- (IBAction)okTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
