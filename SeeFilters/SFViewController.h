//
//  SFViewController.h
//  SeeFilters
//
//  Created by Mike Schwab on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SFViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imgV;
- (IBAction)changeValue:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UISlider *amountSlider;
- (IBAction)loadPhoto:(id)sender;
- (IBAction)savePhoto:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *filterValueLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *filterPicker;
- (void)updateFilter:(NSString *)filterName;
- (NSDictionary *)attributesForFilter:(NSString *)filterName;

@property (weak, nonatomic) IBOutlet UIImageView *originalImageView;
@end
