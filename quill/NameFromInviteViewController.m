//
//  NameFromInviteViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/22/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "NameFromInviteViewController.h"
#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"

@interface NameFromInviteViewController ()

@end

@implementation NameFromInviteViewController

- (IBAction)doneTapped:(id)sender {

    NSString *name = self.nameField.text;
    
    if (name.length > 0) {
     
        NSString *nameString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@", [FirebaseHelper sharedHelper].uid];
        
        Firebase *ref = [[Firebase alloc] initWithUrl:nameString];
        
        [ref updateChildValues:@{ @"name" : name,
                                  @"team" : [FirebaseHelper sharedHelper].teamName }];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
