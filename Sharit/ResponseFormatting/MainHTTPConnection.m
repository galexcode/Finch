//
//  SharesHTTPConnection.m
//  Sharit
//
//  Created by Eugene Dorfman on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPRedirectResponse.h"

#import "SharesProvider.h"
#import "ClipboardShare.h"
#import "Global.h"
#import "HTTPMessage.h"
#import "AppDelegate.h"
#import "Helper.h"
#import "GlobalDefaults.h"
#import "ImageShare.h"
#import "TextShare.h"
#import "BasicTemplateLoader.h"
#import "MacroPreprocessor.h"
#import "ALAssetShare.h"
#import "HTTPAsyncAssetResponse.h"

@interface MainHTTPConnection ()
@property (nonatomic,strong) NSArray* indexPaths;
@property (nonatomic,strong) NSString* redirectPath;
@property (nonatomic,strong) MacroPreprocessor* indexPreprocessor;
@end

@implementation MainHTTPConnection
@synthesize indexPaths;
@synthesize redirectPath;
@synthesize indexPreprocessor;

- (id) initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
    if ((self = [super initWithAsyncSocket:newSocket configuration:aConfig])) {
        NSArray* paths = [NSArray arrayWithObjects:@"/",@"/index.html",@"/text.html",@"/pictures.html", nil];
        self.indexPaths =  paths;
        [self initIndexPreprocessor];
    }
    return self;
}

- (void) initIndexPreprocessor {
    BasicTemplateLoader* basicLoader = [[BasicTemplateLoader alloc] initWithFolder:[[Helper instance] templatesFolder] templateExt:templateExt];
    self.indexPreprocessor = [[MacroPreprocessor alloc] initWithLoader:basicLoader templateName:@"index"];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    if ([method isEqualToString:@"GET"]) {
        return YES;
    } else if ([method isEqualToString:@"POST"]) {
        return requestContentLength < 65535;
    }
	return [super supportsMethod:method atPath:path];
}

- (void)processBodyData:(NSData *)postDataChunk {
	[request appendData:postDataChunk];
}

- (HTTPDataResponse*) indexResponse:(NSString*)path {
    Share* share = [[SharesProvider instance] shareForPath:path andParams:nil];

    NSMutableDictionary* macroDict = [share macrosDict];
    [macroDict setObject:path forKey:kRedirectPath];

    [self.indexPreprocessor setMacroDict:macroDict];
    NSString* responseString = [self.indexPreprocessor process];

    NSData* response = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    return [[HTTPDataResponse alloc] initWithData:response];
}

- (void) processRequestData:(NSString*)path {
    NSData* postData = [request body];
    NSDictionary* dict = [self parseParams:[[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]];

    Share* share = [[SharesProvider instance] shareForPath:path andParams:dict];
    if (share.isShared) {
        [share processRequestData:dict];
    }

    self.redirectPath = [dict objectForKey:kRedirectPath];
    dispatch_async(dispatch_get_main_queue(), ^() {
        AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate sharesRefreshed];
    });
}

- (HTTPRedirectResponse*) redirectResponse:(NSString*)redirectURI {
    HTTPRedirectResponse* response = [[HTTPRedirectResponse alloc] initWithPath:redirectURI];
    return response;
}

- (BOOL) isIndexPath:(NSString*)path {
    BOOL res = [self.indexPaths containsObject:path];
    return res;
}

- (NSObject<HTTPResponse>*) imageResponseForShare:(ImageShare*)share atPath:(NSString*)path {
    NSDictionary* params = [self parseGetParams];
    ALAssetShare* assetShare = [share isKindOfClass:[ALAssetShare class]] ? (ALAssetShare*) share : nil;
    NSData* imageData = [share dataForSizeParam:[params objectForKey:@"size"]];
    NSObject<HTTPResponse>* response = nil;
    if (assetShare && assetShare.isVideo && nil==imageData) {
        response = [[HTTPAsyncAssetResponse alloc] initWithAssetRepresentation:assetShare.defaultRepresentation forConnection:self andContentType:@"video/mp4"];
    } else {
        response = [[HTTPDataResponse alloc] initWithData:imageData];
    }
    return response;
}

- (NSString*) removeParams:(NSString*)path {
    NSArray* components = [path componentsSeparatedByString:@"?"];
    NSString* newPath = path;
    if ([components count]>0) {
        newPath = [components objectAtIndex:0];
    }
    return newPath;
}

- (NSObject<HTTPResponse>*) responseForShareAtPath:(NSString*)path {
    SharesProvider* provider = [SharesProvider instance];
    NSDictionary* params = [self parseGetParams];
    NSString* noParamsPath = [self removeParams:path];
    Share* share = [provider shareForPath:noParamsPath andParams:params];
    NSObject<HTTPResponse> * response = nil;
    if ([share isKindOfClass:[ImageShare class]]) {
        response = [self imageResponseForShare:(ImageShare*)share atPath:path];
    }
    return response;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    if ([method isEqualToString:@"POST"]) {
        [self processRequestData:path];
        NSString* redirect = [self.redirectPath length]? self.redirectPath : @"/index.html";
        self.redirectPath = nil;
        return [self redirectResponse:redirect];
    } else if ([method isEqualToString:@"GET"]) {
        if ([self isIndexPath:path]) {
            return [self indexResponse:path];
        } else {
            NSObject<HTTPResponse>* response = [self responseForShareAtPath:path];
            if (nil!=response) {
                return response;
            }
        }
    }

    return [super httpResponseForMethod:method URI:path];
}

@end