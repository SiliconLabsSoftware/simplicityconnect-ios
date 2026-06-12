//
//  OvenDeviceManager.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 24/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import "OvenDeviceManager.h"
#import "DefaultsUtils.h"

@implementation OvenDeviceManager

- (instancetype)initWithNodeId:(NSNumber *)nodeId {
    self = [super init];
    if (self) {
        _nodeId = nodeId;
        _onOffEndpoint = @3;
        _modeEndpoint = @2;
        _temperatureEndpoint = @1;
    }
    return self;
}

#pragma mark - On/Off Operations

- (void)readOnOffStateWithCompletion:(OvenStateCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error ?: [self connectionError]);
            });
            return;
        }

        MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpointID:self.onOffEndpoint
                                                                                  queue:dispatch_get_main_queue()];

        [onOffCluster readAttributeOnOffWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(value.boolValue, error);
            });
        }];
    });
}

- (void)subscribeToOnOffStateWithParams:(MTRSubscribeParams *)params stateChangeHandler:(OvenStateChangeHandler)handler {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;
    
    MTRDeviceController *controller = InitializeMTR();
    MTRBaseDevice *chipDevice = [MTRBaseDevice deviceWithNodeID:self.nodeId controller:controller];
    
    if (!chipDevice) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(NO, [self connectionError]);
        });
        return;
    }
    
    MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                         endpointID:self.onOffEndpoint
                                                                              queue:dispatch_get_main_queue()];
    
    [onOffCluster subscribeAttributeOnOffWithParams:params
                            subscriptionEstablished:^{
        NSLog(@"Oven OnOff subscription established");
    } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"Error in OnOff subscription: %@", error);
                handler(NO, error);
            } else {
                BOOL isOn = [value isEqual:@1];
                NSLog(@"Oven OnOff state changed via subscription: %@ (1=ON, 0=OFF)", @(isOn));
                handler(isOn, nil);
            }
        });
    }];
}

- (void)turnOffWithCompletion:(OvenCommandCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error ?: [self connectionError]);
            });
            return;
        }

        MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpointID:self.onOffEndpoint
                                                                                  queue:dispatch_get_main_queue()];

        [onOffCluster offWithCompletion:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }];
    });
}

#pragma mark - Mode Operations

- (void)readSupportedModesWithCompletion:(OvenModesCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[], nil, error ?: [self connectionError]);
            });
            return;
        }

        if (@available(iOS 16.4, *)) {
            MTRBaseClusterOvenMode *modeCluster = [[MTRBaseClusterOvenMode alloc] initWithDevice:chipDevice
                                                                                      endpointID:self.modeEndpoint
                                                                                           queue:dispatch_get_main_queue()];

            [modeCluster readAttributeSupportedModesWithCompletion:^(NSArray * _Nullable value, NSError * _Nullable error) {
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(@[], nil, error);
                    });
                    return;
                }

                NSMutableArray *modes = [NSMutableArray array];
                for (id modeObj in value) {
                    NSNumber *modeValue;
                    NSString *modeLabel;

                    if ([modeObj isKindOfClass:[NSDictionary class]]) {
                        modeValue = modeObj[@"mode"];
                        modeLabel = modeObj[@"label"];
                    } else if ([modeObj respondsToSelector:@selector(mode)]) {
                        modeValue = [modeObj performSelector:@selector(mode)];
                        modeLabel = [modeObj performSelector:@selector(label)];
                    }

                    if (modeValue && modeLabel) {
                        [modes addObject:@{@"mode": modeValue, @"label": modeLabel}];
                    }
                }

                [modeCluster readAttributeCurrentModeWithCompletion:^(NSNumber * _Nullable currentMode, NSError * _Nullable modeError) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion([modes copy], currentMode, modeError);
                    });
                }];
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *versionError = [NSError errorWithDomain:@"OvenDeviceManager"
                                                            code:-1
                                                        userInfo:@{NSLocalizedDescriptionKey: @"OvenMode cluster requires iOS 16.4+"}];
                completion(@[], nil, versionError);
            });
        }
    });
}

- (void)setMode:(NSNumber *)modeValue completion:(OvenCommandCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error ?: [self connectionError]);
            });
            return;
        }

        if (@available(iOS 16.4, *)) {
            MTRBaseClusterOvenMode *modeCluster = [[MTRBaseClusterOvenMode alloc] initWithDevice:chipDevice
                                                                                      endpointID:self.modeEndpoint
                                                                                           queue:dispatch_get_main_queue()];

            MTROvenModeClusterChangeToModeParams *params = [[MTROvenModeClusterChangeToModeParams alloc] init];
            params.newMode = modeValue;

            [modeCluster changeToModeWithParams:params completion:^(MTROvenModeClusterChangeToModeResponseParams * _Nullable data, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
            }];
        }
    });
}

#pragma mark - Temperature Operations

- (void)readTemperatureWithCompletion:(OvenTemperatureCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, nil, error ?: [self connectionError]);
            });
            return;
        }

        MTRBaseClusterTemperatureControl *tempCluster = [[MTRBaseClusterTemperatureControl alloc] initWithDevice:chipDevice
                                                                                                     endpointID:self.temperatureEndpoint
                                                                                                          queue:dispatch_get_main_queue()];

        __block NSNumber *setpoint = nil;
        __block NSNumber *minTemp = nil;
        __block NSNumber *maxTemp = nil;
        
        dispatch_group_t group = dispatch_group_create();

        dispatch_group_enter(group);
        [tempCluster readAttributeTemperatureSetpointWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
            if (!error) setpoint = value;
            dispatch_group_leave(group);
        }];

        dispatch_group_enter(group);
        [tempCluster readAttributeMinTemperatureWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
            if (!error) minTemp = value;
            dispatch_group_leave(group);
        }];

        dispatch_group_enter(group);
        [tempCluster readAttributeMaxTemperatureWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
            if (!error) maxTemp = value;
            dispatch_group_leave(group);
        }];

        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            completion(setpoint, minTemp, maxTemp, nil);
        });
    });
}

- (void)setTemperature:(NSNumber *)temperature completion:(OvenCommandCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error ?: [self connectionError]);
            });
            return;
        }

        MTRBaseClusterTemperatureControl *tempCluster = [[MTRBaseClusterTemperatureControl alloc] initWithDevice:chipDevice
                                                                                                     endpointID:self.temperatureEndpoint
                                                                                                          queue:dispatch_get_main_queue()];

        MTRTemperatureControlClusterSetTemperatureParams *params = [[MTRTemperatureControlClusterSetTemperatureParams alloc] init];
        params.targetTemperature = temperature;

        [tempCluster setTemperatureWithParams:params completion:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }];
    });
}

- (void)subscribeToTemperatureSetpointWithParams:(MTRSubscribeParams *)params changeHandler:(OvenTemperatureChangeHandler)handler {
    MTRDeviceController *controller = InitializeMTR();
    MTRBaseDevice *chipDevice = [MTRBaseDevice deviceWithNodeID:self.nodeId controller:controller];

    if (!chipDevice) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(nil, [self connectionError]);
        });
        return;
    }

    MTRBaseClusterTemperatureControl *tempCluster = [[MTRBaseClusterTemperatureControl alloc] initWithDevice:chipDevice
                                                                                                 endpointID:self.temperatureEndpoint
                                                                                                      queue:dispatch_get_main_queue()];

    [tempCluster subscribeAttributeTemperatureSetpointWithParams:params
                                        subscriptionEstablished:^{
        NSLog(@"Temperature setpoint subscription established");
    } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(value, error);
        });
    }];
}

#pragma mark - Device Status

- (void)checkConnectionWithCompletion:(void(^)(BOOL connected))completion {
    [self checkConnectionWithRetryCount:2 completion:completion];
}

- (void)checkConnectionWithRetryCount:(NSInteger)retryCount completion:(void(^)(BOOL connected))completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;
    __weak typeof(self) weakSelf = self;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            if (retryCount > 1) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf checkConnectionWithRetryCount:retryCount - 1 completion:completion];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
            return;
        }

        MTRBaseClusterDescriptor *descriptorCluster = [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                                                            endpointID:@1
                                                                                                 queue:dispatch_get_main_queue()];

        [descriptorCluster readAttributeDeviceTypeListWithCompletion:^(NSArray * _Nullable value, NSError * _Nullable error) {
            if (error != nil && retryCount > 1) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf checkConnectionWithRetryCount:retryCount - 1 completion:completion];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error == nil);
                });
            }
        }];
    });
}

#pragma mark - Helper

- (NSError *)connectionError {
    return [NSError errorWithDomain:@"OvenDeviceManager"
                               code:-1
                           userInfo:@{NSLocalizedDescriptionKey: @"Failed to connect to device"}];
}

@end
