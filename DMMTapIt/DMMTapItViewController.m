//
//  DMMTapItViewController.m
//  DMMTapItDemo
//
//  Created by Daniel on 3/30/15.
//  Copyright (c) 2015 Daniel Miedema. All rights reserved.
//

#import "DMMTapItViewController.h"
#import "DMMTapItAction.h"

@import CoreMotion;
@import AudioToolbox;
@import AVFoundation;

@interface DMMTapItViewController () <UIGestureRecognizerDelegate, AVAudioSessionDelegate>
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeGesture;
@property (strong, nonatomic) NSTimer *gameTimer;
@property (strong, nonatomic) AVAudioPlayer *music;
@property (strong, nonatomic) DMMTapItAction *action;
@property (nonatomic, getter=isPlaying) BOOL playing;

@property (nonatomic) NSInteger gameCount;

@property (strong, nonatomic) AVSpeechSynthesizer *syntesizer;;
@property (strong, nonatomic) AVSpeechSynthesisVoice *voice;

/// sound effects
@property (strong, nonatomic) AVAudioPlayer *tapSoundEffect;
@property (strong, nonatomic) AVAudioPlayer *swipeSoundEffect;
@property (strong, nonatomic) AVAudioPlayer *whipSoundEffect;
@property (strong, nonatomic) AVAudioPlayer *endSoundEffect;

/// Outlets
@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UIButton *startGameButton;
@end

NSURL * URLPathForSound(NSString *sound) {
    return [[NSBundle mainBundle] URLForResource:sound withExtension:@"m4a"];
}

static NSInteger kDMMGameTimer  = 3.5;
static double kDMMGameDecayRate = 0.015;
static double kDMMMusicIncreaseRate = 0.01;

double TimerDurationForCount(NSInteger gameCount) {
    return kDMMGameTimer * pow(1-kDMMGameDecayRate, (double)gameCount);
}

double MusicRateForGameCount(NSInteger gameCount) {
    return 1 * pow(1+kDMMMusicIncreaseRate, (double)gameCount);
}

@implementation DMMTapItViewController

#pragma mark - View Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addGestureRecognizer:self.tapGesture];
    [self.view addGestureRecognizer:self.swipeGesture];
    self.actionLabel.hidden = YES;
}

#pragma mark - Getters
- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    }
    return _tapGesture;
}

- (UISwipeGestureRecognizer *)swipeGesture {
    if (!_swipeGesture) {
        _swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(viewSwipped:)];
        _swipeGesture.direction = (UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionUp);
    }
    return _swipeGesture;
}

- (AVSpeechSynthesizer *)syntesizer {
    if (!_syntesizer) {
        _syntesizer = [[AVSpeechSynthesizer alloc] init];
    }
    return _syntesizer;
}

- (AVSpeechSynthesisVoice *)voice {
    if (!_voice) {
        _voice = [AVSpeechSynthesisVoice voiceWithLanguage:[NSLocale currentLocale].localeIdentifier];
    }
    return _voice;
}

- (AVAudioPlayer *)music {
    if (!_music) {
        self.music = [[AVAudioPlayer alloc] initWithContentsOfURL:URLPathForSound(@"beat") error:nil];
        [self.music setNumberOfLoops:-1];
        self.music.enableRate = YES;
        [self.music prepareToPlay];
        [self.music setVolume:1.00];
    }
    return _music;
}

- (AVAudioPlayer *)tapSoundEffect {
    if (!_tapSoundEffect) {
        _tapSoundEffect = [[AVAudioPlayer alloc] initWithContentsOfURL:URLPathForSound(@"tap") error:nil];
        [_tapSoundEffect prepareToPlay];
    }
    return _tapSoundEffect;
}

- (AVAudioPlayer *)swipeSoundEffect {
    if (!_swipeSoundEffect) {
        _swipeSoundEffect = [[AVAudioPlayer alloc] initWithContentsOfURL:URLPathForSound(@"swipe") error:nil];
        [_swipeSoundEffect prepareToPlay];
    }
    return _swipeSoundEffect;
}

- (AVAudioPlayer *)whipSoundEffect {
    if (!_whipSoundEffect) {
        _whipSoundEffect = [[AVAudioPlayer alloc] initWithContentsOfURL:URLPathForSound(@"whip") error:nil];
        [_whipSoundEffect prepareToPlay];
    }
    return _whipSoundEffect ;
}

- (AVAudioPlayer *)endSoundEffect {
    if (!_endSoundEffect) {
        _endSoundEffect = [[AVAudioPlayer alloc] initWithContentsOfURL:URLPathForSound(@"end") error:nil];
        [_endSoundEffect prepareToPlay];
    }
    return _endSoundEffect;
}

#pragma mark - Setters
- (void)setGameCount:(NSInteger)gameCount {
    _gameCount = gameCount;
    if (gameCount >= 0) {
        self.countLabel.text = [NSString stringWithFormat:@"%li", (long)_gameCount];
        self.countLabel.transform = CGAffineTransformMakeScale(1.5, 1.5);
        [UIView animateWithDuration:0.3 animations:^{
            self.countLabel.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)setPlaying:(BOOL)playing {
    self.actionLabel.hidden     = !playing;
    self.startGameButton.hidden = playing;
    _playing = playing;
}

- (void)setAction:(DMMTapItAction *)action {
    _action = action;
    self.actionLabel.text = action.actionString;
    self.view.backgroundColor = action.color;
}

#pragma mark - SomethingElse
- (NSTimer *)gameTimerWithDuration:(NSTimeInterval)duration {
    NSTimer *timer = [NSTimer timerWithTimeInterval:(duration) target:self selector:@selector(timerExpired:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    return timer;
}

- (void)speakUtteranceForAction:(DMMTapItAction *) action {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:action.actionString];
    [self speakUtterance:utterance];
}

- (void)speakUtterance:(AVSpeechUtterance *)utterance {
    utterance.voice = self.voice;
    utterance.rate = 0.3;
    [self.syntesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.syntesizer speakUtterance:utterance];
}

#pragma mark - Core Motion
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake && self.action.gameAction == DMMTapItGameActionWhip) {
        NSLog(@"Baby Shaken");
        [self.whipSoundEffect play];
        [self nextAction];
    } else {
        [self endGame];
    }
}

#pragma mark - Gesture Recognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return [self.gameTimer isValid];
}

#pragma mark - Actions
- (void)timerExpired:(id)sender {
    [self endGame];
}

- (void)viewTapped:(UITapGestureRecognizer *)gesture {
    if (self.action.gameAction == DMMTapItGameActionTap) {
        NSLog(@"View Swipped at %@", NSStringFromCGPoint([gesture locationInView:self.view]));
        if (![self.tapSoundEffect play]) {
            NSLog(@"Failed to play");
        }
        [self nextAction];
    } else {
        [self endGame];
    }
}

- (void)viewSwipped:(UISwipeGestureRecognizer *)gesture {
    if (self.action.gameAction == DMMTapItGameActionSwipe) {
        NSLog(@"View Swipped at %@", NSStringFromCGPoint([gesture locationInView:self.view]));
        [self.swipeSoundEffect play];
        [self nextAction];
    } else {
        [self endGame];
    }
}

#pragma mark - AVAudioPlayerDelegate
//- (void)beginInterruption {
//
//}
//
//- (void)endInterruption {
//
//}

#pragma mark - Game Methods
- (void)startGame
{
    self.playing = YES;

    if (self.gameTimer) { [self.gameTimer invalidate]; }
    self.view.backgroundColor = [UIColor whiteColor];
    self.gameCount = -1;
    [self nextAction];

    [self.music play];
}

- (void)endGame {
    [self.gameTimer invalidate];
    [self.endSoundEffect play];
    self.playing = NO;
    self.view.backgroundColor = [UIColor magentaColor];
    [self.music stop];
    [self.syntesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

- (void)nextAction {
    [self.gameTimer invalidate];
    self.gameCount++;
    self.gameTimer = [self gameTimerWithDuration:TimerDurationForCount(self.gameCount)];
    self.music.rate = MusicRateForGameCount(self.gameCount);

    DMMTapItGameAction lastAction = self.action.gameAction;
    self.action = [DMMTapItAction generateRandomAction];
    //        self.action = [DMMTapItAction actionWithGameAction:DMMTapItGameActionTap];
    if (lastAction == DMMTapItGameActionWhip
        && self.action.gameAction == DMMTapItGameActionWhip) {
        [self speakUtterance:[AVSpeechUtterance speechUtteranceWithString:NSLocalizedString(@"Whip it good", @"whip it good")]];
    } else {
        [self speakUtteranceForAction:self.action];
    }
}

#pragma mark - IBActions
- (IBAction)startGameButtonPressed:(UIButton *)sender {
    [self startGame];
}

@end
