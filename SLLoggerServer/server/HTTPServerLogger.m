//
//  Created by shaolie on 2018/1/14.
//  Github: https://www.github.com/linshaolie
//  Copyright © 2018年 shaolie. All rights reserved.
//

#import "HTTPServerLogger.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#define DEFAULT_MAX_STACK 20

@interface HTTPServerLogger ()

@property (nonatomic, strong) GCDWebServer *server;

@property (nonatomic, strong) NSMutableArray *logs;
@end

@implementation HTTPServerLogger

+ (instancetype)share {
    static HTTPServerLogger *serverLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serverLogger = [[HTTPServerLogger alloc] init];
    });
    return serverLogger;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self config];
        _logs = [@[] mutableCopy];
        _maxStack = DEFAULT_MAX_STACK;
    }
    return self;
}

- (void)config {
    _server = [[GCDWebServer alloc] init];
    
    NSString* bundlePath = [[NSBundle mainBundle] pathForResource:@"webBundle" ofType:@"bundle"];
    if (bundlePath == nil) {
        return;
    }
    NSBundle* siteBundle = [NSBundle bundleWithPath:bundlePath];
    if (siteBundle == nil) {
        return;
    }
    // Resource files
    [_server addGETHandlerForBasePath:@"/" directoryPath:(NSString*)[siteBundle resourcePath] indexFilename:nil cacheAge:3600 allowRangeRequests:NO];
    
    __weak typeof(self) wSelf = self;
    [_server addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [wSelf rootResponse];
    }];
    
    [_server addHandlerForMethod:@"GET" path:@"/log" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [wSelf logResponse];
    }];
}

- (GCDWebServerResponse *)rootResponse {
//    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString* bundlePath = [[NSBundle mainBundle] pathForResource:@"webBundle" ofType:@"bundle"];
    if (bundlePath == nil) {
        return nil;
    }
    NSBundle* siteBundle = [NSBundle bundleWithPath:bundlePath];
    if (siteBundle == nil) {
        return nil;
    }
    
#if TARGET_OS_IPHONE
    NSString* device = [[UIDevice currentDevice] name];
#else
    NSString* device = CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL, NULL));
#endif
    NSString* title = nil;
    if (title == nil) {
        title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if (title == nil) {
            title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        }
#if !TARGET_OS_IPHONE
        if (title == nil) {
            title = [[NSProcessInfo processInfo] processName];
        }
#endif
    }
    NSString* header = nil;
    if (header == nil) {
        header = title;
    }
    NSString* prologue = nil;
    if (prologue == nil) {
        prologue = [siteBundle localizedStringForKey:@"PROLOGUE" value:@"" table:nil];
    }
    NSString* epilogue = nil;
    if (epilogue == nil) {
        epilogue = [siteBundle localizedStringForKey:@"EPILOGUE" value:@"" table:nil];
    }
    NSString* footer = nil;
    if (footer == nil) {
        NSString* name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#if !TARGET_OS_IPHONE
        if (!name && !version) {
            name = @"OS X";
            version = [[NSProcessInfo processInfo] operatingSystemVersionString];
        }
#endif
        footer = [NSString stringWithFormat:[siteBundle localizedStringForKey:@"FOOTER_FORMAT" value:@"" table:nil], name, version];
    }
    return [GCDWebServerDataResponse
            responseWithHTMLTemplate:[siteBundle pathForResource:@"index" ofType:@"html"]
            variables:@{
                        @"device" : device,
                        @"title" : title,
                        @"header" : header,
                        @"prologue" : prologue,
                        @"epilogue" : epilogue,
                        @"footer" : footer
                        }
            ];
}
     
- (GCDWebServerResponse *)logResponse {
    id obj = [self pop];
    if (obj) {
        if ([obj isKindOfClass:[NSArray class]]) {
            return [GCDWebServerDataResponse responseWithJSONObject:obj];
        } else {
            return [GCDWebServerDataResponse responseWithText:obj];
        }
    }
    return [GCDWebServerDataResponse responseWithText:@""];
}

- (BOOL)start {
    return [self startWithPort:8080];
}

- (BOOL)startWithPort:(NSUInteger)port {
    if (!_server) {
        [self config];
    }
    return [_server startWithPort:port bonjourName:nil];
}

- (void)stop {
    [_server stop];
    _server = nil;
}

- (void)log:(NSString *)content {
    [self push:content];
}

- (void)logA:(NSArray *)arr {
    [self push:arr];
}

- (void)push:(id)content {
    if (_logs.count >= self.maxStack) {
        [self pop];
    }
    [_logs addObject:content];
}

- (id)pop {
    id obj = _logs.firstObject;
    if (_logs.count > 0) {
        [_logs removeObjectAtIndex:0];
    }
    return obj;
}

#define Getter(type, name) -(type)name {return _server.name;}

Getter(NSUInteger, port)
Getter(NSURL *, serverURL)

@end
