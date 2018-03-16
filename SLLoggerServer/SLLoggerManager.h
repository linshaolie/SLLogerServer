//
//  Created by shaolie on 2018/1/11.
//  Github: https://www.github.com/linshaolie
//  Copyright © 2018年 shaolie. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SLLog(FORMAT, ...) [SLLoggerManager Log:FORMAT, ##__VA_ARGS__, nil]

@interface SLLoggerManager : NSObject

+ (instancetype)shareLogger;

+ (void)Log:(NSString *)format, ...;

- (void)redirectStandardOutput;
- (void)recoverStandardOutput;

@end
