//
//  ViewController.swift
//  colona-clone-master
//
//  Created by ota42y on 2015/12/23.
//  Copyright © 2015年 ota42y. All rights reserved.
//

import UIKit

enum Mode {
    case Wait
    case TrainingWait
    case Training
}

class ViewController: UIViewController {
    @IBOutlet weak var trainingButton: UIButton!
    @IBOutlet weak var analyzeButton: UIButton!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var trainingStartButton: UIButton!

    var mode = Mode.Wait
    var nowPoint: CGPoint!
    var nowPointImageView: UIImageView!
    var connector = BluetoothConnector()

    override func viewDidLoad() {
        super.viewDidLoad()

        connector.createManager()

        nowPoint = CGPoint.zero;

        let img:UIImage?  = UIImage(named: "blue.png")
        nowPointImageView = UIImageView(image: img)
        view.addSubview(nowPointImageView)
        nowPointImageView.hidden = true

        trainingButton.addTarget(self, action: "onClickTrainingButton:", forControlEvents: .TouchUpInside)

        trainingStartButton.addTarget(self, action: "onClickTrainingStartButton:", forControlEvents: .TouchUpInside)
        disableTrainingStartButton()
    }

    internal func enableTrainingStartButton() {
        trainingStartButton.enabled = true
        trainingStartButton.hidden = false
    }

    internal func disableTrainingStartButton() {
        trainingStartButton.enabled = false
        trainingStartButton.hidden = true
    }

    internal func showNowTrainingPoint() {
        nowPointImageView.center = nowPoint
        nowPointImageView.hidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (mode == Mode.TrainingWait) {
            if let touch = touches.first {
                nowPoint = touch.locationInView(view)
                showNowTrainingPoint()
                enableTrainingStartButton()
            }
        }
    }

    internal func onClickTrainingStartButton(sender: UIButton) {
        if (mode == Mode.TrainingWait) {
            disableTrainingStartButton()
            trainingButton.enabled = false

            mainLabel.text = "training..."
            mode = Mode.Training

            connector.connectionStart()
        }
    }

    internal func onClickTrainingButton(sender: UIButton){
        if (mode == Mode.Wait) {
            // init training
            initTrainingMode();
        } else {
            // end training
            analyzeButton.enabled = true;
            mainLabel.text = "touch training button or ";
        }
    }

    internal func initTrainingMode() {
        mode = Mode.TrainingWait

        analyzeButton.enabled = false;
        mainLabel.text = "touch training point and set iphone";
        trainingButton.setTitle("end training", forState: UIControlState.Normal)
    }


}

