//
//  YMUpnpResponse.m
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//

#import "YMUpnpResponse.h"
#import "GDataXMLNode.h"

@implementation YMUpnpResponse

-(instancetype)initWithDataArray:(NSArray*)dataArray
{
    self = [super init];
    if(self){
        GDataXMLElement *ele = dataArray.firstObject;
        self.responseName = [ele name];
        NSArray *child = [ele children];
        if(child.count > 0){
            self.dict = [NSMutableDictionary dictionaryWithCapacity:child.count];
            for (GDataXMLElement*childEle in child) {
                NSString *key = childEle.name;
                NSString *value = childEle.stringValue;
                if(key && value){
                    [self.dict setValue:value forKey:key];
                }
            }
        }
    }
    return self;
}

- (instancetype)initWithElement:(GDataXMLElement*)element
{
    self = [super init];
    if(self){
        self.responseName = [element name];
        NSArray *child = [element children];
        if(child.count > 0){
            self.dict = [NSMutableDictionary dictionaryWithCapacity:child.count];
            for (GDataXMLElement*childEle in child) {
                NSString *key = childEle.name;
                NSString *value = childEle.stringValue;
                if(key && value){
                    [self.dict setValue:value forKey:key];
                }
            }
        }
    }
    return self;
}

@end
