//
//  ViewController.m
//  OAuth2ClientTest
//
//  Created by Lin Zhang on 2/3/15.
//  Copyright (c) 2015 Lin Zhang. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"
#import "MailClient.h"

@interface ViewController ()

@end

@implementation ViewController

static NSString * const KIDOAuth2ClientId = @"631436021920-hiqlsrjktg8p9j15qmqbkimic2vpve7r.apps.googleusercontent.com";
static NSString * const KIDOAuth2ClientSecret = @"oHRJEgQnopjQEOdVnK3e0UHj";
static NSString * const KIDOAuth2ClientRedirectURI = @"urn:ietf:wg:oauth:2.0:oob";
static NSString * const KIDOAuth2AuthorizationURL = @"https://accounts.google.com/o/oauth2/auth";
static NSString * const KIDOAuth2TokenURL = @"https://accounts.google.com/o/oauth2/token";
static NSString * const KIDOAuth2Scope = @"https://www.googleapis.com/auth/youtube";
static NSString * const KIDOAuth2AccountType = @"Youtube API";
static NSString * const KIDOAuth2success = @"Success";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.loginWebView.delegate = self;
    [self setupOAuth2AccountStore];
    [self requestOAuth2Access];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - OAuth2 Logic
-(void)setupOAuth2AccountStore{
    [[NXOAuth2AccountStore sharedStore] setClientID:KIDOAuth2ClientId secret:KIDOAuth2ClientSecret scope:[NSSet setWithObject:KIDOAuth2Scope]authorizationURL:[NSURL URLWithString:KIDOAuth2AuthorizationURL] tokenURL:[NSURL URLWithString:KIDOAuth2TokenURL] redirectURL:[NSURL URLWithString:KIDOAuth2ClientRedirectURI] keyChainGroup:@"zdtv" forAccountType:KIDOAuth2AccountType];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *note) {
        if (note.userInfo) {
            //account added, we have access and can rqurest protected data
            NSLog(@"Success! We have an access token.");
            [self requestOAuth2ProtectedDetails];
        }
        else{
            //account removed, we lost access
            NSLog(@"Access lost");
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *note) {
        NSError *error = [note.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
        NSLog(@"Error!!! %@", error.localizedDescription);
    }];
}

- (void)requestOAuth2Access{
    //embeded browser - UIWebView
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:KIDOAuth2AccountType withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        [self.loginWebView loadRequest:[NSURLRequest requestWithURL:preparedURL]];
    }] ;
}

#pragma mark - UIWebBiewDelegate methods

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    if([webView.request.URL.absoluteString rangeOfString:KIDOAuth2AuthorizationURL options:NSCaseInsensitiveSearch].location != NSNotFound){
        self.loginWebView.hidden = NO;
    }
    else{
        self.loginWebView.hidden = YES;
        //read the title from the webview
        NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        NSLog(@"title is %@", pageTitle);
        [self handleOAuth2AccessResult:pageTitle];
    }
}

-(void)handleOAuth2AccessResult: (NSString *)accessResult{
    BOOL success = [accessResult rangeOfString:KIDOAuth2success options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    if(success){
        NSString *arg = accessResult;
        if([arg hasPrefix:KIDOAuth2success]){
            arg = [arg substringFromIndex:KIDOAuth2success.length+1];
        }
        
        NSString *redirectURL = [NSString stringWithFormat:@"%@?%@", KIDOAuth2ClientRedirectURI, arg];
        
        [[NXOAuth2AccountStore sharedStore] handleRedirectURL:[NSURL URLWithString: redirectURL]];
        NSLog(@"RedirectURL: %@", redirectURL);
    }
    else{
        [self requestOAuth2Access];
    }
}

-(void)requestOAuth2ProtectedDetails{
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:KIDOAuth2AccountType];
    
    //performMethod:@"GET" onResource:[NSURL URLWithString:@"https://www.googleapis.com/youtube/v3/subscriptions/?part=snippet&mine=true"]
    //performMethod:@"GET" onResource:[NSURL URLWithString:@"https://www.googleapis.com/youtube/v3/subscriptions/?part=snippet&mine=true"
    //https://github.com/nxtbgthng/OAuth2Client/issues/88
    

    //\"snippet\":{\"resourceId\":{\"channelId\":\"UCqnbDFdCpuN8CMEg0VuEBqA\"
    
    
    
    
    NSData * KIDOAuth2RequestBody = [@"{\"snippet\":{\"resourceId\":{\"kind\":\"youtube#subscription\", \"channelId\":\"UCqnbDFdCpuN8CMEg0VuEBqA\"}}}" dataUsingEncoding:NSUTF8StringEncoding];
    
    // using Jeremy's channel id
    
    //NSData *KIDOAuth2RequestBody = [@"{\"snippet\":{\"resourceId\":{\"kind\":\"youtube#subscription\", \"channelId\":\"UCrqpZkeSMTEmL4NQnq0xC3g\"}}}" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:KIDOAuth2RequestBody options:0 error:nil];
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];

    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:[NSURL URLWithString:@"https://www.googleapis.com/youtube/v3/subscriptions/?part=snippet"] method:@"POST" parameters:nil];
    request.account = accounts[0];
    
    NSMutableURLRequest *urlRequest = [[request signedURLRequest] mutableCopy];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:bodyData];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    [[session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
       
        NSLog(@"request: %@", urlRequest);
        
        if (response) {
            
            NSError *error;
            NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"data: %@", info);
            
            MailClient *mailclient = [[MailClient alloc] init];
            
            [mailclient sendSubscriptionNotice];
            
           
            
            
        }
        
        if (error) {
            
            NSLog(@"ERROR: %@", error.localizedDescription);
            
        }
        
    }]resume];
    
    NSLog(@"After request");
    
    
    
    
    /*
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:nil completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSLog(@"request: %@", urlRequest);
        if(response){
            NSError *error;
            //NSDictionary *channels
            NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"data: %@", info);
        }
        if(connectionError){
            NSLog(@"ERROR: %@", connectionError.localizedDescription);
        }
        NSLog(@"completion block");
    }];
    */
    
    
    NSLog(@"After request");

}
@end
