//
//  GameViewController.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/24.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "GameViewController.h"
#import "ArchiveManager.h"
#import "CXHRecordTool.h"
#import "lame.h"


@interface GameViewController ()<WKUIDelegate,WKNavigationDelegate,WMPlayerDelegate>

@property(nonatomic,strong) WKWebView *webview;
@property(nonatomic,strong) WebViewJavascriptBridge* bridge;
@property(nonatomic,strong) WVJBResponseCallback responseCallback;
@property(nonatomic,strong) NSMutableArray *logDatas;
@property(nonatomic,strong) WMPlayer  *wmPlayer;
@property(nonatomic,strong) UITextView *titleTV;


@end

@implementation GameViewController
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;

    [self initWKWebview];
    [self creatUIControl];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    if (_bridge) {
        _bridge = nil;
    }
    [_bridge removeHandler:@"callbackByJSHandler"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor whiteColor];
    self.logDatas = [NSMutableArray array];
    
    [self requestScriptResource];
    
    // Do any additional setup after loading the view.
}

-(void)initWKWebview{
    
    //注册方法
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    // 初始化一个 WKWebViewConfiguration 对象用于配置 WKWebView
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    configuration.mediaPlaybackRequiresUserAction = false;
    
    
    WKPreferences *preferences = [WKPreferences new];
    [preferences setValue:@(true) forKey:@"allowFileAccessFromFileURLs"];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;
    
    WKWebView *webView =[[WKWebView alloc]initWithFrame:[UIScreen mainScreen].bounds configuration:configuration];
    self.webview = webView;
    [self.view addSubview:webView];
    webView.backgroundColor =[UIColor whiteColor];
    self.webview.UIDelegate = self;
    self.webview.navigationDelegate = self;
    self.webview.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
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
            NSLog(@"Log日志输出----%@",dataDict[@"logMsg"]);
            if (weakSelf.logDatas.count>100) {
                [weakSelf.logDatas removeAllObjects];
            }
            [weakSelf.logDatas addObject:dataDict[@"logMsg"]];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *newStr =  [weakSelf.logDatas componentsJoinedByString:@"\n"];//#为分隔符
                NSLog(@"-----%lu",(unsigned long)[newStr length]);
                if ([newStr length]>30000) {
                    weakSelf.titleTV.text = [newStr substringFromIndex:([newStr length] - 30000)];
                }
                else{
                    weakSelf.titleTV.text = newStr;
                }

            });

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
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }

        else if ([dataDict[@"methodName"] isEqualToString:@"createVideo"]){//视频创建
            NSLog(@"%@",dataDict);
            NSLog(@"%f---%f",SCREEN_WIDTH,SCREEN_HEIGHT);
            WMPlayerModel *model =[WMPlayerModel new];
            model.videoURL = [NSURL URLWithString:dataDict[@"url"]];
            WMPlayer *wmPlayer = [WMPlayer playerWithModel:model];
            wmPlayer.isFullscreen = YES;
            wmPlayer.delegate = weakSelf;
            weakSelf.wmPlayer = wmPlayer;
            [weakSelf.view addSubview:wmPlayer];
            wmPlayer.backBtnStyle = BackBtnStyleNone;
            weakSelf.wmPlayer.frame = CGRectMake([dataDict[@"x"] floatValue], [dataDict[@"y"] floatValue], [dataDict[@"width"] floatValue], [dataDict[@"height"] floatValue]);
            [weakSelf.view insertSubview:weakSelf.wmPlayer belowSubview:weakSelf.titleTV];

            NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
            returnDict[@"status"] = @"success";
            returnDict[@"errorMsg"] = @"";
            returnDict[@"type"] = @"";
            responseCallback([Tool dictionaryToJson:returnDict]);

        }

        else if ([dataDict[@"methodName"] isEqualToString:@"playVideo"]){//视频播放
            [weakSelf.wmPlayer play];

        }

        else if ([dataDict[@"methodName"] isEqualToString:@"onEndedVideo"]){//移除视频控件
            [weakSelf.wmPlayer pause];
            [weakSelf.wmPlayer removeFromSuperview];
            weakSelf.wmPlayer = nil;

        }
        
        else if ([dataDict[@"methodName"] isEqualToString:@"record"]){//录音
            
            if ([dataDict[@"type"] isEqualToString:@"start"]) {//start:开始录音
                [[CXHRecordTool sharedRecordTool] startRecording];
                NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                returnDict[@"status"] = @"success";
                returnDict[@"errorMsg"] = @"";
                returnDict[@"type"] = @"start";
                returnDict[@"url"] = @"";
                responseCallback([Tool dictionaryToJson:returnDict]);
            }
            else{//stop:结束录音
                [[CXHRecordTool sharedRecordTool]  stopRecording];
                NSString *string = [CXHRecordTool sharedRecordTool].recorder.url.absoluteString;
                NSString *urlString = [string substringFromIndex:7];
                NSURL *fileUrl = [NSURL URLWithString:urlString];
                NSURL *mp3Url = [weakSelf transformCAFToMP3:fileUrl];
                [CXHRecordTool sharedRecordTool].recordMP3FileUrl = mp3Url;
                NSLog(@"mp3文件地址：%@",mp3Url);

                NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                returnDict[@"status"] = @"success";
                returnDict[@"errorMsg"] = @"";
                returnDict[@"type"] = @"stop";
                NSURL *url = [CXHRecordTool sharedRecordTool].recordMP3FileUrl;
                returnDict[@"url"] = url.absoluteString;
                responseCallback([Tool dictionaryToJson:returnDict]);
            }
        }
        

        else if ([dataDict[@"methodName"] isEqualToString:@"recognitionText"]){//上传录音
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/html",@"image/jpeg",@"image/jpg",@"image/png",@"application/octet-stream",@"text/json",@"text/plain",nil];
            manager.requestSerializer  = [AFJSONRequestSerializer serializer];
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            NSMutableDictionary *para = [NSMutableDictionary dictionary];
            para[@"babyToken"] = @"GqPNvujTYTvX5xxfuS3tq1NF6wXSiTRY";
            para[@"query"] = dataDict[@"text"];
            NSString *url = @"https://api.bobbyen.com/v4/utility/recognitionText";
            [manager POST:url parameters:para constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {

                NSString *sre = [NSString stringWithFormat:@"file://%@",dataDict[@"url"]];

                /*
                 name 接口文档字段
                 fileName 当前时间戳
                 mimeType 告诉服务端，上传需支持的文件类型格式
                 */

                [formData appendPartWithFileURL:[NSURL URLWithString:sre] name:@"voice" fileName:@"1.mp3" mimeType:@"audio/mpeg3" error:nil];

            } progress:^(NSProgress * _Nonnull uploadProgress) {

                float progress = 1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount;
                NSLog(@"上传进度-----   %f",progress);

            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"上传成功 %@",responseObject);
                NSMutableDictionary *obj = (NSMutableDictionary*)responseObject;
                NSString *code =[NSString stringWithFormat:@"%@",obj[@"code"]];
                if ([code isEqualToString:@"0"]) {
                    NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                    returnDict[@"status"] = @"success";
                    returnDict[@"errorMsg"] = @"";
                    returnDict[@"data"] = [Tool dictionaryToJson:obj];
                    responseCallback([Tool dictionaryToJson:returnDict]);
                }
                else {
                    NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                    returnDict[@"status"] = @"fail";
                    returnDict[@"errorMsg"] = @"";
                    returnDict[@"data"] = [Tool dictionaryToJson:responseObject];
                    responseCallback([Tool dictionaryToJson:returnDict]);

                }

            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"上传失败 %@",error);
                NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
                returnDict[@"status"] = @"fail";
                returnDict[@"errorMsg"] = @"网络出错了";
                returnDict[@"data"] = @"网络出错了";
                responseCallback([Tool dictionaryToJson:returnDict]);
            }];
            
            
        }


    }];
    
}


-(void)requestScriptResource{
//    NSString *scriptURL = @"https://bobbyenoss.oss-cn-beijing.aliyuncs.com/cocos/bobbyen_hzt_test/web-mobile.zip";
    NSString *scriptURL = @"https://bobbyenoss.oss-cn-beijing.aliyuncs.com/cocos/xfj_test/web-mobile.zip";
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

#pragma mark UI控件
-(void)creatUIControl{

    UITextView *titleTV =[UITextView new];
    self.titleTV = titleTV;
    titleTV.frame = CGRectMake(SCREEN_WIDTH*0.25, 0, SCREEN_WIDTH*0.75, SCREEN_HEIGHT);
    [self.view addSubview:titleTV];
    titleTV.font = [UIFont systemFontOfSize:14];
    titleTV.textColor =[UIColor blueColor];
    titleTV.hidden = YES;
    [titleTV setEditable:NO];

    
    UIButton *logBtn =[[UIButton alloc]init];
    [self.view addSubview:logBtn];
    [logBtn setTitle:@"log日志" forState:UIControlStateNormal];
    [logBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [logBtn addTarget:self action:@selector(logClick:) forControlEvents:UIControlEventTouchUpInside];
    logBtn.frame = CGRectMake(SCREEN_WIDTH-100, 20, 80, 30);


    UIButton *clearBtn =[[UIButton alloc]init];
    [self.view addSubview:clearBtn];
    [clearBtn setTitle:@"删除日志" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [clearBtn addTarget:self action:@selector(clearClick) forControlEvents:UIControlEventTouchUpInside];
    clearBtn.frame = CGRectMake(SCREEN_WIDTH-100, 70, 80, 30);
}
-(void)logClick:(UIButton*)btn{
    self.titleTV.hidden = !self.titleTV.hidden;
}
-(void)clearClick{
    [self.logDatas removeAllObjects];
    self.titleTV.text = @"";
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
    self.wmPlayer = nil;
    
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
    self.wmPlayer = nil;
    
    NSMutableDictionary *returnDict =[NSMutableDictionary dictionary];
    returnDict[@"status"] = @"success";
    returnDict[@"errorMsg"] = @"播放完成";
    returnDict[@"type"] = @"onCompleteVideo";
    self.responseCallback([Tool dictionaryToJson:returnDict]);
    
}

#pragma  .caf --> .mp3
- (NSURL *)transformCAFToMP3:(NSURL *)sourceUrl
{
    NSURL *mp3FilePath,*audioFileSavePath;
    
    
    //    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    //    NSTimeInterval time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
    //    NSString *timeString = [NSString stringWithFormat:@"%.0f",time];
    //    //获取沙盒地址
    //    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    //
    //    NSString *folderPath = [NSString stringWithFormat:@"%@/1/%@",path,timeString];
    //    [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    //
    //    NSString *newsPath = [path stringByAppendingString:@"/1"];
    //    NSString *newsPath1 = [newsPath stringByAppendingPathComponent:timeString];
    //    NSString *newsPath2 = [newsPath1 stringByAppendingPathComponent:@"BobbyenVideo.mp3"];
    //    mp3FilePath = [NSURL URLWithString:newsPath2];
    
    
    
    
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
    NSString *timeString = [NSString stringWithFormat:@"%.0f.mp3",time];
    //获取沙盒地址
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *newsPath = [path stringByAppendingString:@"/1"];
    NSString *newsPath1 = [newsPath stringByAppendingPathComponent:timeString];
    mp3FilePath = [NSURL URLWithString:newsPath1];
    
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([[sourceUrl absoluteString] cStringUsingEncoding:1], "rb");   //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                                   //skip file header
        FILE *mp3 = fopen([[mp3FilePath absoluteString] cStringUsingEncoding:1], "wb"); //output 输出生成的Mp3文件位置
        
        //        NSLog(@"sour-- %@   last-- %@",sourceUrl,mp3FilePath);
        //        sour-- //Users/chenxihang/Library/Developer/CoreSimulator/Devices/35F46DFB-3878-44EE-BBC4-B4EEB494548A/data/Containers/Data/App ... cord.caf
        //        last-- /Users/chenxihang/Library/Developer/CoreSimulator/Devices/35F46DFB-3878-44EE-BBC4-B4EEB494548A/data/Containers/Data/Appl ... test.mp3
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        audioFileSavePath = mp3FilePath;
        NSLog(@"MP3生成成功: %@",audioFileSavePath);
    }
    
    return audioFileSavePath;
}


//支持旋转
-(BOOL)shouldAutorotate{
    return YES;
}
//支持的方向,只支持横屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
//一开始的方向  很重要
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeRight;
}

-(void)dealloc{
    NSLog(@"页面释放了---%@",self);
}

@end
