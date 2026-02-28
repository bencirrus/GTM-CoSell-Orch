//
//  ContentView.swift
//  StretchTimer Watch App
//
//  Created by Ben Cirrus on 10/25/25.
//

import SwiftUI
import WatchKit
import Combine
import AVFoundation

struct ContentView: View {
    // Settings (persisted across launches)
    @AppStorage("holdSeconds") private var holdSeconds: Int = 30 // default for holding stretch
    @AppStorage("shiftSeconds") private var shiftSeconds: Int = 10 // default for shifting position
    @AppStorage("announceEnabled") private var announceEnabled: Bool = true // announce phase changes

    // Timer state
    @State private var isRunning = false
    @State private var isHoldPhase = true
    @State private var remainingTime: Int = 30
    @StateObject private var speechSynthesizer = SpeechSynthesizer()

    // Timer publisher
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var backgroundTimer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 2) {
                VStack(spacing: 2) {
                    HStack {
                        Text("hold stretch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(holdSeconds)s")
                            .font(.caption2)
                    }

                    Stepper(value: $holdSeconds, in: 5...600, step: 5) {
                        Text(holdSecondsString)
                            .font(.headline)
                    }
                    .disabled(isRunning)
                }

                VStack(spacing: 2) {
                    HStack {
                        Text("shift position")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(shiftSeconds)s")
                            .font(.caption2)
                    }

                    Stepper(value: $shiftSeconds, in: 5...600, step: 5) {
                        Text(shiftSecondsString)
                            .font(.headline)
                    }
                    .disabled(isRunning)
                }

                // Announcements toggle (persisted)
                HStack {
                    Toggle(isOn: $announceEnabled) {
                        Text("Announcements")
                            .font(.caption2)
                    }
                }

                Divider()

                // Countdown row: label on the left, counter on the right to save vertical space
                // Center the label+counter as a compact group; use larger fixed widths for better visibility on small watch faces
                HStack(spacing: 5) {
                    Text(isRunning ? (isHoldPhase ? "Holding" : "Shifting") : "Ready")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 88, alignment: .leading)

                    Text(formattedTime(remainingTime))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 88, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)

                HStack(spacing: 12) {
                    if !isRunning {
                        Button(action: startSequence) {
                            Text("Start")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    } else {
                        Button(action: endSequence) {
                            Text("End")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            .padding()
            .onAppear {
                // Initialize remaining time to the hold seconds default
                remainingTime = max(5, holdSeconds)
            }
            .onReceive(timer) { _ in
                guard isRunning else { return }
                tick()
            }
            // If the user changes the hold duration while not running, update remainingTime so UI reflects new selection
            .onChange(of: holdSeconds) { _, newValue in
                if !isRunning {
                    remainingTime = max(5, newValue)
                }
            }
        }
    }

    // MARK: - UI helpers
    private var holdSecondsString: String {
        String(format: "Hold: %d s", holdSeconds)
    }

    private var shiftSecondsString: String {
        String(format: "Shift: %d s", shiftSeconds)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        } else {
            return String(format: "%d", secs)
        }
    }

    // MARK: - Timer control
    private func startSequence() {
        // Prevent invalid durations
        let h = max(5, holdSeconds)
        let s = max(5, shiftSeconds)
        holdSeconds = h
        shiftSeconds = s

        isHoldPhase = true
        remainingTime = holdSeconds
        isRunning = true
        
        // Create background timer to prevent app suspension when display dims
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Keep the app alive even when display is off
        }
        
        // Announce the starting phase
        if announceEnabled { announce(isHold: true) }
    }

    private func endSequence() {
        isRunning = false
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }

    private func tick() {
        if remainingTime > 0 {
            remainingTime -= 1
        }

        if remainingTime <= 0 {
            // Play haptic/beep depending on phase
            triggerHaptic(isHold: isHoldPhase)

            // Switch phase and reset remainingTime
            if isHoldPhase {
                isHoldPhase = false
                remainingTime = shiftSeconds
                // Announce shift position phase start
                if announceEnabled { announce(isHold: false) }
            } else {
                isHoldPhase = true
                remainingTime = holdSeconds
                // Announce hold stretch phase start
                if announceEnabled { announce(isHold: true) }
            }
        }
    }

    private func triggerHaptic(isHold: Bool) {
        // Use different haptic patterns to distinguish the two intervals.
        let device = WKInterfaceDevice.current()
        if isHold {
            // Hold stretch finished - short sharp haptic
            device.play(.directionUp)
        } else {
            // Shift position finished - different haptic
            device.play(.directionDown)
        }
    }

    // Announce text for accessibility on watchOS using speech (AVSpeechSynthesizer).
    private func announce(isHold: Bool) {
        let message = isHold ? "Hold stretch" : "Shift position"
        speechSynthesizer.speak(message)
    }
}

// MARK: - Speech Synthesizer
class SpeechSynthesizer: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetoothHFP])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func speak(_ message: String) {
        DispatchQueue.main.async {
            let utterance = AVSpeechUtterance(string: message)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.volume = 1.0
            self.synthesizer.speak(utterance)
        }
    }
}

#Preview {
    ContentView()
}

