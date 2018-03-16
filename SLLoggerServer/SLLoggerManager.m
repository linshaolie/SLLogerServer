//
//  Created by shaolie on 2018/1/11.
//  Github: https://www.github.com/linshaolie
//  Copyright © 2018年 shaolie. All rights reserved.
//

#import "SLLoggerManager.h"
#import "HTTPServerLogger.h"

#define BETA_BUILD 1

@interface SLLoggerManager()

@property(nonatomic, assign) int outFd;
@property(nonatomic, assign) int errFd;

@end

@implementation SLLoggerManager

+ (instancetype)shareLogger {
    static SLLoggerManager *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[SLLoggerManager alloc] init];
    });
    return logger;
}

+ (void)Log:(NSString *)content, ... {
    va_list ap;
    char ch;
    NSMutableArray *arr = [NSMutableArray new];
    
    va_start(ap, content);
    [arr addObject:content];
    int i = 0;
    
    BOOL con = NO;
    while(i < content.length) {
        ch = [content characterAtIndex:i++];
        if (ch == '%') {
            do {
                con = NO;
                ch = [content characterAtIndex:i++];
                switch(ch) {
                    case 'l': {
                        con = YES;
                        break;
                    }
                    case 'd': case 'D':
                    case 'x': case 'X':
                    case 'c': case 'C':
                    case 'i': case 'U':
                    case 'o': case 'O':
                    case 'p': case 't':
                    {
                        int n = va_arg(ap, int);
                        [arr addObject:@(n)];
                        break;
                    }
                    case 'f': case 'F':
                    case 'e': case 'E':
                    case 'g': case 'G':
                    case 'a': case 'A':
                    {
                        double f = va_arg(ap, double);
                        [arr addObject:@(f)];
                        break;
                    }
                    case 's': case 'S':
                    {
                        char *p = va_arg(ap, char *);
                        NSString *s = [NSString stringWithCString:p encoding:NSUTF8StringEncoding];
                        [arr addObject:s];
                        break;
                    }
                    case '@': {
                        id obj = va_arg(ap, id);
                        if(obj != nil) {
                            [arr addObject:obj];
                        } else {
                            [arr addObject:@"null"];
                        }
                        break;
                    }
                    case '%':
                        i++; break;
                    default: break;
                }
            } while(con);
        }
    }
    
    va_end(ap);
}

- (void)redirectStandardOutput {
#if BETA_BUILD
    //记录标准输出及错误流原始文件描述符
    self.outFd = dup(STDOUT_FILENO);
    self.errFd = dup(STDERR_FILENO);
    stdout->_flags = 10;
    NSPipe *outPipe = [NSPipe pipe];
    NSFileHandle *pipeOutHandle = [outPipe fileHandleForReading];
    dup2([[outPipe fileHandleForWriting] fileDescriptor], STDOUT_FILENO);
    [pipeOutHandle readInBackgroundAndNotify];
    stderr->_flags = 10;
    NSPipe *errPipe = [NSPipe pipe];
    NSFileHandle *pipeErrHandle = [errPipe fileHandleForReading];
    dup2([[errPipe fileHandleForWriting] fileDescriptor], STDERR_FILENO);
    [pipeErrHandle readInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redirectOutNotificationHandle:) name:NSFileHandleReadCompletionNotification object:pipeOutHandle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redirectErrNotificationHandle:) name:NSFileHandleReadCompletionNotification object:pipeErrHandle];
#endif
}


- (void)recoverStandardOutput {
#if BETA_BUILD
    dup2(self.outFd, STDOUT_FILENO);
    dup2(self.errFd, STDERR_FILENO);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
}

// 重定向之后的NSLog输出
- (void)redirectOutNotificationHandle:(NSNotification *)nf {
#if BETA_BUILD
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [[HTTPServerLogger share] log:str];
#endif
    [[nf object] readInBackgroundAndNotify];
}

// 重定向之后的错误输出
- (void)redirectErrNotificationHandle:(NSNotification *)nf {
#if BETA_BUILD
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [[HTTPServerLogger share] log:str];
#endif
    [[nf object] readInBackgroundAndNotify];
}

@end

