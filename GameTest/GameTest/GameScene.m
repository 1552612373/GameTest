//
//  GameScene.m
//  GameTest
//
//  Created by yang on 2017/3/14.
//  Copyright © 2017年 yang. All rights reserved.
//

#import "GameScene.h"

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 240.0;

static inline CGPoint CGPointAdd(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointSubtract(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a,const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

static inline CGFloat CGPointLength(const CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}

static inline CGPoint CGPointNormalize(const CGPoint a)
{
    CGFloat length = CGPointLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

static inline CGFloat CGPointToAngle(const CGPoint a)
{
    return atan2f(a.y, a.x);
}

@implementation GameScene
{
    SKSpriteNode *_player;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    CGPoint _velocity;
}

- (instancetype)initWithSize:(CGSize)size
{
    self = [super initWithSize:size];
    if(self)
    {
        SKSpriteNode *bgSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
        bgSprite.position = CGPointMake(self.size.width/2, self.size.height/2);
//        bgSprite.anchorPoint = CGPointZero;
//        bgSprite.position = CGPointZero;
        bgSprite.zRotation = M_PI/8;
        [self addChild:bgSprite];
        
        NSLog(@"%f %f",self.size.width,self.size.height);
        
        
        _player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        _player.position = CGPointMake(100, 100);
        _player.size = CGSizeMake(100, 100);
        [self addChild:_player];
    }
    return self;
    
}




-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
    
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
//    NSLog(@"%0.2f milliseconds since last update", _dt * 1000);
    
//    _player.position = CGPointMake(_player.position.x + 2, _player.position.y);  // 向右无限移动
//
//    [self moveSprite:_player velocity:CGPointMake(ZOMBIE_MOVE_POINTS_PER_SEC, 0)];
    
    
    
    // 精灵移动
    [self moveSprite:_player velocity:_velocity];
    
    // 检查是否碰到边缘
    [self boundsCheckPlayer];
    
    // 碰撞反弹时转头（旋转）
    [self rotateSprite:_player toFace:_velocity];
}

- (void)moveSprite:(SKSpriteNode *)sprite velocity:(CGPoint)velocity
{
    // 1
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, _dt);
    //    NSLog(@"Amount to move: %@", NSStringFromCGPoint(amountToMove));
    // 2
    sprite.position = CGPointAdd(sprite.position, amountToMove);
}

- (void)moveZombieToward:(CGPoint)location {
    CGPoint offset = CGPointSubtract(location, _player.position);
//    CGFloat length = CGPointLength(offset);
    CGPoint direction = CGPointNormalize(offset);
    
    _velocity = CGPointMake(direction.x * ZOMBIE_MOVE_POINTS_PER_SEC,
                direction.y * ZOMBIE_MOVE_POINTS_PER_SEC);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
    
    NSLog(@"touchesBegan");
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
    
    NSLog(@"touchesMoved");
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
    
    NSLog(@"touchesEnded");
}


// 检查是否碰撞到场景边缘，碰到则反弹
- (void)boundsCheckPlayer {
    // 1
    CGPoint newPosition = _player.position;
    CGPoint newVelocity = _velocity;
    // 2
    CGPoint bottomLeft = CGPointZero;
    CGPoint topRight = CGPointMake(self.size.width,
                                   self.size.height);
    // 3
    if (newPosition.x <= bottomLeft.x)
    {
        newPosition.x = bottomLeft.x;
        newVelocity.x = -newVelocity.x;
    }
    
    if (newPosition.x >= topRight.x)
    {
        newPosition.x = topRight.x;
        newVelocity.x = -newVelocity.x;
    }
    
    if (newPosition.y <= bottomLeft.y)
    {
        newPosition.y = bottomLeft.y;
        newVelocity.y = -newVelocity.y;
    }
    
    if (newPosition.y >= topRight.y)
    {
        newPosition.y = topRight.y;
        newVelocity.y = -newVelocity.y;
    }
    // 4
    _player.position = newPosition;
    _velocity = newVelocity;
}

// 精灵前进时改变方向时 旋转的角度
- (void)rotateSprite:(SKSpriteNode *)sprite toFace:(CGPoint)direction
{
    sprite.zRotation = atan2f(direction.y, direction.x);
}


@end
