//
//  SharePopoverViewController.h
//  quill
//
//  Created by Alex Costantini on 5/20/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SharePopoverViewController : UIViewController <UINavigationControllerDelegate, MFMailComposeViewControllerDelegate> {
    
    NSArray *options;
}

@end
