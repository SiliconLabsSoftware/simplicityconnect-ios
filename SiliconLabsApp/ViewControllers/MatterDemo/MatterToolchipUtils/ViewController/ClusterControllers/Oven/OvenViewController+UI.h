//
//  OvenViewController+UI.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 24/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import "OvenViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OvenViewController (UI)

- (void)setupButtonStyles;
- (void)setupModeCollectionView;
- (void)setupTemperatureControls;
- (void)updateButtonStatesForOvenOn:(BOOL)isOn;
- (UIImage *)iconForMode:(NSInteger)mode;
- (UIImage *)iconForModeLabel:(nullable NSString *)modeLabel mode:(NSInteger)mode;

@end

NS_ASSUME_NONNULL_END
