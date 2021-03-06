//
//  ILLinkManagerController.m
//  Instalink
//
//  Created by Eric Partyka on 6/17/17.
//
//

#import "ILLinkManagerController.h"
#import "ILLinkItemTableViewCell.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import "ILLinkDetailController.h"
#import "ILLinkStore.h"
#import "ILLinkModel.h"
#import "ILColorDefines.h"
#import <LGSemiModalNavController/LGSemiModalNavViewController.h>
#import "ILMenuController.h"
#import "ILCacheUtil.h"
#import <MGSwipeTableCell/MGSwipeTableCell.h>
#import "SSARefreshControl.h"
#import "ILWebViewController.h"
#import "ILFormFieldManager.h"
#import "ILClaimInstalinkController.h"
#import "ILAccountProfileController.h"
#import "ILUserModel.h"
#import <ZendeskSDK/ZendeskSDK.h>
#import "ILDeviceUtil.h"
#import "ILValidationUtil.h"
#import "ILVendorModel.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIColor+Hex.h"

#define MAX_LINKS  8

@interface ILLinkManagerController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, ILLinkDetailControllerDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, MGSwipeTableCellDelegate, SSARefreshControlDelegate, ILMenuControllerDelegate>

#pragma mark - Properties

@property (strong, nonatomic) IBOutlet UITableView *theTableView;
@property (strong, nonatomic) IBOutlet UISearchBar *theSearchBar;
@property (strong, nonatomic) IBOutlet UIButton *theFooterButton;
@property (strong, nonatomic) NSArray *theDataArray;
@property (strong, nonatomic) NSArray *theSearchedArray;
@property (readwrite, nonatomic) BOOL isSearching;
@property (strong, nonatomic) SSARefreshControl *theRefreshControl;
@property (strong, nonatomic) UIActivityViewController *theShareController;

@end

@implementation ILLinkManagerController

#pragma mark - View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureViewWillAppear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self configureViewWillDisappear];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureView];
    [self configureNavBar];
    [self configureSearchBar];
    [self configureXIBs];
    [self configureFooterButton];
    [self configureDataSourceWithRefresh:YES];
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Transition Delegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    return [self transitionPresenting:YES];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [self transitionPresenting:NO];
}

-(LGSemiModalTransition*)transitionPresenting:(BOOL)presenting
{
    LGSemiModalTransition *animator = [LGSemiModalTransition new];
    animator.presenting = presenting;
    animator.tapDismissEnabled = YES;
    
    return animator;
}

#pragma mark - Private Methods

- (void)configureViewWillAppear
{
    [[ILFormFieldManager theSharedManager] didResetFieldManager];
}

- (void)configureViewWillDisappear
{
    
}

// set any view display properties, colors, or custom interactions

- (void)configureView
{
    self.theTableView.tableFooterView = [UIView new];
    self.view.backgroundColor = IL_AccentColor;
    [self.theTableView setSeparatorColor:IL_DarkColorSecondary];
    
    self.theRefreshControl = [[SSARefreshControl alloc] initWithScrollView:_theTableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.theRefreshControl.delegate = self;
}

// set navigation bar titles, customer interations, or butons
// all color appearances should be configured in ILAppearanceUtil

- (void)configureNavBar
{
    self.navigationItem.title = NSLocalizedString(@"Link Manager", @"Link Manager");
    self.navigationController.navigationBar.translucent = NO;
}

// set search bar titles, customer interations
// all color appearances should be configured in ILAppearanceUtil

- (void)configureSearchBar
{
    self.theSearchBar.barTintColor = IL_OrangeColor;
    self.theSearchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    [self.theSearchBar setReturnKeyType:UIReturnKeyDone];
    self.theSearchBar.enablesReturnKeyAutomatically = NO;
}

// register any UITableViewCells or custom XIBs needed for the linkmanager tableview

- (void)configureXIBs
{
    [_theTableView registerNib:[UINib nibWithNibName:@"ILLinkItemTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"ILLinkItemTableViewCell"];
}

// set font, action, appearance, title for hover footer button

- (void)configureFooterButton
{
    self.theFooterButton.backgroundColor = IL_DarkAccentColor;
    self.theFooterButton.layer.masksToBounds = YES;
    self.theFooterButton.layer.cornerRadius = 20;
    [self.theFooterButton addTarget:self action:@selector(didPressAddLinkButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.theFooterButton.titleLabel setFont:[UIFont fontWithName:@"Quicksand-Bold" size:15]];
    [self.theFooterButton setTitle:NSLocalizedString(@"ADD NEW URL", @"CREATE NEW URL") forState:UIControlStateNormal];
}

// when loading the data source, first check if data exsists in the cache already
// if there is data in the cache load from cache
// else we call the API to load fresh data

- (void)configureDataSourceWithRefresh:(BOOL)refresh
{
    if (refresh)
    {
        [ILLinkStore didGetAllLinksWithCompletion:^(BOOL success, NSError *error, id responseObject) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (success)
                {
                    [self configureViewForSuccess:responseObject];
                }
                else
                {
                    [self configureViewForFailure:responseObject];
                }
                
            });

        }];
    }
    else
    {
        if ([[ILCacheUtil theCacheManager] isObjectValidForKey:[ILLinkModel theLink]])
        {
            id responseObject = [[ILCacheUtil theCacheManager] didGetObjectForKey:[ILLinkModel theLink]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self configureViewForSuccess:responseObject];
                
            });
        }
        else
        {
            [ILLinkStore didGetAllLinksWithCompletion:^(BOOL success, NSError *error, id responseObject) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (success)
                    {
                        [self configureViewForSuccess:responseObject];
                    }
                    else
                    {
                        [self configureViewForFailure:responseObject];
                    }
                    
                });
                
            }];
            
        }
    }
}

// handle any successful UI/data refreshing after data source loading logic

- (void)configureViewForSuccess:(id)responseObject
{
    self.theDataArray = responseObject;
    [_theTableView reloadData];
    [self.theRefreshControl endRefreshing];
}

// handle any failure UI/data refreshing after data source loading logic

- (void)configureViewForFailure:(id)responseObject
{
    [self.theRefreshControl endRefreshing];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isSearching)
    {
        if (_theSearchedArray && _theSearchedArray.count)
        {
            return _theSearchedArray.count;
        }
        else
        {
            return 0;
        }

    }
    else
    {
        if (_theDataArray && _theDataArray.count)
        {
            return _theDataArray.count;
        }
        else
        {
            return 0;
        }
    }
    
    
}

#pragma mark - Table View Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    ILLinkItemTableViewCell *cell = (ILLinkItemTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ILLinkItemTableViewCell"];
    [self configureLinkItemCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureLinkItemCell:(ILLinkItemTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.delegate = self;
    
    NSDictionary *theDict;
    
    if (_isSearching)
    {
        theDict = [_theSearchedArray objectAtIndex:indexPath.row];
    }
    else
    {
        theDict = [_theDataArray objectAtIndex:indexPath.row];
    }
    
    
    NSString *theTitleString = [NSString stringWithFormat:@"%@", [theDict objectForKey:[ILLinkModel theTitle]]];
    NSString *theURLString = [NSString stringWithFormat:@"%@", [theDict objectForKey:[ILLinkModel theLinkURL]]];
    
    cell.theTitleLabel.text = theTitleString;
    cell.theDetailLabel.text = theURLString;
    
    
    NSString *theImageURLString = [NSString stringWithFormat:@"%@", [theDict objectForKey:[ILVendorModel theVendorLogoURL]]];
    NSURL *theURL = [NSURL URLWithString:theImageURLString];
    
    [cell.theImageView sd_setImageWithURL:theURL placeholderImage:[UIImage new]];
    
    NSString *theVendorNameString = [NSString stringWithFormat:@"%@", [theDict objectForKey:[ILVendorModel theVendorName]]];
    cell.theTitleLabel.text = theVendorNameString;
    
    NSString *theColorCodeString = [NSString stringWithFormat:@"%@", [theDict objectForKey:[ILVendorModel theColorCode]]];
    
    if ([ILValidationUtil isStringValid:theColorCodeString])
    {
        UIColor *theColor = [UIColor colorWithCSS:theColorCodeString];
        cell.theBackgroundView.backgroundColor = theColor;
    }
    else
    {
        cell.theBackgroundView.backgroundColor = IL_OrangeColor;
    }

    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *theDict;
    
    if (_isSearching)
    {
        theDict = [_theSearchedArray objectAtIndex:indexPath.row];
    }
    else
    {
        theDict = [_theDataArray objectAtIndex:indexPath.row];
    }

    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    ILLinkDetailController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ILLinkDetailController"];
    controller.theDelegate = self;
    controller.theSelectedLinkDict = theDict;
    controller.isFromSelection = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
    [searchBar resignFirstResponder];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.isSearching = YES;
    [self isFilteringText:searchText];
}

- (void)isFilteringText:(NSString *)text
{
    if ([_theSearchBar.text length] == 0)
    {
        self.isSearching = NO;
        [self.view endEditing:YES];
        [_theTableView reloadData];
    }
    else
    {
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"title contains[c] %@", text];
        self.theSearchedArray = [self.theDataArray filteredArrayUsingPredicate:resultPredicate];
        [_theTableView reloadData];
    }
    
}

#pragma mark - Actions

- (IBAction)didPressButton:(id)sender
{
    
}

// creating new link logic goes here
// first check if anything in the datasource, if something is there, check if max links created
// if max links NOT created, allow user to add new link

- (IBAction)didPressAddLinkButton:(id)sender
{
    if ([ILValidationUtil isArrayValid:_theDataArray])
    {
        if (![self doesHaveMaxFreeLinks])
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            ILLinkDetailController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ILLinkDetailController"];
            controller.theDelegate = self;
            controller.isFromCreation = YES;
            [self.navigationController pushViewController:controller animated:YES];

        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Maximum Links Created" message:@"You can only create 8 links total. Please remove a link to add a new one." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    else
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        ILLinkDetailController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ILLinkDetailController"];
        controller.theDelegate = self;
        controller.isFromCreation = YES;
        [self.navigationController pushViewController:controller animated:YES];

    }
}

// helper check to determine if max links created

- (BOOL)doesHaveMaxFreeLinks
{
    if (_theDataArray.count == MAX_LINKS)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (IBAction)didPressMenuButton:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    ILMenuController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ILMenuController"];
    controller.theDelegate = self;
    
    LGSemiModalNavViewController *semiModal = [[LGSemiModalNavViewController alloc] initWithRootViewController:controller];
    semiModal.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 400);
    
    semiModal.backgroundShadeColor = [UIColor blackColor];
    semiModal.animationSpeed = 0.35f;
    semiModal.tapDismissEnabled = YES;
    semiModal.backgroundShadeAlpha = 0.4;
    semiModal.scaleTransform = CGAffineTransformMakeScale(.94, .94);
    
    [self presentViewController:semiModal animated:YES completion:nil];
}

#pragma mark - DZNEmptyDataSet Delegate

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"No Links Here!", @"");;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Quicksand-Bold" size:24],
                                 NSForegroundColorAttributeName:[UIColor whiteColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"Looks like you do not have any links yet, go ahead and create one don't by shy!", @"");
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Quicksand-Bold" size:16],
                                 NSForegroundColorAttributeName:[UIColor whiteColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"Share"];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return IL_AccentColor;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return NO;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return 0.0;
}

#pragma mark - ILLinkDetailControllerDelegate

- (void)didCreateLinkWithSuccess:(BOOL)success
{
    [self configureDataSourceWithRefresh:YES];
}

- (void)didUpdateLinkWithSuccess:(BOOL)success
{
    [self configureDataSourceWithRefresh:YES];
}

#pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
	NSIndexPath *theIndexPath = [_theTableView indexPathForCell:cell];
	
    if (direction == MGSwipeDirectionRightToLeft)
    {
        NSLog(@"Tapped Index %ld", (long)index);
		
		NSDictionary *theDict;
		
		if (_isSearching)
		{
			theDict = [_theSearchedArray objectAtIndex:theIndexPath.row];
		}
		else
		{
			theDict = [_theDataArray objectAtIndex:theIndexPath.row];
		}
		
		NSString *theIDString = [NSString stringWithFormat:@"%@", [theDict objectForKey:[ILLinkModel theID]]];
		
		[ILLinkStore didDeleteLinkWithID:theIDString withCompletion:^(BOOL success, NSError *error, id responseObject) {
			
			if (success)
			{
				[self configureDataSourceWithRefresh:YES];
			}
			else
			{
				
			}
			
		}];
    }
    
    return YES;
}

#pragma mark - SSARefreshControlDelegate

- (void)beganRefreshing
{
    [self configureDataSourceWithRefresh:YES];
}

#pragma mark - ILMenuControllerDelegate

- (void)didDismissMenuControllerWithInstalinkViewSelection
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    ILWebViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ILWebViewController"];
    controller.isFromInstalinkView = YES;
    [self.navigationController pushViewController:controller animated:YES];

}
	
- (void)didDimissMenuControllerWithClaimInstalinkSelection
{
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
	ILClaimInstalinkController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ILClaimInstalinkController"];
	controller.isFromMenu = YES;
	[self.navigationController pushViewController:controller animated:YES];
}
	
- (void)didDismissWithAccountSettingsSelection
{
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
	ILAccountProfileController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ILAccountProfileController"];
	[self.navigationController pushViewController:controller animated:YES];
}

// present share sheet with app share link

- (void)didDismissWithShareAppSelection
{
    NSString *theAppStringURL = [NSString stringWithFormat:@"Join the movement and claim your free Instalink profile today by downloading the app! %@", @"https://itunes.apple.com/us/app/instalink-the-dedicated-flexible-url/id1027499757?ls=1&mt=8"];
    NSArray *theArray = [[NSArray alloc] initWithObjects:theAppStringURL, nil];
    
    self.theShareController = [[UIActivityViewController alloc] initWithActivityItems:theArray applicationActivities:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.navigationController presentViewController:_theShareController animated:YES completion:^{
            
            
        }];
        
    });
    
}

// present share sheet with instalink domain

- (void)didDimissMenuWithShareInstalinkSelection
{
    NSString *theURLString = [NSString stringWithFormat:@"http://www.%@", [ILUserModel theInstalinkURLString]];
    NSArray *theArray = [[NSArray alloc] initWithObjects:theURLString, nil];
    
    self.theShareController = [[UIActivityViewController alloc] initWithActivityItems:theArray applicationActivities:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.navigationController presentViewController:_theShareController animated:YES completion:^{
            
            
        }];
        
    });

}

- (void)didDismissWithContactSupportSelection
{
    [self showHelpCenter];
}

// present any help center/support logic here, currently ZendeskKitSDK

- (void)showHelpCenter
{
    [ZDKRequests presentRequestCreationWithViewController:self];
    
    [ZDKRequests configure:^(ZDKAccount *account, ZDKRequestCreationConfig *requestCreationConfig) {
        
        requestCreationConfig.additionalRequestInfo = [ILDeviceUtil theDeviceInfo];
        
    }];
}

@end
