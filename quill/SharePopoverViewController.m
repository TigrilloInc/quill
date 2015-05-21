//
//  SharePopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 5/20/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "SharePopoverViewController.h"
#import "FirebaseHelper.h"


@implementation SharePopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    options = @[ @"Email",
                 @"Save to Camera Roll"
                 ];
    
    self.preferredContentSize = CGSizeMake(200, 18+options.count*45);

    for (int i=0; i<options.count; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 12+i*45, 50, 50);
        [button setTitle:options[i] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:18];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button sizeToFit];
        button.center = CGPointMake(self.preferredContentSize.width/2, button.center.y);
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        button.tag = i;
    }
}

-(void)buttonTapped:(id)sender {
    
    UIButton *button = (UIButton *)sender;
    
    ProjectDetailViewController *projectVC = [FirebaseHelper sharedHelper].projectVC;
    
    if (button.tag == 0) {
        
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    
    if (button.tag == 1) {
        
        [button setTitle:@"Saved to Camera Roll!" forState:UIControlStateNormal];
        [button sizeToFit];
        button.center = CGPointMake(self.view.center.x, button.center.y);
        button.alpha = .5;
        button.enabled = NO;
        
        BoardView *boardView;
        
        if (projectVC.versioning) boardView = (BoardView *)projectVC.versionsCarousel.currentItemView;
        else boardView = (BoardView *)projectVC.carousel.currentItemView;
        
        UIGraphicsBeginImageContextWithOptions(boardView.bounds.size, YES, 0.0);
        [boardView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *boardImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        UIImage *rotatedImage = [UIImage imageWithCGImage:boardImage.CGImage scale:0 orientation:UIImageOrientationRight];
        
        UIImageWriteToSavedPhotosAlbum(rotatedImage, nil, nil, nil);
        
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:.8];
    }
}

-(void) dismiss {
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
