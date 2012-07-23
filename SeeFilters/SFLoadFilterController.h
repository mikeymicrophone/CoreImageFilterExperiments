//
//  SFLoadFilterController.h
//  SeeFilters
//
//  Created by Mike Schwab on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFViewController.h"

@interface SFLoadFilterController : UITableViewController

@property (weak, nonatomic) SFViewController *filterController;
@property (weak, nonatomic) NSMutableArray *filters;

@end
