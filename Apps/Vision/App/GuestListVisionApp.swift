import SwiftUI

@main
struct GuestListVisionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 100))
                .foregroundStyle(.blue)

            Text("GuestList")
                .font(.extraLargeTitle)
                .fontWeight(.bold)

            Text("visionOS App")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("Coming Soon")
                .font(.body)
                .padding(.top)
        }
        .padding(50)
    }
}

#Preview {
    ContentView()
}
