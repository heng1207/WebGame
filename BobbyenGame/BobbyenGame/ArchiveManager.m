//
//  ArchiveManager.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/20.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "ArchiveManager.h"

typedef void (^ManagerStringBlock)(NSString *string);
@interface ArchiveManager()<SSZipArchiveDelegate>

@end

@implementation ArchiveManager

/* 单例控制器 */
+ (instancetype)manager {
    return [[self alloc] init];
}

static ArchiveManager *instance = nil;
static dispatch_once_t onceToken;
- (instancetype)init {
    dispatch_once(&onceToken, ^{
        instance = [super init];
        
        self.cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        self.fileManager = [NSFileManager defaultManager];
        self.manager = [AFHTTPSessionManager manager];
    });
    return instance;
}


#pragma mark - 从Url获取对应文件
-(void)startRequestAndUnzip:(NSString *)urlString
{
    __weak __typeof(self)weakSelf = self;
    // 定义文件夹名称。压缩包名为文件夹名称
    NSString *folderName = [[urlString lastPathComponent] stringByDeletingPathExtension];
    // 文件夹路径
    NSString *folderPath = [_cachesPath stringByAppendingPathComponent:folderName];
    
    //删除以保存的文件
    NSError *error;
    [_fileManager removeItemAtPath:folderPath error:&error];
    
    
    if ([self directoryExists:folderPath]) {
        // 存在文件夹则之间返回
        if (self.resourceBlock) {
            self.resourceBlock(folderPath);
        }
    }else{
        // 不存在文件夹则下载、创建、解压
        [self downloadField:urlString block:^(NSString *filePath) {
            if (filePath) {
                NSString *resultPath = [self.cachesPath stringByAppendingPathComponent:folderName];
                if ([weakSelf createFolderWithPath:resultPath]) {
                    [weakSelf releaseZipFiles:filePath unzipPath:resultPath];
                }else{
            
                // 创建文件夹失败
                }
            }else{
                // 下载文件失败
            }
        }];
    }
}


#pragma mark - 从Url获取对应文件
- (void)startRequest:(NSString *)urlString
{
    __weak __typeof(self)weakSelf = self;
    // 定义文件夹名称。压缩包名为文件夹名称
    NSString *folderName = [[urlString lastPathComponent] stringByDeletingPathExtension];
    // 文件夹路径
    NSString *folderPath = [_cachesPath stringByAppendingPathComponent:folderName];
    
    if ([self directoryExists:folderPath]) {
        // 存在文件夹则之间返回
        if (self.resourceBlock) {
            self.resourceBlock(folderPath);
        }
    }else{
        // 不存在文件夹则下载、创建、解压
        [self downloadField:urlString block:^(NSString *filePath) {
            if (filePath) {
                weakSelf.resourceBlock(filePath);
            }else{
                // 下载文件失败
            }
        }];
    }
}

#pragma mark - 文件处理
#pragma mark 检测目录文件夹是否存在
/**
 检测目录文件夹是否存在
 
 @param directoryPath 目录路径
 @return 是否存在
 */
- (BOOL)directoryExists:(NSString *)directoryPath
{
    BOOL isDir = NO;
    BOOL isDirExist = [_fileManager fileExistsAtPath:directoryPath isDirectory:&isDir];
    if (isDir && isDirExist) {
        return YES;
    }else{
        return NO;
    }
}

#pragma mark 获取文件夹下所有文件列表。
- (NSArray *)fileList:(NSString *)directoryPath
{
    return [[_fileManager contentsOfDirectoryAtPath:directoryPath error:nil] mutableCopy];
}

#pragma mark 创建文件夹。下载完文件，文件需要解压到这个文件夹
- (BOOL)createFolderWithPath:(NSString *)folderPath
{
    // 在路径下创建文件夹
    return [_fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
}


#pragma mark 下载文件。目录文件夹不存在，那么这步
- (void)downloadField:(NSString *)urlString block:(ManagerStringBlock)block
{
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    // 下载文件
    /**
     * 第一个参数 - request：请求对象
     * 第二个参数 - progress：下载进度block
     *      其中： downloadProgress.completedUnitCount：已经完成的大小
     *            downloadProgress.totalUnitCount：文件的总大小
     * 第三个参数 - destination：自动完成文件剪切操作
     *      其中： 返回值:该文件应该被剪切到哪里
     *            targetPath：临时路径 tmp NSURL
     *            response：响应头
     * 第四个参数 - completionHandler：下载完成回调
     *      其中： filePath：真实路径 == 第三个参数的返回值
     *            error:错误信息
     */
    [[_manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"下载进度：%.0f％", downloadProgress.fractionCompleted * 100);
        if (self.progressBlock) {
            self.progressBlock(downloadProgress.fractionCompleted * 100);
        }
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        NSString *fullPath = [self.cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        
        // 返回一个URL, 返回的这个URL就是文件的位置的完整路径
        return [NSURL fileURLWithPath:fullPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (block) {
            block([filePath path]);
        }
    }] resume];
}

#pragma mark - SSZipArchive
#pragma mark 解压
- (void)releaseZipFiles:(NSString *)zipPath unzipPath:(NSString *)unzipPath{
    if ([SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath delegate:self]) {
        
    }else {
        // NSLog(@"解压失败");
    }
}

#pragma mark SSZipArchiveDelegate
- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath
{
    // 解压会出现多余的文件夹__MACOSX，删除掉吧
    NSString *invalidFolder = [unzippedPath stringByAppendingPathComponent:@"__MACOSX"];
    [_fileManager removeItemAtPath:invalidFolder error:nil];
    
    //删除zip包
    NSError *error;
    [_fileManager removeItemAtPath:path error:&error];
    
    if (self.resourceBlock) {
        self.resourceBlock(unzippedPath);
    }
}


-(void)unzipFile:(NSString *)zipURL{
    // 定义文件夹名称。压缩包名为文件夹名称
    NSString *folderName = [[zipURL lastPathComponent] stringByDeletingPathExtension];
    NSString *resultPath = [self.cachesPath stringByAppendingPathComponent:folderName];
    if ([self createFolderWithPath:resultPath]) {
            [self releaseZipFiles:zipURL unzipPath:resultPath];
    }else{
       // 创建文件夹失败
    }
}



@end
