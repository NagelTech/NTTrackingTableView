//
//  ViewController.m
//  NTTrackingTableViewSample
//
//  Created by Ethan Nagel on 10/17/15.
//  Copyright © 2015 Nagel Technologies. All rights reserved.
//

#import "ViewController.h"
#import "NTTrackingTableView.h"


@interface CellInfo : NSObject

@property(nonatomic) NSString *title;
@property(nonatomic) UIColor *color;
@property(nonatomic) CGFloat height;

+ (instancetype)cellInfoWithTitle:(NSString *)title;

@end


@implementation CellInfo


+ (instancetype)cellInfoWithTitle:(NSString *)title
{
    static int itemIndex = 0;

    CellInfo *cellInfo = [[CellInfo alloc] init];

    NSArray<UIColor *> *colors = @[[UIColor lightGrayColor], [UIColor whiteColor], [UIColor yellowColor], [UIColor cyanColor]];
    NSArray<NSNumber *> *sizes = @[@44.0, @64.0, @84.0, @104.0];

    NSUInteger rand = arc4random_uniform(4);

    cellInfo.title = [NSString stringWithFormat:@"%@ #%d", title, itemIndex++];
    cellInfo.color = colors[rand];
    cellInfo.height = [sizes[rand] floatValue];

    return cellInfo;
}
@end


@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet NTTrackingTableView *tableView;

@end


@implementation ViewController
{
    NSMutableArray *_items;
}


#pragma mark - Initialization


- (void)commonInit
{
    _items = [[NSMutableArray alloc] init];

    for(int index=0; index< 100; index++)
        [_items addObject:[CellInfo cellInfoWithTitle:@"Original item"]];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Insert Stuff" style:UIBarButtonItemStylePlain target:self action:@selector(insertStuff)];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete Stuff" style:UIBarButtonItemStylePlain target:self action:@selector(deleteStuff)];
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self=[super initWithCoder:aDecoder]))
    {
        [self commonInit];
    }

    return self;
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        [self commonInit];
    }

    return self;
}


#pragma mark - Test

- (NSArray *)indexPathsInSection:(NSInteger)section range:(NSRange)range
{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];

    for(NSUInteger index=0; index<range.length; index++)
        [indexPaths addObject:[NSIndexPath indexPathForRow:range.location+index inSection:section]];

    return [indexPaths copy];
}


- (void)insertRows:(NSArray *)rows atIndex:(NSUInteger)index
{
    NSRange range = NSMakeRange(index, rows.count);

    [_items insertObjects:rows atIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
    [self.tableView insertRowsAtIndexPaths:[self indexPathsInSection:0 range:range] withRowAnimation:UITableViewRowAnimationFade];
}


- (void)deleteRow:(NSUInteger)index
{
    [_items removeObjectAtIndex:index];
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)insertStuff
{
    [self.tableView beginUpdates];

    CellInfo *newCell = [CellInfo cellInfoWithTitle:@"Inserted Item"];

    [self insertRows:@[newCell] atIndex:5];

    [self.tableView endUpdates];
}


- (void)deleteStuff
{
    [self.tableView beginUpdates];

    CellInfo *first = _items.firstObject;
    for(NSInteger index=_items.count-1; index>=0; index -= 1)
    {
        CellInfo *item = _items[index];

        if ([item.color isEqual:first.color])
            [self deleteRow:index];
    }

    [self.tableView endUpdates];
}


#pragma mark - UIViewController overrides


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource/Delegate


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CellInfo *cellInfo = _items[indexPath.row];

    return cellInfo.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"dataSource cellForRowAtIndexPath:%@", indexPath);

    NSString *REUSE_IDENTIFIER = @"Default";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER];

    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE_IDENTIFIER];

    CellInfo *cellInfo = _items[indexPath.row];

    cell.textLabel.text = cellInfo.title;
    cell.contentView.backgroundColor = cellInfo.color;
    cell.bounds =(CGRect) { .size={_tableView.bounds.size.width, cellInfo.height} };

    return cell;
}


@end
