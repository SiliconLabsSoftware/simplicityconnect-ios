//
//  OvenViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 20/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import "OvenViewController.h"
#import "OvenViewController+UI.h"
#import "OvenDeviceManager.h"
#import "UIColor+SILColors.h"
#import "UIButton+SILMatterStyle.h"
#import "DefaultsUtils.h"
#import "DeviceBindingManager.h"
#import "RangeHoodDeviceManager.h"
#import "CHIPUIViewUtils.h"

@interface OvenViewController ()

@property (strong, nonatomic) NSMutableArray *ovenDeviceList;
@property (strong, nonatomic) NSNumber *boundRangeHoodNodeId;
@property (strong, nonatomic) RangeHoodDeviceManager *rangeHoodDeviceManager;
@property (assign, nonatomic) BOOL hasSubscribedToRangeHood;
@property (strong, nonatomic) NSTimer *rangeHoodControlDebounceTimer;
@property (assign, nonatomic) BOOL pendingRangeHoodOvenState;
@property (strong, nonatomic) NSTimer *rangeHoodStatusPollTimer;
@property (strong, nonatomic) NSNumber *lastDisplayedFanOn;   // nil=unknown, @YES/@NO to prevent flickering from conflicting updates
@property (strong, nonatomic) NSNumber *lastDisplayedLightOn;
@property (assign, nonatomic) BOOL rangeHoodControlInProgress;  // prevents overlapping Range Hood commands
@property (strong, nonatomic) NSTimer *rangeHoodLoaderRestartTimer;  // restarts loader 2 sec after observer done

@end

@implementation OvenViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.ovenDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    self.supportedModes = @[];
    self.currentSelectedMode = @0;

    self.deviceManager = [[OvenDeviceManager alloc] initWithNodeId:self.nodeId];
    
    // Check if Oven is bound to RangeHood
    [self checkBindingState];
    
    // Setup binding button if available
    if (self.bindingButton) {
        [self.bindingButton addTarget:self action:@selector(showBindingOptions) forControlEvents:UIControlEventTouchUpInside];
        [self updateBindingButtonTitle];
    }

    [self setupModeCollectionView];
    [self setupButtonStyles];
    [self updateRangeHoodViewVisibility];
    [self checkDeviceConnection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [CHIPUIViewUtils addRedLineBelowNavigationBarTo:self];
    [self readOvenOnOffState];
    [self updateRangeHoodViewVisibility];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self readOvenSupportedModes];
    [self subscribeToOvenStateChanges];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self cancelRangeHoodControlDebounce];
    [self stopRangeHoodStatusPolling];
    [self cancelRangeHoodLoaderRestart];
    self.rangeHoodControlInProgress = NO;
    //[self showRangeHoodActivityIndicator:NO];
    NSDictionary *userInfo = @{@"controller": @"OvenViewController"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"controllerNotification"
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark - Device Operations

- (void)checkDeviceConnection {
    [SVProgressHUD showWithStatus:@"Connecting to device..."];
    [self.deviceManager checkConnectionWithCompletion:^(BOOL connected) {
        [self saveDeviceStatus:connected ? @"1" : @"0"];
        if (!connected) {
            [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
        }
    }];
}

- (void)readOvenOnOffState {
    [self.deviceManager readOnOffStateWithCompletion:^(BOOL isOn, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error reading OnOff state: %@", error);
            return;
        }
        NSLog(@"Oven OnOff state: %@ (1=ON, 0=OFF)", @(isOn));
        [self updateButtonStatesForOvenOn:isOn];
    }];
}

- (void)subscribeToOvenStateChanges {
    // Subscribe to OnOff state changes to receive updates when device state changes externally
    MTRSubscribeParams *subscribeParams = [[MTRSubscribeParams alloc] initWithMinInterval:@2 maxInterval:@5];
    
    __weak typeof(self) weakSelf = self;
    [self.deviceManager subscribeToOnOffStateWithParams:subscribeParams stateChangeHandler:^(BOOL isOn, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error in OnOff subscription: %@", error);
            return;
        }
        
        NSLog(@"Oven state changed externally - isOn: %@ (1=ON, 0=OFF)", @(isOn));
        
        // Update UI on main thread immediately (responsive)
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateButtonStatesForOvenOn:isOn];
            
            // Debounce RangeHood control - rapid button presses cause overlapping commands and stuck state
            if ([DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) {
                [weakSelf debouncedControlRangeHoodForOvenState:isOn];
            }
        });
    }];
}

- (void)readOvenSupportedModes {
    [self.deviceManager readSupportedModesWithCompletion:^(NSArray<NSDictionary *> *modes, NSNumber * _Nullable currentMode, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error reading supported modes: %@", error);
            return;
        }

        self.supportedModes = modes;

        if (currentMode) {
            self.currentSelectedMode = currentMode;
            NSLog(@"Current oven mode: %@", currentMode);
        } else if (modes.count > 0) {
            self.currentSelectedMode = modes[0][@"mode"];
        }

        [self.modeCollectionView reloadData];
    }];
}

- (void)turnOffOven {
    __weak typeof(self) weakSelf = self;
    [self.deviceManager turnOffWithCompletion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"Error turning oven off: %@", error);
                [weakSelf updateButtonStatesForOvenOn:YES];  // Revert optimistic UI
                if ([DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) {
                    [weakSelf readRangeHoodStatusAndUpdateUI];  // Revert Range Hood to actual state
                }
                [weakSelf showAlertInfoPopup:[NSString stringWithFormat:@"Failed to turn off: %@", error.localizedDescription]];
            } else {
                NSLog(@"Oven turned off successfully");
                [weakSelf updateButtonStatesForOvenOn:NO];
                
                // Automatically turn off RangeHood if bound
                if ([DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) {
                    [weakSelf controlBoundRangeHoodForOvenState:NO];
                }
            }
        });
    }];
}

- (void)setOvenMode:(NSNumber *)modeValue {
    [self.deviceManager setMode:modeValue completion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error setting oven mode: %@", error);
            [self showAlertInfoPopup:[NSString stringWithFormat:@"Failed to set mode: %@", error.localizedDescription]];
        } else {
            NSLog(@"Oven mode set successfully to: %@", modeValue);
        }
    }];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.supportedModes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ModeCell" forIndexPath:indexPath];

    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }

    NSDictionary *modeInfo = self.supportedModes[indexPath.row];
    NSNumber *modeValue = modeInfo[@"mode"];
    NSString *modeLabel = modeInfo[@"label"];
    BOOL isSelected = (self.currentSelectedMode != nil && modeValue != nil && [self.currentSelectedMode isEqualToNumber:modeValue]);

    [self configureCell:cell withLabel:modeLabel modeValue:modeValue isSelected:isSelected];

    return cell;
}

- (void)configureCell:(UICollectionViewCell *)cell withLabel:(NSString *)modeLabel modeValue:(NSNumber *)modeValue isSelected:(BOOL)isSelected {
    cell.contentView.layer.cornerRadius = 12;
    cell.contentView.layer.borderWidth = 2;
    cell.contentView.layer.masksToBounds = YES;

    if (isSelected) {
        cell.contentView.backgroundColor = [UIColor appPrimaryBrand];
        cell.contentView.layer.borderColor = [UIColor appPrimaryBrand].CGColor;
    } else {
        cell.contentView.backgroundColor = [UIColor systemBackgroundColor];
        cell.contentView.layer.borderColor = [UIColor systemGray4Color].CGColor;
    }

    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.image = [self iconForModeLabel:modeLabel mode:modeValue.integerValue];
    iconView.tintColor = isSelected ? [UIColor whiteColor] : [UIColor appPrimaryBrand];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [cell.contentView addSubview:iconView];

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = modeLabel;
    UIFont *modeFont = [UIFont fontWithName:@"Stolzl-Bold" size:12.0];
    label.font = modeFont ?: [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    label.textColor = isSelected ? [UIColor whiteColor] : [UIColor labelColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    [cell.contentView addSubview:label];

    if (isSelected) {
        UIImageView *checkmark = [[UIImageView alloc] init];
        checkmark.translatesAutoresizingMaskIntoConstraints = NO;
        checkmark.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        checkmark.tintColor = [UIColor whiteColor];
        [cell.contentView addSubview:checkmark];

        [NSLayoutConstraint activateConstraints:@[
            [checkmark.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:6],
            [checkmark.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-6],
            [checkmark.widthAnchor constraintEqualToConstant:18],
            [checkmark.heightAnchor constraintEqualToConstant:18]
        ]];
    }

    [NSLayoutConstraint activateConstraints:@[
        [iconView.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor],
        [iconView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:16],
        [iconView.widthAnchor constraintEqualToConstant:32],
        [iconView.heightAnchor constraintEqualToConstant:32],
        [label.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:8],
        [label.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:4],
        [label.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-4]
    ]];
}

#pragma mark - UICollectionView Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (collectionView.frame.size.width - 52) / 3;
    return CGSizeMake(width, 90);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.supportedModes.count) {
        return;
    }
    
    NSDictionary *modeInfo = self.supportedModes[indexPath.row];
    if (!modeInfo || ![modeInfo isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSNumber *selectedMode = modeInfo[@"mode"];
    if (!selectedMode || ![selectedMode isKindOfClass:[NSNumber class]]) {
        return;
    }

    self.currentSelectedMode = selectedMode;
    [self.modeCollectionView reloadData];
    [self setOvenMode:selectedMode];
}

#pragma mark - Device Status Persistence

- (void)saveDeviceStatus:(NSString *)connected {
    NSUInteger index = [self.ovenDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        return [[item objectForKey:@"nodeId"] intValue] == self.nodeId.intValue;
    }];

    if (index != NSNotFound && self.ovenDeviceList.count > 0) {
        NSMutableDictionary *deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:[self.ovenDeviceList[index] valueForKey:@"deviceType"] forKey:@"deviceType"];
        [deviceDic setObject:[self.ovenDeviceList[index] valueForKey:@"nodeId"] forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[self.ovenDeviceList[index] valueForKey:@"title"] forKey:@"title"];
        [deviceDic setObject:@"false" forKey:@"isBinded"];
        [deviceDic setObject:@"" forKey:@"connectedToDeviceType"];
        [deviceDic setObject:@"" forKey:@"connectedToDeviceName"];
        [deviceDic setObject:@"" forKey:@"connectedToNodeId"];

        [self.ovenDeviceList replaceObjectAtIndex:index withObject:deviceDic];
        [[NSUserDefaults standardUserDefaults] setObject:self.ovenDeviceList forKey:@"saved_list"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    [SVProgressHUD dismiss];
    
    if ([connected isEqualToString:@"0"]) {
            [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
        }
}

#pragma mark - Alerts

- (void)showAlertPopup:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertInfoPopup:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - IBAction

- (IBAction)ovenOffAction:(id)sender {
    // Optimistic UI - update Oven and Range Hood immediately for instant feedback
    [self updateButtonStatesForOvenOn:NO];
    if ([DeviceBindingManager isOvenBoundToRangeHood:self.nodeId]) {
        self.lastDisplayedFanOn = nil;
        self.lastDisplayedLightOn = nil;
        [self updateRangeHoodFanStatus:NO];
        [self updateRangeHoodLightStatus:NO];
    }
    [self turnOffOven];
}

#pragma mark - Binding Operations

- (void)checkBindingState {
    if (!self.nodeId) {
        NSLog(@"ERROR: nodeId is nil, cannot check binding state");
        return;
    }
    
    NSDictionary *bindingInfo = [DeviceBindingManager getBindingInfoForOvenNodeId:self.nodeId];
    if (bindingInfo && [bindingInfo isKindOfClass:[NSDictionary class]]) {
        id rangeHoodNodeIdObj = bindingInfo[@"rangeHoodNodeId"];
        if (rangeHoodNodeIdObj && [rangeHoodNodeIdObj isKindOfClass:[NSNumber class]]) {
            self.boundRangeHoodNodeId = (NSNumber *)rangeHoodNodeIdObj;
            NSLog(@"Oven is bound to RangeHood: %@", self.boundRangeHoodNodeId);
            
            // Initialize RangeHood device manager for automatic control
            self.rangeHoodDeviceManager = [[RangeHoodDeviceManager alloc] initWithNodeId:self.boundRangeHoodNodeId];
        } else {
            NSLog(@"WARNING: Invalid rangeHoodNodeId in binding info: %@", rangeHoodNodeIdObj);
            self.boundRangeHoodNodeId = nil;
        }
    } else {
        NSLog(@"Oven is not bound to any RangeHood");
        self.boundRangeHoodNodeId = nil;
    }
    
    [self updateBindingButtonTitle];
    [self updateRangeHoodViewVisibility];
}

- (void)updateRangeHoodViewVisibility {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isBound = [DeviceBindingManager isOvenBoundToRangeHood:self.nodeId];
        self.rangeHoodView.hidden = !isBound;
        [self cancelRangeHoodLoaderRestart];
        //[self showRangeHoodActivityIndicator:NO];  // Hide when visibility changes
        if (isBound) {
            self.lastDisplayedFanOn = nil;
            self.lastDisplayedLightOn = nil;
            //[self showRangeHoodActivityIndicator:YES];  // Start loader when paired
            [self readRangeHoodStatusAndUpdateUI];
            if (!self.hasSubscribedToRangeHood) {
                [self subscribeToRangeHoodStatus];
                self.hasSubscribedToRangeHood = YES;
            }
        } else {
            self.hasSubscribedToRangeHood = NO;
        }
    });
}

- (void)readRangeHoodStatusAndUpdateUI {
    if (!self.rangeHoodDeviceManager) return;
    
    //[self showRangeHoodActivityIndicator:YES];  // Start loader when waiting for Matter device
    
    __weak typeof(self) weakSelf = self;
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [self.rangeHoodDeviceManager readFanStateWithCompletion:^(BOOL isOn, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateRangeHoodFanStatus:isOn];
        });
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    [self.rangeHoodDeviceManager readLightStateWithCompletion:^(BOOL isOn, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateRangeHoodLightStatus:isOn];
        });
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [weakSelf scheduleRangeHoodLoaderRestart];  // Stop loader, restart after 2 sec
    });
}

- (void)updateRangeHoodFanStatus:(BOOL)isOn {
    if (!self.rangeHoodFanImage || !self.rangeHoodFanStatusLabel) return;
    // Only update UI when value actually changed - prevents flickering from subscription + polling conflicts
    if (self.lastDisplayedFanOn != nil && self.lastDisplayedFanOn.boolValue == isOn) return;
    self.lastDisplayedFanOn = @(isOn);
    
    if (isOn) {
        self.rangeHoodFanStatusLabel.text = @"ON";
        self.rangeHoodFanImage.image = [UIImage systemImageNamed:@"fan.fill"];
        self.rangeHoodFanImage.tintColor = [UIColor appPrimaryBrand];
    } else {
        self.rangeHoodFanStatusLabel.text = @"OFF";
        self.rangeHoodFanImage.image = [UIImage systemImageNamed:@"fan"];
        self.rangeHoodFanImage.tintColor = [UIColor systemGrayColor];
    }
}

- (void)updateRangeHoodLightStatus:(BOOL)isOn {
    if (!self.rangeHoodLightImage || !self.rangeHoodLightStatusLabel) return;
    // Only update UI when value actually changed - prevents flickering from subscription + polling conflicts
    if (self.lastDisplayedLightOn != nil && self.lastDisplayedLightOn.boolValue == isOn) return;
    self.lastDisplayedLightOn = @(isOn);
    
    if (isOn) {
        self.rangeHoodLightStatusLabel.text = @"ON";
        self.rangeHoodLightImage.image = [UIImage imageNamed:@"light_icon"];
        self.rangeHoodLightImage.tintColor = [UIColor systemYellowColor];
    } else {
        self.rangeHoodLightStatusLabel.text = @"OFF";
        self.rangeHoodLightImage.image = [UIImage imageNamed:@"light_icon"];
        self.rangeHoodLightImage.tintColor = [UIColor systemGrayColor];
    }
}

- (void)subscribeToRangeHoodStatus {
    if (!self.rangeHoodDeviceManager) return;

    // Balanced intervals - responsive but not so fast as to cause flickering
    MTRSubscribeParams *params = [[MTRSubscribeParams alloc] initWithMinInterval:@0 maxInterval:@2];
    if (@available(iOS 16.4, *)) {
        params.replaceExistingSubscriptions = NO;
    }

    __weak typeof(self) weakSelf = self;
    [self.rangeHoodDeviceManager subscribeToFanStateWithParams:params stateChangeHandler:^(BOOL isOn, NSError * _Nullable error) {
        if (!weakSelf || ![DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateRangeHoodFanStatus:isOn];
            [weakSelf scheduleRangeHoodLoaderRestart];  // Stop loader when observer done, restart after 2 sec
        });
    }];

    [self.rangeHoodDeviceManager subscribeToLightStateWithParams:params stateChangeHandler:^(BOOL isOn, NSError * _Nullable error) {
        if (!weakSelf || ![DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateRangeHoodLightStatus:isOn];
            [weakSelf scheduleRangeHoodLoaderRestart];  // Stop loader when observer done, restart after 2 sec
        });
    }];
}

- (void)startRangeHoodStatusPolling {
    [self stopRangeHoodStatusPolling];
    __weak typeof(self) weakSelf = self;
    self.rangeHoodStatusPollTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if ([DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) {
            [weakSelf readRangeHoodStatusAndUpdateUI];
        } else {
            [weakSelf stopRangeHoodStatusPolling];
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.rangeHoodStatusPollTimer forMode:NSRunLoopCommonModes];
}

- (void)stopRangeHoodStatusPolling {
    [self.rangeHoodStatusPollTimer invalidate];
    self.rangeHoodStatusPollTimer = nil;
}

- (void)updateBindingButtonTitle {
    if (!self.bindingButton || !self.nodeId) return;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.bindingButton) return;
        
        if ([DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) {
            [weakSelf.bindingButton applySILMatterOutlinedStyleWithTitle:@"Unbind from range hood"];
        } else {
            [weakSelf.bindingButton applySILMatterOutlinedStyleWithTitle:@"Bind to range hood"];
        }
    });
}

- (void)cancelRangeHoodControlDebounce {
    [self.rangeHoodControlDebounceTimer invalidate];
    self.rangeHoodControlDebounceTimer = nil;
}

- (void)debouncedControlRangeHoodForOvenState:(BOOL)ovenIsOn {
    [self cancelRangeHoodControlDebounce];
    self.pendingRangeHoodOvenState = ovenIsOn;

    __weak typeof(self) weakSelf = self;
    self.rangeHoodControlDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                                           repeats:NO
                                                                             block:^(NSTimer * _Nonnull timer) {
        [weakSelf cancelRangeHoodControlDebounce];
        if ([DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) {
            [weakSelf controlBoundRangeHoodForOvenState:weakSelf.pendingRangeHoodOvenState];
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.rangeHoodControlDebounceTimer forMode:NSRunLoopCommonModes];
}

- (void)controlBoundRangeHoodForOvenState:(BOOL)ovenIsOn {
    if (!self.boundRangeHoodNodeId) {
        NSLog(@"No RangeHood bound to Oven");
        return;
    }
    
    // Prevent overlapping commands - skip if control already in progress
    if (self.rangeHoodControlInProgress) {
        NSLog(@"RangeHood control already in progress, skipping");
        return;
    }
    
    if (!self.rangeHoodDeviceManager) {
        self.rangeHoodDeviceManager = [[RangeHoodDeviceManager alloc] initWithNodeId:self.boundRangeHoodNodeId];
    }
    
    NSLog(@"Automatically controlling RangeHood (nodeId: %@) based on Oven state: %@", 
          self.boundRangeHoodNodeId, ovenIsOn ? @"ON" : @"OFF");
    
    self.rangeHoodControlInProgress = YES;
    [self cancelRangeHoodLoaderRestart];  // Cancel pending restart when control starts
    //[self showRangeHoodActivityIndicator:YES];
    
    // Optimistic UI update - show expected state immediately so user sees instant feedback
    self.lastDisplayedFanOn = nil;
    self.lastDisplayedLightOn = nil;
    [self updateRangeHoodFanStatus:ovenIsOn];
    [self updateRangeHoodLightStatus:ovenIsOn];
    
    __weak typeof(self) weakSelf = self;
    void (^finishControl)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.rangeHoodControlInProgress = NO;
            // Keep loader running - don't hide, user sees something in progress
            [weakSelf readRangeHoodStatusAndUpdateUI];
        });
    };
    
    // Control both fan and light - fan first, then light (sequential avoids intermittent failures)
    if (ovenIsOn) {
        [self.rangeHoodDeviceManager turnFanOnWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to turn on RangeHood fan: %@", error);
            }
            [weakSelf.rangeHoodDeviceManager turnLightOnWithCompletion:^(NSError * _Nullable lightError) {
                if (lightError) {
                    NSLog(@"Failed to turn on RangeHood light: %@", lightError);
                }
                finishControl();
            }];
        }];
    } else {
        [self.rangeHoodDeviceManager turnFanOffWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to turn off RangeHood fan: %@", error);
            }
            [weakSelf.rangeHoodDeviceManager turnLightOffWithCompletion:^(NSError * _Nullable lightError) {
                if (lightError) {
                    NSLog(@"Failed to turn off RangeHood light: %@", lightError);
                }
                finishControl();
            }];
        }];
    }
}

//- (void)showRangeHoodActivityIndicator:(BOOL)show {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (self.activityIndicatorView) {
//            self.activityIndicatorView.hidden = !show;
//            if (show) {
//                [self.activityIndicatorView startAnimating];
//            } else {
//                [self.activityIndicatorView stopAnimating];
//            }
//        }
//    });
//}

- (void)scheduleRangeHoodLoaderRestart {
    [self cancelRangeHoodLoaderRestart];
    // Keep loader running continuously - don't hide, so user sees something in progress
    
    __weak typeof(self) weakSelf = self;
    self.rangeHoodLoaderRestartTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                                         repeats:NO
                                                                           block:^(NSTimer * _Nonnull timer) {
        if (![DeviceBindingManager isOvenBoundToRangeHood:weakSelf.nodeId]) return;
        //[weakSelf showRangeHoodActivityIndicator:YES];  // Start loader again after 2 sec
        [weakSelf readRangeHoodStatusAndUpdateUI];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.rangeHoodLoaderRestartTimer forMode:NSRunLoopCommonModes];
}

- (void)cancelRangeHoodLoaderRestart {
    [self.rangeHoodLoaderRestartTimer invalidate];
    self.rangeHoodLoaderRestartTimer = nil;
}

- (NSArray<NSDictionary *> *)getAvailableRangeHoodDevices {
    NSMutableArray *rangeHoodDevices = [NSMutableArray array];
    NSMutableArray *deviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    
    if (!deviceList || deviceList.count == 0) {
        return [rangeHoodDevices copy];
    }
    
    for (NSDictionary *device in deviceList) {
        if (!device || ![device isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        id deviceTypeObj = device[@"deviceType"];
        if (!deviceTypeObj) {
            continue;
        }
        
        NSString *deviceType = [NSString stringWithFormat:@"%@", deviceTypeObj];
        if (!deviceType || ![deviceType isEqualToString:RangeHood]) {
            continue;
        }
        
        // Don't include already bound RangeHood
        NSNumber *nodeId = device[@"nodeId"];
        if (!nodeId || ![nodeId isKindOfClass:[NSNumber class]]) {
            continue;
        }
        
        // Safe comparison: if boundRangeHoodNodeId is nil, include this device
        // If it's not nil, only include if nodeIds don't match
        if (self.boundRangeHoodNodeId == nil || ![nodeId isEqualToNumber:self.boundRangeHoodNodeId]) {
            [rangeHoodDevices addObject:device];
        }
    }
    
    return [rangeHoodDevices copy];
}

- (void)showBindingOptions {
    NSArray<NSDictionary *> *availableRangeHoods = [self getAvailableRangeHoodDevices];
    BOOL isBound = [DeviceBindingManager isOvenBoundToRangeHood:self.nodeId];
    
    if (availableRangeHoods.count == 0 && !isBound) {
        [self showAlertInfoPopup:@"No RangeHood devices available for binding. Please commission a RangeHood device first."];
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oven-RangeHood Binding"
                                                                   message:isBound 
                                                                         ? @"Oven is currently bound to a RangeHood. Would you like to unbind?"
                                                                         : @"Select an action:"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (isBound) {
        UIAlertAction *unbindAction = [UIAlertAction actionWithTitle:@"Unbind RangeHood"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction * _Nonnull action) {
            [self unbindFromRangeHood];
        }];
        [alert addAction:unbindAction];
    }
    
    if (availableRangeHoods.count > 0) {
        for (NSDictionary *rangeHood in availableRangeHoods) {
            if (!rangeHood || ![rangeHood isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            
            NSNumber *nodeId = rangeHood[@"nodeId"];
            if (!nodeId || ![nodeId isKindOfClass:[NSNumber class]]) {
                continue;
            }
            
            NSString *title = rangeHood[@"title"];
            if (!title || title.length == 0) {
                title = [NSString stringWithFormat:@"RangeHood %@", nodeId];
            }
            
            UIAlertAction *bindAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Bind to %@", title]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                [self bindToRangeHood:nodeId];
            }];
            [alert addAction:bindAction];
        }
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
    [alert addAction:cancelAction];
    
    // For iPad, set popover presentation
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 0, 0);
        alert.popoverPresentationController.permittedArrowDirections = 0;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)bindToRangeHood:(NSNumber *)rangeHoodNodeId {
    [SVProgressHUD showWithStatus:@"Binding Oven to RangeHood..."];
    __weak typeof(self) weakSelf = self;

    // RangeHood endpoints: Fan typically on endpoint 1, Light on endpoint 2
    // Adjust these based on your actual RangeHood implementation
    NSNumber *fanEndpoint = @1;
    NSNumber *lightEndpoint = @2;
    NSNumber *ovenEndpoint = self.deviceManager.onOffEndpoint ?: @3;
    
    [DeviceBindingManager bindOvenToRangeHoodWithOvenNodeId:self.nodeId
                                               ovenEndpoint:ovenEndpoint
                                           rangeHoodNodeId:rangeHoodNodeId
                                                fanEndpoint:fanEndpoint
                                              lightEndpoint:lightEndpoint
                                                 completion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (success) {
                weakSelf.boundRangeHoodNodeId = rangeHoodNodeId;
                weakSelf.rangeHoodDeviceManager = [[RangeHoodDeviceManager alloc] initWithNodeId:rangeHoodNodeId];
                weakSelf.hasSubscribedToRangeHood = NO; // New binding - subscribe fresh
                [weakSelf updateBindingButtonTitle];
                [weakSelf updateRangeHoodViewVisibility];
                [weakSelf showAlertInfoPopup:@"Successfully bound Oven to RangeHood. When Oven turns ON, RangeHood Fan and Light will automatically turn ON."];
            } else {
                [weakSelf showAlertInfoPopup:[NSString stringWithFormat:@"Failed to bind: %@", error.localizedDescription]];
            }
        });
    }];
}

- (void)unbindFromRangeHood {
    [SVProgressHUD showWithStatus:@"Unbinding Oven from RangeHood..."];
    
    __weak typeof(self) weakSelf = self;
    
    [DeviceBindingManager unbindOvenFromRangeHoodWithOvenNodeId:self.nodeId
                                                      completion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (success) {
                weakSelf.boundRangeHoodNodeId = nil;
                weakSelf.rangeHoodDeviceManager = nil;
                weakSelf.hasSubscribedToRangeHood = NO;
                [weakSelf cancelRangeHoodControlDebounce];
                [weakSelf stopRangeHoodStatusPolling];
                [weakSelf updateBindingButtonTitle];
                [weakSelf updateRangeHoodViewVisibility];
                [weakSelf showAlertInfoPopup:@"Successfully unbound Oven from RangeHood."];
            } else {
                [weakSelf showAlertInfoPopup:[NSString stringWithFormat:@"Failed to unbind: %@", error.localizedDescription]];
            }
        });
    }];
}

@end
