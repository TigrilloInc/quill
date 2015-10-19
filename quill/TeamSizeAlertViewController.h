//
//  TeamSizeAlertViewController.h
//  quill
//
//  Created by Alex Costantini on 7/20/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface TeamSizeAlertViewController : UIViewController {
    
    UIImageView *logoImage;
}

@property (weak, nonatomic) IBOutlet RoundedButton *contactButton;
@end
