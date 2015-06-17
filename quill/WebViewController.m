//
//  WebViewController.m
//  quill
//
//  Created by Alex Costantini on 6/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "WebViewController.h"
#import "ProjectDetailViewController.h"
#import "SlackViewController.h"

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://slack.com/oauth/authorize?client_id=2420812446.6437258849"]]];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    
    NSString *url = webView.request.URL.absoluteString;

    NSRange range = [url rangeOfString:@"code="];
    
    if (range.location != NSNotFound) {

        [self dismissViewControllerAnimated:YES completion:nil];
        
        ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
        SlackViewController *slackVC = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"Slack"];
        slackVC.code = [url substringWithRange:NSMakeRange(range.location+5, 32)];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:slackVC];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
        logoImageView.frame = CGRectMake(175, 8, 32, 32);
        logoImageView.tag = 800;
        [nav.navigationBar addSubview:logoImageView];
        
        [projectVC presentViewController:nav animated:YES completion:nil];
        
    }
}

@end
