//
//  ColorPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 12/17/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "ColorPopoverViewController.h"
#import "ProjectDetailViewController.h"
#import "DrawView.h"

@interface ColorPopoverViewController ()

@end

@implementation ColorPopoverViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    NSArray *colors = @[ @"Black",
                         @"Blue",
                         @"Red",
                         @"Green",
                        ];
    
    for (int i=0; i<colors.count; i++) {
        
        UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeSystem];
        colorButton.frame = CGRectMake(0, i*40, 70, 40);
        [colorButton setTitle:colors[i] forState:UIControlStateNormal];
        [colorButton addTarget:self action:@selector(colorTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:colorButton];
        colorButton.tag = i+1;
    }
    
    self.preferredContentSize = CGSizeMake(70, colors.count*40);
}

-(void)colorTapped:(id)sender {
    
    UIButton *colorButton = (UIButton *)sender;
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.currentDrawView.lineColorNumber = @(colorButton.tag);
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
