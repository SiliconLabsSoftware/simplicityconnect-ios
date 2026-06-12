//
//  OvenViewController+UI.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 24/01/26.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

#import "OvenViewController+UI.h"
#import "UIButton+SILMatterStyle.h"

@implementation OvenViewController (UI)

- (void)setupButtonStyles {
    self.ovenOffButton.configuration = nil;
    self.ovenOffButton.configurationUpdateHandler = nil;
    [self.ovenOffButton setTitle:@"OFF" forState:UIControlStateNormal];
    UIFont *offFont = [UIFont fontWithName:@"Stolzl-Bold" size:14.0];
    self.ovenOffButton.titleLabel.font = offFont ?: [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    self.ovenOffButton.layer.cornerRadius = 10.0;
    self.ovenOffButton.layer.masksToBounds = YES;
    self.ovenOffButton.layer.borderWidth = 0.0;
    self.ovenOffButton.tintColor = [UIColor whiteColor];

    // Load the oven icon programmatically and force template rendering so tintColor changes are visible.
    UIImage *ovenIcon = [UIImage imageNamed:@"icon_oven"];
    self.ovenImage.image = [ovenIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.ovenImage.tintColor = [UIColor systemGrayColor];

    if (self.bindingButton) {
        [self.bindingButton applySILMatterOutlinedStyleWithTitle:@"Bind to range hood"];
    }

    self.modeCollectionView.userInteractionEnabled = YES;
    self.modeCollectionView.alpha = 1.0;
}

- (void)setupModeCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(10, 16, 10, 16);

    self.modeCollectionView.collectionViewLayout = layout;
    self.modeCollectionView.delegate = self;
    self.modeCollectionView.dataSource = self;
    self.modeCollectionView.backgroundColor = [UIColor systemGroupedBackgroundColor];

    [self.modeCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ModeCell"];
}

- (void)updateButtonStatesForOvenOn:(BOOL)isOn {
    self.ovenOffButton.layer.borderWidth = 0.0;
    if (isOn) {
        self.ovenOffButton.backgroundColor = [UIColor appPrimaryBrand];
        [self.ovenOffButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        self.ovenStatus.text = @"ON";
        self.ovenStatus.textColor = [UIColor sil_greenColor];
        self.ovenImage.tintColor = [UIColor appPrimaryBrand];

    } else {
        self.ovenOffButton.backgroundColor = [UIColor sil_silverChaliceColor];
        [self.ovenOffButton setTitleColor:[UIColor sil_masalaColor] forState:UIControlStateNormal];

        self.ovenStatus.text = @"Off";
        self.ovenStatus.textColor = [UIColor appPrimaryBrand];
        self.ovenImage.tintColor = [UIColor systemGrayColor];
    }
}

- (UIImage *)iconForMode:(NSInteger)mode {
    return [self iconForModeLabel:nil mode:mode];
}

- (UIImage *)iconForModeLabel:(nullable NSString *)modeLabel mode:(NSInteger)mode {
    NSString *assetName = [self assetNameForModeLabel:modeLabel];
    if (assetName.length == 0) {
        assetName = [self assetNameForModeIndex:mode];
    }
    UIImage *image = [UIImage imageNamed:assetName];
    if (!image) {
        image = [UIImage imageNamed:@"icon_oven"];
    }
    return image;
}

- (NSString *)assetNameForModeLabel:(nullable NSString *)modeLabel {
    if (modeLabel.length == 0) {
        return nil;
    }
    NSString *normalized = [modeLabel.lowercaseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([normalized containsString:@"convection"] && [normalized containsString:@"bake"]) {
        return @"icon_convection_bake";
    }
    if ([normalized containsString:@"convection"] && [normalized containsString:@"roast"]) {
        return @"icon_convection_roast";
    }
    if ([normalized containsString:@"convection"]) {
        return @"icon_convection";
    }
    if ([normalized containsString:@"clean"]) {
        return @"icon_clean";
    }
    if ([normalized containsString:@"grill"] || [normalized containsString:@"broil"]) {
        return @"icon_grill";
    }
    if ([normalized containsString:@"proof"]) {
        return @"icon_proofing";
    }
    if ([normalized containsString:@"warm"]) {
        return @"icon_warming";
    }
    if ([normalized containsString:@"roast"]) {
        return @"icon_roast";
    }
    if ([normalized containsString:@"bake"]) {
        return @"icon_bake";
    }
    if ([normalized containsString:@"oven"]) {
        return @"icon_oven";
    }
    return nil;
}

- (NSString *)assetNameForModeIndex:(NSInteger)mode {
    switch (mode) {
        case 0:  return @"icon_bake";
        case 1:  return @"icon_convection";
        case 2:  return @"icon_convection_bake";
        case 3:  return @"icon_convection_roast";
        case 4:  return @"icon_grill";
        case 5:  return @"icon_roast";
        case 6:  return @"icon_warming";
        case 7:  return @"icon_proofing";
        case 8:  return @"icon_clean";
        default: return @"icon_oven";
    }
}

@end
