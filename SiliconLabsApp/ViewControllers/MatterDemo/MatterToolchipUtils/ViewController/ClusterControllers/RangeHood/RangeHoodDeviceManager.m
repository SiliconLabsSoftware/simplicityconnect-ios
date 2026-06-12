//
//  RangeHoodDeviceManager.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 24/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import "RangeHoodDeviceManager.h"
#import "DefaultsUtils.h"

@implementation RangeHoodDeviceManager

- (instancetype)initWithNodeId:(NSNumber *)nodeId {
    self = [super init];
    if (self) {
        _nodeId = nodeId;
        _fanEndpoint = @1;  // Default endpoint for fan
        _lightEndpoint = @2; // Default endpoint for light
    }
    return self;
}

#pragma mark - Fan Operations

- (void)readFanStateWithCompletion:(RangeHoodStateCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error ?: [self connectionError]);
            });
            return;
        }

        if (@available(iOS 16.4, *)) {
            // Oven binding uses OnOff on endpoint 1 - read OnOff first for consistent UI updates
            MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                                endpointID:self.fanEndpoint
                                                                                     queue:dispatch_get_main_queue()];

            [onOffCluster readAttributeOnOffWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                if (error) {
                    MTRBaseClusterFanControl *fanCluster = [[MTRBaseClusterFanControl alloc] initWithDevice:chipDevice
                                                                                                endpointID:self.fanEndpoint
                                                                                                     queue:dispatch_get_main_queue()];
                    [fanCluster readAttributeFanModeWithCompletion:^(NSNumber * _Nullable fanMode, NSError * _Nullable fanError) {
                        BOOL isOn = (fanMode && fanMode.intValue != 0);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(isOn, fanError);
                        });
                    }];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(value ? value.boolValue : NO, nil);
                    });
                }
            }];
        } else {
            // Fallback to OnOff cluster for older iOS versions
            MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                                endpointID:self.fanEndpoint
                                                                                     queue:dispatch_get_main_queue()];
            
            [onOffCluster readAttributeOnOffWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(value.boolValue, error);
                });
            }];
        }
    });
}

- (void)subscribeToFanStateWithParams:(MTRSubscribeParams *)params stateChangeHandler:(RangeHoodStateChangeHandler)handler {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, error ?: [self connectionError]);
            });
            return;
        }

        // Oven binding uses OnOff cluster on endpoint 1 - subscribe to OnOff so UI reflects Oven board commands
        MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpointID:self.fanEndpoint
                                                                                  queue:dispatch_get_main_queue()];
        [onOffCluster subscribeAttributeOnOffWithParams:params
                                subscriptionEstablished:nil
                                          reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(value ? value.boolValue : NO, error);
            });
        }];
    });
}

- (void)turnFanOnWithCompletion:(RangeHoodCommandCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error ?: [self connectionError]);
            });
            return;
        }

        if (@available(iOS 16.4, *)) {
            // Oven binding uses OnOff cluster on endpoint 1 - try OnOff first for reliability
            MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                                endpointID:self.fanEndpoint
                                                                                     queue:dispatch_get_main_queue()];

            [onOffCluster onWithCompletion:^(NSError * _Nullable error) {
                if (error) {
                    // Fallback: try FanControl cluster
                    MTRBaseClusterFanControl *fanCluster = [[MTRBaseClusterFanControl alloc] initWithDevice:chipDevice
                                                                                                endpointID:self.fanEndpoint
                                                                                                     queue:dispatch_get_main_queue()];
                    NSNumber *fanMode = @4; // MTRFanControlFanModeOn
                    [fanCluster writeAttributeFanModeWithValue:fanMode completion:^(NSError * _Nullable fanError) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(fanError);
                        });
                    }];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil);
                    });
                }
            }];
        } else if (@available(iOS 16.1, *)) {
            // Fallback to deprecated method for iOS 16.1-16.3
            MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                                endpointID:self.fanEndpoint
                                                                                     queue:dispatch_get_main_queue()];
            
            [onOffCluster onWithCompletionHandler:^(NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *versionError = [NSError errorWithDomain:@"RangeHoodDeviceManager"
                                                           code:-1
                                                       userInfo:@{NSLocalizedDescriptionKey: @"OnOff cluster requires iOS 16.1+"}];
                completion(versionError);
            });
        }
    });
}

- (void)turnFanOffWithCompletion:(RangeHoodCommandCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error ?: [self connectionError]);
            });
            return;
        }

        if (@available(iOS 16.4, *)) {
            // Oven binding uses OnOff cluster on endpoint 1 - try OnOff first for reliability
            MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                                endpointID:self.fanEndpoint
                                                                                     queue:dispatch_get_main_queue()];

            [onOffCluster offWithCompletion:^(NSError * _Nullable error) {
                if (error) {
                    // Fallback: try FanControl cluster
                    MTRBaseClusterFanControl *fanCluster = [[MTRBaseClusterFanControl alloc] initWithDevice:chipDevice
                                                                                                endpointID:self.fanEndpoint
                                                                                                     queue:dispatch_get_main_queue()];
                    NSNumber *fanMode = @0; // MTRFanControlFanModeOff
                    [fanCluster writeAttributeFanModeWithValue:fanMode completion:^(NSError * _Nullable fanError) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(fanError);
                        });
                    }];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil);
                    });
                }
            }];
        } else {
            // Fallback to OnOff cluster for older iOS versions
            MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                                endpointID:self.fanEndpoint
                                                                                     queue:dispatch_get_main_queue()];
            
            [onOffCluster offWithCompletion:^(NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
            }];
        }
    });
}

- (void)readFanModeWithCompletion:(RangeHoodFanModeCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error ?: [self connectionError]);
            });
            return;
        }

        if (@available(iOS 16.4, *)) {
            MTRBaseClusterFanControl *fanCluster = [[MTRBaseClusterFanControl alloc] initWithDevice:chipDevice
                                                                                        endpointID:self.fanEndpoint
                                                                                             queue:dispatch_get_main_queue()];

            [fanCluster readAttributeFanModeWithCompletion:^(NSNumber * _Nullable fanMode, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(fanMode, error);
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *versionError = [NSError errorWithDomain:@"RangeHoodDeviceManager"
                                                            code:-1
                                                        userInfo:@{NSLocalizedDescriptionKey: @"FanControl cluster requires iOS 16.4+"}];
                completion(nil, versionError);
            });
        }
    });
}

#pragma mark - Light Operations

- (void)readLightStateWithCompletion:(RangeHoodStateCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error ?: [self connectionError]);
            });
            return;
        }

        MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpointID:self.lightEndpoint
                                                                                  queue:dispatch_get_main_queue()];

        [onOffCluster readAttributeOnOffWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(value.boolValue, error);
            });
        }];
    });
}

- (void)subscribeToLightStateWithParams:(MTRSubscribeParams *)params stateChangeHandler:(RangeHoodStateChangeHandler)handler {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, error ?: [self connectionError]);
            });
            return;
        }

        MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpointID:self.lightEndpoint
                                                                                  queue:dispatch_get_main_queue()];

        [onOffCluster subscribeAttributeOnOffWithParams:params
                                subscriptionEstablished:nil
                                          reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(value ? value.boolValue : NO, error);
            });
        }];
    });
}

- (void)turnLightOnWithCompletion:(RangeHoodCommandCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error ?: [self connectionError]);
            });
            return;
        }

        MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpointID:self.lightEndpoint
                                                                                  queue:dispatch_get_main_queue()];

        [onOffCluster onWithCompletion:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }];
    });
}

- (void)turnLightOffWithCompletion:(RangeHoodCommandCompletion)completion {
    uint64_t deviceId = self.nodeId.unsignedLongLongValue;

    MTRGetConnectedDeviceWithID(deviceId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (!chipDevice) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error ?: [self connectionError]);
            });
            return;
        }

        MTRBaseClusterOnOff *onOffCluster = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpointID:self.lightEndpoint
                                                                                  queue:dispatch_get_main_queue()];

        [onOffCluster offWithCompletion:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }];
    });
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
    return [NSError errorWithDomain:@"RangeHoodDeviceManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to connect to device"}];
}

@end
