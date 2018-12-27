//
//  GameViewController.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/24.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "GameViewController.h"
#import "ArchiveManager.h"
#import "LogCell.h"

@interface GameViewController ()<WKUIDelegate,WKNavigationDelegate,UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate,WMPlayerDelegate>

@property(nonatomic,strong) WKWebView *webview;
@property(nonatomic,strong) WebViewJavascriptBridge* bridge;
@property(nonatomic,strong) UITableView *logTableView;
@property(nonatomic,strong) NSMutableArray *logDatas;
@property(nonatomic,strong) WMPlayer  *wmPlayer;
@property(nonatomic,strong) WVJBResponseCallback responseCallback;
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
    self.logDatas = [NSMutableArray array];
    [self creatLogTabview];
    
    [self requestScriptResource];
    
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
    configuration.mediaPlaybackRequiresUserAction = false;

    
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
        weakSelf.responseCallback = responseCallback;
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
            NSString *path = [NSString stringWithFormat:@"%@/%@",[ArchiveManager manager].cachesPath,dataDict[@"url"]];
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        }
        
        else if ([dataDict[@"methodName"] isEqualToString:@"getResourcesPath"]){//资源路径
            NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
            returnDict[@"status"] = @"success";
            returnDict[@"errorMsg"] = @"";
            returnDict[@"resPath"] = [NSString stringWithFormat:@"file://%@/1",[ArchiveManager manager].cachesPath];
            responseCallback([Tool dictionaryToJson:returnDict]);
        }
        
        else if ([dataDict[@"methodName"] isEqualToString:@"printLog"]){//Log日志输出
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
        
        else if ([dataDict[@"methodName"] isEqualToString:@"createVideo"]){//视频创建
            NSLog(@"%@",dataDict);
            WMPlayerModel *model =[WMPlayerModel new];
            model.videoURL = [NSURL URLWithString:dataDict[@"url"]];
            WMPlayer *wmPlayer = [WMPlayer playerWithModel:model];
            wmPlayer.isFullscreen = YES;
            wmPlayer.delegate = self;
            self.wmPlayer = wmPlayer;
            [self.view addSubview:wmPlayer];
            wmPlayer.backBtnStyle = BackBtnStyleNone;
            self.wmPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.wmPlayer.frame = CGRectMake([dataDict[@"y"] floatValue], [dataDict[@"x"] floatValue], [dataDict[@"height"] floatValue], [dataDict[@"width"] floatValue]);
            
            
            NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
            returnDict[@"status"] = @"success";
            returnDict[@"errorMsg"] = @"";
            returnDict[@"type"] = @"";
            responseCallback([Tool dictionaryToJson:returnDict]);
            
        }
        
        else if ([dataDict[@"methodName"] isEqualToString:@"playVideo"]){//视频播放
            [self.wmPlayer play];
            
        }
        
        else if ([dataDict[@"methodName"] isEqualToString:@"onEndedVideo"]){//移除视频控件
            [self.wmPlayer pause];
            [self.wmPlayer removeFromSuperview];
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
        NSString *accessPath = [NSString stringWithFormat:@"file://%@",[ArchiveManager manager].cachesPath];
        if (@available(iOS 9.0, *)) {
            [weakSelf.webview loadFileURL:[NSURL URLWithString:webPath] allowingReadAccessToURL:[NSURL URLWithString:accessPath]];
        } else {
//            NSURL *fileURL = [self fileURLForBuggyWKWebView8:[NSURL fileURLWithPath:webPath]];
//            NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
//            [weakSelf.webview loadRequest:request];
            // Fallback on earlier versions
        }
    }];

    [[ArchiveManager manager] startRequestAndUnzip:URL];



    UIButton *logBtn =[[UIButton alloc]init];
    [self.view addSubview:logBtn];
    [logBtn setTitle:@"log日志" forState:UIControlStateNormal];
    [logBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [logBtn addTarget:self action:@selector(logClick:) forControlEvents:UIControlEventTouchUpInside];
    logBtn.frame = CGRectMake(SCREEN_WIDTH-100, SCREEN_HEIGHT-50, 80, 30);

}

////将文件copy到tmp目录
//- (NSURL *)fileURLForBuggyWKWebView8:(NSURL *)fileURL {
//    NSError *error = nil;
//    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
//        return nil;
//    }
//    // Create "/temp/www" directory
//    NSFileManager *fileManager= [NSFileManager defaultManager];
//    NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
//    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
//
//    NSURL *dstURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
//    // Now copy given file to the temp directory
//    [fileManager removeItemAtURL:dstURL error:&error];
//    [fileManager copyItemAtURL:fileURL toURL:dstURL error:&error];
//    // Files in "/temp/www" load flawlesly :)
//    return dstURL;
//}

-(void)creatLogTabview{
    UITableView *logTableView =[[UITableView alloc]initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    self.logTableView = logTableView;
    [self.view addSubview:logTableView];
    logTableView.delegate = self;
    logTableView.dataSource = self;
    logTableView.transform = CGAffineTransformMakeRotation(M_PI_2);
    logTableView.frame = CGRectMake(0, SCREEN_HEIGHT*0.25, SCREEN_WIDTH, SCREEN_HEIGHT*0.75);
    logTableView.hidden = YES;

    [logTableView registerClass:[LogCell class] forCellReuseIdentifier:@"LogCell"];

    //点击手势
    UITapGestureRecognizer *logTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearLogTapChange:)];
    logTap.delegate = self;
    [logTableView addGestureRecognizer:logTap];

}
#pragma mark TableViewDelegate && TableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.logDatas.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    LogCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogCell" forIndexPath:indexPath];
    cell.titleLab.text = self.logDatas[indexPath.row];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 10;
}
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *view =[[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 10)];
    view.backgroundColor =[UIColor grayColor];
    return view;
}
#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
-(void)logClick:(UIButton*)btn{
    self.logTableView.hidden = !self.logTableView.hidden;
}
-(void)clearLogTapChange:(UIRotationGestureRecognizer *)sender{
    [self.logDatas removeAllObjects];
    [self.logTableView reloadData];
}


#pragma mark WMPlayerDelegate
//点击全屏按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedFullScreenButton:(UIButton *)fullScreenBtn{
 
}
//点击关闭按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedCloseButton:(UIButton *)backBtn{
    
}
//播放失败的代理方法
-(void)wmplayerFailedPlay:(WMPlayer *)wmplayer WMPlayerStatus:(WMPlayerState)state{
    [self.wmPlayer pause];
    [self.wmPlayer removeFromSuperview];
    
    NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
    returnDict[@"status"] = @"fail";
    returnDict[@"errorMsg"] = @"播放出错";
    returnDict[@"type"] = @"onErrorVideo";
    self.responseCallback([Tool dictionaryToJson:returnDict]);
}
//播放完毕的代理方法
-(void)wmplayerFinishedPlay:(WMPlayer *)wmplayer{
    [self.wmPlayer pause];
    [self.wmPlayer removeFromSuperview];
    
    NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
    returnDict[@"status"] = @"success";
    returnDict[@"errorMsg"] = @"播放完成";
    returnDict[@"type"] = @"onCompleteVideo";
    self.responseCallback([Tool dictionaryToJson:returnDict]);
}


-(void)dealloc{
    NSLog(@"%@",self);
}

@end
