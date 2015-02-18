//
//  MailClient.swift
//  OAuth2ClientTest
//
//  Created by Jeremy Barger on 2/13/15.
//  Copyright (c) 2015 Lin Zhang. All rights reserved.
//

import Foundation

class MailClient: NSObject {
    
    
    func smtpSession(hostname: String, password: String, username: String, port: UInt32, connectionType: MCOConnectionType) -> Void {
        
        var session = MCOSMTPSession()
        let builder = MCOMessageBuilder()
        
        builder.header.from.displayName = nil
        builder.header.from.mailbox = username
        
        
        session.hostname = hostname
        session.port = port
        session.username = username
        session.password = password
        session.connectionType = MCOConnectionType.TLS
    }
    
    
}