//
//  WidthPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 12/17/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "WidthPopoverViewController.h"
#import "ProjectDetailViewController.h"
#import "BoardView.h"

@interface WidthPopoverViewController ()

@end

@implementation WidthPopoverViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    for (int i=0; i<3; i++) {
        
        UIButton *lineButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *lineImage = [UIImage imageNamed:[NSString stringWithFormat:@"line%i.png",i+1]];
        [lineButton setImage:lineImage forState:UIControlStateNormal];
        lineButton.frame = CGRectMake(0, 0, lineImage.size.width, lineImage.size.height);
        lineButton.transform = CGAffineTransformMakeScale(.1, .1);
        lineButton.center = CGPointMake(35, 35+i*60);
        [lineButton addTarget:self action:@selector(widthTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:lineButton];
        lineButton.tag = i+1;
    }
    
    self.preferredContentSize = CGSizeMake(70, 190);
}

-(void)widthTapped:(id)sender {
    
    UIButton *widthButton = (UIButton *)sender;
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    float lineWidth = 0.0;
    NSString *imageName = [NSString string];
    
    if (widthButton.tag == 1) {
        lineWidth = 2.0f;
        imageName = @"width.png";
    }
    if (widthButton.tag == 2) {
        lineWidth = 6.0f;
        imageName = @"width2.png";
    }
    if (widthButton.tag == 3) {
        lineWidth = 12.0f;
        imageName = @"width3.png";
    }
    
    projectVC.currentBoardView.lineWidth = lineWidth;
    [(UIButton *)[projectVC.view viewWithTag:7] setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}


@end
