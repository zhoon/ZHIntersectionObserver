//
//  ZHExampleTableViewController.m
//  ZHIntersectionObserver
//
//  Created by zhoonchen on 2021/7/7.
//

#import "ZHExampleTableViewController.h"
#import "ZHExample1ViewController.h"
#import "ZHExample2ViewController.h"
#import "ZHExample3ViewController.h"
#import "ZHExample4ViewController.h"

@interface ZHExampleTableViewController ()

@end

@implementation ZHExampleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.rowHeight = 80;
    self.title = @"ZHIntersectionObsever";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.detailTextLabel.numberOfLines = 0;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"基础功能体验（1）";
        cell.detailTextLabel.text = @"设置和更新容器大小，设置曝光临界点，动态检测曝光";
    }
    
    else if (indexPath.row == 1) {
        cell.textLabel.text = @"列表滚动触发曝光（1）";
        cell.detailTextLabel.text = @"实时曝光，Cell 不复用";
    }
    
    else if (indexPath.row == 2) {
        cell.textLabel.text = @"列表滚动触发曝光（2）";
        cell.detailTextLabel.text = @"实时曝光，Cell 有复用";
    }
    
    else if (indexPath.row == 3) {
        cell.textLabel.text = @"列表滚动触发曝光（3）";
        cell.detailTextLabel.text = @"设置最小曝光时间，过滤快速滚动 cell，Cell 不复用";
    }
    
    else if (indexPath.row == 4) {
        cell.textLabel.text = @"列表滚动触发曝光（4）";
        cell.detailTextLabel.text = @"设置最小曝光时间，过滤快速滚动 cell，Cell 有复用";
    }
    
    else if (indexPath.row == 5) {
        cell.textLabel.text = @"数据变化触发曝光（1）";
        cell.detailTextLabel.text = @"过滤短时间曝光，数据变化自动检测曝光（数据不重复）";
    }
    
    else if (indexPath.row == 6) {
        cell.textLabel.text = @"数据变化触发曝光（2）";
        cell.detailTextLabel.text = @"过滤短时间曝光，数据变化自动检测曝光（数据可重复）";
    }
    
    else if (indexPath.row == 7) {
        cell.textLabel.text = @"可视状态变化触发曝光（1）";
        cell.detailTextLabel.text = @"支持 alpha、hidden、removeFromSuperView";
    }
    
    else {
        cell.textLabel.text = [NSString stringWithFormat:@"cell index = %@", @(indexPath.row)];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ZHExample1ViewController *vc = [[ZHExample1ViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 1) {
        ZHExample2ViewController *vc = [[ZHExample2ViewController alloc] init];
        vc.isDelay = NO;
        vc.isReuse = NO;
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 2) {
        ZHExample2ViewController *vc = [[ZHExample2ViewController alloc] init];
        vc.isDelay = NO;
        vc.isReuse = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 3) {
        ZHExample2ViewController *vc = [[ZHExample2ViewController alloc] init];
        vc.isDelay = YES;
        vc.isReuse = NO;
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 4) {
        ZHExample2ViewController *vc = [[ZHExample2ViewController alloc] init];
        vc.isDelay = YES;
        vc.isReuse = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 5) {
        ZHExample3ViewController *vc = [[ZHExample3ViewController alloc] init];
        vc.isRandom = NO;
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 6) {
        ZHExample3ViewController *vc = [[ZHExample3ViewController alloc] init];
        vc.isRandom = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 7) {
        ZHExample4ViewController *vc = [[ZHExample4ViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
