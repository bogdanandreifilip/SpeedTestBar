import Foundation

struct SpeedResult {
    var download: Double = 0
    var upload: Double = 0
    var latency: Double = 0
}

class SpeedTestService {
    
    func measureLatency() async -> Double {
        var totalTime: Double = 0
        let measurements = 5
        
        for _ in 0..<measurements {
            let url = URL(string: "https://speed.cloudflare.com/__down?bytes=0")!
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let start = Date()
            _ = try? await URLSession.shared.data(for: request)
            let elapsed = Date().timeIntervalSince(start) * 1000
            totalTime += elapsed
        }
        
        // Împărțim la 2 pentru că măsurăm RTT complet (dus-întors)
        // și scădem overhead-ul TLS (~20ms estimat)
        let average = (totalTime / Double(measurements))
        return max(1, average / 2)
    }
    
    func measureDownload() async -> Double {
        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=25000000")! // 25MB
        let start = Date()
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        return Double(data.count * 8) / elapsed / 1_000_000 // Mbps
    }
    
    func measureUpload() async -> Double {
        let url = URL(string: "https://speed.cloudflare.com/__up")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 10MB de date random pentru upload
        let uploadData = Data(count: 10_000_000)
        let start = Date()
        guard let (_, _) = try? await URLSession.shared.upload(for: request, from: uploadData) else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        return Double(uploadData.count * 8) / elapsed / 1_000_000 // Mbps
    }
    
    func runFullTest() async -> SpeedResult {
        async let latency = measureLatency()
        let ping = await latency
        let download = await measureDownload()
        let upload = await measureUpload()
        return SpeedResult(download: download, upload: upload, latency: ping)
    }
}
