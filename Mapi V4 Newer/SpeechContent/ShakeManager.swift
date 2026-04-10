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
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let total = abs(data.acceleration.x)
                      + abs(data.acceleration.y)
                      + abs(data.acceleration.z)
            // Umbral: 2.5g detecta un agite claro sin dispararse con movimiento normal
            if total > 2.5 {
                let now = Date()
                // Cooldown de 1.5s para no disparar múltiples veces
                if now.timeIntervalSince(self.lastShakeTime) > 1.5 {
                    self.lastShakeTime = now
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    self.onShake?()
                }
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}
