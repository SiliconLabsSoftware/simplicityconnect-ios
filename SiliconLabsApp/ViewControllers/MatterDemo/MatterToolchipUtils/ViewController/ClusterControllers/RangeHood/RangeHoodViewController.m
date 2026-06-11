//
//  RangeHoodViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 20/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import "RangeHoodViewController.h"
#import "RangeHoodDeviceManager.h"
#import "UIColor+SILColors.h"
#import "UIButton+SILMatterStyle.h"
#import "CHIPUIViewUtils.h"

@interface RangeHoodViewController ()

@property (strong, nonatomic) NSMutableArray *rangeHoodDeviceList;

@end

@implementation RangeHoodViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.rangeHoodDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    
    self.deviceManager = [[RangeHoodDeviceManager alloc] initWithNodeId:self.nodeId];
    
    [self setupUI];
    [self checkDeviceConnection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [CHIPUIViewUtils addRedLineBelowNavigationBarTo:self];
    [self readFanState];
    [self readLightState];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary *userInfo = @{@"controller": @"RangeHoodViewController"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"controllerNotification"
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark - UI Setup

- (void)setupUI {
    [self.fanOnButton applySILMatterOutlinedStyleWithTitle:@"ON"];
    [self.fanOffButton applySILMatterOutlinedStyleWithTitle:@"OFF"];
    [self.lightOnButton applySILMatterOutlinedStyleWithTitle:@"ON"];
    [self.lightOffButton applySILMatterOutlinedStyleWithTitle:@"OFF"];
    
    // Set initial states
    [self updateFanButtonStates:NO];
    [self updateLightButtonStates:NO];
}

- (void)updateFanButtonStates:(BOOL)isOn {
    [self.fanOnButton setSILMatterActive:isOn];
    [self.fanOffButton setSILMatterActive:!isOn];

    self.fanImageView.image = [[UIImage imageNamed:@"icon_fan"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (isOn) {
        self.fanStatusLabel.text = @"ON";
        self.fanStatusLabel.textColor = [UIColor sil_greenColor];
        self.fanImageView.tintColor = [UIColor systemRedColor];
    } else {
        self.fanStatusLabel.text = @"OFF";
        self.fanStatusLabel.textColor = [UIColor appPrimaryBrand];
        self.fanImageView.tintColor = [UIColor systemGrayColor];
    }
}

- (void)updateLightButtonStates:(BOOL)isOn {
    [self.lightOnButton setSILMatterActive:isOn];
    [self.lightOffButton setSILMatterActive:!isOn];

    if (isOn) {
        self.lightStatusLabel.text = @"ON";
        self.lightStatusLabel.textColor = [UIColor sil_greenColor];
        self.lightImageView.image = [UIImage imageNamed:@"light_icon"];
        self.lightImageView.tintColor = [UIColor systemYellowColor];
    } else {
        self.lightStatusLabel.text = @"OFF";
        self.lightStatusLabel.textColor = [UIColor appPrimaryBrand];
        self.lightImageView.image = [UIImage imageNamed:@"light_icon"];
        self.lightImageView.tintColor = [UIColor systemGrayColor];
    }
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

- (void)readFanState {
    [self.deviceManager readFanStateWithCompletion:^(BOOL isOn, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error reading fan state: %@", error);
            return;
        }
        NSLog(@"Fan state: %@ (1=ON, 0=OFF)", @(isOn));
        [self updateFanButtonStates:isOn];
    }];
}

- (void)readLightState {
    [self.deviceManager readLightStateWithCompletion:^(BOOL isOn, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error reading light state: %@", error);
            return;
        }
        NSLog(@"Light state: %@ (1=ON, 0=OFF)", @(isOn));
        [self updateLightButtonStates:isOn];
    }];
}

- (void)turnFanOn {
    [self.deviceManager turnFanOnWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error turning fan on: %@", error);
            [self showAlertInfoPopup:[NSString stringWithFormat:@"Failed to turn fan on: %@", error.localizedDescription]];
        } else {
            NSLog(@"Fan turned on successfully");
            [self updateFanButtonStates:YES];
        }
    }];
}

- (void)turnFanOff {
    [self.deviceManager turnFanOffWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error turning fan off: %@", error);
            [self showAlertInfoPopup:[NSString stringWithFormat:@"Failed to turn fan off: %@", error.localizedDescription]];
        } else {
            NSLog(@"Fan turned off successfully");
            [self updateFanButtonStates:NO];
        }
    }];
}

- (void)turnLightOn {
    [self.deviceManager turnLightOnWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error turning light on: %@", error);
            [self showAlertInfoPopup:[NSString stringWithFormat:@"Failed to turn light on: %@", error.localizedDescription]];
        } else {
            NSLog(@"Light turned on successfully");
            [self updateLightButtonStates:YES];
        }
    }];
}

- (void)turnLightOff {
    [self.deviceManager turnLightOffWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error turning light off: %@", error);
            [self showAlertInfoPopup:[NSString stringWithFormat:@"Failed to turn light off: %@", error.localizedDescription]];
        } else {
            NSLog(@"Light turned off successfully");
            [self updateLightButtonStates:NO];
        }
    }];
}

#pragma mark - Device Status Persistence

- (void)saveDeviceStatus:(NSString *)connected {
    NSUInteger index = [self.rangeHoodDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        return [[item objectForKey:@"nodeId"] intValue] == self.nodeId.intValue;
    }];

    if (index != NSNotFound && self.rangeHoodDeviceList.count > 0) {
        NSMutableDictionary *deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:[self.rangeHoodDeviceList[index] valueForKey:@"deviceType"] forKey:@"deviceType"];
        [deviceDic setObject:[self.rangeHoodDeviceList[index] valueForKey:@"nodeId"] forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[self.rangeHoodDeviceList[index] valueForKey:@"title"] forKey:@"title"];
        [deviceDic setObject:@"false" forKey:@"isBinded"];
        [deviceDic setObject:@"" forKey:@"connectedToDeviceType"];
        [deviceDic setObject:@"" forKey:@"connectedToDeviceName"];
        [deviceDic setObject:@"" forKey:@"connectedToNodeId"];

        [self.rangeHoodDeviceList replaceObjectAtIndex:index withObject:deviceDic];
        [[NSUserDefaults standardUserDefaults] setObject:self.rangeHoodDeviceList forKey:@"saved_list"];
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

- (IBAction)fanOnAction:(id)sender {
    [self turnFanOn];
}

- (IBAction)fanOffAction:(id)sender {
    [self turnFanOff];
}

- (IBAction)lightOnAction:(id)sender {
    [self turnLightOn];
}

- (IBAction)lightOffAction:(id)sender {
    [self turnLightOff];
}

@end
