//
//  InviteEmail.m
//  quill
//
//  Created by Alex Costantini on 2/17/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "InviteEmail.h"
#import "FirebaseHelper.h"

@implementation InviteEmail

-(void) updateHTML {
    
    self.htmlBody = [NSString stringWithFormat:@" <table style='width:650px; padding:0px; margin:0px; border-spacing:0px;'> <tbody style='width:650px; padding:0px; margin:0px'> <tr style='height:100px; width:650px; padding:0px; margin:0px'> <td style='height:100px; width:325px; padding:0px; margin:0px'> </td> <td style='height:100px; width:100px;'> <img src='https://gallery.mailchimp.com/1451b8b5ecc83e2e1e58999dd/images/8c7e664d-8cf3-47c6-b479-6373737f6ef3.png' style='width:100px; height:100px;display:block'> </td> <td style='height:100px; width:325px; padding:0px; margin:0px'> </td> </tr> </tbody> </table> <table style='width:650px; padding:0px; margin:0px; border-spacing:0px;'> <tbody style='width:650px; padding:0px; margin:0px'> <tr style='height:60px; width:650px; padding:0px; margin:0px'> <td style='height:60px; width:650px; color: #606060; font-family: \"Helvetica\"; font-size: 30px; font-weight:600; text-align:center;'> Welcome to Quill! </td> </tr> </tbody> </table> <table style='width:650px; padding:0px; margin:0px; border-spacing:0px;'> <tbody style='width:650px; padding:0px; margin:0px'> <tr style='height:60px; width:650px; padding:0px; margin:0px'> <td style='height:60px; width:650px; color: #606060; font-family: \"Helvetica\"; font-size: 20px; font-weight:200; text-align:center;'> You've been invited by <span style='font-weight:600;'>%@</span> to join <span style='font-weight:600;'>%@</span>. </td> </tr> </tbody> </table> <table style='width:650px; padding:0px; margin:0px; border-spacing:0px;'> <tbody style='width:650px; padding:0px; margin:0px'> <tr style='height:60px; width:650px; padding:0px; margin:0px'> <td style='height:60px; width:650px; color: #606060; font-family: \"Helvetica\"; font-size: 17px; font-weight:200; text-align:center;'> To get started, copy and paste the following into any browser on your iPad: </td> </tr> </tbody> </table> <table style='width:650px; padding:0px; margin:0px; border-spacing:0px;'> <tbody style='width:650px; padding:0px; margin:0px'> <tr style='height:120px; width:650px; padding:0px; margin:0px'> <td style='height:120px; width:650px; color: #286075; font-family: \"Helvetica\"; font-size: 30px; font-weight:600; text-align:center;'> %@ </td> </tr> </tbody> </table> <table style='width:650px; padding:0px; margin:0px; border-spacing:0px;'> <tbody style='width:650px; padding:0px; margin:0px'> <tr style='height:120px; width:650px; padding:0px; margin:0px'> <td style='height:120px; width:650px; color: #606060; font-family: \"Helvetica\"; font-size: 16px; font-weight:200; text-align:center; line-height:22px;'> If you haven't received an invite to download the app yet and would like<br>to be a beta tester, please send us a note at <a href='mailto:hello@tigrillo.co' style='color: #286075; font-weight: 600;'>hello@tigrillo.co</a>. </td> </tr> </tbody> </table> ", [FirebaseHelper sharedHelper].userName, [FirebaseHelper sharedHelper].teamName, self.inviteURL];
    
}

@end
