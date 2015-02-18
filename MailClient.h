//
//  MailClient.h
//  OAuth2ClientTest
//
//  Created by Jeremy Barger on 2/13/15.
//  Copyright (c) 2015 Lin Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MailClient : NSObject

@property (nonatomic) NSMutableArray *recipients;

- (void)sendSubscriptionNotice;


@end
