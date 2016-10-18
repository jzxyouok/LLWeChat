//
//  LLPictureNumberView.m
//  LLPickImageDemo
//
//  Created by GYJZH on 6/26/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLPictureNumberView.h"

@interface LLPictureNumberView ()

@property (nonatomic) UIImageView *backgroundImage;
@property (nonatomic) UILabel *numberLabel;

@end


@implementation LLPictureNumberView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.backgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
    self.backgroundImage.image = [UIImage imageNamed:@"FriendsSendsPicturesNumberIcon"];
    [self addSubview:self.backgroundImage];
    
    self.numberLabel = [[UILabel alloc] initWithFrame:self.backgroundImage.frame];
    self.numberLabel.textColor = [UIColor whiteColor];
    self.numberLabel.font = [UIFont boldSystemFontOfSize:15];
    self.numberLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.numberLabel];
    
    return self;
}

- (void)setNumber:(NSInteger)number {
    if (_number != number) {
        _number = number;
        self.numberLabel.text = [NSString stringWithFormat:@"%ld", _number];
        [self animateView];
    }
}

- (void)animateView {
    __weak typeof(self) weakSelf = self;
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        weakSelf.backgroundImage.transform = CGAffineTransformMakeScale(0.4, 0.4);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.backgroundImage.transform = CGAffineTransformMakeScale(1.3, 1.3);
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                weakSelf.backgroundImage.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
            
        }];
    }];
    
}

@end
