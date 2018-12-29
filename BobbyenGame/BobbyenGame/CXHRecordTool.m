//
//  CXHRecordTool.m
//  Demo_RecordAndPlayVoice
//


#import "CXHRecordTool.h"

@interface CXHRecordTool () <AVAudioRecorderDelegate>


@property (nonatomic, strong) AVAudioSession *session;

@end

@implementation CXHRecordTool


static id instance;
#pragma mark - 单例
+ (instancetype)sharedRecordTool {
    return [[self alloc] init];
}

static CXHRecordTool *instance = nil;
static dispatch_once_t onceToken;
- (instancetype)init {
    dispatch_once(&onceToken, ^{
        instance = [super init];
        
//        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
//        NSString *folderPath = [NSString stringWithFormat:@"%@/1",path];
//        
//        NSError *error;
//        [[NSFileManager defaultManager] removeItemAtPath:folderPath error:&error];
//        
//        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        
    });
    return instance;
}


- (void)startRecording {

    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
    NSString *timeString = [NSString stringWithFormat:@"1/%.0f.caf",time];
    
    
    //获取沙盒地址
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [path stringByAppendingPathComponent:timeString];
    self.recordFileUrl = [NSURL fileURLWithPath:filePath];
    NSLog(@"filePath: %@", filePath);
    
    
    
    // 真机环境下需要的代码
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil)
        NSLog(@"Error creating session: %@", [sessionError description]);
    else
        [session setActive:YES error:nil];
    
    self.session = session;
    
    [self.recorder record];
    
}


- (void)stopRecording {
    if ([self.recorder isRecording]) {
        [self.recorder stop];
    }
}



- (void)playRecordingFile {
    // 播放时停止录音
    [self.recorder stop];
    
    // 正在播放就返回
    if ([self.player isPlaying]) return;
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordFileUrl error:NULL];
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.player play];
}

- (void)stopPlaying {
    [self.player stop];
}



#pragma mark - 懒加载
- (AVAudioRecorder *)recorder {
    if (!_recorder) {
    
        //录音设置
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
        //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）, 采样率必须要设为11025才能使转化成mp3格式后不会失真
        [recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
        //录音通道数  1 或 2 ，要转换成mp3格式必须为双通道
        [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        //线性采样位数  8、16、24、32
        [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        //录音的质量
        [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
        
        //        // 3.设置录音的一些参数
        //        NSMutableDictionary *setting = [NSMutableDictionary dictionary];
        //        // 音频格式
        //        setting[AVFormatIDKey] = @(kAudioFormatAppleIMA4);
        //        // 录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
        //        setting[AVSampleRateKey] = @(44100);
        //        // 音频通道数 1 或 2
        //        setting[AVNumberOfChannelsKey] = @(1);
        //        // 线性音频的位深度  8、16、24、32
        //        setting[AVLinearPCMBitDepthKey] = @(8);
        //        //录音的质量
        //        setting[AVEncoderAudioQualityKey] = [NSNumber numberWithInt:AVAudioQualityHigh];
        
        _recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:recordSetting error:NULL];
        _recorder.delegate = self;
        _recorder.meteringEnabled = YES;
        
        [_recorder prepareToRecord];
    }
    return _recorder;
}

- (void)destructionRecordingFile {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (self.recordFileUrl) {
        [fileManager removeItemAtURL:self.recordFileUrl error:NULL];
    }
}


#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        [self.session setActive:NO error:nil];
    }
}

@end
