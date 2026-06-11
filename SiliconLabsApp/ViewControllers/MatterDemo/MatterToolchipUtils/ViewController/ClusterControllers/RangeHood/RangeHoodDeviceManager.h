//
//  RangeHoodDeviceManager.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 24/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Matter/Matter.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RangeHoodStateCompletion)(BOOL isOn, NSError * _Nullable error);
typedef void(^RangeHoodCommandCompletion)(NSError * _Nullable error);
typedef void(^RangeHoodFanModeCompletion)(NSNumber * _Nullable fanMode, NSError * _Nullable error);
typedef void(^RangeHoodStateChangeHandler)(BOOL isOn, NSError * _Nullable error);

@class RangeHoodDeviceManager;

@interface RangeHoodDeviceManager : NSObject

@property (nonatomic, strong) NSNumber *nodeId;
@property (nonatomic, strong) NSNumber *fanEndpoint;
@property (nonatomic, strong) NSNumber *lightEndpoint;

- (instancetype)initWithNodeId:(NSNumber *)nodeId;

// Fan Operations
- (void)readFanStateWithCompletion:(RangeHoodStateCompletion)completion;
- (void)subscribeToFanStateWithParams:(MTRSubscribeParams *)params stateChangeHandler:(RangeHoodStateChangeHandler)handler;
- (void)turnFanOnWithCompletion:(RangeHoodCommandCompletion)completion;
- (void)turnFanOffWithCompletion:(RangeHoodCommandCompletion)completion;
- (void)readFanModeWithCompletion:(RangeHoodFanModeCompletion)completion;

// Light Operations
- (void)readLightStateWithCompletion:(RangeHoodStateCompletion)completion;
- (void)subscribeToLightStateWithParams:(MTRSubscribeParams *)params stateChangeHandler:(RangeHoodStateChangeHandler)handler;
- (void)turnLightOnWithCompletion:(RangeHoodCommandCompletion)completion;
- (void)turnLightOffWithCompletion:(RangeHoodCommandCompletion)completion;

// Device Status
- (void)checkConnectionWithCompletion:(void(^)(BOOL connected))completion;

@end

NS_ASSUME_NONNULL_END
