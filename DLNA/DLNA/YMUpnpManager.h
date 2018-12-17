//
//  YMUpnpManager.h
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//
// 参考文档： https://eliyar.biz/DLNA_with_iOS_Android_Part_1_Find_Device_Using_SSDP/

/***
 SSDP 设备类型
 
 设备类型                             表示文字(ST：对应的名称)
 UPnP_RootDevice                    upnp:rootdevice
 UPnP_InternetGatewayDevice1        urn:schemas-upnp-org:device:InternetGatewayDevice:1
 UPnP_WANConnectionDevice1          urn:schemas-upnp-org:device:WANConnectionDevice:1
 UPnP_WANDevice1                    urn:schemas-upnp-org:device:WANConnectionDevice:1
 UPnP_WANCommonInterfaceConfig1     urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1
 UPnP_WANIPConnection1              urn:schemas-upnp-org:device:WANConnectionDevice:1
 UPnP_Layer3Forwarding1             urn:schemas-upnp-org:service:WANIPConnection:1
 UPnP_WANConnectionDevice1          urn:schemas-upnp-org:service:Layer3Forwarding:1
 */

/***
 SSDP 服务类型
 
 服务类型                             表示文字(ST：对应的名称)
 UPnP_MediaServer1                   urn:schemas-upnp-org:device:MediaServer:1
 UPnP_MediaRenderer1                 urn:schemas-upnp-org:device:MediaRenderer:1
 UPnP_ContentDirectory1              urn:schemas-upnp-org:service:ContentDirectory:1
 UPnP_RenderingControl1              urn:schemas-upnp-org:service:RenderingControl:1
 UPnP_ConnectionManager1             urn:schemas-upnp-org:service:ConnectionManager:1
 UPnP_AVTransport1                   urn:schemas-upnp-org:service:AVTransport:1
 
 */

/***
 当设备添加到网络后，定期向（239.255.255.250:1900）发送SSDP通知消息宣告自己的设备和服务。
 
 宣告消息分为 ssdp:alive(设备可用) 和 ssdp:byebye(设备不可用)
 ssdp:alive 消息
 NOTIFY * HTTP/1.1           // 消息头
 NT:                         // 在此消息中，NT头必须为服务的服务类型。（如：upnp:rootdevice）
 HOST:                       // 设置为协议保留多播地址和端口，必须是：239.255.255.250:1900（IPv4）或FF0x::C(IPv6
 NTS:                        // 表示通知消息的子类型，必须为ssdp:alive
 LOCATION:                   // 包含根设备描述得URL地址  device 的webservice路径（如：http://127.0.0.1:2351/1.xml)
 CACHE-CONTROL:              // max-age指定通知消息存活时间，如果超过此时间间隔，控制点可以认为设备不存在 （如：max-age=1800）
 SERVER:                     // 包含操作系统名，版本，产品名和产品版本信息( 如：Windows NT/5.0, UPnP/1.0)
 USN:                        // 表示不同服务的统一服务名，它提供了一种标识出相同类型服务的能力。如：
 // 根/启动设备 uuid:f7001351-cf4f-4edd-b3df-4b04792d0e8a::upnp:rootdevice
 // 连接管理器  uuid:f7001351-cf4f-4edd-b3df-4b04792d0e8a::urn:schemas-upnp-org:service:ConnectionManager:1
 // 内容管理器 uuid:f7001351-cf4f-4edd-b3df-4b04792d0e8a::urn:schemas-upnp-org:service:ContentDirectory:1
 
 */


/***
 ssdp:byebye 消息
 NOTIFY * HTTP/1.1       // 消息头
 HOST:                   // 设置为协议保留多播地址和端口，必须是：239.255.255.250:1900（IPv4）或FF0x::C(IPv6
 NTS:                    // 表示通知消息的子类型，必须为ssdp:byebye
 USN:                    // 同上
 
 */


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

////服务类型，这里根据大众化只定义了两个，其实可以更多，具体根据设备来定义
typedef NS_ENUM(NSInteger, YMUpnpServerType) {
    /**投屏*/
    ServerTypeAVTransport = 0,
    /**控制*/
    ServerTypeRenderingControl,      
    
};

UIKIT_EXTERN NSString * const ServiceTypeAVTransport;
UIKIT_EXTERN NSString * const ServiceTypeRenderControl;

UIKIT_EXTERN NSString * const ServiceIdAVTransport;
UIKIT_EXTERN NSString * const ServiceIdRenderControl;



@class YMUpnpDevice,YMUpnpManager,YMUpnpResponse;

typedef void(^YMUpnpResultBlock)(YMUpnpResponse*response,BOOL success);

@protocol YMUpnpManagerDelegate <NSObject>

@optional

/**
 搜索结果

 @param manager manager
 @param devices 搜索到的设备
 */
- (void)upnpManager:(YMUpnpManager*)manager searchResults:(NSArray<YMUpnpDevice*>*)devices;

/**
 当前选中的设备将要消失，由于设备本身的关系
 只针对当前选中的设备
 @param manager manager
 @param device 设备
 */
- (void)upnpManager:(YMUpnpManager*)manager conectedDeviceWillDismiss:(YMUpnpDevice*)device;


@end



NS_ASSUME_NONNULL_BEGIN

@interface YMUpnpManager : NSObject

+ (instancetype)manager;

/**
 
 开始搜索；这里只采用多播搜索模式，格式如下:
 M-SEARCH * HTTP/1.1             // 请求头 不可改变
 MAN: "ssdp:discover"            // 设置协议查询的类型，必须是：ssdp:discover
 MX: 5                           // 设置设备响应最长等待时间，设备响应在0和这个值之间随机选择响应延迟的值。这样可以为控制点响应平衡网络负载。
 HOST: 239.255.255.250:1900      // 设置为协议保留多播地址和端口，必须是：239.255.255.250:1900（IPv4）或FF0x::C(IPv6
 ST: upnp:rootdevice             // 设置服务查询的目标，它必须是下面的类型：
                                 // ssdp:all  搜索所有设备和服务
                                 // upnp:rootdevice  仅搜索网络中的根设备
                                 // uuid:device-UUID  查询UUID标识的设备
                                 // urn:schemas-upnp-org:device:device-Type:version  查询device-Type字段指定的设备类型，设备类型和版本由UPNP组织定义。
                                 // urn:schemas-upnp-org:service:service-Type:version  查询service-Type字段指定的服务类型，服务类型和版本由UPNP组织定义。
 
 
 */
- (void)startSearch;


/**
 停止dlna功能模块
 */
- (void)stopDLNAServer;

@property (nonatomic,weak)id <YMUpnpManagerDelegate>delegate;

/**
 选择具体的设备，
 在真实场景中，可能存在有多个服务设备，这个时候必须选中一个进行接下来的交互，
 如果这步没有进行，则接下来的步骤将无法进行
 */
- (void)selectedDevice:(YMUpnpDevice*)device;


/**
 设置播放资源

 @param uriStr 资源播放uri
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
 获取当前进度 需要进一步研究，如果能使用block肯定采取block回掉的方式，但是目前只能通过代理获取
 */
- (void)getPlayProgressWithResult:(YMUpnpResultBlock)result;

/**
 获取当前播放状态 需要进一步研究，如果能使用block肯定采取block回掉的方式，但是目前只能通过代理获取
 */
- (void)getTransportInfoWithResult:(YMUpnpResultBlock)result;

/**
 获取音量 需要进一步研究，如果能使用block肯定采取block回掉的方式，但是目前只能通过代理获取
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
 发送订阅消息

 @param time 订阅事件
 @param callBack 回调地址
 @param serverType 服务类型
 接收回调会在内部建立一个http server,需要保存sid
 
 */
- (void)sendSubcirbeWithTime:(int)time callBack:(NSString*)callBack serverType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result;

/**
 续订某项服务
 注意:要在之前订阅的时间之前发起，否则无效
 @param time 续订的时间
 @param serverType 服务类型
 */
- (void)contractSubscirbeWithTime:(int)time serverType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result;
/**
 移除订阅

 @param serverType 服务类型
 */
- (void)removeSubscirbeWithServerType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result;

@end

NS_ASSUME_NONNULL_END
