//
//  ArchiveManager.h
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/20.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ManagerResourceLocalPathBlock)(NSString *localPath);
typedef void (^ManagerDownloadProgress)(double progress);

@interface ArchiveManager : NSObject

@property (nonatomic, strong) NSString *cachesPath;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, copy)   ManagerResourceLocalPathBlock resourceBlock;
@property (nonatomic, copy)   ManagerDownloadProgress progressBlock;


+ (instancetype)manager;

//下载同时包括解压
- (void)startRequestAndUnzip:(NSString *)urlString;
//下载
- (void)startRequest:(NSString *)urlString;
//解压
- (void)unzipFile:(NSString *)zipURL;


@end

NS_ASSUME_NONNULL_END
