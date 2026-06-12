//
//  SILAppearance.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/26/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILAppearance.h"
#import "UIColor+SILColors.h"
#import "UIImage+SILHelpers.h"
#import <SVProgressHUD/SVProgressHUD.h>

@implementation SILAppearance

+ (void)setupAppearance {
    [self setupNavigationBarAppearance];
    [self setupBarButtonItemAppearance];
    [self setupTextFieldAppearance];
    [self setupSegmentedControlAppearance];
    
    [self setupSVProgressHUD];
}

+ (void)setupSegmentedControlAppearance {
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[UISegmentedControl.class]] setNumberOfLines:2];
    
    UISegmentedControl.appearance.selectedSegmentTintColor = [UIColor sil_bgWhiteColor];
    UISegmentedControl.appearance.backgroundColor = [UIColor sil_lightGreyColor];
    UIFont *segmentFont = [UIFont helveticaNeueBoldWithSize:11];
    [UISegmentedControl.appearance setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : segmentFont } forState:UIControlStateNormal];
    [UISegmentedControl.appearance setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : segmentFont } forState:UIControlStateSelected];
}

+ (void)setupNavigationBarAppearance {
    UINavigationBarAppearance *x = [UINavigationBarAppearance new];
    x.backgroundColor = [UIColor appNavigationPrimary];
    x.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont stolzlMediumWithSize:17.0],
    };
    
    // Add red bottom line to navigation bar
    x.shadowColor = [UIColor appPrimaryBrand];
    
    UINavigationBar.appearance.standardAppearance = x;
    UINavigationBar.appearance.compactAppearance = x;
    UINavigationBar.appearance.scrollEdgeAppearance = x;
    UINavigationBar.appearance.tintColor = UIColor.whiteColor;
    
    UITabBarAppearance *tabBarAppearance = [UITabBarAppearance new];
    [tabBarAppearance configureWithOpaqueBackground];
    
    // Add red top line to tab bar
    tabBarAppearance.shadowColor = [UIColor appPrimaryBrand];

    UITabBarItemAppearance *itemAppearance = tabBarAppearance.stackedLayoutAppearance;
    itemAppearance.selected.iconColor   = [UIColor appPrimaryBrand];
    itemAppearance.selected.titleTextAttributes = @{ NSForegroundColorAttributeName: [UIColor appPrimaryBrand] };
    itemAppearance.normal.iconColor     = [UIColor systemGrayColor];
    itemAppearance.normal.titleTextAttributes   = @{ NSForegroundColorAttributeName: [UIColor systemGrayColor] };

    UITabBar.appearance.standardAppearance = tabBarAppearance;
    UITabBar.appearance.tintColor = [UIColor appPrimaryBrand];

    if (@available(iOS 15.0, *)) {
        UITabBar.appearance.scrollEdgeAppearance = tabBarAppearance;
    }
    
    [UIButton appearanceWhenContainedInInstancesOfClasses:@[UINavigationBar.class]].tintColor = UIColor.whiteColor;
}

+ (void)setupBarButtonItemAppearance {
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                          NSForegroundColorAttributeName: [UIColor sil_bgWhiteColor],
                                                          NSFontAttributeName: [UIFont stolzlMediumWithSize: 17.0],
                                                          }
                                                forState:UIControlStateNormal];
}

+ (void)setupTextFieldAppearance {
    [[UITextField appearance] setTintColor:[UIColor appPrimaryBrand]];
}

+ (void)setupSVProgressHUD {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
}

@end
