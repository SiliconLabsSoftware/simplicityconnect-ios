//
//  OvenDeviceManager.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 24/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Matter/Matter.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^OvenStateCompletion)(BOOL isOn, NSError * _Nullable error);
typedef void(^OvenModesCompletion)(NSArray<NSDictionary *> *modes, NSNumber * _Nullable currentMode, NSError * _Nullable error);
typedef void(^OvenCommandCompletion)(NSError * _Nullable error);
typedef void(^OvenStateChangeHandler)(BOOL isOn, NSError * _Nullable error);
typedef void(^OvenTemperatureCompletion)(NSNumber * _Nullable setpoint, NSNumber * _Nullable minTemp, NSNumber * _Nullable maxTemp, NSError * _Nullable error);
typedef void(^OvenTemperatureChangeHandler)(NSNumber * _Nullable setpoint, NSError * _Nullable error);

@interface OvenDeviceManager : NSObject

@property (nonatomic, strong) NSNumber *nodeId;
@property (nonatomic, strong) NSNumber *onOffEndpoint;
@property (nonatomic, strong) NSNumber *modeEndpoint;
@property (nonatomic, strong) NSNumber *temperatureEndpoint;

- (instancetype)initWithNodeId:(NSNumber *)nodeId;

// On/Off Operations
- (void)readOnOffStateWithCompletion:(OvenStateCompletion)completion;
- (void)turnOffWithCompletion:(OvenCommandCompletion)completion;
- (void)subscribeToOnOffStateWithParams:(MTRSubscribeParams *)params stateChangeHandler:(OvenStateChangeHandler)handler;

// Mode Operations
- (void)readSupportedModesWithCompletion:(OvenModesCompletion)completion;
- (void)setMode:(NSNumber *)modeValue completion:(OvenCommandCompletion)completion;

// Temperature Operations
- (void)readTemperatureWithCompletion:(OvenTemperatureCompletion)completion;
- (void)setTemperature:(NSNumber *)temperature completion:(OvenCommandCompletion)completion;
- (void)subscribeToTemperatureSetpointWithParams:(MTRSubscribeParams *)params changeHandler:(OvenTemperatureChangeHandler)handler;

// Device Status
- (void)checkConnectionWithCompletion:(void(^)(BOOL connected))completion;

@end

NS_ASSUME_NONNULL_END
