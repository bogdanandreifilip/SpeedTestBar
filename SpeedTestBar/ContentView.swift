import SwiftUI
import ServiceManagement

struct ContentView: View {
    @State private var result = SpeedResult()
    @State private var isTesting = false
    @State private var status = "Click to run a network speed test"
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    @AppStorage("showDownloadInMenuBar") private var showDownload = false
    @AppStorage("showUploadInMenuBar") private var showUpload = false
    @AppStorage("showPingInMenuBar") private var showPing = false
    
    @AppStorage("autoRunInterval") private var autoRunInterval = "15"
    @AppStorage("autoRunUnit") private var autoRunUnit = "Minutes"
    @AppStorage("isAutoRunActive") private var isAutoRunActive = false
    @State private var autoRunTask: Task<Void, Never>? = nil
    
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
            
            Text("Menu Bar Display")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack {
                Toggle("DL", isOn: $showDownload)
                Toggle("UL", isOn: $showUpload)
                Toggle("Ping", isOn: $showPing)
            }
            .toggleStyle(.checkbox)
            .font(.caption)
            .onChange(of: showDownload) { _ in notifyTitleUpdate() }
            .onChange(of: showUpload) { _ in notifyTitleUpdate() }
            .onChange(of: showPing) { _ in notifyTitleUpdate() }

            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Auto-Run Every")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("15", text: $autoRunInterval)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                    
                    Picker("", selection: $autoRunUnit) {
                        Text("Sec").tag("Seconds")
                        Text("Min").tag("Minutes")
                    }
                    .pickerStyle(.segmented)
                    
                    Button(action: toggleAutoRun) {
                        Image(systemName: isAutoRunActive ? "stop.circle.fill" : "play.circle.fill")
                            .foregroundColor(isAutoRunActive ? .red : .green)
                    }
                    .buttonStyle(.plain)
                    .font(.title2)
                }
            }

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
        .onAppear {
            if isAutoRunActive {
                startAutoRunLogic()
            }
        }
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
            
            // Save results for the Menu Bar to read
            UserDefaults.standard.set(result.download, forKey: "lastDownload")
            UserDefaults.standard.set(result.upload, forKey: "lastUpload")
            UserDefaults.standard.set(result.latency, forKey: "lastPing")
            
            status = "Finished Test ✓"
            isTesting = false
            
            notifyTitleUpdate()
        }
    }
    
    private func notifyTitleUpdate() {
        NotificationCenter.default.post(name: NSNotification.Name("UpdateMenuBarTitle"), object: nil)
    }
    
    func toggleAutoRun() {
        isAutoRunActive.toggle()
        if isAutoRunActive {
            startAutoRunLogic()
        } else {
            autoRunTask?.cancel()
            autoRunTask = nil
        }
    }
    
    private func startAutoRunLogic() {
        autoRunTask?.cancel()
        autoRunTask = Task {
            while !Task.isCancelled {
                if !isTesting {
                    startTest()
                }
                
                let intervalValue = Double(autoRunInterval) ?? 15
                let seconds = autoRunUnit == "Minutes" ? intervalValue * 60 : intervalValue
                
                try? await Task.sleep(nanoseconds: UInt64(max(1, seconds) * 1_000_000_000))
            }
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
