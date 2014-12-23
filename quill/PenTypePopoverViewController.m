//
//  WidthPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 12/17/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "PenTypePopoverViewController.h"
#import "ProjectDetailViewController.h"
#import "BoardView.h"

@implementation PenTypePopoverViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *imageNames = @[ @"pen.png",
                             @"marker.png",
                             @"highlighter.png"
                            ];
    
    for (int i=0; i<3; i++) {
        
        UIButton *penButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *penImage = [UIImage imageNamed:imageNames[i]];
        [penButton setImage:penImage forState:UIControlStateNormal];
        penButton.frame = CGRectMake(0, 0, penImage.size.width, penImage.size.height);
        penButton.transform = CGAffineTransformMakeScale(.1, .1);
        penButton.center = CGPointMake(40, 43+i*80);
        [penButton addTarget:self action:@selector(widthTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:penButton];
        penButton.tag = i+1;
    }
    
    self.preferredContentSize = CGSizeMake(80, 250);
}

-(void)widthTapped:(id)sender {
    
    UIButton *penButton = (UIButton *)sender;
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSString *imageName = [NSString string];
    
    if (penButton.tag == 1) imageName = @"penselected.png";
    if (penButton.tag == 2) imageName = @"markerselected.png";
    if (penButton.tag == 3) imageName = @"highlighterselected.png";
    
    projectVC.currentBoardView.penType = penButton.tag;
    [(UIButton *)[projectVC.view viewWithTag:7] setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}


@end
