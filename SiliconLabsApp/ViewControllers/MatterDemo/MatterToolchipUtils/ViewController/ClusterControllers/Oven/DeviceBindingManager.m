//
//  DeviceBindingManager.m
//  BlueGecko
//
//  Created for Oven-RangeHood Binding
//  Copyright © 2026 SiliconLabs. All rights reserved.
//
//  ACL write on RangeHood (target) first,
//  then Binding write on Oven (source) at the OnOff endpoint.
//

#import "DeviceBindingManager.h"
#import "DefaultsUtils.h"

// UserDefaults keys
static NSString * const kBindingInfoKeyPrefix = @"OvenRangeHoodBinding_";

@implementation DeviceBindingManager

#pragma mark - Binding Operations

+ (void)bindOvenToRangeHoodWithOvenNodeId:(NSNumber *)ovenNodeId
                              ovenEndpoint:(NSNumber *)ovenEndpoint
                          rangeHoodNodeId:(NSNumber *)rangeHoodNodeId
                               fanEndpoint:(NSNumber *)fanEndpoint
                             lightEndpoint:(NSNumber *)lightEndpoint
                                 completion:(BindingCompletion)completion {
        
    NSLog(@"ovenNodeId === %@", ovenNodeId);
    NSLog(@"ovenEndpoint === %@", ovenEndpoint);
    NSLog(@"rangeHoodNodeId === %@", rangeHoodNodeId);
    NSLog(@"fanEndpoint === %@", fanEndpoint);
    NSLog(@"lightEndpoint === %@", lightEndpoint);
    
    MTRDeviceController *controller = InitializeMTR();
    if (!controller) {
        NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize Matter controller"}];
        if (completion) completion(NO, error);
        return;
    }
    
    // Step 1: Get RangeHood device (TARGET) - ACL must be written on target first
    MTRBaseDevice *rangeHoodDevice = [MTRBaseDevice deviceWithNodeID:rangeHoodNodeId controller:controller];
    if (!rangeHoodDevice) {
        NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to get RangeHood device"}];
        if (completion) completion(NO, error);
        return;
    }
    
    // Step 2: Read ACL from RangeHood, then write ACL to grant Oven permission
    MTRBaseClusterAccessControl *accessControl = [[MTRBaseClusterAccessControl alloc] initWithDevice:rangeHoodDevice
                                                                                         endpointID:@0
                                                                                              queue:dispatch_get_main_queue()];
    
    [accessControl readAttributeACLWithParams:nil completion:^(NSArray * _Nullable value, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to read ACL from RangeHood: %@", error);
            if (completion) completion(NO, error);
            return;
        }
        
        if (!value || value.count == 0) {
            NSLog(@"RangeHood ACL is empty or invalid");
            NSError *aclError = [NSError errorWithDomain:@"DeviceBindingManager"
                                                    code:-1
                                                userInfo:@{NSLocalizedDescriptionKey: @"Failed to read RangeHood ACL"}];
            if (completion) completion(NO, aclError);
            return;
        }
        
        // Build ACL entries: keep existing, add Oven with privilege 3
        MTRAccessControlClusterAccessControlEntryStruct *entryStruct = value[0];
        NSNumber *existingSubject = entryStruct.subjects[0];
        
        NSMutableArray *aclWriteArray = [NSMutableArray array];
        
        // Keep existing ACL entry
        MTRAccessControlClusterAccessControlEntryStruct *existingEntry = [[MTRAccessControlClusterAccessControlEntryStruct alloc] init];
        existingEntry.fabricIndex = @1;
        existingEntry.privilege = @5;
        existingEntry.authMode = @2;
        existingEntry.subjects = @[existingSubject];
        existingEntry.targets = @[];
        [aclWriteArray addObject:existingEntry];
        
        // Add Oven entry for binding (privilege 3 = manage)
        MTRAccessControlClusterAccessControlEntryStruct *ovenEntry = [[MTRAccessControlClusterAccessControlEntryStruct alloc] init];
        ovenEntry.fabricIndex = @1;
        ovenEntry.privilege = @3;
        ovenEntry.authMode = @2;
        ovenEntry.subjects = @[ovenNodeId];
        ovenEntry.targets = @[];
        [aclWriteArray addObject:ovenEntry];
        
        NSLog(@"Writing ACL to RangeHood to grant Oven permission");
        [accessControl writeAttributeACLWithValue:aclWriteArray completion:^(NSError * _Nullable aclError) {
            if (aclError) {
                NSLog(@"Failed to write ACL to RangeHood: %@", aclError);
                if (completion) completion(NO, aclError);
                return;
            }
            
            NSLog(@"ACL write successful. Now writing Binding on Oven.");
            
            // Step 3: Write Binding on Oven (SOURCE)
            MTRBaseDevice *ovenDevice = [MTRBaseDevice deviceWithNodeID:ovenNodeId controller:controller];
            if (!ovenDevice) {
                NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                                     code:-1
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Failed to get Oven device"}];
                if (completion) completion(NO, error);
                return;
            }
            
            // Create binding targets for BOTH fan and light endpoints on RangeHood
            MTRBindingClusterTargetStruct *fanBindingTarget = [[MTRBindingClusterTargetStruct alloc] init];
            fanBindingTarget.node = rangeHoodNodeId;
            fanBindingTarget.endpoint = fanEndpoint;
            fanBindingTarget.cluster = @6;  // OnOff cluster (0x0006)
            fanBindingTarget.fabricIndex = @1;
            
            MTRBindingClusterTargetStruct *lightBindingTarget = [[MTRBindingClusterTargetStruct alloc] init];
            lightBindingTarget.node = rangeHoodNodeId;
            lightBindingTarget.endpoint = lightEndpoint;
            lightBindingTarget.cluster = @6;  // OnOff cluster (0x0006)
            lightBindingTarget.fabricIndex = @1;
            
            NSArray *bindingTargets = @[fanBindingTarget, lightBindingTarget];
            
            // Write binding on Oven's OnOff endpoint first - firmware looks for bindings
            // on the same endpoint as the application cluster (OnOff on ovenEndpoint)
            [self writeBindingOnOven:ovenDevice
                            targets:bindingTargets
                         ovenNodeId:ovenNodeId
                    rangeHoodNodeId:rangeHoodNodeId
                       tryEndpoints:@[ovenEndpoint, @1, @0]
                         completion:completion];
        }];
    }];
}

+ (void)writeBindingOnOven:(MTRBaseDevice *)ovenDevice
                   targets:(NSArray *)targets
                ovenNodeId:(NSNumber *)ovenNodeId
           rangeHoodNodeId:(NSNumber *)rangeHoodNodeId
              tryEndpoints:(NSArray<NSNumber *> *)endpoints
                completion:(BindingCompletion)completion {
    
    NSLog(@"ovenDevice = %@", ovenDevice);
    NSLog(@"ovenNodeId = %@", ovenNodeId);
    NSLog(@"endpoints = %@", endpoints);
    NSLog(@"binding targets count = %lu", (unsigned long)targets.count);
    
    if (endpoints.count == 0) {
        NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Binding cluster not found on any endpoint"}];
        if (completion) completion(NO, error);
        return;
    }
    
    NSNumber *endpoint = endpoints[0];
    NSArray *remaining = endpoints.count > 1 ? [endpoints subarrayWithRange:NSMakeRange(1, endpoints.count - 1)] : @[];
    
    NSLog(@"Writing Binding on Oven endpoint %@: %lu targets to RangeHood %@", endpoint, (unsigned long)targets.count, rangeHoodNodeId);
    
    MTRBaseClusterBinding *bindingCluster = [[MTRBaseClusterBinding alloc] initWithDevice:ovenDevice
                                                                                endpoint:endpoint.integerValue
                                                                                   queue:dispatch_get_main_queue()];
    
    [bindingCluster writeAttributeBindingWithValue:targets completionHandler:^(NSError * _Nullable bindError) {
        if (bindError) {
            NSLog(@"Binding failed on endpoint %@: %@", endpoint, bindError);
            if (remaining.count > 0) {
                NSLog(@"Trying next endpoint: %@", remaining[0]);
                [self writeBindingOnOven:ovenDevice targets:targets ovenNodeId:ovenNodeId rangeHoodNodeId:rangeHoodNodeId tryEndpoints:remaining completion:completion];
            } else {
                if (completion) completion(NO, bindError);
            }
        } else {
            NSLog(@"Binding successful on endpoint %@ with %lu targets!", endpoint, (unsigned long)targets.count);
            [self saveBindingInfoWithOvenNodeId:ovenNodeId rangeHoodNodeId:rangeHoodNodeId];
            if (completion) completion(YES, nil);
        }
    }];
}

+ (void)unbindOvenFromRangeHoodWithOvenNodeId:(NSNumber *)ovenNodeId
                                    completion:(BindingCompletion)completion {
    
    NSLog(@"Starting unbinding for Oven nodeId: %@", ovenNodeId);
    
    MTRDeviceController *controller = InitializeMTR();
    if (!controller) {
        NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize Matter controller"}];
        if (completion) completion(NO, error);
        return;
    }
    
    MTRBaseDevice *ovenDevice = [MTRBaseDevice deviceWithNodeID:ovenNodeId controller:controller];
    if (!ovenDevice) {
        NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to get Oven device"}];
        if (completion) completion(NO, error);
        return;
    }
    
    // Try Oven's OnOff endpoint first (where binding was written), then fallbacks
    [self unbindFromOven:ovenDevice ovenNodeId:ovenNodeId tryEndpoints:@[@3, @1, @0] completion:completion];
}

+ (void)unbindFromOven:(MTRBaseDevice *)ovenDevice
            ovenNodeId:(NSNumber *)ovenNodeId
          tryEndpoints:(NSArray<NSNumber *> *)endpoints
            completion:(BindingCompletion)completion {
    
    NSLog(@"ovenDevice = %@", ovenDevice);
    NSLog(@"ovenNodeId = %@", ovenNodeId);
    NSLog(@"endpoints = %@", endpoints);

    if (endpoints.count == 0) {
        NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Binding cluster not found on any endpoint"}];
        if (completion) completion(NO, error);
        return;
    }
    
    NSNumber *endpoint = endpoints[0];
    NSArray *remaining = endpoints.count > 1 ? [endpoints subarrayWithRange:NSMakeRange(1, endpoints.count - 1)] : @[];
    
    MTRBaseClusterBinding *bindingCluster = [[MTRBaseClusterBinding alloc] initWithDevice:ovenDevice
                                                                                endpoint:endpoint.integerValue
                                                                                   queue:dispatch_get_main_queue()];
    
    [bindingCluster writeAttributeBindingWithValue:@[] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            if (remaining.count > 0) {
                [self unbindFromOven:ovenDevice ovenNodeId:ovenNodeId tryEndpoints:remaining completion:completion];
            } else {
                if (completion) completion(NO, error);
            }
        } else {
            NSLog(@"Unbinding successful!");
            [self removeBindingInfoForOvenNodeId:ovenNodeId];
            if (completion) completion(YES, nil);
        }
    }];
}

+ (void)checkBindingStateWithOvenNodeId:(NSNumber *)ovenNodeId
                              completion:(BindingStateCompletion)completion {
    
    MTRDeviceController *controller = InitializeMTR();
    if (!controller) {
        NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize Matter controller"}];
        if (completion) completion(NO, nil, error);
        return;
    }
    
    MTRBaseDevice *ovenDevice = [MTRBaseDevice deviceWithNodeID:ovenNodeId controller:controller];
    if (!ovenDevice) {
        NSError *error = [NSError errorWithDomain:@"DeviceBindingManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to get Oven device"}];
        if (completion) completion(NO, nil, error);
        return;
    }
    
    // Try Oven's OnOff endpoint first (3), then fallbacks (1, 0)
    [self readBindingStateFromOven:ovenDevice
                        ovenNodeId:ovenNodeId
                      tryEndpoints:@[@3, @1, @0]
                        completion:completion];
}

+ (void)readBindingStateFromOven:(MTRBaseDevice *)ovenDevice
                      ovenNodeId:(NSNumber *)ovenNodeId
                    tryEndpoints:(NSArray<NSNumber *> *)endpoints
                      completion:(BindingStateCompletion)completion {
    
    if (endpoints.count == 0) {
        if (completion) completion(NO, nil, nil);
        return;
    }
    
    NSNumber *endpoint = endpoints[0];
    NSArray *remaining = endpoints.count > 1 ? [endpoints subarrayWithRange:NSMakeRange(1, endpoints.count - 1)] : @[];
    
    MTRBaseClusterBinding *bindingCluster = [[MTRBaseClusterBinding alloc] initWithDevice:ovenDevice
                                                                                endpoint:endpoint.integerValue
                                                                                   queue:dispatch_get_main_queue()];
    
    MTRReadParams *readParams = [[MTRReadParams alloc] init];
    [bindingCluster readAttributeBindingWithParams:readParams completion:^(NSArray * _Nullable value, NSError * _Nullable error) {
        if (error) {
            if (remaining.count > 0) {
                [self readBindingStateFromOven:ovenDevice ovenNodeId:ovenNodeId tryEndpoints:remaining completion:completion];
            } else {
                if (completion) completion(NO, nil, error);
            }
        } else {
            BOOL isBound = (value != nil && value.count > 0);
            NSDictionary *bindingInfo = isBound ? [self getBindingInfoForOvenNodeId:ovenNodeId] : nil;
            NSLog(@"Binding state on endpoint %@: %@, bindings count: %lu", endpoint, isBound ? @"BOUND" : @"NOT BOUND", (unsigned long)value.count);
            if (completion) completion(isBound, bindingInfo, nil);
        }
    }];
}

#pragma mark - Persistence

+ (void)saveBindingInfoWithOvenNodeId:(NSNumber *)ovenNodeId
                      rangeHoodNodeId:(NSNumber *)rangeHoodNodeId {
    
    NSString *key = [NSString stringWithFormat:@"%@%@", kBindingInfoKeyPrefix, ovenNodeId];
    NSDictionary *bindingInfo = @{
        @"ovenNodeId": ovenNodeId,
        @"rangeHoodNodeId": rangeHoodNodeId,
        @"boundDate": [NSDate date]
    };
    
    [[NSUserDefaults standardUserDefaults] setObject:bindingInfo forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"Saved binding info: Oven %@ -> RangeHood %@", ovenNodeId, rangeHoodNodeId);
}

+ (NSDictionary *)getBindingInfoForOvenNodeId:(NSNumber *)ovenNodeId {
    if (!ovenNodeId) {
        return nil;
    }
    
    NSString *key = [NSString stringWithFormat:@"%@%@", kBindingInfoKeyPrefix, ovenNodeId];
    id bindingInfoObj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if (bindingInfoObj && [bindingInfoObj isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)bindingInfoObj;
    }
    
    return nil;
}

+ (void)removeBindingInfoForOvenNodeId:(NSNumber *)ovenNodeId {
    if (!ovenNodeId) {
        return;
    }
    
    NSString *key = [NSString stringWithFormat:@"%@%@", kBindingInfoKeyPrefix, ovenNodeId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"Removed binding info for Oven %@", ovenNodeId);
}

+ (BOOL)isOvenBoundToRangeHood:(NSNumber *)ovenNodeId {
    if (!ovenNodeId) {
        return NO;
    }
    
    NSDictionary *bindingInfo = [self getBindingInfoForOvenNodeId:ovenNodeId];
    return (bindingInfo != nil && [bindingInfo isKindOfClass:[NSDictionary class]]);
}

@end
