//
//  DownLoadViewController.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/20.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "DownLoadViewController.h"
#import "ArchiveManager.h"

@interface DownLoadViewController ()<WKUIDelegate,WKNavigationDelegate>
@property(nonatomic,strong) WKWebView *webview;
@property(nonatomic,strong) WebViewJavascriptBridge* bridge;
@property(nonatomic,assign) BOOL isFullScreen;
@end

@implementation DownLoadViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
//    [self.navigationController setNavigationBarHidden:YES animated:NO];
    //设置屏幕横向
    self.isFullScreen = YES;

}
-(void)viewWillDisappear:(BOOL)animated{
    [UIApplication sharedApplication].statusBarHidden = NO;
//    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [super viewWillDisappear:animated];
    //设置屏幕横向
    self.isFullScreen = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor whiteColor];

    [self initWebview];
    [self requestResource];

    // Do any additional setup after loading the view.
}

-(void)initWebview{
    
    //注册方法
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    // 初始化一个 WKWebViewConfiguration 对象用于配置 WKWebView
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    
    WKPreferences *preferences = [WKPreferences new];
    [preferences setValue:@(true) forKey:@"allowFileAccessFromFileURLs"];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    //    preferences.minimumFontSize = 20.0;
    configuration.preferences = preferences;
    
    WKWebView *webView =[[WKWebView alloc]initWithFrame:[UIScreen mainScreen].bounds configuration:configuration];
    self.webview = webView;
    [self.view addSubview:webView];
    self.webview.UIDelegate = self;
    self.webview.navigationDelegate = self;
    self.webview.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.webview.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webview];
    [_bridge registerHandler:@"callbackByJSHandler" handler:^(id data, WVJBResponseCallback responseCallback) {
    
    }];
    
}

-(void)requestResource{
    NSString *scriptURL = @"https://bobbyenoss.oss-cn-beijing.aliyuncs.com/cocos/bobbyen_hzt_test/web-mobile.zip";
    NSString *zipURL = @"https://upload.bobbyen.com/zip/production/course/120.zip";
    
    
    dispatch_group_t group = dispatch_group_create();
    //任务一
    dispatch_group_enter(group);

    [[ArchiveManager manager] setResourceBlock:^(NSString * _Nonnull localPath) {
        NSLog(@"资源路径一：%@",localPath);
        
    }];
    [[ArchiveManager manager] setProgressBlock:^(double progress) {
        NSLog(@"当前下载进度：%f",progress);
    }];

    
    [[ArchiveManager manager] startRequest:scriptURL];
    dispatch_group_leave(group);
    
    //任务二
    dispatch_group_enter(group);
    [[ArchiveManager manager] setResourceBlock:^(NSString * _Nonnull localPath) {
        NSLog(@"资源路径二：%@",localPath);
        
    }];
    [[ArchiveManager manager] startRequest:zipURL];
    dispatch_group_leave(group);
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //执行最后任务
            NSString * webPath = [NSString stringWithFormat:@"file://%@/web-mobile/web-mobile/index.html",[ArchiveManager manager].cachesPath];
            NSURL *url = [NSURL URLWithString:webPath];
            NSURLRequest *request =[NSURLRequest requestWithURL:url];
            // 加载网页
            [self.webview loadRequest:request];
        });
        

        
    });

}

#pragma mark  set方法，设置是否需要全屏的方法
-(void)setIsFullScreen:(BOOL)isFullScreen
{
    _isFullScreen = isFullScreen;
    if (isFullScreen) {
        //横竖屏设置
        [UIView animateWithDuration:0.5f animations:^{
            [[UIDevice currentDevice] setValue:
             [NSNumber numberWithInteger: UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
        }];
        NSLog(@"%f--横屏--%f",SCREEN_WIDTH, SCREEN_HEIGHT);//375.000000--横屏--667.000000
    }else{
        [UIView animateWithDuration:0.5f animations:^{
            [[UIDevice currentDevice] setValue:
             [NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
        }];
        NSLog(@"%f--竖屏--%f",SCREEN_WIDTH, SCREEN_HEIGHT);//375.000000--竖屏--667.000000
    }
}


-(void)dealloc{
    NSLog(@"%@",self);
}

@end
