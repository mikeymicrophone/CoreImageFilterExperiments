//
//  SFViewController.m
//  SeeFilters
//
//  Created by Mike Schwab on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SFViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface SFViewController ()

@end

@implementation SFViewController {
    CIContext *context;
    CIFilter *firstFilter;
    CIFilter *secondFilter;
    CIFilter *thirdFilter;
    CIImage *beginImage;
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
    context = [CIContext contextWithOptions:nil];
    
    firstFilterPropertyLabel.numberOfLines = 0;
    secondFilterPropertyLabel.numberOfLines = 0;
    thirdFilterPropertyLabel.numberOfLines = 0;
        
    firstFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
    secondFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
    thirdFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
    
    [self controlFirstFilter:nil];
    firstFilterProperties = [[NSMutableDictionary alloc] init];
    [self updateFilter:@"CIColorMonochrome"];
    
    [self controlSecondFilter:nil];
    secondFilterProperties = [[NSMutableDictionary alloc] init];
    [self updateFilter:@"CISepiaTone"];
    
    [self controlThirdFilter:nil];
    thirdFilterProperties = [[NSMutableDictionary alloc] init];
    [self updateFilter:@"CIColorControls"];
    
    [self updateFilterChain];
    [self controlFirstFilter:nil];
    
    [self logAllFilters];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)updateFilter:(NSString *)filterName
{
    configurableFilter = [CIFilter filterWithName:filterName];
    NSMutableArray *inputs = [NSMutableArray arrayWithArray:[configurableFilter inputKeys]];
    [inputs removeObject:@"inputImage"];
    if (configurableFilterIndex == 1) {
        configurableFilterProperties = firstFilterProperties;
        [firstFilterControl setTitle:[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] forState:UIControlStateNormal];
    } else if (configurableFilterIndex == 2) {
        configurableFilterProperties = secondFilterProperties;
        [secondFilterControl setTitle:[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] forState:UIControlStateNormal];
    } else {
        configurableFilterProperties = thirdFilterProperties;
        [thirdFilterControl setTitle:[[configurableFilter attributes] objectForKey:kCIAttributeFilterDisplayName] forState:UIControlStateNormal];
    }
    
    for (NSString *attr in inputs) {
        id identity = [[[configurableFilter attributes] objectForKey:attr] objectForKey:kCIAttributeIdentity];
        if (identity != nil) {
            [configurableFilterProperties setValue:identity forKey:attr];
        }
    }
    
    
    NSMutableDictionary *attributes = [self attributesForFilter:filterName];
    
    switch (configurableFilterIndex) {
        case 1:
            firstFilter = configurableFilter;
            break;
            
        case 2:
            secondFilter = configurableFilter;
            break;
            
        case 3:
            thirdFilter = configurableFilter;
            break;
            
        default:
            break;
    }
    for(NSString *setting in attributes) {
        [configurableFilter setValue:[attributes valueForKey:setting] forKey:setting];
    }
}

- (NSMutableDictionary *)attributesForFilter:(NSString *)filterName
{
    [self updateSliders];
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if (filterName == @"CIColorMonochrome") {
        [attributes setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputIntensity"];
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        const CGFloat components[4] = {1.0, 1.0, 1.0, 1.0};
        CGColorRef clr = CGColorCreate (colorSpace,  components);
        CIColor *black = [[CIColor alloc] initWithCGColor:clr];
        [attributes setValue:black forKey:@"inputColor"];
    } else if (filterName == @"CISepiaTone") {
        [attributes setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputIntensity"];
    } else if (filterName == @"CIGammaAdjust") {
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputPower"];
    } else if (filterName == @"CIExposureAdjust") {
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputEV"];
    } else if (filterName == @"CIColorControls") {
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputSaturation"];
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputContrast"];
    }
    return attributes;
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)toggleFilter:(id)sender {
    [self updateFilterChain];
}

-(void)updateFilterChain
{
    CIImage *outputImage;
    if (firstFilterArmButton.on) {
        [firstFilter setValue:beginImage forKey:kCIInputImageKey];
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
    
    CGImageRef cgimg = [context createCGImage:outputImage 
                                     fromRect:[outputImage extent]];
    
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];    
    [imgV setImage:newImg];
    
    CGImageRelease(cgimg);
}

-(IBAction)changeValue:(UISlider *)sender {
    float slideValue = [sender value];
    if (sender == amountSlider) {
        configurableAttribute = firstSliderAttribute;
        filterValueLabel.text = [NSString stringWithFormat:@"%1.3f", slideValue];
    } else {
        configurableAttribute = secondSliderAttribute;
        secondFilterValueLabel.text = [NSString stringWithFormat:@"%1.3f", slideValue];
    }
    
    [configurableFilter setValue:[NSNumber numberWithFloat:slideValue] 
                          forKey:configurableAttribute];
    [self updateFilterChain];
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
    [configurableFilterProperties setValue:[NSNumber numberWithFloat:slideValue] forKey:configurableAttribute];
    if ([secondAttrName isEqualToString:@""]) {
        configurableFilterPropertyLabel.text = [NSString stringWithFormat:@"%@: %1.3f", firstAttrName, [amountSlider value]];
    } else {
        configurableFilterPropertyLabel.text = [NSString stringWithFormat:@"%@: %1.3f\n%@: %1.3f", firstAttrName, [amountSlider value], secondAttrName, [secondSlider value]];
    }

}

- (IBAction)loadPhoto:(id)sender {
    UIImagePickerController *pickerC = 
    [[UIImagePickerController alloc] init];
    pickerC.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *pickerP = [[UIPopoverController alloc] initWithContentViewController:pickerC];
        [pickerP presentPopoverFromRect:CGRectMake(100, 100, 100, 100) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        popover = pickerP;
    } else {
        [self presentModalViewController:pickerC animated:YES];
    }
}

- (IBAction)savePhoto:(id)sender {
    CIImage *saveToSave = [firstFilter outputImage];
    CGImageRef cgImg = [context createCGImage:saveToSave 
                                     fromRect:[saveToSave extent]];
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:cgImg 
                                 metadata:[saveToSave properties] 
                          completionBlock:^(NSURL *assetURL, NSError *error) {
                              CGImageRelease(cgImg);
                          }];
}

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
    NSDictionary *attrs = [[filterList objectAtIndex:row] attributes];
    return [attrs objectForKey:kCIAttributeFilterDisplayName];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self updateFilter:[[filterList objectAtIndex:row] name]];
}

- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    UIImage *gotImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    beginImage = [CIImage imageWithCGImage:gotImage.CGImage];    
    [firstFilter setValue:beginImage forKey:kCIInputImageKey];
    [self changeValue:amountSlider];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        originalImageView.image = gotImage;
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

- (IBAction)controlFirstFilter:(id)sender {
    configurableFilter = firstFilter;
    configurableFilterProperties = firstFilterProperties;
    firstFilterControl.backgroundColor = [UIColor blueColor];
    secondFilterControl.backgroundColor = nil;
    thirdFilterControl.backgroundColor = nil;
    configurableFilterIndex = 1;
    [self updateSliders];
    [self updatePicker];
}
- (IBAction)controlSecondFilter:(id)sender {
    configurableFilter = secondFilter;
    configurableFilterProperties = secondFilterProperties;
    firstFilterControl.backgroundColor = nil;
    secondFilterControl.backgroundColor = [UIColor blueColor];
    thirdFilterControl.backgroundColor = nil;
    configurableFilterIndex = 2;
    [self updateSliders];
    [self updatePicker];
}
- (IBAction)controlThirdFilter:(id)sender {
    configurableFilter = thirdFilter;
    configurableFilterProperties = thirdFilterProperties;
    firstFilterControl.backgroundColor = nil;
    secondFilterControl.backgroundColor = nil;
    thirdFilterControl.backgroundColor = [UIColor blueColor];
    configurableFilterIndex = 3;
    [self updateSliders];
    [self updatePicker];
}

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
- (IBAction)writeFilter:(id)sender {
    NSMutableDictionary *filterDetails = [[NSMutableDictionary alloc] initWithCapacity:10];
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
    
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filterListPath = [documentsPath stringByAppendingPathComponent:@"saved_filters.plist"];
    
//    NSInputStream *input = [NSInputStream inputStreamWithFileAtPath:filterListPath];
//
//    NSError *inputError = nil;
//    NSMutableArray *savedFilters = [NSPropertyListSerialization propertyListWithStream:input options:NSPropertyListMutableContainers format:kCFPropertyListXMLFormat_v1_0 error:&inputError];
    NSMutableArray *savedFilters = [[NSMutableArray alloc] initWithContentsOfFile:filterListPath];
    NSLog(@"savedFilters: %@", savedFilters);

    if (savedFilters == nil) {
        NSLog(@"app has no array of saved filters");
        savedFilters = [NSMutableArray arrayWithObject:filterDetails];
    } else {
        NSLog(@"app has an array of saved filters");
        [savedFilters addObject:filterDetails];
        for (NSDictionary *filter in savedFilters) {
            NSLog(@"saved filter: %@", [filter valueForKey:@"filterChainTitle"]);
        }
    }
    
    [savedFilters writeToFile:filterListPath atomically:YES];
    
//    NSError *outputError = nil;
//    NSOutputStream *output = [NSOutputStream outputStreamToFileAtPath:filterListPath append:NO];
//    [output open];
//    [NSPropertyListSerialization writePropertyList:savedFilters toStream:output format:kCFPropertyListXMLFormat_v1_0 options:0 error:&outputError];
//    [output close];
//    NSLog(@"input error: %@", inputError);
//    NSLog(@"output error: %@", outputError);
}
@end
