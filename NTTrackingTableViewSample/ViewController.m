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
    NSMutableArray *_sections;
}


#pragma mark - Initialization


- (void)commonInit
{
    _sections = [[NSMutableArray alloc] init];

    for(int section=0; section<10; section++)
    {
        NSMutableArray *items = [NSMutableArray array];

        for(int index=0; index<10; index++)
            [items addObject:[CellInfo cellInfoWithTitle:@"Original item"]];

        [_sections addObject:items];
    }

//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Insert Row" style:UIBarButtonItemStylePlain target:self action:@selector(insertRow)];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Insert Section" style:UIBarButtonItemStylePlain target:self action:@selector(insertSection)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Resize Row" style:UIBarButtonItemStylePlain target:self action:@selector(resizeRow)];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete Rows" style:UIBarButtonItemStylePlain target:self action:@selector(deleteRows)];
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


- (void)insertItem:(CellInfo *)item atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *items = _sections[indexPath.section];

    [items insertObject:item atIndex:indexPath.row];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}


- (void)deleteIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *items = _sections[indexPath.section];

    [items removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)insertRow
{
    [self.tableView beginUpdates];

    CellInfo *newCell = [CellInfo cellInfoWithTitle:@"Inserted Item"];

    [self insertItem:newCell atIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];

    [self.tableView endUpdates];
}


- (void)deleteRows
{
    [self.tableView beginUpdates];

    __block CellInfo *first = nil;

    [_sections enumerateObjectsUsingBlock:^(NSMutableArray *items, NSUInteger idx, BOOL * _Nonnull stop) {
        if (items.count)
        {
            first = items.firstObject;
            *stop = YES;
        }
    }];

    [_sections enumerateObjectsUsingBlock:^(NSMutableArray *items, NSUInteger section, BOOL * _Nonnull stop) {
        for(NSInteger index=items.count-1; index>=0; index -= 1)
        {
            CellInfo *item = items[index];

            if ([item.color isEqual:first.color])
                [self deleteIndexPath:[NSIndexPath indexPathForRow:index inSection:section]];
        }
    }];

    [self.tableView endUpdates];
}


- (void)resizeRow
{
    [self.tableView beginUpdates];

    NSMutableArray *items = _sections[1];
    CellInfo *cellInfo = items[1];

    cellInfo.height += 50;

    [self.tableView endUpdates];
}


- (void)insertSection
{
    NSMutableArray *items = [NSMutableArray array];

    for(int index=0; index<5; index++)
        [items addObject:[CellInfo cellInfoWithTitle:@"Inserted Section"]];

    [self.tableView beginUpdates];

    [_sections insertObject:items atIndex:1];
    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];

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
    return _sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *items = _sections[section];
    return items.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *items = _sections[indexPath.section];
    CellInfo *cellInfo = items[indexPath.row];

    return cellInfo.height;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Section Header";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"dataSource cellForRowAtIndexPath:%@", indexPath);

    NSString *REUSE_IDENTIFIER = @"Default";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER];

    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE_IDENTIFIER];

    NSMutableArray *items = _sections[indexPath.section];
    CellInfo *cellInfo = items[indexPath.row];

    cell.textLabel.text = cellInfo.title;
    cell.contentView.backgroundColor = cellInfo.color;
    cell.bounds =(CGRect) { .size={_tableView.bounds.size.width, cellInfo.height} };

    return cell;
}


@end
