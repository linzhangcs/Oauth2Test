//
//  MailClient.m
//  OAuth2ClientTest
//
//  Created by Jeremy Barger on 2/13/15.
//  Copyright (c) 2015 Lin Zhang. All rights reserved.
//

#import "MailClient.h"
#import <MailCore/MailCore.h>

@implementation MailClient

- (void)sendSubscriptionNotice {
    
    MCOSMTPSession *session = [[MCOSMTPSession alloc] init];
    
    session.hostname = @"smtp.gmail.com";
    session.username = @"jeremyjusticebarger@gmail.com";
    session.password = @"$h1n3y@ndr3w0livi@";
    session.port = 465;
    session.connectionType = MCOConnectionTypeTLS;
    
    MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
    
    [[builder header] setFrom:[MCOAddress addressWithDisplayName:nil mailbox:session.username]];
    

    NSArray *to = @[[MCOAddress addressWithMailbox:@"jeremyjusticebarger@gmail.com"]];
    
    
    /*
    for (NSString __strong *toAddress in _recipients) {
        
        toAddress = @"jeremyjusticebarger@gmail.com";
        MCOAddress *newAddress = [MCOAddress addressWithMailbox:toAddress];
        [to addObject:newAddress];
        
    }
    */
     
    [[builder header] setTo:to];
    
    [[builder header] setSubject:@"Subcription Notice"];
    [builder setHTMLBody:@"You have a new subscriber!"];
    
    
    NSData *rfc822Data = [builder data];
    
    MCOSMTPSendOperation *sendOperation = [session sendOperationWithData:rfc822Data];
    
    [sendOperation start:^(NSError *error) {
       
        if (error) {
            
            NSLog(@"error %@", error);
            
        } else {
            
            NSLog(@"message sent!");
            
        }
            
            
        
    }];
    
}


@end
