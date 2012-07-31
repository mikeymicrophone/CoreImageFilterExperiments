//
//  SFImportViewController.m
//  SeeFilters
//
//  Created by Mike Schwab on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SFImportViewController.h"

@interface SFImportViewController ()

@end

@implementation SFImportViewController
@synthesize filterTextData;
@synthesize filterController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setFilterTextData:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)completeImport:(id)sender {
    // write xml string to file
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *importPath = [documentsPath stringByAppendingPathComponent:@"importable_filters.plist"];
    NSError *writeError = nil;
    [filterTextData.text writeToFile:importPath atomically:YES encoding:NSASCIIStringEncoding error:&writeError];
     
    // open file as plist
    NSMutableArray *importableFilters = [[NSMutableArray alloc] initWithContentsOfFile:importPath];
    
    // combine plists
    NSMutableArray *previousFilterSet = [filterController savedFilters];
    
    [previousFilterSet addObjectsFromArray:importableFilters];
    
    [previousFilterSet writeToFile:[filterController savePath] atomically:YES];
    [self dismissModalViewControllerAnimated:YES];
}
@end
