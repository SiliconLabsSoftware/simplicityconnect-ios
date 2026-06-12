//
//  RangeHoodViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 20/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>

@class RangeHoodDeviceManager;

NS_ASSUME_NONNULL_BEGIN

@interface RangeHoodViewController : UIViewController

@property (strong, nonatomic) NSNumber *nodeId;
@property (strong, nonatomic) NSNumber *endPoint;

// Fan UI Outlets
@property (weak, nonatomic) IBOutlet UILabel *fanStatusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *fanImageView;
@property (weak, nonatomic) IBOutlet UIButton *fanOnButton;
@property (weak, nonatomic) IBOutlet UIButton *fanOffButton;

// Light UI Outlets
@property (weak, nonatomic) IBOutlet UILabel *lightStatusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *lightImageView;
@property (weak, nonatomic) IBOutlet UIButton *lightOnButton;
@property (weak, nonatomic) IBOutlet UIButton *lightOffButton;

@property (strong, nonatomic) RangeHoodDeviceManager *deviceManager;

- (void)showAlertPopup:(NSString *)message;
- (void)showAlertInfoPopup:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
