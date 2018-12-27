//
//  Tool.h
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/24.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tool : NSObject

#pragma mark 字典转化字符串
+(NSString*)dictionaryToJson:(NSDictionary *)dic;
#pragma 字符串转字典
+(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
    
@end

NS_ASSUME_NONNULL_END
