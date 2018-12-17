//
//  YMUpnpManager.m
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//

#import "YMUpnpManager.h"
#import "GCDAsyncUdpSocket.h"
#import "GDataXMLNode.h"
#import "YMUpnpDevice.h"
#import "YMUpnpRender.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

#define SSD_ADDRESS @"239.255.255.250"
#define SSD_PORT 1900
#define SSD_SEARCH_FILE @"M-SEARCH * HTTP/1.1\r\nHOST: %@:%d\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: %@\r\nUSER-AGENT: iOS UPnP/1.1 TestApp/1.0\r\n\r\n"



NSString * const ServiceTypeAVTransport = @"urn:schemas-upnp-org:service:AVTransport:1";
NSString * const ServiceTypeRenderControl = @"urn:schemas-upnp-org:service:RenderingControl:1";

NSString * const ServiceIdAVTransport = @"urn:upnp-org:serviceId:AVTransport";
NSString * const ServiceIdRenderControl = @"urn:upnp-org:serviceId:RenderingControl";


@interface YMUpnpManager ()<GCDAsyncUdpSocketDelegate>

@property (nonatomic,strong)NSMutableDictionary <NSString *, YMUpnpDevice *>*deviceDict;

@property (nonatomic,strong)GCDAsyncUdpSocket *udpSocket;

@property (nonatomic,strong) dispatch_queue_t queue;
/**
 渲染器
 */
@property (nonatomic,strong)YMUpnpRender *render;

@property (nonatomic,strong)GCDWebServer *webServer;

@end


@implementation YMUpnpManager

#pragma mark - init 初始化方法

+(instancetype)manager
{
    static YMUpnpManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YMUpnpManager alloc]init];
    });
    return manager;
}

-(NSMutableDictionary<NSString *,YMUpnpDevice *> *)deviceDict
{
    if(!_deviceDict){
        _deviceDict = [NSMutableDictionary dictionary];
    }
    return _deviceDict;
}

-(instancetype)init
{
    self = [super init];
    if(self){
        self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        _queue = dispatch_queue_create("ym.upnp.dlna", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


#pragma mark - upd 搜索 发送SSDP 搜索消息

-(NSString *)getSearchFile
{
    NSString * searchFileSource = @"M-SEARCH * HTTP/1.1\r\nHOST: %@:%d\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: %@\r\nUSER-AGENT: iOS UPnP/1.1 TestApp/1.0\r\n\r\n";
    return [NSString stringWithFormat:searchFileSource,SSD_ADDRESS,SSD_PORT,ServiceTypeAVTransport];
}

///这里以搜索投屏服务为准
- (void)startSearch
{
    if(!self.udpSocket){
        self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    if(!_queue){
        _queue = dispatch_queue_create("ym.upnp.dlna", DISPATCH_QUEUE_SERIAL);
    }
    NSError * error;
    NSData * searchData = [[self getSearchFile] dataUsingEncoding:NSUTF8StringEncoding];
    if(![self.udpSocket bindToPort:SSD_PORT error:&error]){
        
        return;
    }
    if(![self.udpSocket joinMulticastGroup:SSD_ADDRESS error:&error]){
        
        return;
    }
    ///搜索设备的时候，先将之前的清除
    [self.deviceDict removeAllObjects];
    if(self.render){
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.delegate && [self.delegate respondsToSelector:@selector(upnpManager:conectedDeviceWillDismiss:)]){
                [self.delegate upnpManager:self conectedDeviceWillDismiss:self.render.device];
            }
            self.render = nil;
        });
    }
    
    [self.udpSocket sendData:searchData toHost:SSD_ADDRESS port:SSD_PORT withTimeout:0 tag:1];
    [self.udpSocket beginReceiving:&error];
    if(error){
        
    }
    
    
}




#pragma mark - GCDAsyncUdpSocketDelegate upd 回掉
/**
 * By design, UDP is a connectionless protocol, and connecting is not needed.
 * However, you may optionally choose to connect to a particular host for reasons
 * outlined in the documentation for the various connect methods listed above.
 *
 * This method is called if one of the connect methods are invoked, and the connection is successful.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    
}

/**
 * By design, UDP is a connectionless protocol, and connecting is not needed.
 * However, you may optionally choose to connect to a particular host for reasons
 * outlined in the documentation for the various connect methods listed above.
 *
 * This method is called if one of the connect methods are invoked, and the connection fails.
 * This may happen, for example, if a domain name is given for the host and the domain name is unable to be resolved.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error
{
    
}

/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"upd消息已经发送...");
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    
}

/**
 设备返回数据样本:
 HTTP/1.1 200 OK             // * 消息头
 LOCATION:                   // * 包含根设备描述得URL地址  device 的webservice路径（如：http://127.0.0.1:2351/1.xml)
 CACHE-CONTROL:              // * max-age指定通知消息存活时间，如果超过此时间间隔，控制点可以认为设备不存在 （如：max-age=1800）
 SERVER:                     // 包含操作系统名，版本，产品名和产品版本信息( 如：Windows NT/5.0, UPnP/1.0)
 EXT:                        // 为了符合HTTP协议要求，并未使用。
 BOOTID.UPNP.ORG:            // 可以不存在，初始值为时间戳，每当设备重启并加入到网络时+1，用于判断设备是否重启。也可以用于区分多宿主设备。
 CONFIGID.UPNP.ORG:          // 可以不存在，由两部分组成的非负十六进制整数，由两部分组成，第一部分代表跟设备和其上的嵌入式设备，第二部分代表这些设备上的服务
 USN:                        // * 表示不同服务的统一服务名
 ST:                         // * 服务的服务类型
 DATE:                       // 响应生成时间
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext
{
    //这里需要注意，一般当成 一次性接收完数据，在tcp的时候会存在这种情况，udp目前还没出现过数据分段接受的
    //这里返回的数据较少，无法真是显示完全一个设备该表达的信息，所以需要再次获取设备信息，发送http数据即可
    [self adjustDeviceWithData:data];
    
}

/**
 * Called when the socket is closed.
 **/
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
    
}


#pragma mark - 解析UPD收到的信息

- (void)adjustDeviceWithData:(NSData*)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([string hasPrefix:@"NOTIFY"]){//说明是广播消息
        //则分为 ssdp:alive 消息 和 ssdp:byebye 消息
        //// 在此消息中，NT头必须为服务的服务类型。（如：upnp:rootdevice）
        NSString *serviceType = [self headerValueForKey:@"NT:" inData:string];
        if([serviceType isEqualToString:ServiceTypeAVTransport]){
            NSString *location = [self headerValueForKey:@"Location:" inData:string];
            if(location == nil){
                location = [self headerValueForKey:@"LOCATION:" inData:string];
            }
            NSString *usn = [self headerValueForKey:@"USN:" inData:string];
            NSString *ssdp = [self headerValueForKey:@"NTS:" inData:string];
            if ([self isNilString:ssdp]) {
                return;
            }
            if ([self isNilString:usn]) {
                return;
            }
            if ([self isNilString:location]) {
                return;
            }
            if([ssdp isEqualToString:@"ssdp:alive"]){
                dispatch_async(_queue, ^{
                    if([self.deviceDict valueForKey:usn] == nil){
                       YMUpnpDevice *device = [self getDeviceWithLocation:location withUSN:usn];
                        if(device){
                             [self.deviceDict setValue:device forKey:usn];
                             [self deviceUpdated];
                        }
                    }
                });
            }else if ([ssdp isEqualToString:@"ssdp:byebye"]){
                dispatch_async(_queue, ^{
                    [self removeDeviceWithUsn:usn];
                });
            }
        }
    }else if ([string hasPrefix:@"HTTP/1.1"]){//搜索消息之后的回应
        NSString *location = [self headerValueForKey:@"Location:" inData:string];
        if(location == nil){
            location = [self headerValueForKey:@"LOCATION:" inData:string];
        }
        NSString *usn = [self headerValueForKey:@"USN:" inData:string];
        if ([self isNilString:usn]) {
            return;
        }
        if ([self isNilString:location]) {
            return;
        }
        dispatch_async(_queue, ^{
            if([self.deviceDict valueForKey:usn] == nil){
                YMUpnpDevice *device = [self getDeviceWithLocation:location withUSN:usn];
                if(device){
                    [self.deviceDict setValue:device forKey:usn];
                    [self deviceUpdated];
                }
            }
        });
    }
    
    
}

#pragma mark - private 内部方法
- (NSString *)headerValueForKey:(NSString *)key inData:(NSString *)data
{
    NSString *str = [NSString stringWithFormat:@"%@", data];
    NSRange keyRange = [str rangeOfString:key options:NSCaseInsensitiveSearch];
    if (keyRange.location == NSNotFound){
        return @"";
    }
    str = [str substringFromIndex:keyRange.location + keyRange.length];
    NSRange enterRange = [str rangeOfString:@"\r\n"];
    NSString *value = [[str substringToIndex:enterRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return value;
}

- (BOOL)isNilString:(NSString *)str
{
    if(str == nil){
        return YES;
    }
    if (![str isKindOfClass:[NSString class]]) {
        return YES;
    }
    if(str.length == 0){
        return YES;
    }
    if([str isEqualToString:@"(null)"] || [str isEqualToString:@"<null>"]){
        return YES;
    }
    return NO;
}

///发送ssdp消息后，对设备返回的消息进行解析，获取locationurl,以便进一步获取设备的详细信息

- (YMUpnpDevice *)getDeviceWithLocation:(NSString *)location withUSN:(NSString *)usn
{
    dispatch_semaphore_t seamphore = dispatch_semaphore_create(0);
    
    __block YMUpnpDevice *device = nil;
    NSURL *URL = [NSURL URLWithString:location];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    request.HTTPMethod = @"GET";
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            
        }else{
            if (response != nil && data != nil) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] == 200) {
                    device = [[YMUpnpDevice alloc] init];
                    device.loaction = URL;
                    device.uuid = usn;
                    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:data options:0 error:nil];
                    GDataXMLElement *xmlEle = [xmlDoc rootElement];
                    NSArray *xmlArray = [xmlEle children];
                    
                    for (int i = 0; i < [xmlArray count]; i++) {
                        GDataXMLElement *element = [xmlArray objectAtIndex:i];
                        if ([[element name] isEqualToString:@"device"]) {
                            [device setArray:[element children]];
                            continue;
                        }
                    }
                }
            }
        }
        dispatch_semaphore_signal(seamphore);
    }] resume];
    dispatch_semaphore_wait(seamphore, DISPATCH_TIME_FOREVER);
    return device;
}

- (void)removeDeviceWithUsn:(NSString*)usn
{
    YMUpnpDevice *device = [self.deviceDict valueForKey:usn];
    if(device){
        if(self.render && [self.render.device.uuid isEqualToString:device.uuid]){
            dispatch_async(dispatch_get_main_queue(), ^{
                if(self.delegate && [self.delegate respondsToSelector:@selector(upnpManager:conectedDeviceWillDismiss:)]){
                    [self.delegate upnpManager:self conectedDeviceWillDismiss:device];
                }
                self.render = nil;
            });
        }
        [self.deviceDict removeObjectForKey:usn];
        [self deviceUpdated];
    }
}


- (void)deviceUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.delegate && [self.delegate respondsToSelector:@selector(upnpManager:searchResults:)]){
            [self.delegate upnpManager:self searchResults:self.deviceDict.allValues];
        }
    });
}




#pragma mark - public 外部接口方法

#pragma mark - 停止dlna服务
- (void)stopDLNAServer
{
    self.render = nil;
    self.udpSocket.delegate = nil;
    self.udpSocket = nil;
    if(self.webServer){
        [self.webServer stop];
    }
}


#pragma mark - 选中设备
- (void)selectedDevice:(YMUpnpDevice*)device
{
    if(device == nil)return;
    ///在切换渲染器后，必须移除代理，并建立新的代理关系
    self.render = [[YMUpnpRender alloc]initWithDevice:device];
   
}

- (void)setAVTransportURIStr:(NSString *)uriStr result:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render setAVTransportURIStr:uriStr result:result];
}

/**
 设置 下一个 投屏地址，播放的为uristr的下一个
 */
- (void)setNextAVTransportURIStr:(NSString *)uriStr result:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render setNextAVTransportURIStr:uriStr result:result];
}

/**
 播放
 */
- (void)playWithResult:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render playWithResult:result];
}

/**
 暂停
 */
- (void)pauseWithResult:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render pauseWithResult:result];
}

/**
 停止播放
 */
- (void)stopWithResult:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render stopWithResult:result];
}

/**
 下一个
 */
- (void)nextWithResult:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render nextWithResult:result];
}

/**
 上一个
 */
- (void)previousWithResult:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render previousWithResult:result];
}


///**
// 获取播放进度,本来相应block回掉完成数据获取，但是没有一个一对一的数据标记，好像比较难实现，有时间研究下，假如我传入一个特点数据，响应不管是失败还是成功如果可以回传过来，则可以实现
//
// @param response 回掉
// */
//- (void)getPlayProgress:(void(^)(YMUpnpResponse*response,BOOL success))response;


/**
 获取当前进度
 */
- (void)getPlayProgressWithResult:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render getPlayProgressWithResult:result];
}

/**
 获取当前播放状态
 */
- (void)getTransportInfoWithResult:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render getTransportInfoWithResult:result];
    
}

/**
 获取音量
 */
- (void)getVolumeWithResult:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render getVolumeWithResult:result];
}

/**
 设置指定音量
 
 @param value 音量
 */
- (void)setVolumeWith:(NSString *)value result:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render setVolumeWith:value result:result];
}

/**
 跳转进度
 @param relTime 进度时间(单位秒)
 */
- (void)seek:(float)relTime result:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render seek:relTime result:result];
}

/**
 跳转至特定进度或视频
 @param target 目标值，可以是 00:02:21 格式的进度或者整数的 TRACK_NR。
 @param unit   REL_TIME（跳转到某个进度）或 TRACK_NR（跳转到某个视频）。
 */
- (void)seekToTarget:(NSString *)target Unit:(NSString *)unit result:(YMUpnpResultBlock)result
{
    if(self.render == nil)return;
    [self.render seekToTarget:target Unit:unit result:result];
}


- (void)sendSubcirbeWithTime:(int)time callBack:(NSString*)callBack serverType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result;
{
    if(self.render == nil)return;
    [self.render sendSubscribeRequestWithTime:time serverType:serverType callBack:callBack result:result];
    [self startWebServer];
}

- (void)contractSubscirbeWithTime:(int)time serverType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result
{
    if(self.render == nil)return;
    [self.render contractSubscirbeWithTime:time serverType:serverType result:result];
    
}

- (void)removeSubscirbeWithServerType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result
{
    if(self.render == nil)return;
    [self.render removeSubscribeWithServerType:serverType result:result];
}



///启动web服务
- (void)startWebServer
{
    if(!self.webServer){
        self.webServer = [[GCDWebServer alloc]init];
        __weak typeof(self)weakSelf = self;
        [self.webServer addHandlerForMethod:@"NOTOFY" pathRegex:@"/dlna/callback" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
            if(request.hasBody){
                if(request.remoteAddressData){
                    [weakSelf parseWebServerMessage:request.remoteAddressData];
                }
            }
        }];
        [self.webServer startWithPort:8080 bonjourName:nil];
    }
}

#pragma mark - webServer 回调处理
- (void)parseWebServerMessage:(NSData*)data
{
     // 这里有个坑，有些设备返回的xml中<>被转义，导致解析时候出错。所以需要先反转义，然后再解析。
    NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    string = [self retransfer:string];
    NSData *xmlData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    GDataXMLDocument *document = [[GDataXMLDocument alloc]initWithData:xmlData options:0 error:&error];
    if(document){
        
    }
    
}

////有些设备返回的xml中 < > 被转义，导致解析时候出错。所以需要先反转义，然后再解析。
- (NSString*)retransfer:(NSString*)string
{
    if(string == nil)return nil;
    NSString*result = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    result = [result stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    return result;
}


@end
