//
//  DetailView.swift
//  StretchTimer
//
//  Created by Ben Cirrus on 10/25/25.
//

import SwiftUI

struct DetailView: View {
    @State private var counter = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("Detail Counter: \(counter)")
                .font(.headline)

            Button("Increment Here") {
                counter += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    DetailView()
}
