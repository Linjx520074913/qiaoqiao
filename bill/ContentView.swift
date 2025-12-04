//
//  ContentView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        MainTabView()
            .environmentObject(appState)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
