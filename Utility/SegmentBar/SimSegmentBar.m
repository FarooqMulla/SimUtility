//
//  SimSegmentBar.m
//
//  Created by Xubin Liu on 12-7-11.
//

#import "SimSegmentBar.h"


@interface SimSegmentBar ()
@property(nonatomic, retain) NSArray *items;
@end

@implementation SimSegmentBar

@synthesize delegate;
@synthesize dataSource;
@synthesize selectedIndex = _selectedIndex;
@synthesize divideLineColor = _divideLineColor;
@synthesize items = _items;


- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _selectedIndex = -1;
    }
    return self;
}

- (void)dealloc{
    self.delegate = nil;
    self.dataSource = nil;
    self.items = nil;
    self.divideLineColor = nil;
    [super dealloc];
}


- (void)reloadData{
    for (UIView *view in [self subviews]) {
        [view removeFromSuperview];
    }
    
    NSInteger count = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfBarItems:)]) {
        count = [self.dataSource numberOfBarItems:self];
    }

    if (count == 0) {
        return;
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(backgroudViewOfSegmentBar:)]) {
        UIView *bgView = [self.dataSource backgroudViewOfSegmentBar:self];
        if (bgView) {
            [self addSubview:bgView];
        }
    }
    
    CGSize unitSize = CGSizeMake(self.frame.size.width/count, self.frame.size.height);
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(unitSizeOfBarItems:)]) {
        unitSize = [self.dataSource unitSizeOfBarItems:self];
    }
    
    CGPoint startPoint = CGPointMake((self.frame.size.width - unitSize.width*count) / (count+1), (self.frame.size.height - unitSize.height)/2);
    CGFloat itemsGap = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(startPointOfBarItems:)]) {
        startPoint = [self.dataSource startPointOfBarItems:self];
        if (![self.dataSource respondsToSelector:@selector(unitGapOfBarItems:)]) {
            if (count > 1) {
                itemsGap = (self.frame.size.width - startPoint.x * 2 - unitSize.width * count) / (count - 1);
            }
        }
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(unitGapOfBarItems:)]) {
        itemsGap = [self.dataSource unitGapOfBarItems:self];
        if (![self.dataSource respondsToSelector:@selector(startPointOfBarItems:)]) {
            if (count > 1) {
                startPoint.x = (self.frame.size.width - unitSize.width*count - itemsGap*(count -1)) / 2;
            }
        }
    }
    
    NSMutableArray *_array = [[NSMutableArray alloc] initWithCapacity:count];
    CGRect _frame = CGRectMake(0, 0, unitSize.width, unitSize.height);
    for (int i = 0; i < count; i++) {
        _frame.origin = CGPointMake(startPoint.x+i*(unitSize.width+itemsGap), startPoint.y);
        SimTabBarItem *_item = [[SimTabBarItem alloc] initWithFrame:_frame];
        [_item addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(segmentBar:defaultItem:atIndex:)]) {
            [self.dataSource segmentBar:self defaultItem:_item atIndex:i];
        }
        _item.selected = (_selectedIndex == i);
        [_array addObject:_item];
        [self addSubview:_item];
        SafeRelease(_item);
    }
    self.items = [NSArray arrayWithArray:_array];
    
    
    if (self.divideLineColor) {
        for (int i = 1; i < self.items.count; i++) {
            SimTabBarItem *_item = [_items objectAtIndex:i];
            UIView *divideView = [[UIView alloc] initWithFrame:CGRectMake(_item.frame.origin.x, 0, 1, _item.frame.size.height)];
            divideView.backgroundColor = self.divideLineColor;
            [self addSubview:divideView];
            SafeRelease(divideView);
        }
    }
    
    
    if (self.barType == BarType_HighlightSelected) {
        if (_selectedIndex < 0 || _selectedIndex >= _items.count) {
            self.selectedIndex = 0;
        }
        else{
            [self refreshItemState];
        }
    }
    
    
    SafeRelease(_array);
}

- (void)refreshItemState{
    for (int i = 0; i < _items.count; i++) {
        SimTabBarItem *_item = [_items objectAtIndex:i];
        if (i == _selectedIndex) {
            _item.selected = YES;
            _item.userInteractionEnabled = NO;
        }
        else{
            _item.selected = NO;
            _item.userInteractionEnabled = YES;
        }
    }
}

- (void)selectItem:(SimTabBarItem *)item{
    self.selectedIndex = [self.items indexOfObject:item];
}

- (void)setBadgeValue:(NSString *)value forIndex:(NSInteger)index{
    if (index >= 0 && index < self.items.count) {
        SimTabBarItem *_item = [self.items objectAtIndex:index];
        [_item setBadge:value];
    }
}

- (NSString *)badgeValueForIndex:(NSInteger)index{
    if (index >= 0 && index < self.items.count) {
        SimTabBarItem *_item = [self.items objectAtIndex:index];
        return _item.badge;
    }
    
    return nil;
}

- (void)setSelectedIndex:(NSInteger)newIndex{
    if (self.barType == BarType_HighlightSelected) {
        if (newIndex != self.selectedIndex ) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(segmentBar:shouldSelectIndex:preIndex:)]) {
                BOOL _rt = [self.delegate segmentBar:self shouldSelectIndex:newIndex preIndex:self.selectedIndex];
                if (!_rt) {
                    return;
                }
            }
            
            NSInteger _previousIndex = self.selectedIndex;
            if (_previousIndex >= 0 && _previousIndex < self.items.count) {
                SimTabBarItem *_preItem = (SimTabBarItem *)[self.items objectAtIndex:_previousIndex];
                _preItem.selected = NO;
                _preItem.userInteractionEnabled = YES;
            }
            
            _selectedIndex = newIndex;
            if (newIndex >= 0 && newIndex < self.items.count) {
                SimTabBarItem *_curItem = (SimTabBarItem *)[self.items objectAtIndex:newIndex];
                _curItem.selected = YES;
                _curItem.userInteractionEnabled = NO;
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(segmentBar:didSelectIndex:preIndex:)]) {
                    [self.delegate segmentBar:self didSelectIndex:newIndex preIndex:_previousIndex];
                }
            }
        }
    }
    else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(segmentBar:didSelectIndex:preIndex:)]) {
            [self.delegate segmentBar:self didSelectIndex:newIndex preIndex:-1];
        }

    }
}

@end
