//
//  YMUpnpAction.m
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//

#import "YMUpnpAction.h"
#import "GDataXMLNode.h"

@interface YMUpnpAction ()

@property (nonatomic,strong)GDataXMLElement *element;

@end

@implementation YMUpnpAction


-(instancetype)initWithAction:(NSString *)action
{
    self = [super init];
    if(self){
        _action = action;
        ///默认为投屏
        _serverType = ServerTypeAVTransport;
        ///根据dlna规范必须这样写:
        NSString *name = [NSString stringWithFormat:@"u:%@", action];
        self.element = [GDataXMLElement elementWithName:name];
        
    }
    return self;
}

- (void)setParamsElement:(NSString*)value name:(NSString*)name
{
    [self.element addChild:[GDataXMLElement elementWithName:name stringValue:value]];
    
}

- (NSString*)soapAction
{
    if(self.serverType == ServerTypeAVTransport){
        return [NSString stringWithFormat:@"\"%@#%@\"", ServiceTypeAVTransport, _action];
    }else if (self.serverType == ServerTypeRenderingControl){
        return [NSString stringWithFormat:@"\"%@#%@\"", ServiceTypeRenderControl, _action];
    }
    return nil;
}

-(NSString *)postXMLFile
{
    ///以下都是固定格式，除了body中是根据具体参数进行添加
    GDataXMLElement *xmlEle = [GDataXMLElement elementWithName:@"s:Envelope"];
    [xmlEle addChild:[GDataXMLElement attributeWithName:@"s:encodingStyle" stringValue:@"http://schemas.xmlsoap.org/soap/encoding/"]];
    [xmlEle addChild:[GDataXMLElement attributeWithName:@"xmlns:s" stringValue:@"http://schemas.xmlsoap.org/soap/envelope/"]];
    [xmlEle addChild:[GDataXMLElement attributeWithName:@"xmlns:u" stringValue:self.serverTypeString]];
    GDataXMLElement *command = [GDataXMLElement elementWithName:@"s:Body"];
    
    [command addChild:self.element];
    [xmlEle addChild:command];
    
    return xmlEle.XMLString;
    
}

/**
 当前的服务
 */
- (NSString*)serverTypeString
{
    NSString *server = @"";
    switch (self.serverType) {
        case ServerTypeAVTransport:
            server = @"urn:schemas-upnp-org:service:AVTransport:1";
            break;
        case ServerTypeRenderingControl:
            server = @"urn:schemas-upnp-org:service:RenderingControl:1";
            break;
        default:
            break;
    }
    
    
    return nil;
}



@end
