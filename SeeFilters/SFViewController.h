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
@property (weak, nonatomic) IBOutlet UISlider *secondSlider;
@property (weak, nonatomic) IBOutlet UILabel *secondFilterValueLabel;
- (IBAction)changeSecondValue:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UIButton *firstFilterControl;
- (IBAction)controlFirstFilter:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *firstFilterArmButton;
@property (weak, nonatomic) IBOutlet UIButton *secondFilterControl;
- (IBAction)controlSecondFilter:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *secondFilterArmButton;
@property (weak, nonatomic) IBOutlet UIButton *thirdFilterControl;
- (IBAction)controlThirdFilter:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *thirdFilterArmButton;
@property (weak, nonatomic) IBOutlet UILabel *firstFilterPropertyLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondFilterPropertyLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdFilterPropertyLabel;
- (IBAction)writeFilter:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *filterChainTitle;

@property (weak, nonatomic) IBOutlet UIImageView *originalImageView;

- (IBAction)toggleFilter:(id)sender;
-(void)updateFilterChain;
@end
