//
//  ShareHelper.h
//  quill
//
//  Created by Alex Costantini on 6/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>
#import "GTLDrive.h"

@interface ShareHelper : NSObject <DBRestClientDelegate>

@property (strong, nonatomic) NSString *slackToken;
@property (strong, nonatomic) NSMutableArray *slackChannels;
@property (strong, nonatomic) DBRestClient *dropboxClient;
@property (strong, nonatomic) GTLServiceDrive *driveService;

+ (ShareHelper *)sharedHelper;

@end
