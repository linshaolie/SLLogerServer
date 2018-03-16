//
//  Created by shaolie on 2018/1/24.
//  Github: https://www.github.com/linshaolie
//  Copyright © 2018年 shaolie. All rights reserved.
//

#import "ViewController.h"
#import "SLLoggerManager.h"
#import "HTTPServerLogger.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UIButton *startServerBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopServerBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _stopServerBtn.enabled = NO;
}

- (IBAction)onLog:(id)sender {
    NSDictionary *dic = @{@"name": @"shaolie.lin", @"age": @24};
    NSLog(@"hello: %@---%@", dic[@"name"], dic);
    SLLog(@"%d, %fhell%%o: %@-%lf-%ld-%@", 5, 3.3, dic[@"name"], 5.1, 100, dic, nil);
}

- (IBAction)startServer:(id)sender {
    HTTPServerLogger *server = [HTTPServerLogger share];
    BOOL rst = [server start];
    if (rst) {
        _startServerBtn.enabled = NO;
        _stopServerBtn.enabled = YES;
        _tipsLabel.text = [NSString stringWithFormat:@"服务已启动\n请访问：%@:%lu", server.serverURL.host, server.port];
    } else {
        _tipsLabel.text = @"服务启动失败！";
    }
}

- (IBAction)stopServer:(id)sender {
    _startServerBtn.enabled = YES;
    _stopServerBtn.enabled = NO;
    [[HTTPServerLogger share] stop];
    _tipsLabel.text = @"服务器已停止！";
}

- (IBAction)redirect:(id)sender {
    [[SLLoggerManager shareLogger] redirectStandardOutput];
}

- (IBAction)recover:(id)sender {
    [[SLLoggerManager shareLogger] recoverStandardOutput];
}

@end

