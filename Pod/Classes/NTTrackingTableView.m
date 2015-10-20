//
//  NTTrackingTableView.m
//  NTTrackingTableViewSample
//
//  Created by Ethan Nagel on 10/17/15.
//  Copyright © 2015 Nagel Technologies. All rights reserved.
//

#import "NTTrackingTableView.h"


#define LOG(...) NSLog(__VA_ARGS__)


@interface NTTrackingTableViewTransaction : NSObject

@property(nonatomic,readonly) NSIndexPath *beforeAnchorIndexPath;
@property(nonatomic,readonly) NSIndexPath *afterAnchorIndexPath;

- (instancetype)initWithTableView:(NTTrackingTableView *)tableView;

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths;

- (CGFloat)contentOffsetDelta;

@end


@implementation NTTrackingTableViewTransaction
{
    NTTrackingTableView *_tableView;
    NSMutableArray<NSIndexPath *> *_insertedRows;
    NSMutableArray<NSIndexPath *> *_deletedRows;
    NSMutableArray<NSNumber *> *_insertedSections;
    NSMutableArray<NSNumber *> *_deletedSections;

    BOOL _delegateRespondsToHeightForRowAtIndexPath;
}


- (instancetype)initWithTableView:(NTTrackingTableView *)tableView
{
    if ((self=[super init]))
    {
        _tableView = tableView;
        _insertedRows = [[NSMutableArray alloc] init];
        _deletedRows = [[NSMutableArray alloc] init];
        _insertedSections = [[NSMutableArray alloc] init];
        _deletedSections = [[NSMutableArray alloc] init];
        _beforeAnchorIndexPath = [tableView.indexPathsForVisibleRows.firstObject copy];
        _afterAnchorIndexPath = _beforeAnchorIndexPath;
        _delegateRespondsToHeightForRowAtIndexPath = [tableView.delegate respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)];
    }

    return self;
}

#pragma mark - Insert/Delete items

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths
{
    [_insertedRows addObjectsFromArray:indexPaths];

    __block NSInteger delta = 0;

    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        if (indexPath.section == _afterAnchorIndexPath.section && indexPath.row <= _afterAnchorIndexPath.row)
            ++delta;
    }];

    if (delta != 0)
        _afterAnchorIndexPath = [NSIndexPath indexPathForRow:_afterAnchorIndexPath.row+delta inSection:_afterAnchorIndexPath.section];
}


- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths
{
    [_deletedRows addObjectsFromArray:indexPaths];

    __block NSInteger delta = 0;

    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        if (indexPath.section == _afterAnchorIndexPath.section && indexPath.row <= _afterAnchorIndexPath.row)
            --delta;
    }];

    if (delta != 0)
    {
        if (-delta > _afterAnchorIndexPath.row) // do not go negative
            delta = -_afterAnchorIndexPath.row;

        _afterAnchorIndexPath = [NSIndexPath indexPathForRow:_afterAnchorIndexPath.row+delta inSection:_afterAnchorIndexPath.section];
    }
}


- (void)insertSections:(NSIndexSet *)sections
{
    __block NSInteger delta = 0;

    [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
        [_insertedSections addObject:@(section)];

        if (section <= _afterAnchorIndexPath.section)
            ++delta;
    }];

    if (delta != 0)
        _afterAnchorIndexPath = [NSIndexPath indexPathForRow:_afterAnchorIndexPath.row inSection:_afterAnchorIndexPath.section+delta];
}


- (void)deleteSections:(NSIndexSet *)sections
{
    __block NSInteger delta = 0;

    [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
        [_deletedSections addObject:@(section)];

        if (section <= _afterAnchorIndexPath.section)
            --delta;
    }];

    if (delta != 0)
    {
        if (-delta > _afterAnchorIndexPath.section) // do not go negative
            delta = -_afterAnchorIndexPath.section;

        _afterAnchorIndexPath = [NSIndexPath indexPathForRow:_afterAnchorIndexPath.row inSection:_afterAnchorIndexPath.section+delta];
    }
}

#pragma mark - "After" (dataSource/Delegate) height calculations


- (CGFloat)afterRowHeightForSection:(NSInteger)afterSection row:(NSInteger)afterRow
{
    CGFloat height =  0;

    if (_delegateRespondsToHeightForRowAtIndexPath)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:afterRow inSection:afterSection];
        height = [_tableView.delegate tableView:_tableView heightForRowAtIndexPath:indexPath];
    }
    else
        height = _tableView.rowHeight;

    NSAssert(height != UITableViewAutomaticDimension, @"UITableViewAutomaticDimension is not supported by NTTrackingTableView");

    return height;
}


- (CGFloat)afterSectionHeaderHeightForSection:(NSInteger)afterSection
{
    CGFloat height;

    if ([_tableView.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)])
        height = [_tableView.delegate tableView:_tableView heightForHeaderInSection:afterSection];

    else if ([_tableView.dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)])
    {
        NSString *title = [_tableView.dataSource tableView:_tableView titleForHeaderInSection:afterSection];

        height = (title.length) ? _tableView.sectionHeaderHeight : 0;
    }

    else
        height = 0;

    NSAssert(height != UITableViewAutomaticDimension, @"UITableViewAutomaticDimension is not supported by NTTrackingTableView");

    return height;
}

- (CGFloat)afterSectionFooterHeightForSection:(NSInteger)afterSection
{
    CGFloat height;

    if ([_tableView.delegate respondsToSelector:@selector(tableView:heightForFooterInSection:)])
        height = [_tableView.delegate tableView:_tableView heightForFooterInSection:afterSection];

    else if ([_tableView.dataSource respondsToSelector:@selector(tableView:titleForFooterInSection:)])
    {
        NSString *title = [_tableView.dataSource tableView:_tableView titleForFooterInSection:afterSection];

        height = (title.length) ? _tableView.sectionFooterHeight : 0;
    }

    else
        height = 0;

    NSAssert(height != UITableViewAutomaticDimension, @"UITableViewAutomaticDimension is not supported by NTTrackingTableView");
    
    return height;
}

- (CGFloat)afterSectionHeightForSection:(NSInteger)afterSection rowCount:(NSInteger)afterRowCount
{
    CGFloat height = 0;

    height += [self afterSectionHeaderHeightForSection:afterSection];

    for(NSInteger afterRow=0; afterRow<afterRowCount; ++afterRow)
        height += [self afterRowHeightForSection:afterSection row:afterRow];

    height += [self afterSectionFooterHeightForSection:afterSection];

    return height;
}


#pragma mark - Delta Calculation


- (CGFloat)contentOffsetDelta
{
    // This can be called when the caller has called endUpdates but *before* we call [super endUpdates].
    // At this point in time the tableView is using an internal cache of sizes, etc representing the state
    // "before" any changes. The dataSource/delegate represent the "after" state.

    // This code walks the before and after rows (and sections), noting changes that impact the contentOffset
    // It only needs to go as far as the afterAnchorIndexPath (which is calculated as inserts/deletes are added
    // to the transaction.)

    // It will correctly handle inserts/deletes of rows and sections (and moves as an inser/delete) as well as cell resizing.

    // Limitations:
    //  - Does not support autolayout (UITableViewAutomaticDimension)
    //  - Does not support headers/footers resizing or appearing/disappearing

    LOG(@"*** calculating offset delta ***");
    LOG(@"beforeAnchor=%zd/%zd", _beforeAnchorIndexPath.section, _beforeAnchorIndexPath.row);
    LOG(@"afterAnchor=%zd/%zd", _afterAnchorIndexPath.section, _afterAnchorIndexPath.row);

    CGFloat delta = 0;

    [_insertedRows sortUsingSelector:@selector(compare:)];
    [_deletedRows sortUsingSelector:@selector(compare:)];
    [_insertedSections sortUsingSelector:@selector(compare:)];
    [_deletedSections sortUsingSelector:@selector(compare:)];

    NSEnumerator<NSIndexPath *> *insertedRowsEnumerator = [_insertedRows objectEnumerator];
    NSEnumerator<NSIndexPath *> *deletedRowsEnumerator = [_deletedRows objectEnumerator];
    NSEnumerator<NSNumber *> *insertedSectionsEnumerator = [_insertedSections objectEnumerator];
    NSEnumerator<NSNumber *> *deletedSectionsEnumerator = [_deletedSections objectEnumerator];

    NSIndexPath *insertedRow = [insertedRowsEnumerator nextObject];
    NSIndexPath *deletedRow = [deletedRowsEnumerator nextObject];
    NSInteger insertedSection = [([insertedSectionsEnumerator nextObject] ?: @(-1)) integerValue];
    NSInteger deletedSection = [([deletedSectionsEnumerator nextObject] ?: @(-1)) integerValue];

    NSInteger beforeSection = 0;

    for(NSInteger afterSection=0; ; ++afterSection)
    {
        // delete sections...

        while (beforeSection == deletedSection)
        {
            CGFloat beforeSectionHeight = [_tableView rectForSection:beforeSection].size.height;

            LOG(@"%zd(%f): Deleted", beforeSection, beforeSectionHeight);

            delta -= beforeSectionHeight;

            deletedSection = [([deletedSectionsEnumerator nextObject] ?: @(-1)) integerValue];

            ++beforeSection;
        }

        // See if we are done with our after sections

        if (afterSection > _afterAnchorIndexPath.section)
            break;

        // calculate our effective row count...

        NSInteger afterRowCount = [_tableView.dataSource tableView:_tableView numberOfRowsInSection:afterSection];

        if  (_afterAnchorIndexPath.section == afterSection)
            afterRowCount = MIN(afterRowCount, _afterAnchorIndexPath.row + 1);

        // insert sections...

        if (afterSection == insertedSection)
        {
            CGFloat afterSectionHeight = [self afterSectionHeightForSection:afterSection rowCount:afterRowCount];

            delta += afterSectionHeight;

            LOG(@"%zd(%f): Inserted", afterSection, afterSectionHeight);
        }

        else // updating a section
        {
            // Handle changes within a section...

            NSInteger beforeRow = 0;

            for (NSInteger afterRow=0; ; ++afterRow)
            {
                // Handle deleted rows...

                while (deletedRow && deletedRow.section == beforeSection && deletedRow.row == beforeRow)
                {
                    CGFloat beforeRowHeight = [_tableView rectForRowAtIndexPath:deletedRow].size.height;

                    LOG(@"%zd/%zd(%f): Deleted", beforeSection, beforeRow, beforeRowHeight);

                    delta -= beforeRowHeight;

                    deletedRow = [deletedRowsEnumerator nextObject];

                    ++beforeRow;
                }

                // stop if we are done with our "after" rows...

                if (afterRow >= afterRowCount)
                    break;

                CGFloat afterRowHeight = [self afterRowHeightForSection:afterSection row:afterRow];

                // handle inserted rows...

                if (insertedRow && insertedRow.section == afterSection && insertedRow.row == afterRow)
                {
                    // Add the added cells height to our delta...

                    delta += afterRowHeight;

                    LOG(@"%zd/%zd(%f): Inserted", afterSection, afterRow, afterRowHeight);

                    // get the next insertedRow...

                    insertedRow = [insertedRowsEnumerator nextObject];
                } // if (insertedRow

                else // not inserted, so we can compare to the existing cell
                {
                    NSIndexPath *beforeIndexPath = [NSIndexPath indexPathForRow:beforeRow inSection:beforeSection];
                    CGFloat beforeRowHeight = [_tableView rectForRowAtIndexPath:beforeIndexPath].size.height;

                    if (beforeRowHeight != afterRowHeight)
                    {
                        LOG(@"%zd/%zd(%f): Resized from %zd/%zd(%f) = %f", afterSection, afterRow, afterRowHeight, beforeSection, beforeRow, beforeRowHeight, beforeRowHeight - afterRowHeight);
                        delta += beforeRowHeight - afterRowHeight;
                    }
                    else
                    {
                        //LOG(@"%zd/%zd(%f): No change, was %zd/%zd(%f)", afterSection, afterRow, afterRowHeight, beforeSection, beforeRow, beforeRowHeight);
                    }

                    ++beforeRow;
                } // else not inserted
            } // for (afterRow

            ++beforeSection;
        } // else not inserted section

    } // for (afterSection

    // todo: could we have problems with trailing deleted sections?

    LOG(@"delta = %f", delta);

    return delta;
}

@end


@implementation NTTrackingTableView
{
    NTTrackingTableViewTransaction *_currentTransaction;
}

- (void)performImplicitUpdate:(void (^)())update
{
    if (_currentTransaction || !self.automaticallyAdjustsContentOffset)
        update();
    else
    {
        [self beginUpdates];
        update();
        [self endUpdates];
    }
}


#pragma mark - Overridden UITableView methods


- (void)beginUpdates
{
    if (self.automaticallyAdjustsContentOffset)
    {
        if (!_currentTransaction)
            _currentTransaction = [[NTTrackingTableViewTransaction alloc] initWithTableView:self];
    }

    // todo: nested update support

    [super beginUpdates];
}


- (void)endUpdates
{
    // todo: nested update support
    if ( !_currentTransaction)
    {
        [super endUpdates];
        return ;

    }

    CGFloat delta = _currentTransaction.contentOffsetDelta;    // this is where we do all the work

    if (delta == 0)
    {
        [super endUpdates]; // we didn't have any contentOffset changes, so a normal animated endUpdates is fine
    }

    else
    {

#ifdef DEBUG

        if (!self.isDecelerating)
        {
            // If we aren't decelerating
            [UIView performWithoutAnimation:^{

                CGPoint beforePoint = [self convertPoint:[self rectForRowAtIndexPath:_currentTransaction.beforeAnchorIndexPath].origin toView:self.superview];

                [super endUpdates];

                CGPoint afterPoint = [self convertPoint:[self rectForRowAtIndexPath:_currentTransaction.afterAnchorIndexPath].origin toView:self.superview];

                CGFloat actualDelta = afterPoint.y - beforePoint.y;

                if (delta != actualDelta)
                    NSLog(@"UH OH contentOffsetDelta returned %f but value should have been %f (off by %f)", delta, actualDelta, actualDelta - delta);

                CGPoint contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y + delta);
                self.contentOffset = contentOffset;

            }];
        }
        else

#endif

        {
            [UIView performWithoutAnimation:^{
                CGPoint contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y + delta);
                self.contentOffset = contentOffset; // important to do it first when decelerating
                [super endUpdates];
                self.contentOffset = contentOffset; // important to do it again after in case the contentSize was too small when it was set before
            }];
        }
    }

    // debugging

    [self selectRowAtIndexPath:_currentTransaction.afterAnchorIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    _currentTransaction = nil;
}


- (void)insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [self performImplicitUpdate:^{
        [_currentTransaction insertRowsAtIndexPaths:indexPaths];
        [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    }];
}


- (void)deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [self performImplicitUpdate:^{
        [_currentTransaction deleteRowsAtIndexPaths:indexPaths];
        [super deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    }];
}


-(void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    [self performImplicitUpdate:^{
        [_currentTransaction deleteRowsAtIndexPaths:@[indexPath]];
        [_currentTransaction insertRowsAtIndexPaths:@[newIndexPath]];
        [super moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
    }];
}


- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [self performImplicitUpdate:^{
        [_currentTransaction insertSections:sections];
        [super insertSections:sections withRowAnimation:animation];
    }];
}


- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [self performImplicitUpdate:^{
        [_currentTransaction deleteSections:sections];
        [super deleteSections:sections withRowAnimation:animation];
    }];
}


- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    [self performImplicitUpdate:^{
        [_currentTransaction deleteSections:[NSIndexSet indexSetWithIndex:section]];
        [_currentTransaction insertSections:[NSIndexSet indexSetWithIndex:newSection]];
    }];
}

@end
