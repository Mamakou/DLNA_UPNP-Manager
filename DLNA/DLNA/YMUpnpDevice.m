//
//  YMUpnpDevice.m
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//

#import "YMUpnpDevice.h"
#import "GDataXMLNode.h"

@implementation YMUpnpDevice

-(YMServerModel *)AVTransport
{
    if(!_AVTransport){
        _AVTransport = [[YMServerModel alloc]init];
    }
    return _AVTransport;
}

-(YMServerModel *)RenderingControl
{
    if(!_RenderingControl){
        _RenderingControl = [[YMServerModel alloc]init];
    }
    return _RenderingControl;
}

-(NSString *)URLHeader
{
   return  [NSString stringWithFormat:@"%@://%@:%@", [self.loaction scheme], [self.loaction host], [self.loaction port]];
}

-(void)setArray:(NSArray *)array
{
    for (int i = 0; i<array.count; i++) {
        GDataXMLElement *element = array[i];
        if ([element.name isEqualToString:@"friendlyName"]) {
            self.friendlyName = [element stringValue];
            continue;
        }
        if ([element.name isEqualToString:@"modelName"]) {
            self.modelName = [element stringValue];
            continue;
        }
        if([element.name isEqualToString:@"serviceList"]){
            NSArray *serviceListArray = [element children];
            for (int j = 0; j<serviceListArray.count; j++) {
                GDataXMLElement *listEle = [serviceListArray objectAtIndex:j];
                if([listEle.name isEqualToString:@"service"]){
                    NSString *serviceString = [listEle stringValue];
                    if([serviceString rangeOfString:ServiceTypeAVTransport].location != NSNotFound ||
                       [serviceString rangeOfString:ServiceIdAVTransport].location != NSNotFound){
                        [self.AVTransport setArray:[listEle children]];
                    }else if ([serviceString rangeOfString:ServiceTypeRenderControl].location != NSNotFound ||
                              [serviceString rangeOfString:ServiceIdRenderControl].location != NSNotFound){
                        [self.RenderingControl setArray:[listEle children]];
                    }
                }
            }
            continue;
        }
    }
    
    
}

/***
 坑点1：有些设备 SCPDURL 、 controlURL 、 eventSubURL 开头包含 / ，有些设备不包含，拼接URL时需要注意。
 */
-(NSString*)controlURLWithServerType:(YMUpnpServerType)serverType
{
    NSString *url = nil;
    if(serverType == ServerTypeAVTransport){
        if(self.AVTransport != nil){
            if ([[self.AVTransport.controlURL substringToIndex:1] isEqualToString:@"/"]){
                url = [NSString stringWithFormat:@"%@%@", self.URLHeader, self.AVTransport.controlURL];
            }else{
                url = [NSString stringWithFormat:@"%@/%@", self.URLHeader, self.AVTransport.controlURL];
            }
        }
    }else if (serverType == ServerTypeRenderingControl){
        if(self.RenderingControl != nil){
            if ([[self.RenderingControl.controlURL substringToIndex:1] isEqualToString:@"/"]){
                url = [NSString stringWithFormat:@"%@%@", self.URLHeader, self.RenderingControl.controlURL];
            }else{
                url = [NSString stringWithFormat:@"%@/%@", self.URLHeader, self.RenderingControl.controlURL];
            }
        }
    }
    return url;
}

- (NSString*)eventSubURLWithServerType:(YMUpnpServerType)serverType
{
    NSString *url = nil;
    if(serverType == ServerTypeAVTransport){
        if(self.AVTransport != nil){
            if ([[self.AVTransport.controlURL substringToIndex:1] isEqualToString:@"/"]){
                url = [NSString stringWithFormat:@"%@%@", self.URLHeader, self.AVTransport.eventSubURL];
            }else{
                url = [NSString stringWithFormat:@"%@/%@", self.URLHeader, self.AVTransport.eventSubURL];
            }
        }
    }else if (serverType == ServerTypeRenderingControl){
        if(self.RenderingControl != nil){
            if ([[self.RenderingControl.controlURL substringToIndex:1] isEqualToString:@"/"]){
                url = [NSString stringWithFormat:@"%@%@", self.URLHeader, self.RenderingControl.eventSubURL];
            }else{
                url = [NSString stringWithFormat:@"%@/%@", self.URLHeader, self.RenderingControl.eventSubURL];
            }
        }
    }
    return url;
}


@end


//////////////////////////////
//////////////////////////////
//////////////////////////////
//////////////////////////////

@implementation YMServerModel

-(void)setArray:(NSArray *)array
{
    for (int i = 0; i<array.count; i++) {
        GDataXMLElement *needEle = array[i];
        if ([needEle.name isEqualToString:@"serviceType"]) {
            self.serviceType = [needEle stringValue];
        }
        if ([needEle.name isEqualToString:@"serviceId"]) {
            self.serviceId = [needEle stringValue];
        }
        if ([needEle.name isEqualToString:@"controlURL"]) {
            self.controlURL = [needEle stringValue];
        }
        if ([needEle.name isEqualToString:@"eventSubURL"]) {
            self.eventSubURL = [needEle stringValue];
        }
        if ([needEle.name isEqualToString:@"SCPDURL"]) {
            self.SCPDURL = [needEle stringValue];
        }
    }
    
}

@end
