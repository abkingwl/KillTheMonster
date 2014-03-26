//
//  HelloWorldScene.m
//  KillTheMonster
//
//  Created by Alan on 3/26/14.
//  Copyright abking 2014. All rights reserved.
//
// -----------------------------------------------------------------------

#import "HelloWorldScene.h"
#import "IntroScene.h"

// -----------------------------------------------------------------------
#pragma mark - HelloWorldScene
// -----------------------------------------------------------------------

@implementation HelloWorldScene
{
    CCSprite *_sprite,*_player;
    CCPhysicsNode *_physicsWorld;
    float _timeToAddMonster,_timer;
    int _killed,_passed,_kill;
    CCLabelTTF *_killedLabel,*_passedLabel;
}

// -----------------------------------------------------------------------
#pragma mark - Create & Destroy
// -----------------------------------------------------------------------

+ (HelloWorldScene *)scene
{
    return [[self alloc] init];
}

// -----------------------------------------------------------------------

- (id)init
{
    // Apple recommend assigning self with supers return value
    self = [super init];
    if (!self) return(nil);
    _kill=_killed=_passed=0;
    _timer=_timeToAddMonster=1.0f;
 
    // Enable touch handling on scene node
    self.userInteractionEnabled = YES;
    
    CCSprite *background=[CCSprite spriteWithImageNamed:@"backgroundiPhone.png"];
    background.position=ccp(self.contentSize.width/2,self.contentSize.height/2);
    [self addChild:background];
    
    _physicsWorld=[CCPhysicsNode node];
    //_physicsWorld.debugDraw=YES;
    _physicsWorld.gravity=ccp(0,0);
    _physicsWorld.collisionDelegate=self;
    [self addChild:_physicsWorld];
    
    _player=[CCSprite spriteWithImageNamed:@"player.png"];
    _player.position=ccp(_player.contentSize.width/2, self.contentSize.height/2);
    [self addChild:_player];
    
    _killedLabel=[CCLabelTTF labelWithString:@"killed:0" fontName:@"Verdana-Bold" fontSize:12];
    _passedLabel=[CCLabelTTF labelWithString:@"passed:0" fontName:@"Verdana-Bold" fontSize:12];
    _killedLabel.position=ccp(self.contentSize.width-_killedLabel.contentSize.width-10,self.contentSize.height-_killedLabel.contentSize.height/2-2);
    _passedLabel.position=ccp(self.contentSize.width-_killedLabel.contentSize.width-5.0f,self.contentSize.height-_killedLabel.contentSize.height/2-_passedLabel.contentSize.height/2-8);
    [self addChild:_killedLabel];
    [self addChild:_passedLabel];
    
    // Create a back button
    CCButton *backButton = [CCButton buttonWithTitle:@"[ Menu ]" fontName:@"Verdana-Bold" fontSize:12.0f];
    backButton.position = ccp(backButton.contentSize.width/2,self.contentSize.height-backButton.contentSize.height/2); 
    [backButton setTarget:self selector:@selector(onBackClicked:)];
    [self addChild:backButton];

    // done
	return self;
}
-(void)addMonster{
    CCSprite *monster=[CCSprite spriteWithImageNamed:@"monster.png"];
    float minY=monster.contentSize.height/2;
    float maxY=self.contentSize.height-monster.contentSize.height/2;
    float rangeY=maxY-minY;
    int positionY=arc4random()%(int)rangeY+(int)minY;
    float minDt=4;
    float maxDt=8;
    float rangeDt=maxDt-minDt;
    int durationTime=arc4random()%(int)rangeDt+(int)minDt;
    monster.position=ccp(self.contentSize.width+monster.contentSize.width/2, positionY);
    monster.physicsBody=[CCPhysicsBody bodyWithRect:(CGRect){CGPointZero,monster.contentSize} cornerRadius:0];
    monster.physicsBody.collisionGroup=@"monsterGroup";
    monster.physicsBody.collisionType=@"monsterCollision";
    [_physicsWorld addChild:monster];
    CCActionMoveTo *monsterMoveTo=[CCActionMoveTo actionWithDuration:durationTime position:ccp(-monster.contentSize.width/2, positionY)];
    //CCActionRemove *monsterMoveToRemove=[CCActionRemove action];
    CCActionCallBlock *monsterActionCallBack=[CCActionCallBlock actionWithBlock:^{
        [monster removeFromParentAndCleanup:YES];
        _passed++;
    }];
    CCActionSequence *monsterActionSequence=[CCActionSequence actionWithArray:@[monsterMoveTo,monsterActionCallBack]];
    [monster runAction:monsterActionSequence];
}
-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    _timer=0;
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    //[_player runAction:[CCActionScaleTo actionWithDuration:0.5f scale:1.0f]];
    CGPoint touchLocation=[touch locationInNode:self];
    NSString *projectileName=(_timer>20)?@"test2.png":@"projectile.png";
    CCSprite *projectile=[CCSprite spriteWithImageNamed:projectileName];
    projectile.name=(_timer>20)?@"YES":@"NO";
    projectile.position=_player.position;
    CGPoint offset=ccpSub(touchLocation, _player.position);
    float ratio=offset.y/offset.x;
    float targetX=self.contentSize.width+_player.contentSize.width/2;
    float targetY=ratio*targetX+_player.position.y;
    CGPoint targetLocation=ccp(targetX,targetY);
    float dt=self.contentSize.width/480;
    projectile.physicsBody=[CCPhysicsBody bodyWithCircleOfRadius:projectile.contentSize.width/2 andCenter:projectile.anchorPointInPoints];
    projectile.physicsBody.collisionGroup=@"playerGroup";
    projectile.physicsBody.collisionType=@"projectileCollision";
    [_physicsWorld addChild:projectile];
    CCActionRotateBy *projectileRotate=[CCActionRotateBy actionWithDuration:1 angle:180];
    [projectile runAction:[CCActionRepeatForever actionWithAction:projectileRotate]];
    CCActionMoveTo *projectileMoveTo=[CCActionMoveTo actionWithDuration:dt position:targetLocation];
    CCActionRemove *projectileMoveToRemove=[CCActionRemove action];
//    CCActionCallBlock *projectileActionCallBack=[CCActionCallBlock actionWithBlock:^{
//        [projectile removeFromParentAndCleanup:YES];
//    }];
    //CCActionSequence *projectileActionSequence=[CCActionSequence actionWithArray:@[projectileMoveTo,projectileActionCallBack]];
    CCActionSequence *projectileActionSequence=[CCActionSequence actionWithArray:@[projectileMoveTo,projectileMoveToRemove]];
    [projectile runAction:projectileActionSequence];
}
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monsterCollision:(CCNode *)monster projectileCollision:(CCNode *)projectile{
    _kill++;
    _killed++;
    if (_kill>=10 && _timeToAddMonster>=0.2) {
        [self unschedule:@selector(addMonster)];
        _kill=0;
        _timeToAddMonster-=0.1;
        [self schedule:@selector(addMonster) interval:_timeToAddMonster];
    }
    [monster removeFromParent];
    if ([projectile.name isEqualToString:@"NO"]) {
        [projectile removeFromParent];
    }
    return YES;
}
-(void)update:(CCTime)delta{
    
    _timer+=1;
//    if (_timer>20) {
//        [_player runAction:[CCActionScaleTo actionWithDuration:0.5f scale:1.5f]];
//    }
    [_killedLabel setString:[NSString stringWithFormat:@"killed:%d",_killed]];
    [_passedLabel setString:[NSString stringWithFormat:@"passed:%d",_passed]];
}

// -----------------------------------------------------------------------

- (void)dealloc
{
    // clean up code goes here
}

// -----------------------------------------------------------------------
#pragma mark - Enter & Exit
// -----------------------------------------------------------------------

- (void)onEnter
{
    // always call super onEnter first
    [super onEnter];
    [self schedule:@selector(addMonster) interval:_timeToAddMonster];
    
}

// -----------------------------------------------------------------------

- (void)onExit
{
    // always call super onExit last
    [super onExit];
}



// -----------------------------------------------------------------------
#pragma mark - Button Callbacks
// -----------------------------------------------------------------------

- (void)onBackClicked:(id)sender
{
    // back to intro scene with transition
    [[CCDirector sharedDirector] replaceScene:[IntroScene scene]
                               withTransition:[CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:1.0f]];
}

// -----------------------------------------------------------------------
@end
