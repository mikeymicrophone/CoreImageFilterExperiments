//
//  SFImportViewController.h
//  SeeFilters
//
//  Created by Mike Schwab on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFViewController.h"

@interface SFImportViewController : UIViewController
- (IBAction)completeImport:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *filterTextData;
@property (weak, nonatomic) SFViewController *filterController;

@end
