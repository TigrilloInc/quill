//
//  OneSignalHelper.m
//  quill
//
//  Created by Alex Costantini on 3/1/16.
//  Copyright © 2016 chalk. All rights reserved.
//

#import "OneSignalHelper.h"

@implementation OneSignalHelper

static OneSignalHelper *sharedHelper = nil;

+ (OneSignalHelper *) sharedHelper {
    
    if (!sharedHelper) {
        
        sharedHelper = [[OneSignalHelper alloc] init];
    }
    return sharedHelper;
}

+(void) sendPush:(NSMutableDictionary *)pushDict {

    [pushDict setObject:@"4cf29860-40b3-43fc-9a48-2a7c55a6dd3b" forKey:@"app_id"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:pushDict  options:0 error:nil];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://onesignal.com/api/v1/notifications"]];
    [request setValue:@"Basic ZWIzZDA4YmUtNGNjZi00YzBhLTk2MTgtOTkwYTIzMDU0ZDJl" forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSLog(@"data from push is %@", [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]);
    }];
    [task resume];
}

@end
