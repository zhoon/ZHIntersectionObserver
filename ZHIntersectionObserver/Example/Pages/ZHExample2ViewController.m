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

@property(nonatomic, assign) BOOL isDelay;
@property(nonatomic, assign) BOOL isReuse;

@end

@implementation ZHExample2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isDelay = YES;
    self.isReuse = YES;
    
    [self initIntersectionObserver];
    [self updateNavigationItem];

    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.rowHeight = 100;
}

- (void)updateNavigationItem {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    if (self.isReuse) {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"切到Cell不复用" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeReuse)]];
    } else {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"切到Cell复用" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeReuse)]];
    }
    if (self.isDelay) {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"切到要求曝光时长" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeDelay)]];
    } else {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"切到实时曝光" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeDelay)]];
    }
    self.navigationItem.rightBarButtonItems = items;
}

- (void)handleChangeReuse {
    self.isReuse = !self.isReuse;
    [self.tableView reloadData];
    [self updateNavigationItem];
}

- (void)handleChangeDelay {
    self.isDelay = !self.isDelay;
    if (self.tableView.intersectionObserverContainerOptions) {
        [self.tableView.intersectionObserverContainerOptions updateIntersectionDuration:self.isDelay ? 600 : 0];
    }
    [self.tableView reloadData];
    [self updateNavigationItem];
}

- (void)initIntersectionObserver {
    IntersectionObserverContainerOptions *containerOptions = [IntersectionObserverContainerOptions initOptionsWithScope:@"Example2" rootMargin:UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0) thresholds:@[@1] containerView:self.tableView intersectionDuration:self.isDelay ? 600 : 0 callback:^(NSString * _Nonnull scope, NSArray<IntersectionObserverEntry *> * _Nonnull entries) {
        NSLog(@"Example2: entries = %@", entries);
        for (NSInteger i = 0; i < entries.count; i++) {
            IntersectionObserverEntry *entry = entries[i];
            ZHExample2UITableViewCell *cell = (ZHExample2UITableViewCell *)entry.target;
            NSLog(@"zhoon entry, isInsecting = %@ index = %@", @(entry.isInsecting), entry.data[@"row"]);
            if (cell) {
                cell.backgroundColor = entry.isInsecting ? [[UIColor orangeColor] colorWithAlphaComponent:0.2] : [UIColor whiteColor];
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
    if (self.isReuse) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[ZHExample2UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    } else {
        NSString *uniqKey = [NSString stringWithFormat:@"%@%@", @(indexPath.row), @([NSDate date].timeIntervalSince1970 * 1000)];
        cell = [[ZHExample2UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:uniqKey];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    
    cell.textLabel.text = cell.textLabel.text && cell.textLabel.text.length > 0 ? [NSString stringWithFormat:@"复用堆栈 %@ - %@ (黄色代表曝光)", @(indexPath.row), [cell.textLabel.text substringWithRange:NSMakeRange(5, cell.textLabel.text.length - 13)]] : [NSString stringWithFormat:@"复用堆栈 %@ (黄色代表曝光)", @(indexPath.row)];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"cell: %p", cell];
    
    if (!cell.intersectionObserverTargetOptions) {
        IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example2" dataKey:[NSString stringWithFormat:@"%@", @(indexPath.row)] data:@{@"row": @(indexPath.row)} targetView:cell];
        cell.intersectionObserverTargetOptions = targetOptions;
    } else {
        [cell.intersectionObserverTargetOptions updateDataKey:[NSString stringWithFormat:@"%@", @(indexPath.row)] data:@{@"row": @(indexPath.row)}];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *emptyVC = [[UIViewController alloc] init];
    emptyVC.title = @"测试空界面";
    emptyVC.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:emptyVC animated:YES];
}

@end
