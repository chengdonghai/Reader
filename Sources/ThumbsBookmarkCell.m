//
//  ThumbsBookmarkCell.m
//  Reader
//
//  Created by chengdonghai on 15/6/19.
//
//

#import "ThumbsBookmarkCell.h"
#import "ThumbsViewController.h"

@implementation ThumbsBookmarkCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.textColor = PDFUIColorFromRGB(0x808080);
        self.textLabel.font = [UIFont systemFontOfSize:12.0f];
        UIImageView *line = [[UIImageView alloc]initWithFrame:CGRectMake(25, CGRectGetHeight(self.frame)-1, CGRectGetWidth(self.frame)-50, 1)];
        line.image = [UIImage imageNamed:@"TYReader-day_line"];
        line.tag = 121;
        self.detailTextLabel.textColor = PDFUIColorFromRGB(0xacacac);
        self.detailTextLabel.font = [UIFont systemFontOfSize:9.f];
        [self.contentView addSubview:line];
    
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGRect textRect = self.textLabel.frame;
    CGRect timeRect = self.detailTextLabel.frame;
    
    textRect.origin.x = 25;
    timeRect.origin.x = self.contentView.frame.size.width - 25 - timeRect.size.width;
    self.textLabel.frame = textRect;
    self.detailTextLabel.frame = timeRect;
    UIView *line = [self.contentView viewWithTag:121];
    CGRect lineRect = line.frame;
    lineRect.origin.y = CGRectGetHeight(self.frame)-1;
    line.frame = lineRect;
    
}
@end
