//
//  LLLabel.m
//  LLWeChat
//
//  Created by GYJZH on 8/10/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLLabel.h"
#import "LLColors.h"
#import "LLUtils.h"
#import "UIKit+LLExt.h"


@interface LLLabelRichTextData ()

@property (nonatomic) NSMutableArray<NSValue *> *rects;

@end

@implementation LLLabelRichTextData

- (instancetype)initWithType:(LLLabelRichTextType)type {
    self = [super init];
    if (self) {
        self.type = type;
    }
    
    return self;
}

@end


@interface LLLabel ()  <UIGestureRecognizerDelegate>

@property (nonatomic) UIColor *richTextColor;
@property (nonatomic) UIColor *selectedBackgroundColor; //用户选中时的背景颜色
@property (nonatomic) LLLabelRichTextData *data;

@property (nonatomic) UILongPressGestureRecognizer *longPress;

@end

@implementation LLLabel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.scrollEnabled = NO;
        self.scrollsToTop = NO;
        self.editable = NO;
        self.selectable = NO;
        self.textContainerInset = UIEdgeInsetsZero;
        self.textContainer.lineFragmentPadding = 0;
        
        _data = nil;
        _richTextDatas = [NSMutableArray array];
        _richTextColor = kLLTextLinkColor;
        _selectedBackgroundColor = [UIColor colorWithWhite:0.4 alpha:0.3];
    
        _longPress = [self addLongPressGestureRecognizer:@selector(longPressHandler:) duration:0.6];
        _longPress.delegate = self;
        
        UITapGestureRecognizer *tap = [self addTapGestureRecognizer:@selector(tapHandler:)];
        tap.delegate = self;

    }
    
    return self;
}

                          
- (void)parseText:(NSAttributedString *)text {
    [self.richTextDatas removeAllObjects];
    
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber | NSTextCheckingTypeLink
                                                               error:&error];
    NSArray *matches = [detector matchesInString:text.string
                                         options:kNilOptions
                                           range:NSMakeRange(0, [text.string length])];
    
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        if ([match resultType] == NSTextCheckingTypeLink) {
            NSURL *url = [match URL];
            LLLabelRichTextData *data = [[LLLabelRichTextData alloc] initWithType:kLLLabelRichTextTypeURL];
            data.range = matchRange;
            data.url = url;
            data.rects = [self calculateRectsForCharacterRange:matchRange];
            [self.richTextDatas addObject:data];
            
        } else if ([match resultType] == NSTextCheckingTypePhoneNumber) {
            NSString *phoneNumber = [match phoneNumber];
            
            LLLabelRichTextData *data = [[LLLabelRichTextData alloc] initWithType:kLLLabelRichTextTypePhoneNumber];
            data.range = matchRange;
            data.phoneNumber = phoneNumber;
            data.rects = [self calculateRectsForCharacterRange:matchRange];
            
            [self.richTextDatas addObject:data];
            
        }
        
    }
    
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    
    if (self.data) {
        [self _setNeedsDisplay:nil];
    }
}


- (void)layoutSubviews  {
    [super layoutSubviews];
   
    if (CGRectGetHeight(self.frame) < 2 * self.font.lineHeight) {
        CGFloat gap = (CGRectGetHeight(self.frame) - self.font.lineHeight ) / 2;
        self.textContainerInset = UIEdgeInsetsMake(gap, 0, gap, 0);
    }else {
        self.textContainerInset = UIEdgeInsetsZero;
    }
   
    [self parseText:self.attributedText];

}

- (NSMutableArray<NSValue *> *)calculateRectsForCharacterRange:(NSRange)range {
    NSMutableArray<NSValue *> *rects = [NSMutableArray array];
    
    NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
    
    CGRect startRect = [self.layoutManager boundingRectForGlyphRange:NSMakeRange(glyphRange.location, 1) inTextContainer:self.textContainer];
    
    CGRect endRect = [self.layoutManager boundingRectForGlyphRange:NSMakeRange(glyphRange.location  +   glyphRange.length-1, 1) inTextContainer:self.textContainer];
    
    CGFloat lineHeight = self.font.lineHeight;
    NSInteger lineNumber = (CGRectGetMaxY(endRect) - CGRectGetMinY(startRect)) / lineHeight;
    
    CGRect lineRect;
    CGRect drawRect;
    
    //计算第一行
    if (lineNumber == 1) {
        drawRect = CGRectMake(CGRectGetMinX(startRect), CGRectGetMinY(startRect), CGRectGetMaxX(endRect) - CGRectGetMinX(startRect), CGRectGetHeight(startRect));
    }else {
        lineRect = [self.layoutManager lineFragmentUsedRectForGlyphAtIndex:glyphRange.location effectiveRange:nil];
        drawRect = CGRectMake(CGRectGetMinX(startRect), CGRectGetMinY(startRect), CGRectGetWidth(lineRect) - CGRectGetMinX(startRect), CGRectGetHeight(startRect));
    }
    [rects addObject:[NSValue valueWithCGRect:drawRect]];
    
    
    //计算最后一行
    if (lineNumber >= 2) {
        drawRect = CGRectMake(0, CGRectGetMinY(endRect), CGRectGetMaxX(endRect), CGRectGetHeight(endRect));
        [rects addObject:[NSValue valueWithCGRect:drawRect]];
    }
    
    //计算中间行
    for (NSInteger i = 1; i < lineNumber-1; i++) {
        NSInteger glyphIndex = [self.layoutManager glyphIndexForPoint:CGPointMake(0, CGRectGetMinY(startRect) + lineHeight *i) inTextContainer:self.textContainer];
        lineRect = [self.layoutManager lineFragmentUsedRectForGlyphAtIndex:glyphIndex effectiveRange:nil];
        [rects addObject:[NSValue valueWithCGRect:lineRect]];
    }
    
    if (self.textContainerInset.top > 0) {
        CGRect rect = CGRectOffset(rects[0].CGRectValue, 0, self.textContainerInset.top);
        rects[0] = [NSValue valueWithCGRect:rect];
    }
    
    return rects;
}


- (void)drawRect:(CGRect)rect {
    if (!self.data)
        return;
    
    NSArray<NSValue *> *rects = self.data.rects;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.selectedBackgroundColor.CGColor);
    for (NSValue *value in rects) {
        CGContextFillRect(context, value.CGRectValue);
    }
    
}

- (LLLabelRichTextData *)richTextDataForPoint:(CGPoint)point {
    CGFloat fraction;
    NSInteger glyphIndex = [self.layoutManager glyphIndexForPoint:point inTextContainer:self.textContainer fractionOfDistanceThroughGlyph:&fraction];
    CGRect rect = [self.layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:self.textContainer];
    
    if (!CGRectContainsPoint(rect, point)) {
        return nil;
    }
    
    NSInteger characterIndex = [self.layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    for (LLLabelRichTextData *data in self.richTextDatas) {
        if (characterIndex >= data.range.location && characterIndex < data.range.location + data.range.length) {
            return data;
        }
    }
    
    return nil;
}


- (void)_setNeedsDisplay:(LLLabelRichTextData *)data {
    self.data = data;
    [self setNeedsDisplay];
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

    CGPoint point = [touch locationInView:self];
    LLLabelRichTextData *data = [self richTextDataForPoint:point];
    
    if (!data)return NO;
    [self _setNeedsDisplay:data];
    
    return YES;
}


- (void)longPressHandler:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateEnded) {
        if (self.data) {
            [self _setNeedsDisplay:nil];
        }
    }
    
    if (self.longPressAction) {
        self.longPressAction(self.data, longPress.state);
    }

}

- (void)tapHandler:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded) {
        if (self.data && self.tapAction) {
            self.tapAction(self.data);
            [self _setNeedsDisplay:nil];
        }
    }
}


- (BOOL)touchShouldBegin:(UITouch *)touch {
    CGPoint point = [touch locationInView:self];
    LLLabelRichTextData *data = [self richTextDataForPoint:point];
    
    if (!data)return NO;
    return YES;
}

- (BOOL)shouldReceiveTouchAtPoint:(CGPoint)point {
    LLLabelRichTextData *data = [self richTextDataForPoint:point];
    
    if (!data)return NO;
    return YES;
}

- (void)cancelTouch:(UITouch *)touch {
    if (self.data) {
        [self _setNeedsDisplay:nil];
    }
}

@end
