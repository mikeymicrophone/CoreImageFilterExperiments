//
//  SFViewController.h
//  SeeFilters
//
//  Created by Mike Schwab on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+ProportionalFill.h"

@interface SFViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imgV;
- (IBAction)changeValue:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UISlider *amountSlider;
- (IBAction)loadPhoto:(id)sender;
- (IBAction)savePhoto:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *filterValueLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *filterPicker;
- (void)updateFilter:(NSString *)filterName withProperties:(NSMutableDictionary *)properties;
- (NSDictionary *)attributesForFilter:(NSString *)filterName;
@property (weak, nonatomic) IBOutlet UISlider *secondSlider;
@property (weak, nonatomic) IBOutlet UILabel *secondFilterValueLabel;
@property (weak, nonatomic) IBOutlet UIButton *firstFilterControl;
- (IBAction)controlFilter:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *firstFilterArmButton;
@property (weak, nonatomic) IBOutlet UIButton *secondFilterControl;
@property (weak, nonatomic) IBOutlet UISwitch *secondFilterArmButton;
@property (weak, nonatomic) IBOutlet UIButton *thirdFilterControl;
@property (weak, nonatomic) IBOutlet UISwitch *thirdFilterArmButton;
@property (weak, nonatomic) IBOutlet UILabel *firstFilterPropertyLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondFilterPropertyLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdFilterPropertyLabel;
- (IBAction)writeFilter:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *filterChainTitle;
- (IBAction)loadFilter:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterControl;

@property (weak, nonatomic) IBOutlet UIImageView *originalImageView;

- (IBAction)toggleFilter:(id)sender;
-(void)updateFilteredImage:(CIImage *)image context:(CIContext *)context;
- (NSMutableArray *)savedFilters;
-(void)useSavedFilterAtIndex:(NSUInteger)index;
@end
