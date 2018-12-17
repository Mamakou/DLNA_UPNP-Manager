//
//  YMUpnpResponse.h
//  PresentAnimatDemo
//
//  Created by goviewtech on 2018/12/12.
//  Copyright © 2018 goviewtech. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GDataXMLElement;

/**
 响应结果
 */
@interface YMUpnpResponse : NSObject

@property (nonatomic,copy)NSString *actionName;
/**
 响应名称 如：PlayResponse、StopResponse
 */
@property (nonatomic,copy)NSString *responseName;

/**只有在返回对应值的时候，dict才有值*/
@property (nonatomic,strong)NSMutableDictionary *dict;

/**
 这里只处理dataArray.firstobject，因为实际上响应后只有一个元素，不可能同时响应多个
 */
-(instancetype)initWithDataArray:(NSArray*)dataArray;

- (instancetype)initWithElement:(GDataXMLElement*)element;

@end


