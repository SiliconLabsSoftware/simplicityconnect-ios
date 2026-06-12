
#import "CHIPUIViewUtils.h"
#import "UIColor+SILColors.h"

@implementation CHIPUIViewUtils

+ (UILabel *)addTitle:(NSString *)title toView:(UIView *)view
{
    UILabel * titleLabel = [UILabel new];
    titleLabel.text = title;
    titleLabel.textColor = UIColor.blackColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:25 weight:UIFontWeightBold];
    [view addSubview:titleLabel];

    titleLabel.translatesAutoresizingMaskIntoConstraints = false;
    [titleLabel.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
    [titleLabel.topAnchor constraintEqualToAnchor:view.topAnchor constant:110].active = YES;

    return titleLabel;
}

+ (UIStackView *)stackViewWithLabel:(UILabel *)label result:(UILabel *)result
{
    UIStackView * stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionEqualSpacing;

    stackView.alignment = UIStackViewAlignmentLeading;
    stackView.spacing = 3;

    label.textColor = [UIColor appPrimaryBrand];
    result.textColor = [UIColor appPrimaryBrand];
    label.font = [UIFont systemFontOfSize:17];
    result.font = [UIFont italicSystemFontOfSize:17];

    [stackView addArrangedSubview:label];
    [stackView addArrangedSubview:result];

    label.translatesAutoresizingMaskIntoConstraints = false;
    result.translatesAutoresizingMaskIntoConstraints = false;

    return stackView;
}

+ (UIView *)viewWithLabel:(UILabel *)label textField:(UITextField *)textField
{
    UIView * containingView = [UIView new];

    label.font = [UIFont systemFontOfSize:17];
    [containingView addSubview:label];

    label.translatesAutoresizingMaskIntoConstraints = false;
    [label.leadingAnchor constraintEqualToAnchor:containingView.leadingAnchor].active = true;
    [label.topAnchor constraintEqualToAnchor:containingView.topAnchor].active = true;
    [label.bottomAnchor constraintEqualToAnchor:containingView.bottomAnchor].active = YES;

    textField.font = [UIFont systemFontOfSize:17];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.textColor = UIColor.blackColor;
    [textField.layer setCornerRadius:14.0f];
    [containingView addSubview:textField];

    textField.translatesAutoresizingMaskIntoConstraints = false;
    [textField.trailingAnchor constraintEqualToAnchor:containingView.trailingAnchor].active = true;
    [textField.topAnchor constraintEqualToAnchor:containingView.topAnchor].active = true;
    [textField.bottomAnchor constraintEqualToAnchor:containingView.bottomAnchor].active = YES;
    [textField.leadingAnchor constraintEqualToAnchor:label.trailingAnchor constant:20].active = YES;
    return containingView;
}

+ (UIView *)viewWithLabel:(UILabel *)label toggle:(UISwitch *)toggle
{
    UIView * containingView = [UIView new];

    label.font = [UIFont systemFontOfSize:17];
    [containingView addSubview:label];

    label.translatesAutoresizingMaskIntoConstraints = false;
    [label.leadingAnchor constraintEqualToAnchor:containingView.leadingAnchor].active = true;
    [label.topAnchor constraintEqualToAnchor:containingView.topAnchor].active = true;
    [label.bottomAnchor constraintEqualToAnchor:containingView.bottomAnchor].active = YES;

    [containingView addSubview:toggle];

    toggle.translatesAutoresizingMaskIntoConstraints = false;
    [toggle.trailingAnchor constraintEqualToAnchor:containingView.trailingAnchor].active = true;
    [toggle.topAnchor constraintEqualToAnchor:containingView.topAnchor].active = true;
    [toggle.bottomAnchor constraintEqualToAnchor:containingView.bottomAnchor].active = YES;
    [toggle.leadingAnchor constraintGreaterThanOrEqualToAnchor:label.trailingAnchor constant:20].active = YES;

    return containingView;
}

+ (UIView *)viewWithUITextField:(UITextField *)textField button:(UIButton *)button
{
    UIView * containingView = [UIView new];

    textField.font = [UIFont systemFontOfSize:17];
    textField.backgroundColor = UIColor.whiteColor;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.textColor = UIColor.blackColor;
    [textField.layer setCornerRadius:14.0f];
    [containingView addSubview:textField];

    textField.translatesAutoresizingMaskIntoConstraints = false;
    [textField.leadingAnchor constraintEqualToAnchor:containingView.leadingAnchor].active = true;
    [textField.topAnchor constraintEqualToAnchor:containingView.topAnchor].active = true;
    [textField.bottomAnchor constraintEqualToAnchor:containingView.bottomAnchor].active = YES;

    button.titleLabel.font = [UIFont systemFontOfSize:17];
    button.titleLabel.textColor = [UIColor blackColor];
    button.layer.cornerRadius = 5;
    button.clipsToBounds = YES;
    button.backgroundColor = [UIColor appPrimaryBrand];
    [containingView addSubview:button];

    button.translatesAutoresizingMaskIntoConstraints = false;
    [button.trailingAnchor constraintEqualToAnchor:containingView.trailingAnchor].active = true;
    [button.topAnchor constraintEqualToAnchor:containingView.topAnchor].active = true;
    [button.bottomAnchor constraintEqualToAnchor:containingView.bottomAnchor].active = YES;
    [button.widthAnchor constraintEqualToConstant:60].active = YES;
    [button.leadingAnchor constraintEqualToAnchor:textField.trailingAnchor constant:15].active = YES;

    return containingView;
}

+ (UIStackView *)stackViewWithButtons:(NSArray<UIButton *> *)buttons
{
    UIStackView * stackViewButtons = [UIStackView new];
    stackViewButtons.axis = UILayoutConstraintAxisHorizontal;
    stackViewButtons.distribution = UIStackViewDistributionFillEqually;
    stackViewButtons.alignment = UIStackViewAlignmentTrailing;
    stackViewButtons.spacing = 10;

    for (int i = 0; i < buttons.count; i++) {
        UIButton * buttonForStack = [buttons objectAtIndex:i];
        buttonForStack.backgroundColor = [UIColor appPrimaryBrand];
        buttonForStack.titleLabel.font = [UIFont systemFontOfSize:17];
        buttonForStack.titleLabel.textColor = [UIColor whiteColor];
        buttonForStack.layer.cornerRadius = 5;
        buttonForStack.clipsToBounds = YES;
        buttonForStack.translatesAutoresizingMaskIntoConstraints = false;
        [buttonForStack.widthAnchor constraintEqualToConstant:70].active = YES;
        [stackViewButtons addArrangedSubview:buttonForStack];
    }
    return stackViewButtons;
}

+ (UIStackView *)stackViewWithLabel:(UILabel *)label buttons:(NSArray<UIButton *> *)buttons
{
    // Button stack view
    UIStackView * stackViewButtons = [UIStackView new];
    stackViewButtons.axis = UILayoutConstraintAxisHorizontal; // man
//    stackViewButtons.axis = UILayoutConstraintAxisVertical;

    stackViewButtons.distribution = UIStackViewDistributionEqualSpacing;
    stackViewButtons.alignment = UIStackViewAlignmentLeading;
    stackViewButtons.spacing = 100;

//    label.font = [UIFont systemFontOfSize: 17];
//    [stackViewButtons addArrangedSubview: label];

//    label.translatesAutoresizingMaskIntoConstraints = false;
//    [label.centerYAnchor constraintEqualToAnchor: stackViewButtons.centerYAnchor].active = YES;

    stackViewButtons.translatesAutoresizingMaskIntoConstraints = false;
    for (int i = 0; i < buttons.count; i++) {
        UIButton * buttonForStack = [buttons objectAtIndex:i];
        buttonForStack.backgroundColor = [UIColor appPrimaryBrand];
        buttonForStack.titleLabel.font = [UIFont systemFontOfSize:17];
        buttonForStack.titleLabel.textColor = [UIColor whiteColor];
        buttonForStack.layer.cornerRadius = 5;
        buttonForStack.clipsToBounds = YES;
        buttonForStack.translatesAutoresizingMaskIntoConstraints = false;
        [buttonForStack.widthAnchor constraintGreaterThanOrEqualToConstant:100].active = YES;
        [stackViewButtons addArrangedSubview:buttonForStack];
    }

    return stackViewButtons;
}
// Device title
+ (NSString *)addDeviceTitle:(NSString *)deviceType {
    NSString * deviceTitle = @"";
    if ([deviceType isEqualToString:@"514"]) {
        deviceTitle = [NSMutableString stringWithFormat:@"Window Cover"];
    }else if ([deviceType isEqualToString:@"10"]){
        deviceTitle = [NSMutableString stringWithFormat:@"Door Lock"];
    }else if ([deviceType isEqualToString:DimmingLight] || [deviceType isEqualToString:EnhancedColorLight] || [deviceType isEqualToString:OnOffLight] || [deviceType isEqualToString:TemperatureColorLight])  {
        deviceTitle = [NSMutableString stringWithFormat:@"Light"];
    }else if ([deviceType isEqualToString:@"769"]){
        deviceTitle = [NSMutableString stringWithFormat:@"Thermostat"];
    }else if ([deviceType isEqualToString:@"267"]){
        deviceTitle = [NSMutableString stringWithFormat:@"Plug"];
    }else if ([deviceType isEqualToString:@"770"]){
        //Temperature Sensor
        deviceTitle = [NSMutableString stringWithFormat:@"Temperature Sensor"];
    }else if ([deviceType isEqualToString:@"263"]){
        //Occupancy Sensor
        deviceTitle = [NSMutableString stringWithFormat:@"Occupancy Sensor"];
    }else if ([deviceType isEqualToString:@"21"]){
        //Contact Sensor
        deviceTitle = [NSMutableString stringWithFormat:@"Contact Sensor"];
    }else if ([deviceType isEqualToString:@"259"] || [deviceType isEqualToString:DimmerSwitch]) {
        //Switch
        deviceTitle = [NSMutableString stringWithFormat:@"Switch"];
    } else if ([deviceType isEqualToString:Dishwasher]) {
        deviceTitle = [NSMutableString stringWithFormat:@"Dishwasher"];
    } else if ([deviceType isEqualToString:AirQuality]) {
        deviceTitle = [NSMutableString stringWithFormat:@"Air Quality"];
    } else if ([deviceType isEqualToString:ElectricVehicles] || [deviceType isEqualToString:@"1292"]) {
        deviceTitle = [NSMutableString stringWithFormat:@"Electric Vehicles"];
    } else if ([deviceType isEqualToString:RangeHood]) {
        deviceTitle = [NSMutableString stringWithFormat:@"Range Hood"];
    } else if ([deviceType isEqualToString:Oven]) {
        deviceTitle = [NSMutableString stringWithFormat:@"Oven"];
    }
    return  deviceTitle;
}

+ (void)addRedLineBelowNavigationBarTo:(UIViewController *)viewController {
    static const NSInteger kSILMatterRedNavLineTag = 99888;

    UIView *existingLine = [viewController.view viewWithTag:kSILMatterRedNavLineTag];
    if (existingLine != nil) {
        [viewController.view bringSubviewToFront:existingLine];
        return;
    }

    UIView *redLine = [[UIView alloc] init];
    redLine.tag = kSILMatterRedNavLineTag;
    redLine.backgroundColor = [UIColor appPrimaryBrand];
    redLine.translatesAutoresizingMaskIntoConstraints = NO;
    [viewController.view addSubview:redLine];

    [NSLayoutConstraint activateConstraints:@[
        [redLine.topAnchor constraintEqualToAnchor:viewController.view.safeAreaLayoutGuide.topAnchor],
        [redLine.leadingAnchor constraintEqualToAnchor:viewController.view.leadingAnchor],
        [redLine.trailingAnchor constraintEqualToAnchor:viewController.view.trailingAnchor],
        [redLine.heightAnchor constraintEqualToConstant:1.0]
    ]];
}

@end
