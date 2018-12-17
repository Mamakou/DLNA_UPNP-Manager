//
//  YMUpnpRender.h
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMUpnpDevice.h"

@class YMUpnpRender,YMUpnpResponse;

/***
 upnp 渲染器 其实本身就是设备 负责播放等操作的主体
 注意，一般的使用场景 中的渲染器 就是一些，播放、暂停、快进、音量等操作
 如果需要为特定的设备增加一些功能操作，可以自行添加，根据serviceId定义的即可，当然既然是特定的设备且特点的功能，这些字段应该是提前知道的
 
 */
@interface YMUpnpRender : NSObject

/**
 在搜索设备并选定后，便可以初始化一个渲染器了
 */
-(instancetype)initWithDevice:(YMUpnpDevice*)device;

@property (nonatomic,strong)YMUpnpDevice *device;

/**订阅后存储的sid，一个设备可以有多个服务，所以理论上存在可以订阅多个*/
@property (nonatomic,strong,readonly)NSMutableDictionary *subscribeSidDict;

/**
 设置投屏地址
 */
- (void)setAVTransportURIStr:(NSString *)uriStr result:(YMUpnpResultBlock)result;

/**
 设置 下一个 投屏地址，播放的为uristr的下一个
 */
- (void)setNextAVTransportURIStr:(NSString *)uriStr result:(YMUpnpResultBlock)result;

/**
 播放
 */
- (void)playWithResult:(YMUpnpResultBlock)result;

/**
 暂停
 */
- (void)pauseWithResult:(YMUpnpResultBlock)result;

/**
 停止播放
 */
- (void)stopWithResult:(YMUpnpResultBlock)result;

/**
 下一个
 */
- (void)nextWithResult:(YMUpnpResultBlock)result;

/**
 上一个
 */
- (void)previousWithResult:(YMUpnpResultBlock)result;


///**
// 获取播放进度,本来相应block回掉完成数据获取，但是没有一个一对一的数据标记，好像比较难实现，有时间研究下，假如我传入一个特点数据，响应不管是失败还是成功如果可以回传过来，则可以实现
//
// @param response 回掉
// */
//- (void)getPlayProgress:(void(^)(YMUpnpResponse*response,BOOL success))response;


/**
 获取当前进度
 */
- (void)getPlayProgressWithResult:(YMUpnpResultBlock)result;

/**
 获取当前播放状态
 */
- (void)getTransportInfoWithResult:(YMUpnpResultBlock)result;

/**
 获取音量
 */
- (void)getVolumeWithResult:(YMUpnpResultBlock)result;

/**
 设置指定音量

 @param value 音量
 */
- (void)setVolumeWith:(NSString *)value result:(YMUpnpResultBlock)result;

/**
 跳转进度
 @param relTime 进度时间(单位秒)
 */
- (void)seek:(float)relTime result:(YMUpnpResultBlock)result;

/**
 跳转至特定进度或视频
 @param target 目标值，可以是 00:02:21 格式的进度或者整数的 TRACK_NR。
 @param unit   REL_TIME（跳转到某个进度）或 TRACK_NR（跳转到某个视频）。
 */
- (void)seekToTarget:(NSString *)target Unit:(NSString *)unit result:(YMUpnpResultBlock)result;


/**
 针对某项服务发送订阅消息

 @param time 订阅多久时间
 @param serverType 服务类型
 @param callBack 数据回调的链接地址，这里采用了GCDWebServer获取回调，但是demo中的不知道对不对哈
 */
- (void)sendSubscribeRequestWithTime:(int)time serverType:(YMUpnpServerType)serverType callBack:(NSString*)callBack result:(void(^)(BOOL success))result;

/**
 续订某项服务
 注意:要在之前订阅的时间之前发起，否则无效
 @param time 续订的时间
 @param serverType 服务类型
 */
- (void)contractSubscirbeWithTime:(int)time serverType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result;

/**
 移除针对某项服务的订阅

 @param serverType 服务类型
 */
- (void)removeSubscribeWithServerType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result;


@end


