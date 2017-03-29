//
//  GameScene.m
//  GameTest
//
//  Created by yang on 2017/3/14.
//  Copyright © 2017年 yang. All rights reserved.
//

#import "GameScene.h"
#import "GameOverScene.h"
#import <AVFoundation/AVFoundation.h>

#define ARC4RANDOM_MAX 0x100000000

// 随机数
static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max)
{
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 120; // zombie速度
static const float CAT_MOVE_POINTS_PER_SEC = 120.0; // cat速度
static const float  BG_POINTS_PER_SEC = 50; // 背景移动速度


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



// 使改变方向时更平滑
static inline CGFloat ScalarSign(CGFloat a)
{
    return a >= 0 ? 1 : -1;
}
// Returns shortest angle between two angles,
// between -M_PI and M_PI
static inline CGFloat ScalarShortestAngleBetween(const CGFloat a, const CGFloat b)
{
    CGFloat difference = b - a;
    CGFloat angle = fmodf(difference, M_PI * 2);
    if (angle >= M_PI) {
        angle -= M_PI * 2; }
    else if (angle <= -M_PI) { angle += M_PI * 2;
    }
    return angle;
}

static const float ZOMBIE_ROTATE_RADIANS_PKER_SEC = 4 * M_PI;

@implementation GameScene
{
    SKSpriteNode *_zombie;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    CGPoint _velocity;
    SKAction *_enemyAnimation;
    SKAction *_zombieAnimation;
    SKAction *_catCollisionSound; // 音效
    SKAction *_enemyCollisionSound; // 音效
    SKNode *_bgLayer;
    AVAudioPlayer *_backgroundMusicPlayer;
    
    int _lives; // player（conga）生命数
    BOOL _gameOver;
}

- (instancetype)initWithSize:(CGSize)size
{
    self = [super initWithSize:size];
    if(self)
    {
        _bgLayer = [SKNode node];
        [self addChild:_bgLayer];
        self.backgroundColor = [SKColor whiteColor];
        [self playBackgroundMusic:@"bgMusic.mp3"];
        
        for (int i = 0; i < 2; i++)
        {
            SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
            bg.anchorPoint = CGPointZero;
            bg.position =  CGPointMake(i * self.size.width, 0);
            bg.size = self.size;
            bg.name = @"bg";
            [_bgLayer addChild:bg];
        }
        
        _lives = 5;
        _gameOver = NO;
        
        // 先创建这个action，为了防止第一次加载声音有些许卡顿
        _catCollisionSound = [SKAction playSoundFileNamed:@"hitCat.wav" waitForCompletion:NO];
        _enemyCollisionSound = [SKAction playSoundFileNamed:@"hitCatLady.wav" waitForCompletion:NO];
        
        

        
        [self createZombieAnimation];
        
        _enemyAnimation = [SKAction repeatActionForever: [SKAction sequence:@[[SKAction performSelector:@selector(createEnemySprite) onTarget:self],[SKAction waitForDuration:2.0]]]];
        [self runAction:_enemyAnimation];
        
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction performSelector:@selector(spawnCat) onTarget:self],[SKAction waitForDuration:2.0]]]]];
        
        NSLog(@"%f %f",self.size.width,self.size.height);
        
        
        _zombie = [SKSpriteNode spriteNodeWithImageNamed:@"zombie1"];
        _zombie.position = CGPointMake(100, 100);
        _zombie.size = CGSizeMake(79*1.3, 51*1.3);
        [self addChild:_zombie];
    }
    return self;
    
}

- (void)playBackgroundMusic:(NSString*)filename
{
    NSError *error;
    NSURL *backgroundMusicURL = [[NSBundle mainBundle] URLForResource:filename withExtension:Nil];
    _backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
    _backgroundMusicPlayer.numberOfLoops = -1;
    [_backgroundMusicPlayer prepareToPlay];
    [_backgroundMusicPlayer play];
}


- (void)createZombieAnimation
{
    // 1
    NSMutableArray *textures = [NSMutableArray arrayWithCapacity:10];
    // 2
    for (int i = 1; i<4; i++)
    {
        NSString *textureName = [NSString stringWithFormat:@"zombie%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [textures addObject:texture];
    }
    // 3
    for (int i = 4; i > 1; i--)
    {
        NSString *textureName = [NSString stringWithFormat:@"zombie%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [textures addObject:texture];
    }
    // 4
    _zombieAnimation = [SKAction animateWithTextures:textures timePerFrame:0.1];
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
    
//    _zombie.position = CGPointMake(_zombie.position.x + 2, _zombie.position.y);  // 向右无限移动
//
//    [self moveSprite:_zombie velocity:CGPointMake(ZOMBIE_MOVE_POINTS_PER_SEC, 0)];
    
    
    
    // _zombie移动
    [self moveSprite:_zombie velocity:_velocity];
    
    // 检查是否碰到边缘
    [self boundsCheckPlayer];
    
    // 碰撞反弹时转头（旋转）
    [self rotateSprite:_zombie toFace:_velocity];
    
    // 检测输赢
    if (_lives <= 0 && !_gameOver)
    {
        _gameOver = YES;
        NSLog(@"You lose!");
        
        [_backgroundMusicPlayer stop];
        
        // 1
        GameOverScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
        // 2
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        // 3
        [self.view presentScene:gameOverScene transition:reveal];
    }
    
    // 捕获到的串一串
    [self moveTrain];
    
    // 移动背景
    [self moveBg];
}

- (void)didEvaluateActions
{
    // 碰撞检测
    [self checkCollisions];
    
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
    
    // 行走动画
    [self startZombieAnimation];
    
    CGPoint offset = CGPointSubtract(location, _zombie.position);
//    CGFloat length = CGPointLength(offset);
    CGPoint direction = CGPointNormalize(offset);
    
    _velocity = CGPointMake(direction.x * ZOMBIE_MOVE_POINTS_PER_SEC,
                direction.y * ZOMBIE_MOVE_POINTS_PER_SEC);
}

- (void)startZombieAnimation
{
    if (![_zombie actionForKey:@"animation"])
    {
        [_zombie runAction:[SKAction repeatActionForever:_zombieAnimation] withKey:@"animation"];
    }
}

- (void)stopZombieAnimation
{
    [_zombie removeActionForKey:@"animation"];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
    
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
}


// 检查是否碰撞到场景边缘，碰到则反弹
- (void)boundsCheckPlayer {
    // 1
    CGPoint newPosition = _zombie.position;
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
    _zombie.position = newPosition;
    _velocity = newVelocity;
}


// 碰撞检测
- (void)checkCollisions
{
    
    // zombie捕获到了cat
    [self enumerateChildNodesWithName:@"train" usingBlock:^(SKNode *node, BOOL *stop){
        
                               SKSpriteNode *cat = (SKSpriteNode *)node;
        
                               if (CGRectIntersectsRect(cat.frame, _zombie.frame))
                               {
                                   NSLog(@"catch a cat");
                                   cat.name = @"greenTrain";
                                   [cat removeAllActions];
                                   cat.scale = 1;
                                   cat.zRotation = 0.0;
                                   [cat runAction: [SKAction colorizeWithColor:[SKColor greenColor] colorBlendFactor:1.0 duration:1]];
                                   
                                   [self runAction:_catCollisionSound]; // 播放音效

                               }
    }];
    
    
    // zombie被lady打到了
    [self enumerateChildNodesWithName:@"enemy"
                           usingBlock:^(SKNode *node, BOOL *stop){
                               
                               SKSpriteNode *enemy = (SKSpriteNode *)node;
                               
                               CGRect smalleEnemyrFrame = CGRectInset(enemy.frame, 5, 5);
                               CGRect smalleZombierFrame = CGRectInset(_zombie.frame, 5, 5);
                               
                               if (CGRectIntersectsRect(smalleEnemyrFrame, smalleZombierFrame))
                               {
                                   [enemy removeFromParent];
                                   NSLog(@"catched by lady");
                                   // 播放音效
                                   [self runAction:_enemyCollisionSound];
                                   [self loseCats];
                                   _lives--;
                               }
                               
   }];
    
}


// 被敌人碰撞后 lose cat
- (void)loseCats {
    // 1
    __block int loseCount = 0;
    [self enumerateChildNodesWithName:@"greenTrain" usingBlock:
     ^(SKNode *node, BOOL *stop) {
         // 2
         CGPoint randomSpot = node.position;
         randomSpot.x += ScalarRandomRange(-100, 100);
         randomSpot.y += ScalarRandomRange(-100, 100);
         // 3
         node.name = @"";
         [node runAction:
          [SKAction sequence:@[
                               [SKAction group:@[
                                                 [SKAction rotateByAngle:M_PI * 4 duration:1.0],
                                                 [SKAction moveTo:randomSpot duration:1.0],
                                                 [SKAction scaleTo:0 duration:1.0]]],
                                                 [SKAction removeFromParent]]]];
         
         // 4
         loseCount++;
         if (loseCount >= 2)
         {
             *stop = YES;
         }
     }];


}




// 精灵前进时改变方向时 旋转的角度
- (void)rotateSprite:(SKSpriteNode *)sprite toFace:(CGPoint)direction
{
    sprite.zRotation = atan2f(direction.y, direction.x);
}


// 创建lady
- (void)createEnemySprite
{
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy.png"];
    enemy.size = CGSizeMake(80, 80);
    enemy.position = CGPointMake(self.size.width + enemy.size.width/2,
                                 ScalarRandomRange(enemy.size.height/2,
                                                   self.size.height-enemy.size.height/2));
    enemy.name = @"enemy";
    [self addChild:enemy];
    
    
    
    
    
    SKAction *actionMove = [SKAction moveToX:-enemy.size.width/2 duration:2.0];
    SKAction *actionRemove = [SKAction removeFromParent];
    [enemy runAction:[SKAction sequence:@[actionMove, actionRemove]]];
    

    
}


// 生成cat
- (void)spawnCat {
    // 1
    SKSpriteNode *cat = [SKSpriteNode spriteNodeWithImageNamed:@"cat"];
    float scaleWH = 1080/1920.0;
    cat.size = CGSizeMake(100*scaleWH, 120);
    cat.name = @"train";
    
    cat.position = CGPointMake( ScalarRandomRange(50, self.size.width), ScalarRandomRange(50, self.size.height));
    cat.xScale = 0;
    cat.yScale = 0;
    [self addChild:cat];
    // 2
    SKAction *appear = [SKAction scaleTo:1.0 duration:0.5];
    
    
    cat.zRotation = -M_PI / 16;
    SKAction *leftWiggle = [SKAction rotateByAngle:M_PI / 8
                                          duration:0.5];
    SKAction *rightWiggle = [leftWiggle reversedAction];
    SKAction *fullWiggle =[SKAction sequence:@[leftWiggle, rightWiggle]];
    
    // 左右摇摆
//    SKAction *wiggleWait = [SKAction repeatAction:fullWiggle count:10];
    
    // 不停旋转
//    SKAction *wiggleWait = [SKAction repeatAction:[SKAction rotateByAngle:M_PI * 18
//                                                                 duration:1] count:5];
    
    
    // group action  同时的action
    SKAction *scaleUp = [SKAction scaleBy:1.2 duration:0.25];
    SKAction *scaleDown = [scaleUp reversedAction];
    SKAction *fullScale = [SKAction sequence:@[scaleUp, scaleDown, scaleUp, scaleDown]];
    SKAction *group = [SKAction group:@[fullScale, fullWiggle]];
    SKAction *groupWait = [SKAction repeatAction:group count:5];
    
    //SKAction *wait = [SKAction waitForDuration:10.0];
    
    SKAction *disappear = [SKAction scaleTo:0.0 duration:0.5];
    SKAction *removeFromParent = [SKAction removeFromParent];
    // 0.5  1  0.5  0
    [cat runAction:[SKAction sequence:@[appear, groupWait, disappear, removeFromParent]]];
}




// 捕获到的cat 串成一串
- (void)moveTrain {
    
    __block int trainCount = 0;
    __block CGPoint targetPosition = _zombie.position;
    [self enumerateChildNodesWithName:@"greenTrain" usingBlock:^(SKNode *node, BOOL *stop)
        {
            SKSpriteNode *cat = (SKSpriteNode *)node;
            trainCount++;
            if (!cat.hasActions)
            {
                NSLog(@"cat move to zombie");
                
                float actionDuration = 0.3;
                CGPoint offset = CGPointSubtract(targetPosition, cat.position); // a
                CGPoint direction = CGPointNormalize(offset); // b
                CGPoint amountToMovePerSec = CGPointMultiplyScalar(direction, CAT_MOVE_POINTS_PER_SEC); // c
                CGPoint amountToMove = CGPointMultiplyScalar(amountToMovePerSec, actionDuration); // d
                SKAction *moveAction = [SKAction moveByX:amountToMove.x y:amountToMove.y duration:actionDuration]; // e
                [cat runAction:moveAction];
            }
            targetPosition = cat.position;
        }];
    
    
    if (trainCount >= 20 && !_gameOver)
    {
        
        _gameOver = YES;
        [_backgroundMusicPlayer stop];
        
        NSLog(@"You win!");
        
        // 1
        GameOverScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
        // 2
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        // 3
        [self.view presentScene:gameOverScene transition:reveal];
    }
    
}


- (void)moveBg
{
    CGPoint bgVelocity = CGPointMake(-BG_POINTS_PER_SEC, 0);
    CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity, _dt);
    _bgLayer.position = CGPointAdd(_bgLayer.position, amtToMove);
    [_bgLayer enumerateChildNodesWithName:@"bg" usingBlock:^(SKNode *node, BOOL *stop){
        SKSpriteNode *bg = (SKSpriteNode *)node;
        CGPoint bgScreenPos = [_bgLayer convertPoint:bg.position toNode:self];
        if (bgScreenPos.x <= -bg.size.width)
        {
            bg.position = CGPointMake(bg.position.x + bg.size.width*2, bg.position.y);
        }
    }];
}
                                 
//// 基础action例子
//- (void)createEnemySprite
//{
//    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];
//    enemy.position = CGPointMake(self.size.width + enemy.size.width/2, self.size.height/2);
//    [self addChild:enemy];
//    
////    // 1
////    SKAction *actionMidMove =
////    [SKAction moveTo:CGPointMake(self.size.width/2,
////                                 enemy.size.height/2)
////            duration:1.0];
////    // 2
////    SKAction *actionMove =
////    [SKAction moveTo:CGPointMake(-enemy.size.width/2,
////                                 enemy.position.y) duration:1.0];
//    
//    // 这个是可逆的action  上面两个moveTo是不可逆的
//    SKAction *actionMidMove = [SKAction moveByX:-self.size.width/2-enemy.size.width/2
//                    y:-self.size.height/2+enemy.size.height/2
//                    duration:1.0];
//    
//    SKAction *actionMove = [SKAction moveByX:-self.size.width/2-enemy.size.width/2
//                    y:self.size.height/2+enemy.size.height/2
//                    duration:1.0];
//    
//    SKAction *wait = [SKAction waitForDuration:0.25];
//    
//    SKAction *logMessage = [SKAction runBlock:^{
//        
//        NSLog(@"Reached bottom!");
//    }];
//    
//    
//    SKAction *reverseMid = [actionMidMove reversedAction];
//    
//    SKAction *reverseMove = [actionMove reversedAction];
//    
//    // 3
//    // 逆action
////    SKAction *sequence = [SKAction sequence:@[actionMidMove, logMessage, wait, actionMove, reverseMove, logMessage, wait ,reverseMid]];
//    // 或者
//    SKAction *sequence = [SKAction sequence:@[actionMidMove, logMessage, wait, actionMove]];
//    sequence = [SKAction sequence:@[sequence,[sequence reversedAction]]];
//    
//    
//    // 重复某个动作
//    SKAction *repeat = [SKAction repeatActionForever:sequence];
//    [enemy runAction:repeat];
//    
//    // 4
//    [enemy runAction:sequence];
//}

@end
