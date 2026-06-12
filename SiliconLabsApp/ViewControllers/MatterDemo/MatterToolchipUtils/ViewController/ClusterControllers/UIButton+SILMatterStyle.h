#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Shared corner radius used by all SIL Matter-styled buttons (and any other
/// view that should match their rounded corners, such as the "Add Device"
/// button on the QR code screen).
extern const CGFloat SILMatterButtonCornerRadius;

@interface UIButton (SILMatterStyle)

/// Applies an outlined red-border style matching the Matter screen design.
- (void)applySILMatterOutlinedStyleWithTitle:(NSString *)title;

/// Applies an outlined red-border style with a leading icon.
- (void)applySILMatterOutlinedStyleWithTitle:(NSString *)title image:(nullable UIImage *)image;

/// Applies an outlined gray-border style for the disabled / idle state.
- (void)applySILMatterDisabledOutlinedStyleWithTitle:(NSString *)title;

/// Toggles the SIL Matter button between active (filled red) and inactive (white outlined) states.
- (void)setSILMatterActive:(BOOL)active;

/// Applies the Matter brand title font (Stolzl-Medium 14) to the receiver, preserving any existing configuration / styling.
- (void)applySILMatterTitleFont;

@end

/// UIButton subclass that automatically renders its title in the Matter brand
/// font (Stolzl-Medium 14) when loaded from a storyboard or nib. Use this as
/// `customClass` on any button in `Cluster.storyboard` whose title should
/// follow the Matter brand styling without any per-view-controller code.
@interface SILMatterStyledButton : UIButton

@end

NS_ASSUME_NONNULL_END
