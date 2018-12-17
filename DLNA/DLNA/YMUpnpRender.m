//
//  YMUpnpRender.m
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//

#import "YMUpnpRender.h"
#import "YMUpnpAction.h"
#import "GDataXMLNode.h"
#import "YMUpnpResponse.h"


@implementation YMUpnpRender



-(instancetype)initWithDevice:(YMUpnpDevice *)device
{
    self = [super init];
    if(self){
        self.device = device;
        _subscribeSidDict = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark -  各种action
///设置资源播放路径
- (void)setAVTransportURIStr:(NSString *)uriStr result:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"SetAVTransportURI"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [action setParamsElement:uriStr name:@"CurrentURI"];
    [action setParamsElement:@"" name:@"NextURIMetaData"];
    [self postRequestWithAction:action result:result];
}

- (void)setNextAVTransportURIStr:(NSString *)uriStr result:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"SetNextAVTransportURI"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [action setParamsElement:uriStr name:@"NextURI"];
    [action setParamsElement:@"" name:@"NextURIMetaData"];
    [self postRequestWithAction:action result:result];
    
}

- (void)playWithResult:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"Play"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [action setParamsElement:@"1" name:@"Speed"];
    [self postRequestWithAction:action result:result];
    
}

- (void)pauseWithResult:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"Pause"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [self postRequestWithAction:action result:result];
    
}

- (void)stopWithResult:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"Stop"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [self postRequestWithAction:action result:result];
}

- (void)nextWithResult:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"Next"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [self postRequestWithAction:action result:result];
}

- (void)previousWithResult:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"Previous"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [self postRequestWithAction:action result:result];
}


- (void)getPlayProgressWithResult:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"GetPositionInfo"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [self postRequestWithAction:action result:result];
}

- (void)getTransportInfoWithResult:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"GetTransportInfo"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [self postRequestWithAction:action result:result];
}

- (void)getVolumeWithResult:(YMUpnpResultBlock)result
{
    if(self.device == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"GetVolume"];
    action.serverType = ServerTypeRenderingControl;
    [action setParamsElement:@"0" name:@"InstanceID"];
    [action setParamsElement:@"Master" name:@"Channel"];
    [self postRequestWithAction:action result:result];
    
}

- (void)setVolumeWith:(NSString *)value result:(YMUpnpResultBlock)result
{
    if(self.device == nil || value == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"SetVolume"];
    action.serverType = ServerTypeRenderingControl;
    [action setParamsElement:@"0" name:@"InstanceID"];
    [action setParamsElement:@"Master" name:@"Channel"];
    [action setParamsElement:value name:@"DesiredVolume"];
    [self postRequestWithAction:action result:result];
    
}

- (void)seek:(float)relTime result:(YMUpnpResultBlock)result
{
    [self seekToTarget:[self stringWithDurationTime:relTime] Unit:@"REL_TIME" result:result];
}

- (NSString *)stringWithDurationTime:(float)timeValue
{
    return [NSString stringWithFormat:@"%02d:%02d:%02d",
            (int)(timeValue / 3600.0),
            (int)(fmod(timeValue, 3600.0) / 60.0),
            (int)fmod(timeValue, 60.0)];
}


- (void)seekToTarget:(NSString *)target Unit:(NSString *)unit result:(YMUpnpResultBlock)result
{
    if(self.device == nil || unit == nil)return;
    YMUpnpAction *action = [[YMUpnpAction alloc]initWithAction:@"Seek"];
    [action setParamsElement:@"0" name:@"InstanceID"];
    [action setParamsElement:unit name:@"Unit"];
    [action setParamsElement:target name:@"Target"];
    [self postRequestWithAction:action result:result];
}



#pragma mark - post 请求
- (void)postRequestWithAction:(YMUpnpAction*)action result:(YMUpnpResultBlock)result
{
    ///这里可以考虑使用信号量，单一处理
    dispatch_semaphore_t semat = dispatch_semaphore_create(1);//创建信号量每次都执行一次
    dispatch_semaphore_wait(semat, DISPATCH_TIME_FOREVER);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:[self.device controlURLWithServerType:action.serverType]];
    if(url == nil)return;
    NSString *soapAction = [action soapAction];
    if(soapAction == nil)return;
    
    NSString*postXML = [action postXMLFile];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    [request addValue:soapAction forHTTPHeaderField:@"SOAPAction"];
    request.HTTPBody = [postXML dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || data == nil) {
            if(result){
                result(nil,NO);
            }
            dispatch_semaphore_signal(semat);
            return;
        }else{
            GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:data options:0 error:nil];
            GDataXMLElement *xmlEle = [xmlDoc rootElement];
            NSArray *bigArray = [xmlEle children];
            BOOL isflag = NO;
            for (int i = 0; i < [bigArray count]; i++) {
                GDataXMLElement *element = [bigArray objectAtIndex:i];
                if ([[element name] hasSuffix:@"Body"]) {
                    ///一般情况下，needArr个数为1，但是既然是数据，原则上就不排除两个的情况
                    isflag = YES;
                    NSArray *needArr = [element children];
                    ///真是场景应该不会返回多个，为了方便回调后的阅读性，就直接取第一个了
                    if(needArr.count > 0){
                        GDataXMLElement *ele = needArr.firstObject;
                        YMUpnpResponse *response = [[YMUpnpResponse alloc]initWithElement:ele];
                        response.actionName = action.action;
                        if(result){
                            result(response,YES);
                        }
                    }
                    break;
                }
            }
            if(isflag == NO){
                if(result){
                    result(nil,YES);
                }
            }
            dispatch_semaphore_signal(semat);
        }
    }];
    [dataTask resume];
    
}


- (void)sendSubscribeRequestWithTime:(int)time serverType:(YMUpnpServerType)serverType callBack:(NSString*)callBack result:(void(^)(BOOL success))result
{
    if(self.device == nil)return;
    NSString *url = [self.device eventSubURLWithServerType:serverType];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"SUBSCRIBE";
    NSString *version = [UIDevice currentDevice].systemVersion;
    NSString *userAgent = [NSString stringWithFormat:@"iOS/%@ UPnP/1.1 SCDLNA/1.0",version];
    [request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [request addValue:[NSString stringWithFormat:@"<%@>",callBack] forHTTPHeaderField:@"CALLBACK"];
    [request addValue:@"upnp:event" forHTTPHeaderField:@"NT"];
    [request addValue:[NSString stringWithFormat:@"Second-%d",time] forHTTPHeaderField:@"TIMEOUT"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error){
            NSLog(@"%@",error);
            if(result){
                result(NO);
            }
            return ;
        }
        if(result){
            result(YES);
        }
        //正常结果返回参考
//    HTTP/1.1 200 OK
//    Server: Linux/3.10.33 UPnP/1.0 IQIYIDLNA/iqiyidlna/NewDLNA/1.0
//    SID: uuid:f392-a153-571c-e10b
//        Content-Type: text/html; charset="utf-8"
//    TIMEOUT: Second-3600
//    Date: Thu, 03 Mar 2016 19:01:42 GMT
       NSHTTPURLResponse *resultResponse = (NSHTTPURLResponse*)response;
       NSString *sid = [resultResponse.allHeaderFields valueForKey:@"SID"];
        if(sid){
            NSString *sidKey = ServiceTypeAVTransport;
            if(serverType == ServerTypeRenderingControl){
                sidKey = ServiceTypeRenderControl;
            }
            [self->_subscribeSidDict setValue:sid forKey:sidKey];

        }
        
    }];
    [dataTask resume];
    
}

- (void)contractSubscirbeWithTime:(int)time serverType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result
{
    if(self.device == nil)return;
    NSString *url = [self.device eventSubURLWithServerType:serverType];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"SUBSCRIBE";
    NSString *subscirbeKey = ServiceTypeAVTransport;
    if(serverType == ServerTypeRenderingControl){
        subscirbeKey = ServiceTypeRenderControl;
    }
    NSString *sid = [self.subscribeSidDict valueForKey:subscirbeKey];
    if(sid == nil)return;
    [request addValue:sid forHTTPHeaderField:@"SID"];
    [request addValue:[NSString stringWithFormat:@"Second-%d",time] forHTTPHeaderField:@"TIMEOUT"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error){
            if(result){
                result(NO);
            }
        }else{
            if(result){
                result(YES);
            }
        }
    }];
    
    [dataTask resume];
}

- (void)removeSubscribeWithServerType:(YMUpnpServerType)serverType result:(void(^)(BOOL success))result
{
    if(self.device == nil)return;
    NSString *url = [self.device eventSubURLWithServerType:serverType];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"UNSUBSCRIBE";
    NSString *subscirbeKey = ServiceTypeAVTransport;
    if(serverType == ServerTypeRenderingControl){
        subscirbeKey = ServiceTypeRenderControl;
    }
    NSString *sid = [self.subscribeSidDict valueForKey:subscirbeKey];
    if(sid == nil)return;
    [request addValue:sid forHTTPHeaderField:@"SID"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error){
            if(result){
                result(NO);
            }
        }else{
            if(result){
                result(YES);
            }
        }
    }];
    
    [dataTask resume];
}






@end
