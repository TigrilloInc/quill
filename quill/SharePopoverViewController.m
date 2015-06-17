//
//  SharePopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 5/20/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "SharePopoverViewController.h"
#import "FirebaseHelper.h"
#import "WebViewController.h"
#import "ShareHelper.h"
#import "SlackViewController.h"

@implementation SharePopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    options = @[ @"slack",
                 @"email",
                 @"cameraroll",
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
    
    
    if (button.tag == 2) {
        
        UIImage *boardImage = [boardView generateImage:NO];
        
        [button setImage:[UIImage imageNamed:@"camerarollsaved.png"] forState:UIControlStateNormal];
        button.enabled = NO;
        
        UIImage *rotatedImage = [UIImage imageWithCGImage:boardImage.CGImage scale:0 orientation:UIImageOrientationRight];
        
        UIImageWriteToSavedPhotosAlbum(rotatedImage, nil, nil, nil);
        
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:.8];
    }
    
    else if (button.tag == 1) {
        
        UIImage *boardImage = [boardView generateImage:YES];
        
        [self dismissViewControllerAnimated:NO completion:nil];
        
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = projectVC;
        
        NSString *boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:projectVC.boardIDs[projectVC.carousel.currentItemIndex]] objectForKey:@"name"];
        
        NSString *projectName = [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"name"];
        
        NSString *bodyString;
        
        if (projectVC.versioning) {
            
            NSUInteger versionNum = projectVC.versionsCarousel.currentItemIndex+1;
            [mailVC setSubject: [NSString stringWithFormat:@"Version %lu of '%@' shared from Quill", versionNum, boardName]];
            bodyString = [NSString stringWithFormat:@"I've attached an image of Version %lu of the board <b>%@</b> from the project <b>%@</b>.<br><br>If you'd like to view it in Quill, make sure you're a member of the team <b>%@</b>.", versionNum, boardName, projectName, [FirebaseHelper sharedHelper].teamName];
        }
        else {
            
            [mailVC setSubject: [NSString stringWithFormat:@"'%@' shared from Quill", boardName]];
            bodyString = [NSString stringWithFormat:@"I've attached an image of the board <b>%@</b> from the project <b>%@</b>.<br><br>If you'd like to view it in Quill, make sure you're a member of the team <b>%@</b>.", boardName, projectName, [FirebaseHelper sharedHelper].teamName];
        }
        
        [mailVC setMessageBody:bodyString isHTML:YES];
        
        NSData *imageData = UIImagePNGRepresentation(boardImage);
        
        [mailVC addAttachmentData:imageData mimeType:@"image/png" fileName:boardName];
        
        [projectVC presentViewController:mailVC animated:YES completion:nil];
    }
    
    else if (button.tag == 0) {
        
        [self dismissViewControllerAnimated:NO completion:nil];
        
        if ([ShareHelper sharedHelper].slackToken) {
            
            SlackViewController *slackVC = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"Slack"];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:slackVC];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            
            UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
            logoImageView.frame = CGRectMake(175, 8, 32, 32);
            logoImageView.tag = 800;
            [nav.navigationBar addSubview:logoImageView];
            
            [projectVC presentViewController:nav animated:YES completion:nil];
        }
        else {
            
            WebViewController *webVC = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"Web"];
            [projectVC presentViewController:webVC animated:YES completion:^{
                
                projectVC.showButtons = true;
                [projectVC.carousel reloadData];
            }];
        }
    }
}

-(void) dismiss {
    
    [self dismissViewControllerAnimated:NO completion:nil];
}



@end
