//
//  LogCell.m
//  BobbyenGame
//
//  Created by iOS-Mac on 2018/12/26.
//  Copyright © 2018年 iOS-Mac. All rights reserved.
//

#import "LogCell.h"

@implementation LogCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self creatSubView];
    }
    return self;
    
}

-(void)creatSubView{
    UILabel *titleLab =[UILabel new];
    self.titleLab = titleLab;
    [self.contentView addSubview:titleLab];
    titleLab.font = [UIFont systemFontOfSize:14];
    titleLab.textColor =[UIColor blueColor];
    titleLab.numberOfLines = 0;
    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.mas_equalTo(0);
    }];
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
