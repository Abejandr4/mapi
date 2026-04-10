//
//  ShakeManager.swift
//  SpeechContent
//
//  Created by iOS Lab on 08/04/26.
//
import CoreMotion
import UIKit

class ShakeManager {
    static let shared = ShakeManager()
    private let motionManager = CMMotionManager()
    private var onShake: (() -> Void)?
    private var lastShakeTime: Date = .distantPast

    func start(onShake: @escaping () -> Void) {
        self.onShake = onShake
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.05
        
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self, let data else { return }
            let total = abs(data.acceleration.x)
                      + abs(data.acceleration.y)
                      + abs(data.acceleration.z)
            if total > 2.5 {
                let now = Date()
                if now.timeIntervalSince(self.lastShakeTime) > 1.5 {
                    self.lastShakeTime = now
                    DispatchQueue.main.async {
                        self.onShake?()
                    }
                }
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}
