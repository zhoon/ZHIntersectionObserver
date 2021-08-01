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

@interface ZHExampleTableViewController ()

@end

@implementation ZHExampleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.rowHeight = 100;
    self.title = @"ZHIntersectionObsever";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.detailTextLabel.numberOfLines = 0;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"基础功能体验";
        cell.detailTextLabel.text = @"设置和更新容器大小，设置曝光临界点，动态检测曝光";
    }
    
    else if (indexPath.row == 1) {
        cell.textLabel.text = @"列表滚动触发曝光";
        cell.detailTextLabel.text = @"设置最小曝光时间，过滤快速滚动 cell，支持 cell 复用";
    }
    
    else if (indexPath.row == 2) {
        cell.textLabel.text = @"数据变化触发曝光";
        cell.detailTextLabel.text = @"过滤短时间曝光的数据，数据变化自动检测新数据曝光";
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
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 2) {
        ZHExample3ViewController *vc = [[ZHExample3ViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
