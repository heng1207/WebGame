//
//  GameViewController.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/24.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "GameViewController.h"
#import "ArchiveManager.h"

@interface GameViewController ()<WKUIDelegate,WKNavigationDelegate,UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>

@property(nonatomic,strong) WKWebView *webview;
@property(nonatomic,strong) WebViewJavascriptBridge* bridge;
@property(nonatomic,strong) UITableView *logTableView;
@property(nonatomic,strong) NSMutableArray *logDatas;
@end

@implementation GameViewController
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_bridge) {
        _bridge = nil;
    }
    [_bridge removeHandler:@"callbackByJSHandler"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor whiteColor];
    [self initWKWebview];
    [self requestScriptResource];
    self.logDatas = [NSMutableArray array];
    [self creatLogTabview];
    // Do any additional setup after loading the view.
}

-(void)initWKWebview{
    
    //注册方法
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    // 初始化一个 WKWebViewConfiguration 对象用于配置 WKWebView
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    
    WKPreferences *preferences = [WKPreferences new];
    [preferences setValue:@(true) forKey:@"allowFileAccessFromFileURLs"];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    //preferences.minimumFontSize = 20.0;
    configuration.preferences = preferences;
    
    WKWebView *webView =[[WKWebView alloc]initWithFrame:[UIScreen mainScreen].bounds configuration:configuration];
    self.webview = webView;
    [self.view addSubview:webView];
    self.webview.UIDelegate = self;
    self.webview.navigationDelegate = self;
    self.webview.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.webview.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    webView.userInteractionEnabled = YES;
    [WebViewJavascriptBridge enableLogging];
    [_bridge setWebViewDelegate:self];
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webview];
    
    __weak GameViewController *weakSelf = self;
    [_bridge registerHandler:@"callbackByJSHandler" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dataDict = [Tool dictionaryWithJsonString:[NSString stringWithFormat:@"%@",data]];

        if ([dataDict[@"methodName"] isEqualToString:@"downloadResource"]) {//下载
            [[ArchiveManager manager] setResourceBlock:^(NSString * _Nonnull localPath) {
                NSLog(@"资源路径：%@",localPath);
                NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                returnDict[@"status"] = @"success";
                returnDict[@"progress"] = @"100";
                returnDict[@"url"] = localPath;
                returnDict[@"errorMsg"] = @"";
                responseCallback([Tool dictionaryToJson:returnDict]);
            }];

            [[ArchiveManager manager] setProgressBlock:^(double progress) {
                NSLog(@"当前下载进度：%f",progress);
                NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                returnDict[@"progress"] = [NSString stringWithFormat:@"%f",progress];
                responseCallback([Tool dictionaryToJson:returnDict]);
            }];
            [[ArchiveManager manager] startRequest:dataDict[@"url"]];

        }
        else if ([dataDict[@"methodName"] isEqualToString:@"unzipFile"]){//解压

            [[ArchiveManager manager] setResourceBlock:^(NSString * _Nonnull localPath) {
                NSLog(@"资源路径：%@",localPath);
                if (localPath) {
                    NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                    returnDict[@"status"] = @"success";
                    returnDict[@"url"] = localPath;
                    responseCallback([Tool dictionaryToJson:returnDict]);
                }
                else{
                    NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                    returnDict[@"status"] = @"fail";
                    returnDict[@"url"] = @"";
                    responseCallback([Tool dictionaryToJson:returnDict]);
                }

            }];
            [[ArchiveManager manager] unzipFile:dataDict[@"url"]];

        }
        else if ([dataDict[@"methodName"] isEqualToString:@"removeDirectory"]){//删除

            NSDictionary *dataDict = [Tool dictionaryWithJsonString:[NSString stringWithFormat:@"%@",data]];
            NSString *path = [NSString stringWithFormat:@"%@/%@",[ArchiveManager manager].cachesPath,dataDict[@"url"]];
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        }
        else if ([dataDict[@"methodName"] isEqualToString:@"getResourcesPath"]){//资源路径
            NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
            returnDict[@"status"] = @"success";
            returnDict[@"errorMsg"] = @"";
            returnDict[@"resPath"] = [ArchiveManager manager].cachesPath;
            responseCallback([Tool dictionaryToJson:returnDict]);
        }
        else if ([dataDict[@"methodName"] isEqualToString:@"printLog"]){//Log日志输出
            NSDictionary *dataDict = [Tool dictionaryWithJsonString:[NSString stringWithFormat:@"%@",data]];
            NSLog(@"%@",dataDict[@"logMsg"]);
            [weakSelf.logDatas addObject:dataDict[@"logMsg"]];
            [weakSelf.logTableView reloadData];
        }

        else if ([dataDict[@"methodName"] isEqualToString:@"getUserInfo"]){//获取用户信息
            NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
            returnDict[@"status"] = @"success";
            returnDict[@"errorMsg"] = @"";
            returnDict[@"token"] = @"PKr3jKHltRhVJGA1wV8jrdYhZjZPRo2e";
            returnDict[@"courseId"] = @"1";
            returnDict[@"classId"] = @"1";
            responseCallback([Tool dictionaryToJson:returnDict]);
        }

        else if ([dataDict[@"methodName"] isEqualToString:@"exitMiniGame"]){//退出游戏
            [self.navigationController popViewControllerAnimated:YES];
        }

    }];
    
}


-(void)requestScriptResource{
    NSString *scriptURL = @"https://bobbyenoss.oss-cn-beijing.aliyuncs.com/cocos/bobbyen_hzt_test/web-mobile.zip";
    __weak GameViewController *weakSelf = self;
    [[ArchiveManager manager] setResourceBlock:^(NSString * _Nonnull localPath) {
        NSLog(@"资源路径一：%@",localPath);
        [weakSelf requestCourseResource];
    }];
    [[ArchiveManager manager] startRequestAndUnzip:scriptURL];
}

-(void)requestCourseResource{
    __weak GameViewController *weakSelf = self;
    NSString *URL = @"https://upload.bobbyen.com/zip/production/course/1.zip";
    [[ArchiveManager manager] setResourceBlock:^(NSString * _Nonnull localPath) {
        NSLog(@"资源路径：%@",localPath);
        
        NSString *webPath = [NSString stringWithFormat:@"file://%@/web-mobile/web-mobile/index.html",[ArchiveManager manager].cachesPath];
        NSString *accessPath = [NSString stringWithFormat:@"file://%@/web-mobile/web-mobile",[ArchiveManager manager].cachesPath];
        if (@available(iOS 9.0, *)) {
            [weakSelf.webview loadFileURL:[NSURL URLWithString:webPath] allowingReadAccessToURL:[NSURL URLWithString:accessPath]];
        } else {
            NSURL *fileURL = [self fileURLForBuggyWKWebView8:[NSURL fileURLWithPath:webPath]];
            NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
            [weakSelf.webview loadRequest:request];
            // Fallback on earlier versions
        }
    }];

    [[ArchiveManager manager] startRequestAndUnzip:URL];
    
    
    
    
    //点击手势
    UITapGestureRecognizer *logTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doLogTapChange:)];
    logTap.delegate = self;
    [self.webview addGestureRecognizer:logTap];
    
}

//将文件copy到tmp目录
- (NSURL *)fileURLForBuggyWKWebView8:(NSURL *)fileURL {
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    // Create "/temp/www" directory
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSURL *dstURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    // Now copy given file to the temp directory
    [fileManager removeItemAtURL:dstURL error:&error];
    [fileManager copyItemAtURL:fileURL toURL:dstURL error:&error];
    // Files in "/temp/www" load flawlesly :)
    return dstURL;
}

-(void)creatLogTabview{
    UITableView *logTableView =[[UITableView alloc]initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    self.logTableView = logTableView;
    [self.view addSubview:logTableView];
    logTableView.delegate = self;
    logTableView.dataSource = self;
    logTableView.transform = CGAffineTransformMakeRotation(M_PI_2);
    logTableView.frame = CGRectMake(0, SCREEN_HEIGHT*0.25, SCREEN_WIDTH, SCREEN_HEIGHT*0.75);
    logTableView.hidden = YES;
    
    [logTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    
    //点击手势
    UITapGestureRecognizer *logTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearLogTapChange:)];
    logTap.delegate = self;
    [logTableView addGestureRecognizer:logTap];
    
}
#pragma mark TableViewDelegate && TableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  self.logDatas.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = self.logDatas[indexPath.row];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

-(void)doLogTapChange:(UIRotationGestureRecognizer *)sender{
    self.logTableView.hidden = !self.logTableView.hidden;
}
-(void)clearLogTapChange:(UIRotationGestureRecognizer *)sender{
//    [self.logDatas removeAllObjects];
//    [self.logTableView reloadData];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)dealloc{
    NSLog(@"%@",self);
}

@end
