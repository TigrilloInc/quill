//
//  ShareHelper.m
//  quill
//
//  Created by Alex Costantini on 6/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "ShareHelper.h"
#import "GTMOAuth2ViewControllerTouch.h"

@implementation ShareHelper

static ShareHelper *sharedHelper = nil;

+ (ShareHelper *) sharedHelper {
    
    if (!sharedHelper) {
        
        sharedHelper = [[ShareHelper alloc] init];
        sharedHelper.slackToken = nil;
        sharedHelper.slackChannels = [NSMutableArray array];
        sharedHelper.dropboxClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        sharedHelper.dropboxClient.delegate = sharedHelper;
        sharedHelper.driveService = [[GTLServiceDrive alloc] init];
        sharedHelper.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:nil clientID:@"326374351015-tqisrbuiesr90tgg0t0jfe30dd1g3l2a.apps.googleusercontent.com" clientSecret:@"DP8uFrMI1ahrh50QDyxgqQ8W"];
                                        
    }
    
    return sharedHelper;
}



@end
