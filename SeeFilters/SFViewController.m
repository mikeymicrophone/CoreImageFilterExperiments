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
    UIPopoverController *popover;
    CIFilter *configurableFilter;
    NSMutableDictionary *firstFilterProperties;
    NSMutableDictionary *secondFilterProperties;
    NSMutableDictionary *thirdFilterProperties;
    NSMutableDictionary *configurableFilterProperties;
    
}
@synthesize secondSlider;
@synthesize secondFilterValueLabel;
@synthesize firstFilterControl;
@synthesize firstFilterArmButton;
@synthesize secondFilterControl;
@synthesize secondFilterArmButton;
@synthesize thirdFilterControl;
@synthesize thirdFilterArmButton;
@synthesize originalImageView;
@synthesize filterValueLabel;
@synthesize filterPicker;
@synthesize amountSlider;
@synthesize imgV;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"image" ofType:@"png"];
    NSURL *fileNameAndPath = [NSURL fileURLWithPath:filePath];
    
    beginImage = [CIImage imageWithContentsOfURL:fileNameAndPath];
    context = [CIContext contextWithOptions:nil];
        
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)updateFilter:(NSString *)filterName
{
    NSMutableArray *inputs = [NSMutableArray arrayWithArray:[configurableFilter inputKeys]];
    [inputs removeObject:@"inputImage"];
    if (configurableFilter == firstFilter) {
        configurableFilterProperties = firstFilterProperties;
    } else if (configurableFilter == secondFilter) {
        configurableFilterProperties = secondFilterProperties;
    } else {
        configurableFilterProperties = thirdFilterProperties;
    }
    
    for (NSString *attr in inputs) {
        id identity = [[[configurableFilter attributes] objectForKey:attr] objectForKey:kCIAttributeIdentity];
        if (identity != nil) {
            [configurableFilterProperties setValue:identity forKey:attr];
        }
    }
    
    NSMutableDictionary *attributes = [self attributesForFilter:filterName];
    NSLog(@"filter %@ is being assigned attributes %@", filterName, attributes);
    NSLog(@"configurable filter is %@", configurableFilter);
    configurableFilter = [CIFilter filterWithName:filterName];
    NSString *setting;
    for(setting in attributes) {
        [configurableFilter setValue:[attributes valueForKey:setting] forKey:setting];
    }
}

- (NSDictionary *)attributesForFilter:(NSString *)filterName
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if (filterName == @"CIColorMonochrome") {
        [attributes setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputIntensity"];
        firstSliderAttribute = @"inputIntensity";
        amountSlider.maximumValue = 1.0;
        amountSlider.minimumValue = 0.0;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        const CGFloat components[4] = {1.0, 1.0, 1.0, 1.0};
        CGColorRef clr = CGColorCreate (colorSpace,  components);
        CIColor *black = [[CIColor alloc] initWithCGColor:clr];
        [attributes setValue:black forKey:@"inputColor"];
        
        secondSlider.hidden = YES;
        secondFilterValueLabel.hidden = YES;
    } else if (filterName == @"CISepiaTone") {
        [attributes setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputIntensity"];
        firstSliderAttribute = @"inputIntensity";
        amountSlider.maximumValue = 1.0;
        amountSlider.minimumValue = 0.0;
        
        secondSlider.hidden = YES;
        secondFilterValueLabel.hidden = YES;
    } else if (filterName == @"CIGammaAdjust") {
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputPower"];
        firstSliderAttribute = @"inputPower";
        amountSlider.maximumValue = 4.0;
        amountSlider.minimumValue = 0.25;
        
        secondSlider.hidden = YES;
        secondFilterValueLabel.hidden = YES;
    } else if (filterName == @"CIExposureAdjust") {
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputEV"];
        firstSliderAttribute = @"inputEV";
        amountSlider.maximumValue = 4.0;
        amountSlider.minimumValue = -4.0;
        
        secondSlider.hidden = YES;
        secondFilterValueLabel.hidden = YES;
    } else if (filterName == @"CIColorControls") {
        firstSliderAttribute = @"inputSaturation";
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:firstSliderAttribute];
        amountSlider.value = 1.0;
        amountSlider.maximumValue = 2.0;
        amountSlider.minimumValue = -1.0;
        
        secondSliderAttribute = @"inputContrast";
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:secondSliderAttribute];
        secondFilterValueLabel.text = @"1.000";
        secondSlider.value = 1.0;
        secondSlider.maximumValue = 4.0;
        secondSlider.minimumValue = 0.0;
        
        secondSlider.hidden = NO;
        secondFilterValueLabel.hidden = NO;
    }
    return attributes;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
    
    filterValueLabel.text = [NSString stringWithFormat:@"%1.3f", slideValue];
    
    [configurableFilter setValue:[NSNumber numberWithFloat:slideValue] 
              forKey:firstSliderAttribute];
    [self updateFilterChain];
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
    return 5;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch (row) {
        case 0:
            return @"Black/White";
            break;
            
        case 1:
            return @"Sepia";
            break;
            
        case 2:
            return @"Gamma";
            break;
            
        case 3:
            return @"Exposure";
            break;
            
        case 4:
            return @"Color Controls";
            break;
            
        default:
            return @"Other Filters";
            break;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (row) {
        case 0:
            [self updateFilter:@"CIColorMonochrome"];
            break;
            
        case 1:
            [self updateFilter:@"CISepiaTone"];
            break;
        
        case 2:
            [self updateFilter:@"CIGammaAdjust"];
            break;
            
        case 3:
            [self updateFilter:@"CIExposureAdjust"];
            break;
            
        case 4:
            [self updateFilter:@"CIColorControls"];
            break;
            
        default:
            break;
    }
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
- (IBAction)changeSecondValue:(UISlider *)sender {
    float slideValue = [sender value];
    
    secondFilterValueLabel.text = [NSString stringWithFormat:@"%1.3f", slideValue];
    
    [firstFilter setValue:[NSNumber numberWithFloat:slideValue] 
              forKey:secondSliderAttribute];
    CIImage *outputImage = [firstFilter outputImage];
    
    CGImageRef cgimg = [context createCGImage:outputImage 
                                     fromRect:[outputImage extent]];
    
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];    
    [imgV setImage:newImg];
    
    CGImageRelease(cgimg);
}
- (IBAction)controlFirstFilter:(id)sender {
    configurableFilter = firstFilter;
    NSLog(@"first filter is now configurable.");
}
- (IBAction)controlSecondFilter:(id)sender {
    configurableFilter = secondFilter;
    NSLog(@"second filter is now configurable.");
}
- (IBAction)controlThirdFilter:(id)sender {
    configurableFilter = thirdFilter;
    NSLog(@"third filter is now configurable.");
}
@end
