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
    
    self.htmlBody = [NSString stringWithFormat:@"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'> <html xmlns='http://www.w3.org/1999/xhtml'> <head> <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'> <meta name='viewport' content='width=device-width, initial-scale=1.0'> <title>Welcome to Quill!</title> <style type='text/css'> @import url(http://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,600); body,#bodyTable,#bodyCell{ height:100% !important; margin:0; padding:0; width:100% !important; } table{ border-collapse:collapse; } img,a img{ border:0; outline:none; text-decoration:none; } h1,h2,h3,h4,h5,h6{ margin:0; padding:0; } p{ margin:1em 0; padding:0; } a{ word-wrap:break-word; } .ReadMsgBody{ width:100%; } .ExternalClass{ width:100%; } .ExternalClass,.ExternalClass p,.ExternalClass span,.ExternalClass font,.ExternalClass td,.ExternalClass div{ line-height:100%; } table,td{ mso-table-lspace:0pt; mso-table-rspace:0pt; } #outlook a{ padding:0; } img{ -ms-interpolation-mode:bicubic; } body,table,td,p,a,li,blockquote{ -ms-text-size-adjust:100%; -webkit-text-size-adjust:100%; } #bodyCell{ padding:20px; } .mcnImage{ vertical-align:bottom; } .mcnTextContent img{ height:auto !important; } body,#bodyTable{ background-color:#F2F2F2; } #bodyCell{ border-top:0; } #templateContainer{ border:0; } h1{ color:#606060 !important; display:block; font-family:'Source Sans Pro', sans-serif; font-size:35px; font-style:normal; font-weight:bold; line-height:125%; margin:0; text-align:center; } h2{ color:#404040 !important; display:block; font-family:'Source Sans Pro', sans-serif; font-size:26px; font-style:normal; font-weight:bold; line-height:125%; letter-spacing:-.75px; margin:0; text-align:left; } h3{ color:#606060 !important; display:block; font-family:'Source Sans Pro', sans-serif; font-size:18px; font-style:normal; font-weight:bold; line-height:125%; letter-spacing:-.5px; margin:0; text-align:left; } h4{ color:#808080 !important; display:block; font-family:'Source Sans Pro', sans-serif; font-size:16px; font-style:normal; font-weight:bold; line-height:125%; letter-spacing:normal; margin:0; text-align:left; } #templatePreheader{ background-color:#FFFFFF; border-top:0; border-bottom:0; } .preheaderContainer .mcnTextContent,.preheaderContainer .mcnTextContent p{ color:#606060; font-family:'Source Sans Pro', sans-serif; font-size:11px; line-height:125%; text-align:left; } .preheaderContainer .mcnTextContent a{ color:#606060; font-weight:normal; text-decoration:underline; } #templateHeader{ background-color:#FFFFFF; border-top:0; border-bottom:0; } .headerContainer .mcnTextContent,.headerContainer .mcnTextContent p{ color:#606060; font-family:'Source Sans Pro', sans-serif; font-size:15px; line-height:150%; text-align:left; } .headerContainer .mcnTextContent a{ color:#6DC6DD; font-weight:normal; text-decoration:underline; } #templateBody{ background-color:#FFFFFF; border-top:0; border-bottom:0; } .bodyContainer .mcnTextContent,.bodyContainer .mcnTextContent p{ color:#606060; font-family:'Source Sans Pro', sans-serif; font-size:15px; line-height:150%; text-align:left; } .bodyContainer .mcnTextContent a{ color:#6DC6DD; font-weight:normal; text-decoration:underline; } #templateFooter{ background-color:#FFFFFF; border-top:0; border-bottom:0; } .footerContainer .mcnTextContent,.footerContainer .mcnTextContent p{ color:#606060; font-family:'Source Sans Pro', sans-serif; font-size:11px; line-height:125%; text-align:left; } .footerContainer .mcnTextContent a{ color:#606060; font-weight:normal; text-decoration:underline; } @media only screen and (max-width: 480px){ body,table,td,p,a,li,blockquote{ -webkit-text-size-adjust:none !important; } } @media only screen and (max-width: 480px){ body{ width:100% !important; min-width:100% !important; } } @media only screen and (max-width: 480px){ td[id=bodyCell]{ padding:10px !important; } } @media only screen and (max-width: 480px){ table[class=mcnTextContentContainer]{ width:100% !important; } } @media only screen and (max-width: 480px){ table[class=mcnBoxedTextContentContainer]{ width:100% !important; } } @media only screen and (max-width: 480px){ table[class=mcpreview-image-uploader]{ width:100% !important; display:none !important; } } @media only screen and (max-width: 480px){ img[class=mcnImage]{ width:30% !important; } } @media only screen and (max-width: 480px){ table[class=mcnImageGroupContentContainer]{ width:100% !important; } } @media only screen and (max-width: 480px){ td[class=mcnImageGroupContent]{ padding:9px !important; } } @media only screen and (max-width: 480px){ td[class=mcnImageGroupBlockInner]{ padding-bottom:0 !important; padding-top:0 !important; } } @media only screen and (max-width: 480px){ tbody[class=mcnImageGroupBlockOuter]{ padding-bottom:9px !important; padding-top:9px !important; } } @media only screen and (max-width: 480px){ table[class=mcnCaptionTopContent],table[class=mcnCaptionBottomContent]{ width:100% !important; } } @media only screen and (max-width: 480px){ table[class=mcnCaptionLeftTextContentContainer],table[class=mcnCaptionRightTextContentContainer],table[class=mcnCaptionLeftImageContentContainer],table[class=mcnCaptionRightImageContentContainer],table[class=mcnImageCardLeftTextContentContainer],table[class=mcnImageCardRightTextContentContainer]{ width:100% !important; } } @media only screen and (max-width: 480px){ td[class=mcnImageCardLeftImageContent],td[class=mcnImageCardRightImageContent]{ padding-right:18px !important; padding-left:18px !important; padding-bottom:0 !important; } } @media only screen and (max-width: 480px){ td[class=mcnImageCardBottomImageContent]{ padding-bottom:9px !important; } } @media only screen and (max-width: 480px){ td[class=mcnImageCardTopImageContent]{ padding-top:18px !important; } } @media only screen and (max-width: 480px){ td[class=mcnImageCardLeftImageContent],td[class=mcnImageCardRightImageContent]{ padding-right:18px !important; padding-left:18px !important; padding-bottom:0 !important; } } @media only screen and (max-width: 480px){ td[class=mcnImageCardBottomImageContent]{ padding-bottom:9px !important; } } @media only screen and (max-width: 480px){ td[class=mcnImageCardTopImageContent]{ padding-top:18px !important; } } @media only screen and (max-width: 480px){ table[class=mcnCaptionLeftContentOuter] td[class=mcnTextContent],table[class=mcnCaptionRightContentOuter] td[class=mcnTextContent]{ padding-top:9px !important; } } @media only screen and (max-width: 480px){ td[class=mcnCaptionBlockInner] table[class=mcnCaptionTopContent]:last-child td[class=mcnTextContent]{ padding-top:18px !important; } } @media only screen and (max-width: 480px){ td[class=mcnBoxedTextContentColumn]{ padding-left:18px !important; padding-right:18px !important; } } @media only screen and (max-width: 480px){ td[class=mcnTextContent]{ padding-right:18px !important; padding-left:18px !important; } } @media only screen and (max-width: 480px){ table[id=templateContainer],table[id=templatePreheader],table[id=templateHeader],table[id=templateBody],table[id=templateFooter]{ max-width:600px !important; width:100% !important; } } @media only screen and (max-width: 480px){ h1{ font-size:24px !important; line-height:125% !important; } } @media only screen and (max-width: 480px){ h2{ font-size:20px !important; line-height:125% !important; } } @media only screen and (max-width: 480px){ h3{ font-size:18px !important; line-height:125% !important; } } @media only screen and (max-width: 480px){ h4{ font-size:16px !important; line-height:125% !important; } } @media only screen and (max-width: 480px){ table[class=mcnBoxedTextContentContainer] td[class=mcnTextContent],td[class=mcnBoxedTextContentContainer] td[class=mcnTextContent] p{ font-size:18px !important; line-height:125% !important; } } @media only screen and (max-width: 480px){ table[id=templatePreheader]{ display:block !important; } } @media only screen and (max-width: 480px){ td[class=preheaderContainer] td[class=mcnTextContent],td[class=preheaderContainer] td[class=mcnTextContent] p{ font-size:14px !important; line-height:115% !important; } } @media only screen and (max-width: 480px){ td[class=headerContainer] td[class=mcnTextContent],td[class=headerContainer] td[class=mcnTextContent] p{ font-size:18px !important; line-height:125% !important; } } @media only screen and (max-width: 480px){ td[class=bodyContainer] td[class=mcnTextContent],td[class=bodyContainer] td[class=mcnTextContent] p{ font-size:18px !important; line-height:125% !important; } } @media only screen and (max-width: 480px){ td[class=footerContainer] td[class=mcnTextContent],td[class=footerContainer] td[class=mcnTextContent] p{ font-size:14px !important; line-height:115% !important; } } @media only screen and (max-width: 480px){ td[class=footerContainer] a[class=utilityLink]{ display:block !important; } }</style></head> <body leftmargin='0' marginwidth='0' topmargin='0' marginheight='0' offset='0'> <center> <table align='center' border='0' cellpadding='0' cellspacing='0' height='100%' width='100%' id='bodyTable'> <tr> <td align='center' valign='top' id='bodyCell'> <table border='0' cellpadding='0' cellspacing='0' width='600' id='templateContainer'> <tr> <td align='center' valign='top'> <table border='0' cellpadding='0' cellspacing='0' width='600' id='templatePreheader'> <tr> <td valign='top' class='preheaderContainer' style='padding-top:9px;'></td> </tr> </table> </td> </tr> <tr> <td align='center' valign='top'> <table border='0' cellpadding='0' cellspacing='0' width='600' id='templateHeader'> <tr> <td valign='top' class='headerContainer'></td> </tr> </table> </td> </tr> <tr> <td align='center' valign='top'> <table border='0' cellpadding='0' cellspacing='0' width='600' id='templateBody'> <tr> <td valign='top' class='bodyContainer'><table border='0' cellpadding='0' cellspacing='0' width='100%' class='mcnImageBlock'> <tbody class='mcnImageBlockOuter'> <tr> <td valign='top' style='padding:9px' class='mcnImageBlockInner'> <table align='left' width='100%' border='0' cellpadding='0' cellspacing='0' class='mcnImageContentContainer'> <tbody><tr> <td class='mcnImageContent' valign='top' style='padding-right: 9px; padding-left: 9px; padding-top: 0; padding-bottom: 0; text-align:center;'> <img align='center' alt='' src='https://gallery.mailchimp.com/1451b8b5ecc83e2e1e58999dd/images/8c7e664d-8cf3-47c6-b479-6373737f6ef3.png' width='100' style='max-width:256px; padding-bottom: 0; display: inline !important; vertical-align: bottom;' class='mcnImage'> </td> </tr> </tbody></table> </td> </tr> </tbody> </table><table border='0' cellpadding='0' cellspacing='0' width='100%' class='mcnTextBlock'> <tbody class='mcnTextBlockOuter'> <tr> <td valign='top' class='mcnTextBlockInner'> <table align='left' border='0' cellpadding='0' cellspacing='0' width='600' class='mcnTextContentContainer'> <tbody><tr> <td valign='top' class='mcnTextContent' style='padding-top:9px; padding-right: 18px; padding-left: 18px;'> <h1><span style='line-height:1.2em'>Welcome to Quill!</span></h1> <h1><font size='3'>You've been invited by %@ to join %@.</font></h1> <p style='font-weight:200;'>Quill will let you collaborate with your team in a whole new way! Let's get you started...</p> <ol> <li>Download the latest version of the Quill app.</li> <a href='%@'> <table border='0' cellpadding='0' cellspacing='0' width='100%' class='mcnButtonBlock'> <tbody class='mcnButtonBlockOuter'> <tr> <td style='padding-top:20px; padding-right:58px; padding-bottom:30px; padding-left:18px;' valign='top' align='left' class='mcnButtonBlockInner'> <table border='0' cellpadding='0' cellspacing='0' width='100%' class='mcnButtonContentContainer' style='border-collapse: separate !important;border: 2px solid #707070;border-top-left-radius: 5px;border-top-right-radius: 5px;border-bottom-right-radius: 5px;border-bottom-left-radius: 5px;background-color: #909090;'> <tbody> <tr> <td align='center' valign='middle' class='mcnButtonContent' style='font-size: 20px; padding: 16px;'> <a class='mcnButton ' title='Download Quill' href='%@' target='_blank' style='font-weight: bold;letter-spacing: normal;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;'>Download Quill</a> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </a> <li>Verify your account in Quill.</li> <a href='%@'> <table border='0' cellpadding='0' cellspacing='0' width='100%' class='mcnButtonBlock'> <tbody class='mcnButtonBlockOuter'> <tr> <td style='padding-top:20px; padding-right:58px; padding-bottom:30px; padding-left:18px;' valign='top' align='left' class='mcnButtonBlockInner'> <table border='0' cellpadding='0' cellspacing='0' width='100%' class='mcnButtonContentContainer' style='border-collapse: separate !important;border: 2px solid #707070;border-top-left-radius: 5px;border-top-right-radius: 5px;border-bottom-right-radius: 5px;border-bottom-left-radius: 5px;background-color: #909090;'> <tbody> <tr> <td align='center' valign='middle' class='mcnButtonContent' style='font-size: 20px; padding: 16px;'> <a class='mcnButton ' title='Open Quill' href='%@' target='_blank' style='font-weight: bold;letter-spacing: normal;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;'>Verify Account</a> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </a> </ol> <p style='font-weight:200;'>Have any questions or feedback? Please feel free to contact us at <a href='mailto:hello@tigrillo.co?subject=Quill%20Question' target='_blank'>hello@tigrillo.co</a>.</p> </td> </tr> </tbody></table> </td> </tr> </tbody> </table></td> </tr> </table> </td> </tr> <tr> <td align='center' valign='top'> <table border='0' cellpadding='0' cellspacing='0' width='600' id='templateFooter'> <tr> <td valign='top' class='footerContainer' style='padding-bottom:9px;'></td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </center> </body> </html>", [FirebaseHelper sharedHelper].userName, [[FirebaseHelper sharedHelper].team objectForKey:@"name"], self.inviteURL, self.inviteURL, self.inviteURL, self.inviteURL];
    
}

@end
