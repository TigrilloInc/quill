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
#import <DropboxSDK/DropboxSDK.h>
#import "GTMOAuth2ViewControllerTouch.h"
#import "GeneralAlertViewController.h"

@implementation SharePopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    options = @[ @"drive",
                 @"dropbox",
                 @"slack",
                 @"email",
                 @"cameraroll",
                 ];
    
    self.preferredContentSize = CGSizeMake(254, 10+options.count*50);

    for (int i=0; i<options.count; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(5, 5+i*50, 243, 50);
        
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
    
    
    if (button.tag == 4) {
        
        UIImage *boardImage = [boardView generateImage];
        
        [button setImage:[UIImage imageNamed:@"camerarollsaved.png"] forState:UIControlStateNormal];
        button.enabled = NO;

        UIImageWriteToSavedPhotosAlbum(boardImage, nil, nil, nil);
        
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:.8];
    }
    
    else if (button.tag == 3) {
        
        UIImage *boardImage = [boardView generateImage];
        
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
    
    else if (button.tag == 2) {
        
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
            webVC.modalPresentationStyle = UIModalPresentationPageSheet;
            
            [projectVC presentViewController:webVC animated:YES completion:^{
                projectVC.handleOutsideTaps = true;
                projectVC.showButtons = true;
            }];
        }
    }
    else if (button.tag == 1) {

        if (![[DBSession sharedSession] isLinked]) {
            
            [self dismissViewControllerAnimated:YES completion:nil];
            projectVC.handleOutsideTaps = true;
            [[DBSession sharedSession] linkFromController:projectVC];
        }
        else {
            
            [button setImage:[UIImage imageNamed:@"dropboxsaved.png"] forState:UIControlStateNormal];
            button.enabled = NO;
            
            UIImage *boardImage = [boardView generateImage];
            NSData *imageData = UIImagePNGRepresentation(boardImage);
            NSString *filename = [NSString stringWithFormat:@"%@.png", projectVC.boardNameLabel.text];
            NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            NSString *localPath = [localDir stringByAppendingPathComponent:filename];
            [imageData writeToFile:localPath atomically:YES];
            
            [[ShareHelper sharedHelper].dropboxClient uploadFile:filename toPath:@"/Quill" withParentRev:nil fromPath:localPath];
            
            [self performSelector:@selector(dismiss) withObject:nil afterDelay:.8];
        }
    }
    else if (button.tag == 0) {
        
        if ([[ShareHelper sharedHelper].driveService.authorizer canAuthorize]) {
            
            [self uploadToDrive];
            
            [button setImage:[UIImage imageNamed:@"drivesaved.png"] forState:UIControlStateNormal];
            button.enabled = NO;

            [self performSelector:@selector(dismiss) withObject:nil afterDelay:.8];
        }
        else {
            
            projectVC.handleOutsideTaps = true;
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            GTMOAuth2ViewControllerTouch *authController = [GTMOAuth2ViewControllerTouch controllerWithScope:@"https://www.googleapis.com/auth/drive" clientID:@"326374351015-kqguhqk7m5cgvcc1bj3hbu9se42r130h.apps.googleusercontent.com" clientSecret:@"dSEKG_KwpILXAxHYAppVbj3e" keychainItemName:nil delegate:self finishedSelector:@selector(viewController:finishedWithAuth:error:)];
            authController.modalPresentationStyle = UIModalPresentationPageSheet;
            
            [projectVC presentViewController:authController animated:YES completion:nil];
        }
    }
}

-(void) uploadToDrive {
 
    ProjectDetailViewController *projectVC = [FirebaseHelper sharedHelper].projectVC;
    
    BoardView *boardView;
    
    if (projectVC.versioning) boardView = (BoardView *)projectVC.versionsCarousel.currentItemView;
    else boardView = (BoardView *)projectVC.carousel.currentItemView;
    
    GTLDriveFile *metadata = [GTLDriveFile object];
    metadata.title = projectVC.boardNameLabel.text;;
    metadata.mimeType = @"image/png";
    
    UIImage *boardImage = [boardView generateImage];
    
    NSData *imageData = UIImagePNGRepresentation(boardImage);
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:imageData MIMEType:@"image/png"];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:metadata
                                                       uploadParameters:uploadParameters];
    [[ShareHelper sharedHelper].driveService executeQuery:query completionHandler:nil];
}

-(void) dismiss {
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    
    ProjectDetailViewController *projectVC = [FirebaseHelper sharedHelper].projectVC;
    
    GeneralAlertViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"Alert"];
    vc.type = 3;
    vc.boardName = projectVC.boardNameLabel.text;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    if (error != nil) {
        logoImageView.frame = CGRectMake(120, 8, 32, 32);
        vc.navigationItem.title = @"Google Drive Error";
        vc.generalLabel.text = error.localizedDescription;
        [ShareHelper sharedHelper].driveService.authorizer = nil;
    }
    else {
        logoImageView.frame = CGRectMake(112, 8, 32, 32);
        vc.type = 3;
        [ShareHelper sharedHelper].driveService.authorizer = authResult;
        [self uploadToDrive];
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    [projectVC presentViewController:nav animated:YES completion:nil];
}

@end
