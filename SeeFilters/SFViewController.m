//
//  SFViewController.m
//  SeeFilters
//
//  Created by Mike Schwab on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SFViewController.h"
#import "SFLoadFilterController.h"
#import "SFImportViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface SFViewController ()

@end

@implementation SFViewController {
    CIContext *previewContext;
    CIContext *saveContext;
    CIFilter *firstFilter;
    CIFilter *secondFilter;
    CIFilter *thirdFilter;
    CIImage *beginImage;
    UIImage *fullSizeImage;
    NSString *firstSliderAttribute;
    NSString *secondSliderAttribute;
    NSString *configurableAttribute;
    UIPopoverController *popover;
    CIFilter *configurableFilter;
    int configurableFilterIndex;
    NSMutableDictionary *firstFilterProperties;
    NSMutableDictionary *secondFilterProperties;
    NSMutableDictionary *thirdFilterProperties;
    NSMutableDictionary *configurableFilterProperties;
    NSArray *filterList;
    UIImage *alternatePreviewImage;
    bool pickingAlternative;
}
@synthesize longPressAlternativeImageLoader;
@synthesize secondSlider;
@synthesize secondFilterValueLabel;
@synthesize firstFilterControl;
@synthesize firstFilterArmButton;
@synthesize secondFilterControl;
@synthesize secondFilterArmButton;
@synthesize thirdFilterControl;
@synthesize thirdFilterArmButton;
@synthesize firstFilterPropertyLabel;
@synthesize secondFilterPropertyLabel;
@synthesize thirdFilterPropertyLabel;
@synthesize filterChainTitle;
@synthesize filterControl;
@synthesize originalImageView;
@synthesize filterValueLabel;
@synthesize filterPicker;
@synthesize amountSlider;
@synthesize imgV;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self initFilterList];
    NSLog(@"length of filter list: %d", [filterList count]);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"image" ofType:@"png"];
    NSURL *fileNameAndPath = [NSURL fileURLWithPath:filePath];
    
    beginImage = [CIImage imageWithContentsOfURL:fileNameAndPath];
    originalImageView.image = [UIImage imageWithContentsOfFile:filePath];
    previewContext = [CIContext contextWithOptions:nil];
    saveContext = [CIContext contextWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kCIContextUseSoftwareRenderer]];
    
    firstFilterPropertyLabel.numberOfLines = 0;
    secondFilterPropertyLabel.numberOfLines = 0;
    thirdFilterPropertyLabel.numberOfLines = 0;
        
    firstFilter = [CIFilter filterWithName:@"CIVibrance"];
    secondFilter = [CIFilter filterWithName:@"CIVibrance"];
    thirdFilter = [CIFilter filterWithName:@"CIVibrance"];
    
    [self controlFilter:[NSNumber numberWithInt:1]];
    firstFilterProperties = [[NSMutableDictionary alloc] init];
    [self updateFilter:@"CIVibrance" withProperties:nil];
    
    [self controlFilter:[NSNumber numberWithInt:2]];
    secondFilterProperties = [[NSMutableDictionary alloc] init];
    [self updateFilter:@"CIGammaAdjust" withProperties:nil];
    
    [self controlFilter:[NSNumber numberWithInt:3]];
    thirdFilterProperties = [[NSMutableDictionary alloc] init];
    [self updateFilter:@"CIExposureAdjust" withProperties:nil];
    
    [self updateFilteredImage:beginImage context:previewContext];
    
//    [self logAllFilters];
}

#pragma mark -- updaters --
// This method loads a filter into one of the filter banks, with settings that are either determined from a saved filter or set to default values.
- (void)updateFilter:(NSString *)filterName withProperties:(NSMutableDictionary *)properties
{
    configurableFilter = [CIFilter filterWithName:filterName];
    
    if (properties == nil) {
        configurableFilterProperties = [[NSMutableDictionary alloc] initWithCapacity:3];
        NSMutableArray *inputs = [NSMutableArray arrayWithArray:[configurableFilter inputKeys]];
        [inputs removeObject:@"inputImage"];
        for (NSString *attr in inputs) {
            id identity = [[[configurableFilter attributes] objectForKey:attr] objectForKey:kCIAttributeIdentity];
            if (identity != nil) {
                [configurableFilterProperties setValue:identity forKey:attr];
            } else {
                [configurableFilterProperties setValue:[[[configurableFilter attributes] objectForKey:attr] objectForKey:kCIAttributeDefault] forKey:attr];
            }
        }
    } else {
        configurableFilterProperties = properties;
    }
    
    NSDictionary *myDefaults = [self attributesForFilter:filterName];
    [configurableFilterProperties addEntriesFromDictionary:myDefaults];
    
    for(NSString *setting in configurableFilterProperties) {
        if ([setting isEqualToString:@"configuredMaximumForFirstSlider"] || [setting isEqualToString:@"configuredMinimumForFirstSlider"] || [setting isEqualToString:@"configuredMaximumForSecondSlider"] || [setting isEqualToString:@"configuredMinimumForSecondSlider"]) {
            NSLog(@"got it");
        } else {
            [configurableFilter setValue:[configurableFilterProperties valueForKey:setting] forKey:setting];
        }
    }
    if (configurableFilterIndex == 1) {
        firstFilter = configurableFilter;
        firstFilterProperties = configurableFilterProperties;
        [firstFilterControl setTitle:[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] forState:UIControlStateNormal];
        [filterControl setTitle:[[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] substringToIndex:1] forSegmentAtIndex:0];
    } else if (configurableFilterIndex == 2) {
        secondFilter = configurableFilter;
        secondFilterProperties = configurableFilterProperties;
        [secondFilterControl setTitle:[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] forState:UIControlStateNormal];
        [filterControl setTitle:[[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] substringToIndex:1] forSegmentAtIndex:1];
    } else if (configurableFilterIndex == 3) {
        thirdFilter = configurableFilter;
        thirdFilterProperties = configurableFilterProperties;
        [thirdFilterControl setTitle:[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] forState:UIControlStateNormal];
        [filterControl setTitle:[[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] substringToIndex:1] forSegmentAtIndex:2];
    }
    [self updateSliders];
    [self updateFilterLabels];
    [self updateFilteredImage:beginImage context:previewContext];
}

// This method determines how many sliders to display, and which values to set them at, while making a filter active for configuration.
- (void)updateSliders
{
    NSString *filterName = [configurableFilter name];
    CIFilter *filter = [self filterOfName:filterName];
    bool secondSliderUsed;
    
    if ([filterName isEqualToString:@"CIColorMonochrome"]) {
        firstSliderAttribute = @"inputIntensity";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CISepiaTone"]) {
        firstSliderAttribute = @"inputIntensity";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIGammaAdjust"]) {
        firstSliderAttribute = @"inputPower";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIExposureAdjust"]) {
        firstSliderAttribute = @"inputEV";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIColorControls"]) {
        firstSliderAttribute = @"inputSaturation";
        secondSliderAttribute = @"inputContrast";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIVibrance"]) {
        firstSliderAttribute = @"inputAmount";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIHueAdjust"]) {
        firstSliderAttribute = @"inputAngle";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIHighlightShadowAdjust"]) {
        firstSliderAttribute = @"inputShadowAmount";
        secondSliderAttribute = @"inputHighlightAmount";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIVignette"]) {
        firstSliderAttribute = @"inputIntensity";
        secondSliderAttribute = @"inputRadius";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIBloom"]) {
        firstSliderAttribute = @"inputIntensity";
        secondSliderAttribute = @"inputRadius";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIBumpDistortion"]) {
        firstSliderAttribute = @"inputScale";
        secondSliderAttribute = @"inputRadius";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CICircularScreen"]) {
        firstSliderAttribute = @"inputWidth";
        secondSliderAttribute = @"inputSharpness";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIColorInvert"]) {
        firstSliderAttribute = nil;
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIColorPosterize"]) {
        firstSliderAttribute = @"inputLevels";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIDotScreen"]) {
        firstSliderAttribute = @"inputWidth";
        secondSliderAttribute = @"inputSharpness";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIGaussianBlur"]) {
        firstSliderAttribute = @"inputRadius";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIGloom"]) {
        firstSliderAttribute = @"inputIntensity";
        secondSliderAttribute = @"inputRadius";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIHatchedScreen"]) {
        firstSliderAttribute = @"inputWidth";
        secondSliderAttribute = @"inputSharpness";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIUnsharpMask"]) {
        firstSliderAttribute = @"inputIntensity";
        secondSliderAttribute = @"inputRadius";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CICircleSplashDistortion"]) {
        firstSliderAttribute = @"inputRadius";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIColorCube"]) {
        firstSliderAttribute = @"inputCubeDimension";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIConvolution3X3"]) {
        firstSliderAttribute = @"inputBias";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIEightfoldReflectedTile"]) {
        firstSliderAttribute = @"inputAngle";
        secondSliderAttribute = @"inputWidth";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIFourfoldReflectedTile"]) {
        firstSliderAttribute = @"inputAngle";
        secondSliderAttribute = @"inputWidth";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIFourfoldRotatedTile"]) {
        firstSliderAttribute = @"inputAngle";
        secondSliderAttribute = @"inputWidth";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIHoleDistortion"]) {
        firstSliderAttribute = @"inputRadius";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CILanczosScaleTransform"]) {
        firstSliderAttribute = @"inputScale";
        secondSliderAttribute = @"inputAspectRatio";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CILightTunnel"]) {
        firstSliderAttribute = @"inputRotation";
        secondSliderAttribute = @"inputRadius";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CILineScreen"]) {
        firstSliderAttribute = @"inputAngle";
        secondSliderAttribute = @"inputSharpness";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIPinchDistortion"]) {
        firstSliderAttribute = @"inputRadius";
        secondSliderAttribute = @"inputScale";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIPixellate"]) {
        firstSliderAttribute = @"inputScale";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CISharpenLuminance"]) {
        firstSliderAttribute = @"inputSharpness";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CIStraightenFilter"]) {
        firstSliderAttribute = @"inputAngle";
        secondSliderUsed = NO;
    } else if ([filterName isEqualToString:@"CITriangleKaleidoscope"]) {
        firstSliderAttribute = @"inputSize";
        secondSliderAttribute = @"inputDecay";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CITwirlDistortion"]) {
        firstSliderAttribute = @"inputRadius";
        secondSliderAttribute = @"inputAngle";
        secondSliderUsed = YES;
    } else if ([filterName isEqualToString:@"CIVortexDistortion"]) {
        firstSliderAttribute = @"inputRadius";
        secondSliderAttribute = @"inputAngle";
        secondSliderUsed = YES;
    }
    
    
    
    NSLog(@"filter attributes: %@", [filter attributes]);
    
    
    if ([configurableFilterProperties valueForKey:@"configuredMaximumForFirstSlider"]) {
        amountSlider.maximumValue = [[configurableFilterProperties valueForKey:@"configuredMaximumForFirstSlider"] floatValue];
    } else {
        if ([[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:@"CIAttributeSliderMax"]) {
            amountSlider.maximumValue = [[[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:@"CIAttributeSliderMax"] floatValue];
        } else if ([[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:@"CIAttributeMax"]) {
            amountSlider.maximumValue = [[[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:@"CIAttributeMax"] floatValue];
        } else {
            amountSlider.maximumValue = 4.0;
        }
        
    }
    if ([configurableFilterProperties valueForKey:@"configuredMinimumForFirstSlider"]) {
        amountSlider.minimumValue = [[configurableFilterProperties valueForKey:@"configuredMinimumForFirstSlider"] floatValue];
    } else {
        if ([[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:@"CIAttributeSliderMin"]) {
            amountSlider.minimumValue = [[[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:@"CIAttributeSliderMin"] floatValue];
        } else if ([[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:@"CIAttributeMin"]) {
            amountSlider.minimumValue = [[[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:@"CIAttributeMin"] floatValue];
        } else {
            amountSlider.minimumValue = 0.0;
        }
    }
    if ([configurableFilterProperties valueForKey:firstSliderAttribute]) {
        [amountSlider setValue:[[configurableFilterProperties valueForKey:firstSliderAttribute] floatValue] animated:YES];
    } else {
        [amountSlider setValue:[[[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:kCIAttributeIdentity] floatValue] animated:YES];
    }

    filterValueLabel.text = [NSString stringWithFormat:@"%1.3f", amountSlider.value];

    if (secondSliderUsed) {
        if ([configurableFilterProperties valueForKey:@"configuredMaximumForSecondSlider"]) {
            secondSlider.maximumValue = [[configurableFilterProperties valueForKey:@"configuredMaximumForSecondSlider"] floatValue];
        } else {
            if ([[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:@"CIAttributeSliderMax"]) {
                secondSlider.maximumValue = [[[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:@"CIAttributeSliderMax"] floatValue];
            } else if ([[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:@"CIAttributeMax"]) {
                secondSlider.maximumValue = [[[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:@"CIAttributeMax"] floatValue];
            } else {
                secondSlider.maximumValue = 4.0;
            }
        }
        if ([configurableFilterProperties valueForKey:@"configuredMinimumForSecondSlider"]) {
            secondSlider.minimumValue = [[configurableFilterProperties valueForKey:@"configuredMinimumForSecondSlider"] floatValue];
        } else {
            if ([[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:@"CIAttributeSliderMin"]) {
                secondSlider.minimumValue = [[[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:@"CIAttributeSliderMin"] floatValue];
            } else if ([[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:@"CIAttributeMin"]) {
                secondSlider.minimumValue = [[[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:@"CIAttributeMin"] floatValue];
            } else {
                secondSlider.minimumValue = 0.0;
            }
        }
        if ([configurableFilterProperties valueForKey:secondSliderAttribute]) {
            [secondSlider setValue:[[configurableFilterProperties valueForKey:secondSliderAttribute] floatValue] animated:YES];
        } else {
            [secondSlider setValue:[[[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:kCIAttributeIdentity] floatValue] animated:YES];
        }
        secondFilterValueLabel.text = [NSString stringWithFormat:@"%1.3f", secondSlider.value];
    } else {
        secondSliderAttribute = @"";
    }
    secondSlider.hidden = !secondSliderUsed;
    secondFilterValueLabel.hidden = !secondSliderUsed;
}

// This method applies the filter chain to the image.  It is used for both preview and export.
-(void)updateFilteredImage:(CIImage *)image context:(CIContext *)context
{
    CIImage *outputImage;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (firstFilterArmButton.on) {
            [firstFilter setValue:image forKey:kCIInputImageKey];
            if (secondFilterArmButton.on) {
                [secondFilter setValue:firstFilter.outputImage forKey:kCIInputImageKey];
                if (thirdFilterArmButton.on) {
                    [thirdFilter setValue:secondFilter.outputImage forKey:kCIInputImageKey];
                    outputImage = thirdFilter.outputImage;
                } else {
                    outputImage = secondFilter.outputImage;
                }
            } else {
                if (thirdFilterArmButton.on) {
                    [thirdFilter setValue:firstFilter.outputImage forKey:kCIInputImageKey];
                    outputImage = thirdFilter.outputImage;
                } else {
                    outputImage = firstFilter.outputImage;
                }
            }
        } else {
            if (secondFilterArmButton.on) {
                [secondFilter setValue:beginImage forKey:kCIInputImageKey];
                if (thirdFilterArmButton.on) {
                    [thirdFilter setValue:secondFilter.outputImage forKey:kCIInputImageKey];
                    outputImage = thirdFilter.outputImage;
                } else {
                    outputImage = secondFilter.outputImage;
                }
            } else {
                if (thirdFilterArmButton.on) {
                    [thirdFilter setValue:beginImage forKey:kCIInputImageKey];
                    outputImage = thirdFilter.outputImage;
                }
            }
        }
    } else {
        [firstFilter setValue:beginImage forKey:kCIInputImageKey];
        [secondFilter setValue:firstFilter.outputImage forKey:kCIInputImageKey];
        [thirdFilter setValue:secondFilter.outputImage forKey:kCIInputImageKey];
        outputImage = thirdFilter.outputImage;
    }
    if (context == previewContext) {
        CGImageRef cgimg = [context createCGImage:outputImage 
                                         fromRect:[outputImage extent]];
        
        UIImage *newImg = [UIImage imageWithCGImage:cgimg];    
        [imgV setImage:newImg];
        
        CGImageRelease(cgimg);
    } else if (context == saveContext) {
        CGImageRef cgImg = [context createCGImage:outputImage fromRect:[outputImage extent]];
        ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:cgImg metadata:[outputImage properties]
                              completionBlock:^(NSURL *assetURL, NSError *error) {
                                  CGImageRelease(cgImg);
                              }];
    }
}

// This method displays the configured values of the filters.
-(void)updateFilterLabels
{
    NSString *firstAttrName = [firstSliderAttribute substringFromIndex:5];
    NSString *secondAttrName;
    if ([secondSliderAttribute isEqualToString:@""]) {
        secondAttrName = @"";
    } else {
        secondAttrName = [secondSliderAttribute substringFromIndex:5];
    }
    
    UILabel *configurableFilterPropertyLabel;
    switch (configurableFilterIndex) {
        case 1:
            configurableFilterPropertyLabel = firstFilterPropertyLabel;
            break;
        case 2:
            configurableFilterPropertyLabel = secondFilterPropertyLabel;
            break;
        case 3:
            configurableFilterPropertyLabel = thirdFilterPropertyLabel;
            break;
        default:
            break;
    }
    
    if ([secondAttrName isEqualToString:@""]) {
        configurableFilterPropertyLabel.text = [NSString stringWithFormat:@"%@: %1.3f", firstAttrName, [amountSlider value]];
    } else {
        configurableFilterPropertyLabel.text = [NSString stringWithFormat:@"%@: %1.3f\n%@: %1.3f", firstAttrName, [amountSlider value], secondAttrName, [secondSlider value]];
    }
}

// This method updates the color of the filter name based on its interactive status.
-(void)updateTitleColors
{
    UIColor *firstTitleColor;
    UIColor *secondTitleColor;
    UIColor *thirdTitleColor;
    if (firstFilterArmButton.on) {
        if (configurableFilterIndex == 1) {
            firstTitleColor = [UIColor blueColor];
        } else {
            firstTitleColor = [UIColor darkGrayColor];
        }
    } else {
        if (configurableFilterIndex == 1) {
            firstTitleColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
        } else {
            firstTitleColor = [UIColor lightGrayColor];
        }
    }
    if (secondFilterArmButton.on) {
        if (configurableFilterIndex == 2) {
            secondTitleColor = [UIColor blueColor];
        } else {
            secondTitleColor = [UIColor darkGrayColor];
        }
    } else {
        if (configurableFilterIndex == 2) {
            secondTitleColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
        } else {
            secondTitleColor = [UIColor lightGrayColor];
        }
    }
    if (thirdFilterArmButton.on) {
        if (configurableFilterIndex == 3) {
            thirdTitleColor = [UIColor blueColor];
        } else {
            thirdTitleColor = [UIColor darkGrayColor];
        }
    } else {
        if (configurableFilterIndex == 3) {
            thirdTitleColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
        } else {
            thirdTitleColor = [UIColor lightGrayColor];
        }
    }
    [firstFilterControl setTitleColor:firstTitleColor forState:UIControlStateNormal];
    [secondFilterControl setTitleColor:secondTitleColor forState:UIControlStateNormal];
    [thirdFilterControl setTitleColor:thirdTitleColor forState:UIControlStateNormal];
}

// This method moves the picker wheel to display the name of the active filter, just for clarity's sake.
- (void)updatePicker
{
    int filterIndex;
    for (CIFilter *filter in filterList) {
        if ([[filter name] isEqualToString:[configurableFilter name]]) {
            filterIndex = [filterList indexOfObject:filter];
        }
    }
    [filterPicker selectRow:filterIndex inComponent:0 animated:YES];
}

#pragma mark -- interface controls --
// This method responds to the user pushing a slider by updating filters, labels, and stored properties.
-(IBAction)changeValue:(UISlider *)sender {
    float slideValue = [sender value];
    if (sender == amountSlider) {
        configurableAttribute = firstSliderAttribute;
        filterValueLabel.text = [NSString stringWithFormat:@"%1.3f", slideValue];
    } else {
        configurableAttribute = secondSliderAttribute;
        secondFilterValueLabel.text = [NSString stringWithFormat:@"%1.3f", slideValue];
    }
    
    [configurableFilter setValue:[NSNumber numberWithFloat:slideValue] forKey:configurableAttribute];
    [configurableFilterProperties setValue:[NSNumber numberWithFloat:slideValue] forKey:configurableAttribute];
    [self updateFilteredImage:beginImage context:previewContext];
    [self updateFilterLabels];
}

// This method updates the endpoints of a slider, responding to a pan gesture of two or three fingers.
- (IBAction)pushSliderEndpoints:(UIPanGestureRecognizer *)recognizer
{
    CGPoint trans = [recognizer translationInView:self.view];
    NSString *sliderConfigIdentity;
    UISlider *configurableSlider = (UISlider *) recognizer.view;
    UILabel *configurableLabel;
    if (recognizer.view == amountSlider) {
        configurableLabel = filterValueLabel;
        sliderConfigIdentity = @"FirstSlider";
    } else if (recognizer.view == secondSlider) {
        configurableLabel = secondFilterValueLabel;
        sliderConfigIdentity = @"SecondSlider";
    }
    if (recognizer.numberOfTouches == 3) {
        configurableSlider.maximumValue = configurableSlider.maximumValue - (trans.y / 100);
        configurableLabel.text = [NSString stringWithFormat:@"%1.3f", configurableSlider.maximumValue];
        NSString *configurableKey = [@"configuredMaximumFor" stringByAppendingString:sliderConfigIdentity];
        [configurableFilterProperties setValue:[NSNumber numberWithFloat:configurableSlider.maximumValue] forKey:configurableKey];
    } else if (recognizer.numberOfTouches == 2) {
        configurableSlider.minimumValue = configurableSlider.minimumValue - (trans.y / 100);
        configurableLabel.text = [NSString stringWithFormat:@"%1.3f", configurableSlider.minimumValue];
        NSString *configurableKey = [@"configuredMinimumFor" stringByAppendingString:sliderConfigIdentity];
        [configurableFilterProperties setValue:[NSNumber numberWithFloat:configurableSlider.minimumValue] forKey:configurableKey];
    }
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

// This method responds to a toggle control by re-filtering the image and coloring the filter name.
- (IBAction)toggleFilter:(id)sender {
    [self updateFilteredImage:beginImage context:previewContext];
    [self updateTitleColors];
}

// This method tells the app which filter is being configured.  It responds to a tap on one of the filter banks.
- (IBAction)controlFilter:(id)sender {
    if (sender == firstFilterControl || (sender == filterControl && (filterControl.selectedSegmentIndex == 0)) || (sender == [NSNumber numberWithInt:1])) {
        configurableFilter = firstFilter;
        configurableFilterProperties = firstFilterProperties;
        configurableFilterIndex = 1;
        [firstFilterArmButton setOn:YES animated:YES];
    } else if (sender == secondFilterControl || (sender == filterControl && (filterControl.selectedSegmentIndex == 1)) || (sender == [NSNumber numberWithInt:2])) {
        configurableFilter = secondFilter;
        configurableFilterProperties = secondFilterProperties;
        configurableFilterIndex = 2;
        [secondFilterArmButton setOn:YES animated:YES];
    } else if (sender == thirdFilterControl || (sender == filterControl && (filterControl.selectedSegmentIndex == 2)) || (sender == [NSNumber numberWithInt:3])) {
        configurableFilter = thirdFilter;
        configurableFilterProperties = thirdFilterProperties;
        configurableFilterIndex = 3;
        [thirdFilterArmButton setOn:YES animated:YES];
    }
    [self updateSliders];
    [self updatePicker];
    [self toggleFilter:nil];
}

#pragma mark -- filter definitions --
// This is a list of the filters available.
- (void)initFilterList
{
    filterList = [NSArray arrayWithObjects:
                  [CIFilter filterWithName:@"CIColorMonochrome"],
                  [CIFilter filterWithName:@"CISepiaTone"],
                  [CIFilter filterWithName:@"CIGammaAdjust"],
                  [CIFilter filterWithName:@"CIExposureAdjust"],
                  [CIFilter filterWithName:@"CIColorControls"],
                  [CIFilter filterWithName:@"CIVibrance"],
                  [CIFilter filterWithName:@"CIHueAdjust"],
                  [CIFilter filterWithName:@"CIHighlightShadowAdjust"],
                  [CIFilter filterWithName:@"CIVignette"],
                  [CIFilter filterWithName:@"CIBloom"],
                  [CIFilter filterWithName:@"CIBumpDistortion"],
                  [CIFilter filterWithName:@"CICircularScreen"],
                  [CIFilter filterWithName:@"CIColorInvert"],
                  [CIFilter filterWithName:@"CIColorPosterize"],
                  [CIFilter filterWithName:@"CIDotScreen"],
                  [CIFilter filterWithName:@"CIGaussianBlur"],
                  [CIFilter filterWithName:@"CIGloom"],
                  [CIFilter filterWithName:@"CIHatchedScreen"],
                  [CIFilter filterWithName:@"CIUnsharpMask"],
                  [CIFilter filterWithName:@"CICircleSplashDistortion"],
                  [CIFilter filterWithName:@"CIColorCube"],
                  [CIFilter filterWithName:@"CIConvolution3X3"],
                  [CIFilter filterWithName:@"CIEightfoldReflectedTile"],
                  [CIFilter filterWithName:@"CIFourfoldReflectedTile"],
                  [CIFilter filterWithName:@"CIFourfoldRotatedTile"],
                  [CIFilter filterWithName:@"CIHoleDistortion"],
                  [CIFilter filterWithName:@"CILanczosScaleTransform"],
                  [CIFilter filterWithName:@"CILightTunnel"],
                  [CIFilter filterWithName:@"CILineScreen"],
                  [CIFilter filterWithName:@"CIMaskToAlpha"],
                  [CIFilter filterWithName:@"CIPinchDistortion"],
                  [CIFilter filterWithName:@"CIPixellate"],
                  [CIFilter filterWithName:@"CISharpenLuminance"],
                  [CIFilter filterWithName:@"CIStraightenFilter"],
                  [CIFilter filterWithName:@"CITriangleKaleidoscope"],
                  [CIFilter filterWithName:@"CITwirlDistortion"],
                  [CIFilter filterWithName:@"CIVortexDistortion"], nil];
}

// This method provides a filter object, given its name.
- (CIFilter *)filterOfName:(NSString *)filterName
{
    for (CIFilter *filter in filterList) {
        if ([[filter name] isEqualToString:filterName]) {
            return filter;
        }
    }
    
    return nil;
}

// This method enables the setting of a default value not present in the filter's own defaults.
- (NSMutableDictionary *)attributesForFilter:(NSString *)filterName
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if (filterName == @"CIColorMonochrome") {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        const CGFloat components[4] = {1.0, 1.0, 1.0, 1.0};
        CGColorRef clr = CGColorCreate (colorSpace,  components);
        CIColor *black = [[CIColor alloc] initWithCGColor:clr];
        [attributes setValue:black forKey:@"inputColor"];
    }
    return attributes;
}

// This method prints out details about the API of each filter.  Currently it highlights those with numeric inputs, which are suitable for slider controls.
- (void)logAllFilters
{
    NSArray *inputs;
    NSString *attrClass;
    NSArray* filters = [CIFilter filterNamesInCategories:nil];
    for (NSString* filterName in filters)
    {
        CIFilter *filter = [CIFilter filterWithName:filterName];
        NSLog(@"Filter: %@", filterName);
        inputs = [filter inputKeys];
        NSLog(@"Inputs: %@", inputs);
        for (NSString *input in inputs) {
            attrClass = [[[filter attributes] valueForKey:input] valueForKey:kCIAttributeClass];
            if ([attrClass isEqualToString:@"NSNumber"]) {
                NSLog(@"filter takes a number as input: %@", filterName);
            }
        }
    }
}

#pragma mark -- saving custom filters --
// This method saves the currently configured filter chain.
- (IBAction)writeFilter:(id)sender {
    [self.view endEditing:YES];
    NSMutableDictionary *filterDetails = [[NSMutableDictionary alloc] initWithCapacity:10];
    [firstFilterProperties removeObjectForKey:@"inputColor"];
    [secondFilterProperties removeObjectForKey:@"inputColor"];
    [thirdFilterProperties removeObjectForKey:@"inputColor"];
    
    [filterDetails setValue:[firstFilter name] forKey:@"firstFilterName"];
    [filterDetails setValue:firstFilterProperties forKey:@"firstFilterProperties"];
    [filterDetails setValue:[NSNumber numberWithBool:firstFilterArmButton.on] forKey:@"firstFilterArmed"];
    
    [filterDetails setValue:[secondFilter name] forKey:@"secondFilterName"];
    [filterDetails setValue:secondFilterProperties forKey:@"secondFilterProperties"];
    [filterDetails setValue:[NSNumber numberWithBool:secondFilterArmButton.on] forKey:@"secondFilterArmed"];
    
    [filterDetails setValue:[thirdFilter name] forKey:@"thirdFilterName"];
    [filterDetails setValue:thirdFilterProperties forKey:@"thirdFilterProperties"];
    [filterDetails setValue:[NSNumber numberWithBool:thirdFilterArmButton.on] forKey:@"thirdFilterArmed"];
    
    [filterDetails setValue:filterChainTitle.text forKey:@"filterChainTitle"];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [filterDetails setValue:[NSNumber numberWithBool:YES] forKey:@"firstFilterArmed"];
        [filterDetails setValue:[NSNumber numberWithBool:YES] forKey:@"secondFilterArmed"];
        [filterDetails setValue:[NSNumber numberWithBool:YES] forKey:@"thirdFilterArmed"];
    }

    NSMutableArray *filters = [self savedFilters];
    
    if (filters == nil) {
        filters = [NSMutableArray arrayWithObject:filterDetails];
    } else {
        [filters addObject:filterDetails];
    }

    BOOL success = [filters writeToFile:[self savePath] atomically:YES];
    NSLog(@"save success: %d", success);
}

// This method displays a list of available filter chains.
- (IBAction)loadFilter:(id)sender {
    SFLoadFilterController *filterChooser = [[SFLoadFilterController alloc] initWithStyle:UITableViewStylePlain];
    filterChooser.filters = [self savedFilters];
    filterChooser.filterController = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *chooserP = [[UIPopoverController alloc] initWithContentViewController:filterChooser];
        [chooserP presentPopoverFromRect:CGRectMake(65, 935, 85, 20) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        popover = chooserP;
    } else {
        [self presentModalViewController:filterChooser animated:YES];
    }
}

// This method loads a saved filter chain into the filter banks.
-(void)useSavedFilterAtIndex:(NSUInteger)index
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    NSMutableDictionary *filterDetails = [[self savedFilters] objectAtIndex:index];
    [self controlFilter:[NSNumber numberWithInt:1]];
    firstFilterProperties = [filterDetails valueForKey:@"firstFilterProperties"];
    [self updateFilter:[filterDetails valueForKey:@"firstFilterName"] withProperties:firstFilterProperties];
    
    [self controlFilter:[NSNumber numberWithInt:2]];
    secondFilterProperties = [filterDetails valueForKey:@"secondFilterProperties"];
    [self updateFilter:[filterDetails valueForKey:@"secondFilterName"] withProperties:secondFilterProperties];
    
    [self controlFilter:[NSNumber numberWithInt:3]];
    thirdFilterProperties = [filterDetails valueForKey:@"thirdFilterProperties"];
    [self updateFilter:[filterDetails valueForKey:@"thirdFilterName"] withProperties:thirdFilterProperties];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [firstFilterArmButton setOn:[[filterDetails valueForKey:@"firstFilterArmed"] boolValue] animated:YES];
        [secondFilterArmButton setOn:[[filterDetails valueForKey:@"secondFilterArmed"] boolValue] animated:YES];
        [thirdFilterArmButton setOn:[[filterDetails valueForKey:@"thirdFilterArmed"] boolValue] animated:YES];
    }
    
    filterChainTitle.text = [filterDetails valueForKey:@"filterChainTitle"];
    [self updateFilteredImage:beginImage context:previewContext];
}

// This method displays a list of saved filters that can be deleted.
- (IBAction)chooseFilterToDelete:(id)sender {
    SFLoadFilterController *filterChooser = [[SFLoadFilterController alloc] initWithStyle:UITableViewStylePlain];
    filterChooser.filters = [self savedFilters];
    filterChooser.filterController = self;
    filterChooser.idiom = @"delete";
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *chooserP = [[UIPopoverController alloc] initWithContentViewController:filterChooser];
        [chooserP presentPopoverFromRect:CGRectMake(65, 975, 85, 20) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        popover = chooserP;
    } else {
        [self presentModalViewController:filterChooser animated:YES];
    }
}

// This method removes a chosen filter chain from the saved group.
- (void)deleteFilterAtIndex:(NSUInteger)index
{
    NSMutableArray *newFilterGroup = [self savedFilters];
    [newFilterGroup removeObjectAtIndex:index];
    BOOL success = [newFilterGroup writeToFile:[self savePath] atomically:YES];
    NSLog(@"save success: %d", success);
}

// This is the path to the file used for storing saved filters.
- (NSString *)savePath
{
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:@"saved_filters.plist"];
}

// This is the array of saved filter chains (stored as dictionaries containing configuration settings).
- (NSMutableArray *)savedFilters
{
    return [[NSMutableArray alloc] initWithContentsOfFile:[self savePath]];
}

#pragma mark -- filter selection --
// This indicates that the filters in the picker are not currently grouped in any way.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// This tells the picker how many filters it will hold.
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [filterList count];
}

// This gets human-readable names for the filters implemented.
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    CIFilter *filter = [filterList objectAtIndex:row];
    NSDictionary *attrs = [filter attributes];
    return [attrs objectForKey:kCIAttributeFilterDisplayName];
}

// This responds to the picker by loading the selected filter into the active bank.
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self updateFilter:[[filterList objectAtIndex:row] name] withProperties:nil];
}

#pragma mark -- image selection --
// This method displays the photo album picker used to pick photos.
- (IBAction)loadPhoto:(id)sender {
    if (![longPressAlternativeImageLoader isEnabled]) return; // code to prevent multiple long press messages
    [longPressAlternativeImageLoader setEnabled:NO];
    [longPressAlternativeImageLoader performSelector:@selector(setEnabled:) withObject: [NSNumber numberWithBool:YES] afterDelay:0.5];
    CGRect popoverSpot;
    UIPopoverArrowDirection arrowDirection;
    if (sender == longPressAlternativeImageLoader) {
        pickingAlternative = YES;
        popoverSpot = CGRectMake(140, 340, 100, 50);
        arrowDirection = UIPopoverArrowDirectionUp;
    } else {
        pickingAlternative = NO;
        popoverSpot = CGRectMake(650, 925, 75, 20);
        arrowDirection = UIPopoverArrowDirectionDown;
    }
    UIImagePickerController *pickerC = [[UIImagePickerController alloc] init];
    pickerC.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *pickerP = [[UIPopoverController alloc] initWithContentViewController:pickerC];
        [pickerP presentPopoverFromRect:popoverSpot inView:self.view permittedArrowDirections:arrowDirection animated:YES];
        popover = pickerP;
    } else {
        [self presentModalViewController:pickerC animated:YES];
    }
}

// This method saves/exports a full-resolution version of the filtered image.
- (IBAction)savePhoto:(id)sender {
    CIImage *fullSize = [CIImage imageWithCGImage:fullSizeImage.CGImage];
    [self updateFilteredImage:fullSize context:saveContext];
}

// This method loads the selected image into the preview window and into the filter chain (unless it's just a reference image).
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [popover dismissPopoverAnimated:YES];
        popover = nil;
        [longPressAlternativeImageLoader setEnabled:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    fullSizeImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CGFloat height = fullSizeImage.size.height;
    CGFloat width = fullSizeImage.size.width;
    
    CGFloat minorDimension;
    if (width > height) {
        minorDimension = height;
    } else {
        minorDimension = width;
    }
    UIImage *croppedImage = [[[UIImage alloc] initWithData:UIImageJPEGRepresentation(fullSizeImage, 1.0)] imageCroppedToFitSize:CGSizeMake(minorDimension, minorDimension)];
    
    CGSize imageSize;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([[UIScreen mainScreen] scale] > 1.0) {
            if (minorDimension > 746.0) {
                imageSize = CGSizeMake(746.0, 746.0);
            } else {
                imageSize = CGSizeMake(minorDimension, minorDimension);
            }
        } else {
            if (minorDimension > 373.0) {
                imageSize = CGSizeMake(373.0, 373.0);
            } else {
                imageSize = CGSizeMake(minorDimension, minorDimension);
            }
        }
    } else {
        if ([[UIScreen mainScreen] scale] > 1.0) {
            if (minorDimension > 342.0) {
                imageSize = CGSizeMake(342.0, 342.0);
            } else {
                imageSize = CGSizeMake(minorDimension, minorDimension);
            }
        } else {
            if (minorDimension > 171.0) {
                imageSize = CGSizeMake(171.0, 171.0);
            } else {
                imageSize = CGSizeMake(minorDimension, minorDimension);
            }
        }
    }
    UIImage *sizedImage = [[[UIImage alloc] initWithData:UIImageJPEGRepresentation(croppedImage, 1.0)] imageScaledToFitSize:imageSize];
    if (!pickingAlternative) {
        beginImage = [CIImage imageWithCGImage:sizedImage.CGImage];    
        [firstFilter setValue:beginImage forKey:kCIInputImageKey];
        [self changeValue:amountSlider];
    } else {
        alternatePreviewImage = sizedImage;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        originalImageView.image = sizedImage;
    }
}

// This method handles cancellation of an image pick - although I'm not sure how to cancel (tapping outside the picker doesn't seem to run this).
- (void)imagePickerControllerDidCancel:
(UIImagePickerController *)picker {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [popover dismissPopoverAnimated:YES];
        popover = nil;
        [longPressAlternativeImageLoader setEnabled:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

// This method toggles whether your original image or your reference image is displayed in the left-side preview window.
- (IBAction)toggleAlternatePreviewImage:(id)sender
{
    if (originalImageView.image == alternatePreviewImage) {
        CGImageRef cgimg = [previewContext createCGImage:beginImage fromRect:[beginImage extent]];
        UIImage *filterImage = [UIImage imageWithCGImage:cgimg];    
        originalImageView.image = filterImage;
    } else {
        originalImageView.image = alternatePreviewImage;
    }
}

#pragma mark -- filter sharing and importing --
// This method populates an email with attachments (filter plist, current previews) and instructions on how to import filters.
- (IBAction)sendFilterListInEmail:(id)sender {
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    
    mailer.mailComposeDelegate = self;
    
    [mailer setSubject:@"My saved filters"];
    
    NSArray *toRecipients = [NSArray arrayWithObjects:@"mike.schwab@gmail.com", nil];
    [mailer setToRecipients:toRecipients];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIImage *currentOriginalImage = originalImageView.image;
        NSData *originalImageData = UIImagePNGRepresentation(currentOriginalImage);
        [mailer addAttachmentData:originalImageData mimeType:@"image/png" fileName:@"unfiltered-image"];
    }
    UIImage *currentFilteredImage = imgV.image;
    NSData *currentImageData = UIImagePNGRepresentation(currentFilteredImage);
    NSData *filterPlist = [NSData dataWithContentsOfFile:[self savePath]];
    [mailer addAttachmentData:currentImageData mimeType:@"image/png" fileName:@"filtered-image"];
    [mailer addAttachmentData:filterPlist mimeType:@"text/xml" fileName:@"saved-filters.plist"];
    NSString *emailBody = @"Here are all of the filters I've saved, with the newest ones at the bottom.  To load them into your filtering app, open the attached \"saved_filters.plist\" file on a computer, copy the filter XML into an email you can open on your iPad, and paste the XML into the 'Load Filters' window.\n\n\n";
    
    [mailer setMessageBody:emailBody isHTML:NO];
    
    mailer.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentModalViewController:mailer animated:YES];
}

// This method presents the import view where filter XML can be pasted.
- (IBAction)importFiltersFromXML:(id)sender {
    SFImportViewController *importController = [[SFImportViewController alloc] initWithNibName:@"SFImportViewController" bundle:nil];
    importController.filterController = self;
    
    importController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentModalViewController:importController animated:YES];
}

// This method sends the email after composition is complete.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    
        // Remove the mail view
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -- boilerplate --
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload
{
    [self setImgV:nil];
    [self setAmountSlider:nil];
    [self setFilterValueLabel:nil];
    [self setFilterPicker:nil];
    [self setOriginalImageView:nil];
    [self setSecondSlider:nil];
    [self setSecondFilterValueLabel:nil];
    [self setFirstFilterControl:nil];
    [self setFirstFilterArmButton:nil];
    [self setSecondFilterControl:nil];
    [self setSecondFilterArmButton:nil];
    [self setThirdFilterControl:nil];
    [self setThirdFilterArmButton:nil];
    [self setFirstFilterPropertyLabel:nil];
    [self setSecondFilterPropertyLabel:nil];
    [self setThirdFilterPropertyLabel:nil];
    [self setFilterChainTitle:nil];
    [self setFilterControl:nil];
    [self setLongPressAlternativeImageLoader:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}
@end
