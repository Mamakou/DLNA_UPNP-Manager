//
//  YMUpnpDevice.h
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMUpnpManager.h"

@class YMServerModel;

/**
 设备模型
 */
@interface YMUpnpDevice : NSObject

@property (nonatomic, copy) NSString    *uuid;
@property (nonatomic, strong) NSURL     *loaction;
@property (nonatomic, copy,readonly) NSString    *URLHeader;

@property (nonatomic, copy) NSString *friendlyName;
@property (nonatomic, copy) NSString *modelName;

@property (nonatomic, strong) YMServerModel *AVTransport;
@property (nonatomic, strong) YMServerModel *RenderingControl;

/**控制访问路径*/
-(NSString*)controlURLWithServerType:(YMUpnpServerType)serverType;

/**订阅访问路径*/
- (NSString*)eventSubURLWithServerType:(YMUpnpServerType)serverType;

/**遍历设备下面的xml数据*/
- (void)setArray:(NSArray *)array;

@end


/**
 设备里面的服务模型
 */
@interface YMServerModel : NSObject

///服务类型
@property (nonatomic, copy) NSString *serviceType;
///服务id
@property (nonatomic, copy) NSString *serviceId;
///控制事件的地址
@property (nonatomic, copy) NSString *controlURL;
///订阅事件的地址
@property (nonatomic, copy) NSString *eventSubURL;
///获取设备描述文档URL
@property (nonatomic, copy) NSString *SCPDURL;

/**遍历设备下面的xml数据*/
- (void)setArray:(NSArray *)array;

@end
