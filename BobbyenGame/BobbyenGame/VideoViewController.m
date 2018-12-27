//
//  VideoViewController.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/21.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "VideoViewController.h"


@interface VideoViewController ()<WMPlayerDelegate>
@property(nonatomic,strong) WMPlayer  *wmPlayer;
@property(nonatomic,assign) BOOL fullscreen;

@property (strong, nonatomic)UISlider *avSlider;//用来现实视频的播放进度，并且通过它来控制视频的快进快退。
@end

@implementation VideoViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
    [self creatVideoUI];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor grayColor];
    
//    [self customPlayer];
//    [self creatCLPlayer];
    // Do any additional setup after loading the view.
}

-(void)creatVideoUI{
    WMPlayerModel *model =[WMPlayerModel new];
    NSString *urlStr =  @"https://upload.bobbyen.com/files/pqp/SXO/A99pfqVrme7XqSGB8NmDZh9w0AyoF9B2.mp4";
    model.videoURL = [NSURL URLWithString:urlStr];
    
    WMPlayer  *wmPlayer = [WMPlayer playerWithModel:model];
    wmPlayer.delegate = self;
    self.wmPlayer = wmPlayer;
    self.fullscreen = YES;
    [self.view addSubview:wmPlayer];
    wmPlayer.backBtnStyle = BackBtnStylePop;
    [wmPlayer play];
//    self.wmPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.wmPlayer.frame = CGRectMake(0, 0,  SCREEN_WIDTH, SCREEN_HEIGHT);
    NSLog(@"%f---%f",SCREEN_WIDTH,SCREEN_HEIGHT);
}
//点击全屏按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedFullScreenButton:(UIButton *)fullScreenBtn{
    self.fullscreen = !self.fullscreen;
    if (self.fullscreen) {
        self.wmPlayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    }
    else{
        self.wmPlayer.frame = CGRectMake(0, 0, SCREEN_WIDTH-60, SCREEN_HEIGHT-100);
    }

    NSLog(@"%f---%f",SCREEN_WIDTH,SCREEN_HEIGHT);
    
}
//点击关闭按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedCloseButton:(UIButton *)backBtn{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)customPlayer{
    
    UIView *bgView =[[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    bgView.backgroundColor = [UIColor redColor];
    [self.view addSubview:bgView];
    
    
    //构建播放网址
    NSURL *mediaURL = [NSURL URLWithString:@"https://upload.bobbyen.com/files/pqp/SXO/A99pfqVrme7XqSGB8NmDZh9w0AyoF9B2.mp4"];
    //构建播放单元
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:mediaURL];
    //构建播放器对象
    AVPlayer *myPlayer = [AVPlayer playerWithPlayerItem:item];
    //构建播放器的layer
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:myPlayer];
    [bgView.layer addSublayer:playerLayer];
    bgView.transform = CGAffineTransformMakeRotation(M_PI_2);
    bgView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    playerLayer.frame = bgView.bounds;
    [myPlayer play];
}


-(void)creatCLPlayer{
    CLPlayerView  *playerView = [[CLPlayerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:playerView];
    [CLPlayerViewConfig defaultConfig].fullStatusBarHiddenType = FullStatusBarHiddenAlways;
    //视频地址
    playerView.url = [NSURL URLWithString:@"https://upload.bobbyen.com/files/pqp/SXO/A99pfqVrme7XqSGB8NmDZh9w0AyoF9B2.mp4"];
    //播放
    [playerView playVideo];
}


//支持旋转
-(BOOL)shouldAutorotate{
    return YES;
}
//支持的方向,只支持横屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft;
}
//一开始的方向  很重要
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeLeft;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
