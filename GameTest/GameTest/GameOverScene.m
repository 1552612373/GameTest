//
//  GameOverScene.m
//  GameTest
//
//  Created by szy-js-chenleping on 17/3/29.
//  Copyright © 2017年 yang. All rights reserved.
//

#import "GameOverScene.h"
#import "GameScene.h"

@implementation GameOverScene

- (void)didMoveToView:(SKView *)view
{
    [super didMoveToView:view];
}

- (void)willMoveFromView:(SKView *)view
{
    [super willMoveFromView:view];
}

- (id)initWithSize:(CGSize)size won:(BOOL)won
{
    if(self = [super initWithSize:size])
    {
        SKSpriteNode *bg;
        if (won) {
            bg = [SKSpriteNode spriteNodeWithImageNamed:@"YouWin.png"];
            [self runAction:[SKAction sequence:@[
                                                 [SKAction waitForDuration:0.1],
                                                 [SKAction playSoundFileNamed:@"win.wav" waitForCompletion:NO]]] ];
        } else {
            bg = [SKSpriteNode spriteNodeWithImageNamed:@"YouLose.png"];
            [self runAction:[SKAction sequence:@[
                                                 [SKAction waitForDuration:0.1],
                                                 [SKAction playSoundFileNamed:@"lose.wav" waitForCompletion:NO]]] ];
        }
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:bg];

        
        
        //   跳转到GameScene
        SKAction * wait = [SKAction waitForDuration:3.0];
        SKAction * block = [SKAction runBlock:^{
            GameScene * myScene = [[GameScene alloc] initWithSize:self.size];
            SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
            [self.view presentScene:myScene transition: reveal];
        }];
        
        [self runAction:[SKAction sequence:@[wait, block]]];
    }
    return self;
}


@end
