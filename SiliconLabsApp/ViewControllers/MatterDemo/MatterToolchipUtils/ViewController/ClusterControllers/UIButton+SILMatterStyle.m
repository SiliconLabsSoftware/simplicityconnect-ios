#import "UIButton+SILMatterStyle.h"
#import "UIColor+SILColors.h"

static const CGFloat SILMatterButtonIconHeight = 16.0;
const CGFloat SILMatterButtonCornerRadius = 15.0;

static UIFont *SILMatterButtonFont(void) {
    UIFont *font = [UIFont fontWithName:@"Stolzl-Medium" size:14.0];
    return font ?: [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
}

static UIImage *SILMatterResizeImageToHeight(UIImage *image, CGFloat targetHeight) {
    if (image == nil || image.size.height <= 0 || targetHeight <= 0) {
        return image;
    }
    CGFloat aspect = image.size.width / image.size.height;
    CGSize newSize = CGSizeMake(round(targetHeight * aspect), targetHeight);
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:newSize format:format];
    UIImage *resized = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    }];
    return [resized imageWithRenderingMode:image.renderingMode];
}

static UIConfigurationTextAttributesTransformer SILMatterButtonFontTransformer(void) {
    return ^NSDictionary<NSAttributedStringKey, id> * _Nonnull (NSDictionary<NSAttributedStringKey, id> * _Nonnull incoming) {
        NSMutableDictionary *outgoing = [incoming mutableCopy];
        outgoing[NSFontAttributeName] = SILMatterButtonFont();
        return outgoing;
    };
}

@implementation UIButton (SILMatterStyle)

- (void)applySILMatterOutlinedStyleWithTitle:(NSString *)title {
    [self applySILMatterOutlinedStyleWithTitle:title image:nil];
}

- (void)applySILMatterOutlinedStyleWithTitle:(NSString *)title image:(UIImage *)image {
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.title = title;
    config.baseForegroundColor = UIColor.appPrimaryBrand;
    config.background.backgroundColor = UIColor.whiteColor;
    config.background.strokeColor = UIColor.appPrimaryBrand;
    config.background.strokeWidth = 1.5;
    config.background.cornerRadius = SILMatterButtonCornerRadius;
    config.titleTextAttributesTransformer = SILMatterButtonFontTransformer();
    if (image != nil) {
        config.image = SILMatterResizeImageToHeight(image, SILMatterButtonIconHeight);
        config.imagePlacement = NSDirectionalRectEdgeLeading;
        config.imagePadding = 8.0;
    }
    self.configuration = config;
    self.backgroundColor = UIColor.clearColor;
}

- (void)applySILMatterDisabledOutlinedStyleWithTitle:(NSString *)title {
    UIColor *grayColor = [UIColor sil_subtitleTextColor];
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.title = title;
    config.baseForegroundColor = grayColor;
    config.background.backgroundColor = UIColor.whiteColor;
    config.background.strokeColor = grayColor;
    config.background.strokeWidth = 1.5;
    config.background.cornerRadius = SILMatterButtonCornerRadius;
    config.titleTextAttributesTransformer = SILMatterButtonFontTransformer();
    self.configuration = config;
    self.backgroundColor = UIColor.clearColor;
}

- (void)setSILMatterActive:(BOOL)active {
    UIButtonConfiguration *config = self.configuration ?: [UIButtonConfiguration plainButtonConfiguration];
    if (active) {
        config.baseForegroundColor = UIColor.whiteColor;
        config.background.backgroundColor = UIColor.appPrimaryBrand;
        config.background.strokeColor = UIColor.appPrimaryBrand;
    } else {
        config.baseForegroundColor = UIColor.appPrimaryBrand;
        config.background.backgroundColor = UIColor.whiteColor;
        config.background.strokeColor = UIColor.appPrimaryBrand;
    }
    config.background.strokeWidth = 1.5;
    config.background.cornerRadius = SILMatterButtonCornerRadius;
    config.titleTextAttributesTransformer = SILMatterButtonFontTransformer();
    self.configuration = config;
    self.backgroundColor = UIColor.clearColor;
}

- (void)applySILMatterTitleFont {
    if (self.configuration != nil) {
        UIButtonConfiguration *config = self.configuration;
        config.titleTextAttributesTransformer = SILMatterButtonFontTransformer();
        self.configuration = config;
    } else {
        self.titleLabel.font = SILMatterButtonFont();
    }
}

@end

@implementation SILMatterStyledButton

- (void)awakeFromNib {
    [super awakeFromNib];
    [self applySILMatterTitleFont];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window != nil) {
        [self applySILMatterTitleFont];
    }
}

@end
