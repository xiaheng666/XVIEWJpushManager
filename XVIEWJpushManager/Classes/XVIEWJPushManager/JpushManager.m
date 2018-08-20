//
//  JpushManager.m
//  JpushManager
//
//  Created by yyj on 2018/7/4.
//  Copyright © 2018年 zd. All rights reserved.
//

#import "JpushManager.h"
#import "JPUSHService.h"
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "XVIEWSDKObject.h"
@interface JpushManager()<JPUSHRegisterDelegate>
@property (nonatomic,strong)void (^pushCallback)(XVIEWSDKResonseStatusCode code,NSDictionary *dict);
@end
@implementation JpushManager
+ (instancetype)defaultJpushManager{
    static JpushManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[JpushManager alloc]init];
    });
    return manager;
}
//初始化
- (void)initWithDict:(NSDictionary *)dict{
    [JPUSHService setupWithOption:dict[@"launchOptions"] appKey:dict[@"key"] channel:dict[@"key"] apsForProduction:[dict[@"product"] boolValue]];
}
- (void)setAlias:(NSDictionary*)dic{
    [JPUSHService setAlias:dic[@"alias"] completion:^(NSInteger iResCode, NSString *iAlias, NSInteger seq) {
        
    } seq:1];
}
-(void)cancelAlias{
    [JPUSHService deleteAlias:^(NSInteger iResCode, NSString *iAlias, NSInteger seq) {
        
    } seq:1];
}
- (void)registerForRemoteNotificationConfig:(void (^)(XVIEWSDKResonseStatusCode code,NSDictionary* info))pushCallBack{
    JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound;
    [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
    self.pushCallback = pushCallBack;
}
- (void)registerRemoteNotificationType{
    [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                      UIUserNotificationTypeSound |
                                                      UIUserNotificationTypeAlert)
                                          categories:nil];
}
- (void)registerDeviceToken:(NSData*)deviceToken{
    [JPUSHService registerDeviceToken:deviceToken];
}
- (void)showRemoteNotification:(NSDictionary*)dic pushCallBack:(void(^)(XVIEWSDKResonseStatusCode code,NSDictionary *info))pushCallBack{
    self.pushCallback = pushCallBack;
    [JPUSHService handleRemoteNotification:dic];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
        self.pushCallback(XVIEWSDKCodeSuccess,dic);
    else  self.pushCallback(XVIEWSDKCodeSuccess,dic);
}
- (void)setBadge:(NSDictionary*)dic{
    [JPUSHService setBadge:[dic[@"badge"] integerValue]];
}
#pragma mark - JPUSHSERVICEDELEGATE
// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    [self showRemoteNotification:userInfo pushCallBack:self.pushCallback];
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler(UNNotificationPresentationOptionBadge); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
}
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    // Required
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    [self showRemoteNotification:userInfo pushCallBack:self.pushCallback];
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler();  // 系统要求执行这个方法
}
@end
