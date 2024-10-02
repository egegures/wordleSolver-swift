//
//  wordleSolverApp.swift
//  wordleSolver
//
//  Created by Ege Gures on 2024-09-23.
//

import SwiftUI

@main
struct wordleSolverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onDisappear() {
                    NSApplication.shared.terminate(nil)
                }
        }
    }
}
