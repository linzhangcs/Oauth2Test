//
//  ViewController.m
//  OAuth2ClientTest
//
//  Created by Lin Zhang on 2/3/15.
//  Copyright (c) 2015 Lin Zhang. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"

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
    //https://www.googleapis.com/youtube/v3/subscriptions

    //performMethod:@"GET" onResource:[NSURL URLWithString:@"https://www.googleapis.com/youtube/v3/subscriptions/?part=snippet&mine=true"]
    
    [NXOAuth2Request performMethod:@"GET" onResource:[NSURL URLWithString:@"https://www.googleapis.com/youtube/v3/subscriptions/?part=snippet&mine=true"] usingParameters: nil withAccount: accounts[0] sendProgressHandler:^(unsigned long long bytesSend, unsigned long long bytesTotal) {
        //progress
    }responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
        if(responseData){
            NSError *error;
            //NSDictionary *channels
            NSDictionary *info = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"Subscription info: %@", info);
        }
        if(error){
            NSLog(@"ERROR: %@", error.localizedDescription);
        }
    }];
}
@end
