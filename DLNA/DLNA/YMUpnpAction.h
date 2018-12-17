//
//  YMUpnpAction.h
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//
/***
 发送post 数据的格式
 
 POST <control URL> HTTP/1.0
 Host: hostname:portNumber
 Content-Lenght: byte in body
 Content-Type: text/xml; charset="utf-8"
 SOAPACTION: "urn:schemas-upnp-org:service:serviceType:v#actionName"
 <!--必有字段-->
 <?xml version="1.0" encoding="utf-8"?>
 <!--SOAP必有字段-->
 <s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
      <s:Body>
         <!--Body内部分根据不同动作不同-->
         <!--动作名称-->
         <u:actionName xmlns:u="urn:schemas-upnp-org:service:serviceType:v">
           <!--输入参数名称和值-->
           <argumentName>in arg values</argumentName>
           <!--若有多个参数则需要提供-->
         </u:actionName>
       </s:Body>
 </s:Envelope>
 */

/**
 各种动作说明
 
 1、设置播放资源URI
   名称:SetAVTransportURI 响应:SetAVTransportURIResponse
 
    参数:
    InstanceID：设置当前播放时期时为 0 即可。
    CurrentURI： 播放资源URI
    CurrentURIMetaData： 媒体meta数据，可以为空
    Header_SOAPACTION： “urn:upnp-org:serviceId:AVTransport#SetAVTransportURI”
 
 2、播放
    名称：Play    响应:PlayResponse
 
    参数：
    InstanceID：设置当前播放时期时为 0 即可。
    Speed：播放速度，默认传 1 。
    Header_SOAPACTION： “urn:upnp-org:serviceId:AVTransport#Pause”
 
 3、暂停
   名称：Pause   响应：PlayResponse
   参数：
   InstanceID：设置当前播放时期时为 0 即可。
   Header_SOAPACTION： “urn:upnp-org:serviceId:AVTransport#Pause”
 
 4、获取播放进度
    名称：GetPositionInfo。  响应：GetPositionInfoResponse
    参数：
    InstanceID：设置当前播放时期时为 0 即可。
    MediaDuration： 可以为空。
    Header_SOAPACTION： “urn:upnp-org:serviceId:AVTransport#MediaDuration”
 
 5、跳转至特定进度或视频
    名称：Seek。  响应：SeekResponse
    参数：
    InstanceID: 一般为 0 。
    Unit：REL_TIME（跳转到某个进度）或 TRACK_NR（跳转到某个视频）。
    Target： 目标值，可以是 00:02:21 格式的进度或者整数的 TRACK_NR。
    Header_SOAPACTION： “urn:upnp-org:serviceId:AVTransport#Seek”
 
 
 
 
 
 */




#import <Foundation/Foundation.h>
#import "YMUpnpManager.h"


@interface YMUpnpAction : NSObject
/**
 根据操作的动作 生成对象，注意，这里的ac
 */
-(instancetype)initWithAction:(NSString*)action;

///控制动作所对应的服务类型，具体根据设备来定义
@property (nonatomic,assign)YMUpnpServerType serverType;

@property (nonatomic,copy,readonly)NSString *action;

///给xml数据设置参数 dlna协议基本上是基于xml传输的
- (void)setParamsElement:(NSString*)value name:(NSString*)name;

/**
 SOAPACTION: "urn:schemas-upnp-org:service:serviceType:v#actionName"
 */
- (NSString*)soapAction;
/**
 最终需要上传的xmlz格式字符串
 */
- (NSString *)postXMLFile;



@end


