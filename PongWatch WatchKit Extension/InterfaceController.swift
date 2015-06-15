//
//  InterfaceController.swift
//  PongWatch WatchKit Extension
//
//  Created by Andrew H on 6/11/15.
//  Copyright © 2015 Andrew H. All rights reserved.
//

/* 

This game should:
- Have two moving paddles, one for the player and another autonomous computer one
- Have a ball that bounces off walls and paddles in a dynamic, interesting, and realistic way
- Keep score. Player vs. Computer. 1pt per ball missed by opponent. Score shown on top of screen (?)
- Render quickly allowing for at least 60 FPS

--------

TODO:
- Dynamiclly bounce off the paddles depending on the position of the ball bounce relative to the center of the paddle.
- Keep score
- App icon
- Rounded paddles (?)

*/

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var interfaceImage: WKInterfaceImage?;
    @IBOutlet var picker: WKInterfacePicker?;
    
    let numPickerIndicies = 50;
    let paddleHeight = CGFloat(40.0);
    let paddleWidth = CGFloat(10.0);
    let ballRadius = CGFloat(5.0);
    
    var paddleY = CGFloat(20);
    var compY = CGFloat(20);
    
    var ballLoc = CGPointZero;
    var ballVelocity = CGVector(dx: 1.0, dy: 1.0); // points per frame
    
    var compMaxSpeed = CGFloat(0.65); // points per frame
    
    let FPS = 60.0;
    
    var timer: NSTimer?;

    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        print("test");
        // Configure interface objects here.
        
        ballLoc = CGPoint(x: CGRectGetMidX(contentFrame), y: CGRectGetMidY(contentFrame));
        
        // Give the picker some empty items to show
        let item = WKPickerItem();
        item.title = "";
        
        // Make an array of a bunch of these items
        var arr = [WKPickerItem]();
        for _ in 1...numPickerIndicies {
            arr.append(item);
        }
        
        picker!.setItems(arr);
        
        // Do a render to get stuff on the screen
        renderTheStuffs(nil);
        
        // Setup the timer
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0/FPS, target: self, selector: "renderTheStuffs:", userInfo: nil, repeats: true);
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func crownSpin(index: Int) {
        paddleY = (CGFloat(index) / CGFloat(numPickerIndicies-1)) * contentFrame.height-paddleHeight + CGFloat(paddleHeight)/2.0;
        print(index);
    }
    
    func renderTheStuffs(timer: NSTimer?) {
        // Do some physics
        physicsTick();
        
        // Setup the graphics context
        UIGraphicsBeginImageContext(contentFrame.size);
        let ctx = UIGraphicsGetCurrentContext();
        
        // Fill the whole thing with black to start
        CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 1.0);
        CGContextFillRect(ctx, CGRect(origin: CGPointZero, size: contentFrame.size));
        
        // Draw a white outline around the game
        CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 1.0);
        CGContextStrokeRect(ctx, CGRect(origin: CGPointZero, size: contentFrame.size));
        
        // Draw the player paddle
        CGContextSetRGBFillColor(ctx, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(ctx, CGRect(x: contentFrame.width - paddleWidth, y: paddleY - paddleHeight/2.0, width: paddleWidth, height: paddleHeight))
        
        // Draw the computer paddle
        CGContextFillRect(ctx, CGRect(x: 0, y: compY - paddleHeight/2.0, width: paddleWidth, height: paddleHeight));
        
        // Draw the ball
        CGContextFillEllipseInRect(ctx, CGRect(x: ballLoc.x - ballRadius, y: ballLoc.y - ballRadius, width: ballRadius*2, height: ballRadius*2));
        
        // Save the state - not sure if necessary
        CGContextSaveGState(ctx);
        
        // Get a UIImage of the current context state
        let img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // Show the image on the screen
        interfaceImage!.setImage(img);
    }
    
    func physicsTick() {
        
        ballLoc.x += ballVelocity.dx;
        ballLoc.y += ballVelocity.dy;
        
        // Move the computer paddle according to the ball's position, but not faster than the max speed
        if (ballLoc.y >= compY) {
            compY += min(ballLoc.y - compY, compMaxSpeed);
        } else {
            compY -= min(compY - ballLoc.y, compMaxSpeed);
        }
        
        // Make sure we didn't move the paddle beyond the screen
        if (compY > contentFrame.height - paddleHeight/2.0) {
            compY = contentFrame.height - paddleHeight/2.0;
        } else if (compY < paddleHeight/2.0) {
            compY = paddleHeight/2.0;
        }
        
        // Check the ball bounderies
        boundryCheck();
    }
    
    func boundryCheck() {
        let ballTopside = ballLoc.y - ballRadius;
        let ballBottomside = ballLoc.y + ballRadius;
        let ballRightside = ballLoc.x + ballRadius;
        let ballLeftside = ballLoc.x - ballRadius;
        
        let compTopside = compY - paddleHeight/2;
        let compBottomside = compY + paddleHeight/2
        
        let playerTopside = paddleY - paddleHeight/2;
        let playerBottomside = paddleY + paddleHeight/2
        
        // Top/Bottom screen boundries
        // If the ball is moving away from the boundry then don't bother touching anything
        if (ballTopside <= 0.0 && ballVelocity.dy < 0) || (ballBottomside >= contentFrame.height && ballVelocity.dy > 0) {
            ballVelocity.inverseVectorY();
            ballLoc.y += ballVelocity.dy;
            print("yboundery - new vector: \(ballVelocity)");
            return;
        }
        
        // Paddle boundries
        if (ballLeftside <= paddleWidth && ballVelocity.dx < 0 && ballBottomside > compTopside && ballTopside < compBottomside) || (ballRightside >= contentFrame.width - paddleWidth && ballVelocity.dx > 0 && ballBottomside > playerTopside && ballTopside < playerBottomside) {
            ballVelocity.inverseVectorX();
            ballLoc.x += ballVelocity.dx;
            print("paddleboundery - new vector: \(ballVelocity)");
        }
        
        // Left/Right screen boundries
        if (ballLoc.x - ballRadius <= 0.0) || (ballLoc.x + ballRadius >= contentFrame.width) {
            ballVelocity.inverseVectorX();
            ballLoc.x += ballVelocity.dx;
            print("xBoundery - new vector: \(ballVelocity)");
        }
        
        
    }
    
    // TODO: This shouldn't break everything
    func testBallMovingToCorner() {
        ballLoc = CGPoint(x: 1, y: 1);
        ballVelocity = CGVector(dx: -1.0, dy: -1.0);
        boundryCheck();
        
    }

}
