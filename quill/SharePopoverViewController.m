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
    
    options = @[ @"email",
                 @"cameraroll"
                 ];
    
    self.preferredContentSize = CGSizeMake(240, 10+options.count*50);

    for (int i=0; i<options.count; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(5, 5+i*50, 230, 50);
        
        NSString *imageString = [NSString stringWithFormat:@"%@.png", options[i]];
        NSString *highlightedString = [NSString stringWithFormat:@"%@-highlighted.png", options[i]];
        [button setImage:[UIImage imageNamed:imageString] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:highlightedString] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        button.tag = i;
    }
}

-(void)buttonTapped:(id)sender {
    
    UIButton *button = (UIButton *)sender;
    
    ProjectDetailViewController *projectVC = [FirebaseHelper sharedHelper].projectVC;
    
    BoardView *boardView;
    
    if (projectVC.versioning) boardView = (BoardView *)projectVC.versionsCarousel.currentItemView;
    else boardView = (BoardView *)projectVC.carousel.currentItemView;
    
    [boardView viewWithTag:1].hidden = true;
    for (CommentButton *comment in boardView.commentButtons) comment.hidden = YES;
    UIGraphicsBeginImageContextWithOptions(boardView.bounds.size, YES, 0.0);
    [boardView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *boardImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    for (CommentButton *comment in boardView.commentButtons) comment.hidden = NO;
    [boardView viewWithTag:1].hidden = false;
    
    
    if (button.tag == 0) {
        
        [self dismissViewControllerAnimated:NO completion:nil];
        
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = projectVC;
        
        NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:boardView.boardID] objectForKey:@"name"];
        
        [mailVC setSubject: [NSString stringWithFormat:@"'%@' Shared from Quill", boardName]];
        
        NSString *projectName = [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"name"];
        
        NSString *bodyString = [NSString stringWithFormat:@"I've shared the board '<b>%@</b>' from the project '<b>%@</b>' with you.<br><br>If you'd like to view it in Quill, make sure you're a member of the team '<b>%@</b>'.", boardName, projectName, [FirebaseHelper sharedHelper].teamName];
        
        [mailVC setMessageBody:bodyString isHTML:YES];
        
        CGRect newRect = CGRectMake(0, 0, boardView.bounds.size.height, boardView.bounds.size.width);
        UIGraphicsBeginImageContextWithOptions(newRect.size, YES, 0.0);
        [[UIImage imageWithCGImage:boardImage.CGImage scale:1.0 orientation:UIImageOrientationRight] drawInRect:newRect];
        UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *imageData = UIImagePNGRepresentation(rotatedImage);
        
        [mailVC addAttachmentData:imageData mimeType:@"image/png" fileName:boardName];
        
        [projectVC presentViewController:mailVC animated:YES completion:nil];
    }
    
    if (button.tag == 1) {
        
        [button setImage:[UIImage imageNamed:@"camerarollsaved.png"] forState:UIControlStateNormal];
        button.enabled = NO;
        
        UIImage *rotatedImage = [UIImage imageWithCGImage:boardImage.CGImage scale:0 orientation:UIImageOrientationRight];
        
        UIImageWriteToSavedPhotosAlbum(rotatedImage, nil, nil, nil);
        
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:.8];
    }
}

-(void) dismiss {
    
    [self dismissViewControllerAnimated:NO completion:nil];
}



@end
