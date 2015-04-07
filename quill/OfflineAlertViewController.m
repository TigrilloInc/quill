//
//  OfflineAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 3/31/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "OfflineAlertViewController.h"

@interface OfflineAlertViewController ()

@end

@implementation OfflineAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Lost Connection";
    
    self.offlineLabel.text = @"Your internet connection has been lost.\n\nPlease reconnect your device to continue.";
}

@end
