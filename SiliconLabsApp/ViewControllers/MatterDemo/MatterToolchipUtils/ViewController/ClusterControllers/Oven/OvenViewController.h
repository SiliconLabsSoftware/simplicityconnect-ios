//
//  OvenViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 20/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>

@class OvenDeviceManager;

NS_ASSUME_NONNULL_BEGIN

@interface OvenViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSNumber *nodeId;
@property (strong, nonatomic) NSNumber *endPoint;

@property (weak, nonatomic) IBOutlet UILabel *ovenStatus;
@property (weak, nonatomic) IBOutlet UIImageView *ovenImage;
@property (weak, nonatomic) IBOutlet UIButton *ovenOffButton;
@property (weak, nonatomic) IBOutlet UICollectionView *modeCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *bindingButton; 

@property (weak, nonatomic) IBOutlet UIView *rangeHoodView;
@property (weak, nonatomic) IBOutlet UIImageView *rangeHoodLightImage;
@property (weak, nonatomic) IBOutlet UILabel *rangeHoodLightStatusLabel;

@property (weak, nonatomic) IBOutlet UIImageView *rangeHoodFanImage;
@property (weak, nonatomic) IBOutlet UILabel *rangeHoodFanStatusLabel;

//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) NSArray<NSDictionary *> *supportedModes;
@property (strong, nonatomic) NSNumber *currentSelectedMode;
@property (strong, nonatomic) OvenDeviceManager *deviceManager;

- (void)showAlertPopup:(NSString *)message;
- (void)showAlertInfoPopup:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
