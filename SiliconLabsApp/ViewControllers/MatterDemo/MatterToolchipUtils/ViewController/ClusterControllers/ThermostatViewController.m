//
//  ThermostatViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "ThermostatViewController.h"
#import "UIButton+SILMatterStyle.h"
#import "DefaultsUtils.h"
#import "CHIPUIViewUtils.h"
#import <Matter/Matter.h>

@interface ThermostatViewController ()
@property (strong, nonatomic) NSTimer *tempRefreshTimer;

@end

@implementation ThermostatViewController
@synthesize nodeId, endPoint;
NSMutableArray * deviceListTemperature;

- (void)viewDidLoad {
    [super viewDidLoad];
    deviceListTemperature = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    [self readDevice];
    [self autoRefress];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [CHIPUIViewUtils addRedLineBelowNavigationBarTo:self];
    
    _bgView.layer.cornerRadius = 10;
    _bgView.clipsToBounds = YES;
    
    [self setupUIElements];
    [self readThermos];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([_tempRefreshTimer isValid]) {
        [_tempRefreshTimer invalidate];
    }
    _tempRefreshTimer = nil;
    NSDictionary* userInfo = @{@"controller": @"ThermostatViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}

// MARK: UI Setup

- (void)setupUIElements {
    [_refressButton applySILMatterOutlinedStyleWithTitle:@"Refresh"];
    _titleLabel.font = [UIFont fontWithName:@"Stolzl-Medium" size:14.0];
    _titleLabel.textColor = [UIColor colorNamed:@"sil_primaryTextColor"];
}

- (void)updateTempInUI:(int)newTemp
{
    float tempInCelsius = (float) newTemp / 100.0f;
    [self displayTemperatureInCelsius:tempInCelsius];
    _deviceCurrentStatusLabel.hidden = YES;
}

// Builds a two-style string like "34" + ".19°C" where the integer part is
// rendered at the label's full size and the fractional portion (with the unit)
// is rendered smaller, matching the design.
- (void)displayTemperatureInCelsius:(float)tempInCelsius
{
    NSString *full = [NSString stringWithFormat:@"%.2f", tempInCelsius];
    NSRange dotRange = [full rangeOfString:@"."];
    NSString *integerString = (dotRange.location != NSNotFound) ? [full substringToIndex:dotRange.location] : full;
    NSString *decimalString = (dotRange.location != NSNotFound)
        ? [NSString stringWithFormat:@"%@°C", [full substringFromIndex:dotRange.location]]
        : @"°C";

    CGFloat largeSize = 64.0;
    CGFloat smallSize = 40.0;
    UIFont *largeFont = [UIFont fontWithName:@"Roboto-Light" size:largeSize] ?: [UIFont systemFontOfSize:largeSize weight:UIFontWeightLight];
    UIFont *smallFont = [UIFont fontWithName:@"Roboto-Light" size:smallSize] ?: [UIFont systemFontOfSize:smallSize weight:UIFontWeightLight];
    UIColor *textColor = _tempValueLabel.textColor ?: [UIColor colorNamed:@"sil_siliconLabsRedColor"];

    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] init];
    [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:integerString attributes:@{
        NSFontAttributeName: largeFont,
        NSForegroundColorAttributeName: textColor,
    }]];
    [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:decimalString attributes:@{
        NSFontAttributeName: smallFont,
        NSForegroundColorAttributeName: textColor,
    }]];

    _tempValueLabel.attributedText = attributed;
    NSLog(@"Status: Updated temp in UI to %@%@", integerString, decimalString);
}

- (void)readThermos {
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        
        if (chipDevice) {
            if (@available(iOS 16.4, *)) {
                MTRBaseClusterThermostat * temp = [[MTRBaseClusterThermostat alloc] initWithDevice:chipDevice endpointID:@1 queue:dispatch_get_main_queue()];
                
                [temp readAttributeLocalTemperatureWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                    
                    if (error) {
                        NSLog(@"Thermostat: Failed to read LocalTemperature. Error: %@", error.localizedDescription);
                        return;
                    }
                    
                    NSLog(@"Thermostat: Raw LocalTemperature value from matter device = %@ (intValue=%d, floatValue=%f)", value, value.intValue, value.floatValue);
                    
                    float tempInCelsius = value.floatValue / 100.0f;
                    NSLog(@"Thermostat: Converted temperature in Celsius = %.2f °C", tempInCelsius);
                    
                    [self displayTemperatureInCelsius:tempInCelsius];
                }];
            }
        } else {
            NSLog(@"Status: Failed to establish a connection with the device");
        }
    })) {
        NSLog(@"Status: Waiting for connection with the device");
    } else {
        NSLog(@"Status: Failed to trigger the connection with the device");
    }
}

// MARK: UIButton actions

- (IBAction)refressAction:(id)sender {
    [self readThermos];
}

- (void) getCurrentTemp:(NSTimer *)timer {
    [self readThermos];
}

#pragma mark - Timers

- (void)autoRefress {
    self.tempRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                             target:self selector:@selector(getCurrentTemp:) userInfo:nil repeats:YES];
}
-(void) readDevice {
    uint64_t _devId = nodeId.intValue;
    [SVProgressHUD showWithStatus: @"Connecting to commissioned device..."];
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            MTRBaseClusterDescriptor * descriptorCluster =
            [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                    endpoint:1
                                                       queue:dispatch_get_main_queue()];
            
            [descriptorCluster readAttributeDeviceListWithCompletionHandler:^(NSArray * _Nullable value, NSError * _Nullable error) {
                if (error) {
                    [self setDeviceStatus:@"0" nodeId:self->nodeId];
                    return;
                }
                [self setDeviceStatus:@"1" nodeId:self->nodeId];
            }];
        } else {
            [self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
        // Connection in progress; status will be reported in the completion block.
    } else {
        [self setDeviceStatus:@"0" nodeId:self->nodeId];
    }
}
- (void)setDeviceStatus:(NSString *)connected nodeId:(NSNumber *)node_id{
    NSUInteger index2 = [deviceListTemperature indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    if([deviceListTemperature count] > 0){
        NSNumber *nodeId = [deviceListTemperature[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [deviceListTemperature[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[deviceListTemperature[index2] valueForKey:@"title"] forKey:@"title"];
        
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];

        [deviceListTemperature replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:deviceListTemperature forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",deviceListTemperature);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }
}
-(void) showAlertPopup:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Go back to with payload and add device
            [self.navigationController popViewControllerAnimated: YES];
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
