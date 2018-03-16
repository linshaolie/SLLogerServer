//
//  Created by shaolie on 2018/1/14.
//  Github: https://www.github.com/linshaolie
//  Copyright © 2018年 shaolie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTPServerLogger : NSObject

@property(nonatomic, readonly) NSUInteger port;
@property(nonatomic, readonly) NSURL *serverURL;

/// 栈的最大数，@default 20
@property(nonatomic, assign) NSUInteger maxStack;

+ (instancetype)share;

- (BOOL)start;
- (BOOL)startWithPort:(NSUInteger)port;
- (void)stop;

- (void)log:(NSString *)content;
- (void)logA:(NSArray *)arr;

@end
