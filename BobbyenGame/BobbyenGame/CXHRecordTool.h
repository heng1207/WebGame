//
//  CXHRecordTool.h
//  Demo_RecordAndPlayVoice
//
//  Created by Ihefe_Hanrovey on 2016/11/3.
//  Copyright © 2016年 Ihefe_Hanrovey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface CXHRecordTool : NSObject

/** 录音对象 */
@property (nonatomic, strong) AVAudioRecorder *recorder;
/** 播放器对象 */
@property (nonatomic, strong) AVAudioPlayer *player;

/** caf录音文件地址 */
@property (nonatomic, strong) NSURL *recordFileUrl;
/** mp3录音文件地址 */
@property (nonatomic, strong) NSURL *recordMP3FileUrl;

/** 录音工具的单例 */
+ (instancetype)sharedRecordTool;

/** 开始录音 */
- (void)startRecording;

/** 停止录音 */
- (void)stopRecording;

/** 播放录音文件 */
- (void)playRecordingFile;

/** 停止播放录音文件 */
- (void)stopPlaying;

/** 销毁录音文件 */
- (void)destructionRecordingFile;



@end
