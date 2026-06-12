//
//  DeviceBindingManager.h
//  BlueGecko
//
//  Created for Oven-RangeHood Binding
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Matter/Matter.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BindingCompletion)(BOOL success, NSError * _Nullable error);
typedef void(^BindingStateCompletion)(BOOL isBound, NSDictionary * _Nullable bindingInfo, NSError * _Nullable error);

/**
 * DeviceBindingManager handles Matter device bindings between Oven and RangeHood devices.
 * This enables automatic control: when Oven turns ON, RangeHood Fan and Light automatically turn ON.
 */
@interface DeviceBindingManager : NSObject

/**
 * Bind Oven device to RangeHood Fan and Light
 * @param ovenNodeId Source device (Oven) node ID
 * @param ovenEndpoint Oven endpoint (typically @3 for OnOff cluster)
 * @param rangeHoodNodeId Target device (RangeHood) node ID
 * @param fanEndpoint RangeHood fan endpoint
 * @param lightEndpoint RangeHood light endpoint
 * @param completion Completion handler
 */
+ (void)bindOvenToRangeHoodWithOvenNodeId:(NSNumber *)ovenNodeId
                              ovenEndpoint:(NSNumber *)ovenEndpoint
                          rangeHoodNodeId:(NSNumber *)rangeHoodNodeId
                               fanEndpoint:(NSNumber *)fanEndpoint
                             lightEndpoint:(NSNumber *)lightEndpoint
                                 completion:(BindingCompletion)completion;

/**
 * Unbind Oven from RangeHood
 * @param ovenNodeId Oven node ID
 * @param completion Completion handler
 */
+ (void)unbindOvenFromRangeHoodWithOvenNodeId:(NSNumber *)ovenNodeId
                                    completion:(BindingCompletion)completion;

/**
 * Check if Oven is bound to RangeHood
 * @param ovenNodeId Oven node ID
 * @param completion Completion handler with binding state
 */
+ (void)checkBindingStateWithOvenNodeId:(NSNumber *)ovenNodeId
                              completion:(BindingStateCompletion)completion;

/**
 * Save binding information to UserDefaults
 * @param ovenNodeId Oven node ID
 * @param rangeHoodNodeId RangeHood node ID
 */
+ (void)saveBindingInfoWithOvenNodeId:(NSNumber *)ovenNodeId
                      rangeHoodNodeId:(NSNumber *)rangeHoodNodeId;

/**
 * Get binding information from UserDefaults
 * @param ovenNodeId Oven node ID
 * @return Dictionary with binding info or nil if not bound
 */
+ (NSDictionary * _Nullable)getBindingInfoForOvenNodeId:(NSNumber *)ovenNodeId;

/**
 * Remove binding information from UserDefaults
 * @param ovenNodeId Oven node ID
 */
+ (void)removeBindingInfoForOvenNodeId:(NSNumber *)ovenNodeId;

/**
 * Check if devices are bound
 * @param ovenNodeId Oven node ID
 * @return YES if bound, NO otherwise
 */
+ (BOOL)isOvenBoundToRangeHood:(NSNumber *)ovenNodeId;

@end

NS_ASSUME_NONNULL_END
