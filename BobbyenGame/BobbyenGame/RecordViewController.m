//
//  RecordViewController.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/28.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "RecordViewController.h"
#import "CXHRecordTool.h"
#import "lame.h"

@interface RecordViewController ()

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor whiteColor];
    
    
    
    // 录音按钮
    UIButton *recordBtn =[[UIButton alloc]initWithFrame:CGRectMake(100, 120, 80, 30)];
    [self.view addSubview:recordBtn];
    [recordBtn setTitle:@"按住 说话" forState:UIControlStateNormal];
    [recordBtn setTitle:@"松开 结束" forState:UIControlStateHighlighted];
    [recordBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    [recordBtn addTarget:self action:@selector(recordBtnDidTouchDown:) forControlEvents:UIControlEventTouchDown];
    [recordBtn addTarget:self action:@selector(recordBtnDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [recordBtn addTarget:self action:@selector(recordBtnDidTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    
    // 播放按钮
    UIButton *playBtn =[[UIButton alloc]initWithFrame:CGRectMake(100, 300, 80, 30)];
    [self.view addSubview:playBtn];
    [playBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [playBtn setTitle:@"播放" forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];

    
    
    // Do any additional setup after loading the view.
}



#pragma mark - 录音按钮事件
// 按下
- (void)recordBtnDidTouchDown:(UIButton *)recordBtn {
    [[CXHRecordTool sharedRecordTool] startRecording];
}
// 点击
- (void)recordBtnDidTouchUpInside:(UIButton *)recordBtn {
    double currentTime = [CXHRecordTool sharedRecordTool].recorder.currentTime;
    NSLog(@"%lf", currentTime);
    [[CXHRecordTool sharedRecordTool]  stopRecording];
    // 已成功录音
    NSLog(@"已成功录音,录音文件地址---%@",[CXHRecordTool sharedRecordTool].recorder.url.absoluteString);
    
    
    NSString *string = [CXHRecordTool sharedRecordTool].recorder.url.absoluteString;
    NSString *urlString = [string substringFromIndex:7];
    NSURL *fileUrl = [NSURL URLWithString:urlString];
    
    NSURL *mp3Url = [self transformCAFToMP3:fileUrl];
    NSLog(@"mp3文件地址：%@",mp3Url);
    
}
#pragma mark - 播放录音
- (void)play {
    [[CXHRecordTool sharedRecordTool] playRecordingFile];
}

// .caf --> .mp3
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
        
        NSLog(@"sour-- %@   last-- %@",sourceUrl,mp3FilePath);
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
//            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"mp3转化成功！" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    return audioFileSavePath;
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
