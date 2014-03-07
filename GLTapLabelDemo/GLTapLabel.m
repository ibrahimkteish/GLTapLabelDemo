/*
 * Copyright (c) 2011 German Laullon
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#define is_iOS_7 [[UIDevice currentDevice].systemVersion hasPrefix:@"7"]

#import "GLTapLabel.h"

@implementation GLTapLabel

@synthesize delegate;
@synthesize linkColor;

-(void)drawTextInRect:(CGRect)rect
{
    UIColor *origColor = [self textColor];
    [origColor set];
    if(!hotFont){
        hotFont = [UIFont fontWithName:[NSString stringWithFormat:@"Helvetica-Bold"] size:self.font.pointSize];
    }
    
    if(!hotZones){
        hotZones = [NSMutableArray array];
        hotWords = [NSMutableArray array];
    }else{
        [hotZones removeAllObjects];
        [hotWords removeAllObjects];
    }
    
    CGSize space = CGSizeZero;
    
    if (is_iOS_7)
    {
        space = [@" " boundingRectWithSize:rect.size
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{NSFontAttributeName:self.font}
                                   context:nil].size;
    }
    else
    {
        space = [@" " sizeWithFont:self.font constrainedToSize:rect.size lineBreakMode:self.lineBreakMode];
    }
    
    
    __block CGPoint drawPoint = CGPointMake(0,0);
    NSString *read;
    NSScanner *s = [NSScanner scannerWithString:self.text];
    while ([s scanUpToCharactersFromSet:[NSCharacterSet symbolCharacterSet] intoString:&read]) {
        NSArray *origWords = [read componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSMutableArray *words = [NSMutableArray array];
        for (NSString* word in origWords)
        {
            // this is just to avoid ARC complications. We could just as easily make it __strong but then it won't work with non-ARC builds.
            NSString* origWord = word;
            NSString* newWord = word;
            CGSize s = CGSizeZero;
            if (is_iOS_7)
            {
                s = [newWord sizeWithAttributes:@{NSFontAttributeName:self.font}];
            }
            else
            {
                s = [newWord sizeWithFont:self.font];
            }
            NSString *cutWord = @"";
            int c = [word length]-1;
            while (s.width > rect.size.width) {
                cutWord = [origWord substringFromIndex:c];
                newWord = [origWord substringToIndex:c];
                if (is_iOS_7)
                {
                    s = [newWord sizeWithAttributes:@{NSFontAttributeName:self.font}];
                }
                else
                {
                    s = [newWord sizeWithFont:self.font];
                }
                
                c -= 1;
                if (s.width <= rect.size.width)
                {
                    [words addObject:newWord];
                    origWord = cutWord;
                    if (is_iOS_7)
                    {
                        s = [newWord sizeWithAttributes:@{NSFontAttributeName:self.font}];
                    }
                    else
                    {
                        s = [newWord sizeWithFont:self.font];
                    }
                    c = [origWord length]-1;
                }
            }
            [words addObject:origWord];
        }
        
        [words enumerateObjectsUsingBlock:^(NSString *word, NSUInteger idx, BOOL *stop) {
            BOOL hot = [word hasPrefix:@"#"] || [word hasPrefix:@"@"];
            UIFont *f= hot ? hotFont : self.font;
            CGSize s = CGSizeZero;
            if (is_iOS_7)
            {
                s = [word sizeWithAttributes:@{NSFontAttributeName:f}];
            }
            else
            {
                s = [word sizeWithFont:f];
            }
            if(drawPoint.x + s.width > rect.size.width) {
                drawPoint = CGPointMake(0, drawPoint.y + s.height);
            }
            if(hot){
                [hotZones addObject:[NSValue valueWithCGRect:CGRectMake(drawPoint.x, drawPoint.y, s.width, s.height)]];
                [hotWords addObject:word];
                [linkColor set];
            }
            if (is_iOS_7)
            {
                [word drawAtPoint:drawPoint withAttributes:@{NSFontAttributeName:f}];
            }
            else
            {
                [word drawAtPoint:drawPoint withFont:f];
                
            }
            
            [origColor set];
            
            drawPoint = CGPointMake(drawPoint.x + s.width + space.width, drawPoint.y);
        }];
        
        while ([s scanCharactersFromSet:[NSCharacterSet symbolCharacterSet] intoString:&read]) {
            for(int idx=0;idx<read.length;idx=idx+2)
            {
                NSString *word=[read substringWithRange:NSMakeRange(idx, 2)];
                CGSize s = CGSizeZero;
                if (is_iOS_7)
                {
                    s = [word sizeWithAttributes:@{NSFontAttributeName:self.font}];
                }
                else
                {
                    s = [word sizeWithFont:self.font];
                }
                if(drawPoint.x + s.width > rect.size.width) {
                    drawPoint = CGPointMake(0, drawPoint.y + s.height);
                }
                
                if(drawPoint.x + s.width > rect.size.width) {
                    drawPoint = CGPointMake(0, drawPoint.y + s.height);
                }
                if (is_iOS_7)
                {
                    [word drawAtPoint:drawPoint withAttributes:@{NSFontAttributeName:self.font}];
                }
                else
                {
                    [word drawAtPoint:drawPoint withFont:self.font];
                    
                }
                drawPoint = CGPointMake(drawPoint.x + s.width, drawPoint.y);
            }
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = event.allTouches.anyObject;
    CGPoint point = [touch locationInView:self];
    [hotZones enumerateObjectsUsingBlock:^(NSValue *obj, NSUInteger idx, BOOL *stop) {
        CGRect hotzone = [obj CGRectValue];
        if (CGRectContainsPoint(hotzone, point)) {
            if(delegate){
                [delegate label:self didSelectedHotWord:[hotWords objectAtIndex:idx]];
            }
            *stop = YES;
        }
    }];
}

@end

