# DLNA_UPNP-Manager
简单集成就可以实现dlna投屏技术

## 如何使用

##### 1、设备搜索
```
///使用方法
YMUpnpManager *manager = [YMUpnpManager manager];
///通过代理接收搜索消息
manager.delegate = self;
///开始搜索
[manager startSearch];
```
##### 2、选择设备
```
#pragma mark - YMUpnpManagerDelegate
- (void)upnpManager:(YMUpnpManager*)manager searchResults:(NSArray<YMUpnpDevice*>*)devices
{
    ///这里仅仅是demo展示用
    YMUpnpDevice *device = devices.firstObject;
    if(device == nil)return;
    [[YMUpnpManager manager] selectedDevice:device];
    
}
```
##### 3、具体操作

这里仅仅列出了大众化的一些操作，比如设置URI资源、播放、暂停等等
```
///设置播放资源,采用block返回
[[YMUpnpManager manager] setAVTransportURIStr:@"需要被播放的资源路径" result:^(YMUpnpResponse *response, BOOL success) {
        
}];
///开始播放
[[YMUpnpManager manager] playWithResult:^(YMUpnpResponse *response, BOOL success) {
        
}];
///订阅后，通过callback设置的回调路径接收订阅消息，因为没有设备所以功能需要完善
[[YMUpnpManager manager] sendSubcirbeWithTime:3600 callBack:@"回调" serverType:ServerTypeAVTransport result:^(BOOL success) {
        
}]; 
```
