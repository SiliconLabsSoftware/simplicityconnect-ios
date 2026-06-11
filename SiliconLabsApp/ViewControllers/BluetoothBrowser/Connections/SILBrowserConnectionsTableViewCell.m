//
//  SILBrowserConnectionsTableViewCell.m
//  BlueGecko
//
//  Created by Kamil Czajka on 29/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserConnectionsTableViewCell.h"

@interface SILBrowserConnectionsTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *disconnectButton;

@property (nonatomic, readwrite) NSUInteger index;

@end

@implementation SILBrowserConnectionsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setFonts];
}

- (void)setFonts {
    [self.deviceNameLabel setFont:[UIFont stolzlMediumWithSize:[UIFont getLargeFontSize]]];
    self.deviceNameLabel.textColor = [UIColor sil_primaryTextColor];
    self.deviceNameLabel.adjustsFontSizeToFitWidth = YES;
    
    self.disconnectButton.layer.cornerRadius = CornerRadiusForButtons;
    self.disconnectButton.titleLabel.font = [UIFont stolzlMediumWithSize:[UIFont getSmallFontSize]];
    self.disconnectButton.backgroundColor = [UIColor appPrimaryBrand];
    self.disconnectButton.titleLabel.textColor = [UIColor sil_backgroundColor];
    self.disconnectButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (IBAction)disconnectButtonTapped:(id)sender {
    [self postNotificationToViewModel];
}

- (void)setDeviceName:(NSString*)deviceName index:(NSInteger)index andIsSelected:(BOOL)isSelected {
    _deviceNameLabel.text = deviceName;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    _index = index;
    if (isSelected) {
        [self customizeSelectedAppearance];
    } else {
        [self customizeUnselectedAppearance];
    }
}


- (void)customizeSelectedAppearance {
    self.deviceNameLabel.textColor = [UIColor appPrimaryBrand];
}

- (void)customizeUnselectedAppearance {
    self.deviceNameLabel.textColor = [UIColor sil_primaryTextColor];
}

- (void)postNotificationToViewModel {
    NSDictionary* userInfo = @{SILNotificationKeyIndex: @(_index)};
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationDisconnectPeripheral object:self userInfo:userInfo];
}

@end
