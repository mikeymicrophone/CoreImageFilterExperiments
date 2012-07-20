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
    CIFilter *filter;
    CIImage *beginImage;
    NSString *firstSliderAttribute;
}
@synthesize filterValueLabel;
@synthesize filterPicker;
@synthesize amountSlider;
@synthesize imgV;

//-(void)logAllFilters {
//    NSArray *properties = [CIFilter filterNamesInCategory:
//                           kCICategoryBuiltIn];
//    NSLog(@"%@", properties);
//    for (NSString *filterName in properties) {
//        CIFilter *fltr = [CIFilter filterWithName:filterName];
//        NSLog(@"%@", [fltr attributes]);
//    }
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"image" ofType:@"png"];
    NSURL *fileNameAndPath = [NSURL fileURLWithPath:filePath];
    
    beginImage = [CIImage imageWithContentsOfURL:fileNameAndPath];
    context = [CIContext contextWithOptions:nil];
    
    [self updateFilter:@"CIColorMonochrome"];
    
    CIImage *outputImage = [filter outputImage];
    
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];
    
    [imgV setImage:newImg];
    
    filterValueLabel.text = [NSString stringWithFormat:@"%1.2f", 0.5];
    
    CGImageRelease(cgimg);
    
//    [self logAllFilters];
}

- (void)viewDidUnload
{
    [self setImgV:nil];
    [self setAmountSlider:nil];
    [self setFilterValueLabel:nil];
    [self setFilterPicker:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)updateFilter:(NSString *)filterName
{
    NSDictionary *attributes = [self attributesForFilter:filterName];
    
    filter = [CIFilter filterWithName:filterName];
    [filter setValue:beginImage forKey:kCIInputImageKey];
    NSString *setting;
    for(setting in attributes) {
        [filter setValue:[attributes valueForKey:setting] forKey:setting];
    }
    
}

- (NSDictionary *)attributesForFilter:(NSString *)filterName
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if (filterName == @"CIColorMonochrome") {
        [attributes setValue:[NSNumber numberWithFloat:0.8] forKey:@"inputIntensity"];
        firstSliderAttribute = @"inputIntensity";
        amountSlider.maximumValue = 1.0;
        amountSlider.minimumValue = 0.0;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        const CGFloat components[4] = {1.0, 1.0, 1.0, 1.0 };
        CGColorRef clr = CGColorCreate (colorSpace,  components);
        CIColor *black = [[CIColor alloc] initWithCGColor:clr];
        [attributes setValue:black forKey:@"inputColor"];
    } else if (filterName == @"CISepiaTone") {
        [attributes setValue:[NSNumber numberWithFloat:0.8] forKey:@"inputIntensity"];
        firstSliderAttribute = @"inputIntensity";
        amountSlider.maximumValue = 1.0;
        amountSlider.minimumValue = 0.0;
    } else if (filterName == @"CIGammaAdjust") {
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputPower"];
        firstSliderAttribute = @"inputPower";
        amountSlider.maximumValue = 4.0;
        amountSlider.minimumValue = 0.25;
    } else if (filterName == @"CIExposureAdjust") {
        [attributes setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputEV"];
        firstSliderAttribute = @"inputEV";
        amountSlider.maximumValue = 10.0;
        amountSlider.minimumValue = -10.0;
    }
    return attributes;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(IBAction)changeValue:(UISlider *)sender {
    float slideValue = [sender value];
    
    filterValueLabel.text = [NSString stringWithFormat:@"%1.2f", slideValue];
    
    [filter setValue:[NSNumber numberWithFloat:slideValue] 
              forKey:firstSliderAttribute];
    CIImage *outputImage = [filter outputImage];
    
    CGImageRef cgimg = [context createCGImage:outputImage 
                                     fromRect:[outputImage extent]];
    
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];    
    [imgV setImage:newImg];
    
    CGImageRelease(cgimg);
}

- (IBAction)loadPhoto:(id)sender {
    UIImagePickerController *pickerC = 
    [[UIImagePickerController alloc] init];
    pickerC.delegate = self;
    [self presentModalViewController:pickerC animated:YES];
}

- (IBAction)savePhoto:(id)sender {
    CIImage *saveToSave = [filter outputImage];
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
    return 4;
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
            
        default:
            break;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissModalViewControllerAnimated:YES];
    UIImage *gotImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    beginImage = [CIImage imageWithCGImage:gotImage.CGImage];    
    [filter setValue:beginImage forKey:kCIInputImageKey];
    [self changeValue:amountSlider];
}

- (void)imagePickerControllerDidCancel:
(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}
@end
