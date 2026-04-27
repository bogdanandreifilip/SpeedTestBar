import SwiftUI
import ServiceManagement

struct ContentView: View {
    @State private var result = SpeedResult()
    @State private var isTesting = false
    @State private var status = "Click to run a network speed test"
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    let service = SpeedTestService()

    var body: some View {
        VStack(spacing: 14) {
            Text("🌐 Speed Test")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatView(label: "Download", value: result.download, unit: "Mbps", color: .green)
                StatView(label: "Upload", value: result.upload, unit: "Mbps", color: .blue)
                StatView(label: "Ping", value: result.latency, unit: "ms", color: .orange)
            }
            
            Text(status)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: startTest) {
                Text(isTesting ? "Testing ..." : "Run speed test")
                    .frame(maxWidth: .infinity)
            }
            .disabled(isTesting)
            .buttonStyle(.borderedProminent)

            Divider()
                .padding(.vertical, 4)

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    do {
                        if newValue && SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
                        else if !newValue && SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
                    } catch {
                        print("Launch at login error: \(error)")
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
            .font(.caption)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .padding()
        .frame(width: 260)
    }
    
    func startTest() {
        isTesting = true
        status = "Running..."
        result = SpeedResult()
        
        Task {
            status = "Ping..."
            let ping = await service.measureLatency()
            result.latency = ping
            
            status = "Download..."
            let dl = await service.measureDownload()
            result.download = dl
            
            status = "Upload..."
            let ul = await service.measureUpload()
            result.upload = ul
            
            status = "Finished Test ✓"
            isTesting = false
        }
    }
}

struct StatView: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value > 0 ? String(format: "%.1f", value) : "—")
                .font(.title3)
                .bold()
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
