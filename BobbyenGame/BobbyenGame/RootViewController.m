//
//  RootViewController.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/20.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "RootViewController.h"
#import "GameViewController.h"
#import "DownLoadViewController.h"
#import "VideoViewController.h"

@interface RootViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)UITableView *tableView;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor whiteColor];
    self.title = @"波比游戏";
    [self.view addSubview:self.tableView];
    
    
    
    // Do any additional setup after loading the view.
}
-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        
    }
    return _tableView;
}
#pragma mark UITableViewDelegate&&UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.row==0) {
        cell.textLabel.text = @"波比游戏";
    }
    else if (indexPath.row==1) {
        cell.textLabel.text = @"下载zip文件并且解压zip的功能；";
    }
    else if (indexPath.row==2){
        cell.textLabel.text = @"注册WebViewJavascriptBridge相关方法，使JS能够调用到;";
    }
    else if (indexPath.row==3){
        cell.textLabel.text = @"视频播放功能";
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // 解决cell的点击延迟问题
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row==0) {
        GameViewController*vc=[GameViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row==1) {
        DownLoadViewController *vc=[DownLoadViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row==2) {
        
    }
    else if (indexPath.row==3) {
        VideoViewController *vc=[[VideoViewController alloc]init];
        [self presentViewController:vc animated:YES completion:nil];
    }
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}


//支持旋转
-(BOOL)shouldAutorotate{
    return YES;
}
//支持的方向,支持竖屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}




/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
