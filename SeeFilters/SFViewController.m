//
//  SFViewController.m
//  SeeFilters
//
//  Created by Mike Schwab on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SFViewController.h"
#import "SFLoadFilterController.h"
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
}
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
    [self updateFilter:@"CISepiaTone" withProperties:nil];
    
    [self controlFilter:[NSNumber numberWithInt:2]];
    secondFilterProperties = [[NSMutableDictionary alloc] init];
    [self updateFilter:@"CIExposureAdjust" withProperties:nil];
    
    [self controlFilter:[NSNumber numberWithInt:3]];
    thirdFilterProperties = [[NSMutableDictionary alloc] init];
    [self updateFilter:@"CIExposureAdjust" withProperties:nil];
    
    [self updateFilteredImage:beginImage context:previewContext];
    
//    [self logAllFilters];
}

#pragma mark -- updaters --

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
        [configurableFilter setValue:[configurableFilterProperties valueForKey:setting] forKey:setting];
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
    }
    amountSlider.maximumValue = [[[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:kCIAttributeSliderMax] floatValue];
    amountSlider.minimumValue = [[[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:kCIAttributeSliderMin] floatValue];
    if ([configurableFilterProperties valueForKey:firstSliderAttribute]) {
        [amountSlider setValue:[[configurableFilterProperties valueForKey:firstSliderAttribute] floatValue] animated:YES];
    } else {
        [amountSlider setValue:[[[[filter attributes] valueForKey:firstSliderAttribute] valueForKey:kCIAttributeIdentity] floatValue] animated:YES];
    }

    filterValueLabel.text = [NSString stringWithFormat:@"%1.3f", amountSlider.value];

    if (secondSliderUsed) {
        secondSlider.maximumValue = [[[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:kCIAttributeSliderMax] floatValue];
        secondSlider.minimumValue = [[[[filter attributes] valueForKey:secondSliderAttribute] valueForKey:kCIAttributeSliderMin] floatValue];        
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
    }
}

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

- (IBAction)toggleFilter:(id)sender {
    [self updateFilteredImage:beginImage context:previewContext];
    [self updateTitleColors];
}

- (IBAction)controlFilter:(id)sender {
    if (sender == firstFilterControl || (sender == filterControl && (filterControl.selectedSegmentIndex == 0)) || (sender == [NSNumber numberWithInt:1])) {
        configurableFilter = firstFilter;
        configurableFilterProperties = firstFilterProperties;
        configurableFilterIndex = 1;        
    } else if (sender == secondFilterControl || (sender == filterControl && (filterControl.selectedSegmentIndex == 1)) || (sender == [NSNumber numberWithInt:2])) {
        configurableFilter = secondFilter;
        configurableFilterProperties = secondFilterProperties;
        configurableFilterIndex = 2;
    } else if (sender == thirdFilterControl || (sender == filterControl && (filterControl.selectedSegmentIndex == 2)) || (sender == [NSNumber numberWithInt:3])) {
        configurableFilter = thirdFilter;
        configurableFilterProperties = thirdFilterProperties;
        configurableFilterIndex = 3;
    }
    [self updateSliders];
    [self updatePicker];
    [self updateTitleColors];
}

#pragma mark -- filter definitions --

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
                  [CIFilter filterWithName:@"CIVignette"], nil];
}

- (CIFilter *)filterOfName:(NSString *)filterName
{
    for (CIFilter *filter in filterList) {
        if ([[filter name] isEqualToString:filterName]) {
            return filter;
        }
    }
    
    return nil;
}

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
        NSLog(@"app found no saved filters");
        filters = [NSMutableArray arrayWithObject:filterDetails];
    } else {
        NSLog(@"app found saved filters");
        [filters addObject:filterDetails];
    }
    NSLog(@"details: %@", filterDetails);
    BOOL success = [filters writeToFile:[self savePath] atomically:YES];
    NSLog(@"save success: %d", success);
}

- (IBAction)loadFilter:(id)sender {
    SFLoadFilterController *filterChooser = [[SFLoadFilterController alloc] initWithStyle:UITableViewStylePlain];
    filterChooser.filters = [self savedFilters];
//    NSLog(@"filterChooser's filters: %@", filterChooser.filters);
    filterChooser.filterController = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *chooserP = [[UIPopoverController alloc] initWithContentViewController:filterChooser];
        [chooserP presentPopoverFromRect:CGRectMake(65, 935, 85, 20) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        popover = chooserP;
    } else {
        [self presentModalViewController:filterChooser animated:YES];
    }
}

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

- (NSString *)savePath
{
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:@"saved_filters.plist"];
}

- (NSMutableArray *)savedFilters
{
    return [[NSMutableArray alloc] initWithContentsOfFile:[self savePath]];
}

#pragma mark -- filter selection --

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [filterList count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    CIFilter *filter = [filterList objectAtIndex:row];
    NSDictionary *attrs = [filter attributes];
    return [attrs objectForKey:kCIAttributeFilterDisplayName];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self updateFilter:[[filterList objectAtIndex:row] name] withProperties:nil];
}

#pragma mark -- image selection --

- (IBAction)loadPhoto:(id)sender {
    UIImagePickerController *pickerC = 
    [[UIImagePickerController alloc] init];
    pickerC.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *pickerP = [[UIPopoverController alloc] initWithContentViewController:pickerC];
        [pickerP presentPopoverFromRect:CGRectMake(650, 925, 75, 20) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        popover = pickerP;
    } else {
        [self presentModalViewController:pickerC animated:YES];
    }
}

- (IBAction)savePhoto:(id)sender {
    CIImage *fullSize = [CIImage imageWithCGImage:fullSizeImage.CGImage];
    [self updateFilteredImage:fullSize context:saveContext];
    CIImage *imageToSave = thirdFilter.outputImage;
    CGImageRef cgImg = [saveContext createCGImage:imageToSave fromRect:[imageToSave extent]];
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:cgImg metadata:[imageToSave properties] 
                          completionBlock:^(NSURL *assetURL, NSError *error) {
                              CGImageRelease(cgImg);
                          }];
}

- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    fullSizeImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CGFloat height = fullSizeImage.size.height;
    CGFloat width = fullSizeImage.size.width;
    
    CGSize cropSize;
    if (width > height) {
        cropSize = CGSizeMake(height, height);
    } else {
        cropSize = CGSizeMake(width, width);
    }
    UIImage *croppedImage = [[[UIImage alloc] initWithData:UIImageJPEGRepresentation(fullSizeImage, 1.0)] imageCroppedToFitSize:cropSize];
    
    CGSize imageSize;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([[UIScreen mainScreen] scale] > 1.0) {
            imageSize = CGSizeMake(746.0, 746.0);
        } else {
            imageSize = CGSizeMake(373.0, 373.0);
        }
    } else {
        if ([[UIScreen mainScreen] scale] > 1.0) {
            imageSize = CGSizeMake(342.0, 342.0);
        } else {
            imageSize = CGSizeMake(171.0, 171.0);
        }
    }
    UIImage *sizedImage = [[[UIImage alloc] initWithData:UIImageJPEGRepresentation(croppedImage, 1.0)] imageScaledToFitSize:imageSize];
    beginImage = [CIImage imageWithCGImage:sizedImage.CGImage];    
    [firstFilter setValue:beginImage forKey:kCIInputImageKey];
    [self changeValue:amountSlider];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        originalImageView.image = sizedImage;
    }
}

- (void)imagePickerControllerDidCancel:
(UIImagePickerController *)picker {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

@end
