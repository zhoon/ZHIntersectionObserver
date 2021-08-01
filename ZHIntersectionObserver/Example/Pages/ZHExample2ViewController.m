//
//  ZHExample2ViewController.m
//  ZHIntersectionObserver
//
//  Created by zhoonchen on 2021/7/8.
//

#import "ZHExample2ViewController.h"
#import "IntersectionObserverHeader.h"

@interface ZHExample2UITableViewCell : UITableViewCell

@end

@implementation ZHExample2UITableViewCell

@end


@interface ZHExample2ViewController ()

@property(nonatomic, assign) BOOL isFilter;
@property(nonatomic, assign) BOOL isReuseCell;

@end

@implementation ZHExample2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initIntersectionObserver];
    [self updateNavigationItem];

    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.rowHeight = 100;
}

- (void)updateNavigationItem {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    if (self.isFilter) {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"不用曝光时长" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeFilter)]];
    } else {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"要求曝光0.6秒" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeFilter)]];
    }
    if (self.isReuseCell) {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"Cell复用" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeReuseCell)]];
    } else {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"Cell不复用" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeReuseCell)]];
    }
    self.navigationItem.rightBarButtonItems = items;
}

- (void)handleChangeReuseCell {
    self.isReuseCell = !self.isReuseCell;
    [self.tableView reloadData];
    [self updateNavigationItem];
}

- (void)handleChangeFilter {
    self.isFilter = !self.isFilter;
    if (self.tableView.intersectionObserverContainerOptions) {
        [self.tableView.intersectionObserverContainerOptions updateIntersectionDuration:self.isFilter ? 0 : 600];
    }
    [self.tableView reloadData];
    [self updateNavigationItem];
}

- (void)initIntersectionObserver {
    IntersectionObserverContainerOptions *containerOptions = [IntersectionObserverContainerOptions initOptionsWithScope:@"Example2" rootMargin:UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0) thresholds:@[@1] containerView:self.tableView intersectionDuration:600 callback:^(NSString * _Nonnull scope, NSArray<IntersectionObserverEntry *> * _Nonnull entries) {
        NSLog(@"Example2: entries = %@", entries);
        for (NSInteger i = 0; i < entries.count; i++) {
            IntersectionObserverEntry *entry = entries[i];
            ZHExample2UITableViewCell *cell = (ZHExample2UITableViewCell *)entry.target.superview;
            if (cell) {
                cell.backgroundColor = entry.isInsecting ? [[UIColor orangeColor] colorWithAlphaComponent:0.5] : [UIColor whiteColor];
            }
        }
    }];
    self.tableView.intersectionObserverContainerOptions = containerOptions;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ZHExample2UITableViewCell *cell = nil;
    if (self.isReuseCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[ZHExample2UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    } else {
        NSString *uniqKey = [NSString stringWithFormat:@"%@%@", @(indexPath.row), @([NSDate date].timeIntervalSince1970 * 1000)];
        cell = [[ZHExample2UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:uniqKey];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    
    cell.textLabel.text = cell.textLabel.text && cell.textLabel.text.length > 0 ? [NSString stringWithFormat:@"复用堆栈 %@ - %@ (背景色代表已曝光)", @(indexPath.row), [cell.textLabel.text substringWithRange:NSMakeRange(5, cell.textLabel.text.length - 15)]] : [NSString stringWithFormat:@"复用堆栈 %@ (背景色代表已曝光)", @(indexPath.row)];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"cell: %p, contentView: %p", cell, cell.contentView];
    
    // TODO：cell 在复用的瞬间会被设置为 hidden 导致判断不准确，先用 cell.contentView
    if (!cell.contentView.intersectionObserverTargetOptions) {
        IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example2" dataKey:[NSString stringWithFormat:@"%@", @(indexPath.row)] data:@{@"row": @(indexPath.row)} targetView:cell.contentView];
        cell.contentView.intersectionObserverTargetOptions = targetOptions;
    } else {
        [cell.contentView.intersectionObserverTargetOptions updateDataKey:[NSString stringWithFormat:@"%@", @(indexPath.row)] data:@(indexPath.row)];
    }
    
    return cell;
}

@end
