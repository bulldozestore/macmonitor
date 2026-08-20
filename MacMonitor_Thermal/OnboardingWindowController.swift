import Cocoa

class OnboardingWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x:0, y:0, width:620, height:610),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacMonitor"
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        self.init(window: window)
        window.contentViewController = OnboardingViewController()
    }
}

class OnboardingViewController: NSViewController {

    var memLabel: NSTextField?
    var diskLabel: NSTextField?
    var battLabel: NSTextField?
    var memBar: NSView?
    var diskBar: NSView?

    override func loadView() {
        let v = NSView(frame: NSRect(x:0, y:0, width:620, height:610))

        // ── Footer ──
        let footer = NSView(frame: NSRect(x:0, y:0, width:620, height:72))
        footer.wantsLayer = true
        footer.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.04).cgColor
        v.addSubview(footer)

        let ghIconView = NSImageView(frame: NSRect(x:16, y:20, width:32, height:32))
        ghIconView.image = Self.makeGitHubIcon(size: 32)
        ghIconView.contentTintColor = .secondaryLabelColor
        footer.addSubview(ghIconView)

        let ghMain = NSTextField(labelWithString: L("open_source_label"))
        ghMain.font = .systemFont(ofSize:12)
        ghMain.textColor = .secondaryLabelColor
        ghMain.frame = NSRect(x:56, y:40, width:340, height:16)
        footer.addSubview(ghMain)

        let ghLink = NSTextField(labelWithString:"github.com/goiascontab-ui/macmonitor")
        ghLink.font = .systemFont(ofSize:12, weight:.semibold)
        ghLink.textColor = .systemBlue
        ghLink.frame = NSRect(x:56, y:20, width:340, height:16)
        footer.addSubview(ghLink)

        let ghBtn = NSButton(title:"", target:self, action:#selector(openGitHub))
        ghBtn.frame = NSRect(x:56, y:16, width:340, height:40)
        ghBtn.isBordered = false
        footer.addSubview(ghBtn)

        // Shield badge
        let shield = NSView(frame: NSRect(x:488, y:10, width:116, height:52))
        shield.wantsLayer = true
        shield.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.1).cgColor
        shield.layer?.cornerRadius = 8
        shield.layer?.borderWidth = 1
        shield.layer?.borderColor = NSColor.systemGreen.withAlphaComponent(0.3).cgColor
        footer.addSubview(shield)

        let shieldEmoji = NSTextField(labelWithString:"🛡️")
        shieldEmoji.font = .systemFont(ofSize:16)
        shieldEmoji.frame = NSRect(x:8, y:28, width:24, height:22)
        shield.addSubview(shieldEmoji)

        let shieldLbl = NSTextField(wrappingLabelWithString:"Open Source\nMIT License\nAuditable & Trusted")
        shieldLbl.font = .systemFont(ofSize:8.5, weight:.semibold)
        shieldLbl.textColor = .systemGreen
        shieldLbl.frame = NSRect(x:34, y:6, width:78, height:42)
        shield.addSubview(shieldLbl)

        // ── Botão ──
        let btn = NSButton(frame: NSRect(x:40, y:82, width:540, height:44))
        btn.title = L("onboarding_btn")
        btn.bezelStyle = .rounded
        btn.font = .systemFont(ofSize:15, weight:.semibold)
        btn.target = self
        btn.action = #selector(done)
        btn.keyEquivalent = "\r"
        v.addSubview(btn)

        // ── Cards — linha inferior (Disco + Bateria) ──
        buildDiskCard(v, x:30, y:140)
        buildBattCard(v, x:320, y:140)

        // ── Cards — linha superior (Processador + Memória) ──
        buildProcessorCard(v, x:30, y:294)
        buildMemCard(v, x:320, y:294)

        // ── Separador ──
        let sep = NSBox(frame: NSRect(x:30, y:450, width:560, height:1))
        sep.boxType = .separator
        v.addSubview(sep)

        // ── Header ──
        let sub = NSTextField(labelWithString: L("onboarding_subtitle"))
        sub.font = .systemFont(ofSize:13)
        sub.textColor = .secondaryLabelColor
        sub.alignment = .center
        sub.frame = NSRect(x:20, y:466, width:580, height:18)
        v.addSubview(sub)

        let title = NSTextField(labelWithString: L("onboarding_running"))
        title.font = .boldSystemFont(ofSize:24)
        title.alignment = .center
        title.frame = NSRect(x:20, y:494, width:580, height:32)
        v.addSubview(title)

        let iconView = NSImageView(frame: NSRect(x:271, y:522, width:76, height:76))
        if let img = NSImage(systemSymbolName:"checkmark.circle.fill", accessibilityDescription:nil) {
            iconView.image = img.withSymbolConfiguration(
                NSImage.SymbolConfiguration(pointSize:56, weight:.regular, scale:.large))
        }
        iconView.contentTintColor = NSColor(calibratedRed:0.2, green:0.78, blue:0.35, alpha:1.0)
        v.addSubview(iconView)

        self.view = v

        DispatchQueue.main.asyncAfter(deadline:.now()+0.6){ [weak self] in self?.refreshData() }
    }

    // MARK: - Cards

    func buildProcessorCard(_ parent:NSView, x:CGFloat, y:CGFloat) {
        let card = makeCard(x:x, y:y, w:270, h:144, parent:parent)
        makeCardHeader("thermometer.medium", label: L("label_processor"), card:card)
        let states: [(String,NSColor)] = [
            ("● \(L("thermal_normal"))",   .systemGreen),
            ("● \(L("thermal_warm"))",     NSColor(calibratedRed:1.0,green:0.58,blue:0.0,alpha:1)),
            ("● \(L("thermal_hot"))",      NSColor(calibratedRed:1.0,green:0.35,blue:0.0,alpha:1)),
            ("● \(L("thermal_critical"))", .systemRed)
        ]
        var bx: CGFloat = 12
        for (lbl, color) in states {
            let b = NSTextField(labelWithString:lbl)
            b.font = .systemFont(ofSize:10, weight:.semibold)
            b.textColor = color
            let w = CGFloat(lbl.count)*7+6
            b.frame = NSRect(x:bx, y:14, width:w, height:22)
            b.wantsLayer = true
            b.layer?.backgroundColor = color.withAlphaComponent(0.12).cgColor
            b.layer?.cornerRadius = 4
            card.addSubview(b)
            bx += w+8
        }
    }

    func buildMemCard(_ parent:NSView, x:CGFloat, y:CGFloat) {
        let card = makeCard(x:x, y:y, w:270, h:144, parent:parent)
        makeCardHeader("memorychip", label: L("label_memory"), card:card)

        let bigVal = NSTextField(labelWithString:"--")
        bigVal.font = .boldSystemFont(ofSize:32)
        bigVal.frame = NSRect(x:14, y:64, width:200, height:38)
        card.addSubview(bigVal)
        memLabel = bigVal

        let barBg = NSView(frame:NSRect(x:14, y:52, width:242, height:6))
        barBg.wantsLayer=true; barBg.layer?.backgroundColor=NSColor.quaternaryLabelColor.cgColor; barBg.layer?.cornerRadius=3
        card.addSubview(barBg)
        let barFg = NSView(frame:NSRect(x:0,y:0,width:0,height:6))
        barFg.wantsLayer=true; barFg.layer?.backgroundColor=NSColor.systemBlue.cgColor; barFg.layer?.cornerRadius=3
        barBg.addSubview(barFg); memBar=barFg

        makeSmallLabel(L("card_memory_sub"), card:card, y:32)
    }

    func buildDiskCard(_ parent:NSView, x:CGFloat, y:CGFloat) {
        let card = makeCard(x:x, y:y, w:270, h:144, parent:parent)
        makeCardHeader("internaldrive.fill", label: L("label_disk"), card:card)

        let bigVal = NSTextField(labelWithString:"--")
        bigVal.font = .boldSystemFont(ofSize:26)
        bigVal.frame = NSRect(x:14, y:66, width:242, height:32)
        card.addSubview(bigVal)
        diskLabel = bigVal

        let barBg = NSView(frame:NSRect(x:14, y:54, width:242, height:6))
        barBg.wantsLayer=true; barBg.layer?.backgroundColor=NSColor.quaternaryLabelColor.cgColor; barBg.layer?.cornerRadius=3
        card.addSubview(barBg)
        let barFg = NSView(frame:NSRect(x:0,y:0,width:0,height:6))
        barFg.wantsLayer=true; barFg.layer?.backgroundColor=NSColor.systemOrange.cgColor; barFg.layer?.cornerRadius=3
        barBg.addSubview(barFg); diskBar=barFg

        makeSmallLabel(L("card_disk_sub"), card:card, y:32)
    }

    func buildBattCard(_ parent:NSView, x:CGFloat, y:CGFloat) {
        let card = makeCard(x:x, y:y, w:270, h:144, parent:parent)
        makeCardHeader("battery.75", label: L("label_battery"), card:card)

        let bigVal = NSTextField(labelWithString:"--")
        bigVal.font = .boldSystemFont(ofSize:32)
        bigVal.frame = NSRect(x:14, y:62, width:242, height:38)
        card.addSubview(bigVal)
        battLabel = bigVal

        makeSmallLabel(L("card_battery_sub"), card:card, y:36)
    }

    // MARK: - Helpers

    @discardableResult
    func makeCard(x:CGFloat,y:CGFloat,w:CGFloat,h:CGFloat,parent:NSView)->NSView {
        let c=NSView(frame:NSRect(x:x,y:y,width:w,height:h))
        c.wantsLayer=true
        c.layer?.backgroundColor=NSColor.labelColor.withAlphaComponent(0.05).cgColor
        c.layer?.cornerRadius=12
        c.layer?.borderWidth=0.5
        c.layer?.borderColor=NSColor.labelColor.withAlphaComponent(0.1).cgColor
        parent.addSubview(c); return c
    }

    func makeCardHeader(_ symbol:String, label:String, card:NSView) {
        let icon=NSImageView(frame:NSRect(x:14,y:112,width:16,height:16))
        if let img=NSImage(systemSymbolName:symbol,accessibilityDescription:nil){
            icon.image=img.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize:11,weight:.medium,scale:.medium))
        }
        icon.contentTintColor = .secondaryLabelColor
        card.addSubview(icon)
        let lbl=NSTextField(labelWithString:label)
        lbl.font = .systemFont(ofSize:12,weight:.semibold)
        lbl.frame=NSRect(x:36,y:112,width:220,height:18)
        card.addSubview(lbl)
    }

    @discardableResult
    func makeSmallLabel(_ text:String, card:NSView, y:CGFloat)->NSTextField {
        let l=NSTextField(labelWithString:text)
        l.font = .systemFont(ofSize:10)
        l.textColor = .secondaryLabelColor
        l.frame=NSRect(x:14,y:y,width:242,height:14)
        card.addSubview(l); return l
    }

    // MARK: - Live data

    func refreshData() {
        var pageSize:vm_size_t=0; host_page_size(mach_host_self(),&pageSize)
        var stats=vm_statistics64()
        var count=mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size/MemoryLayout<integer_t>.size)
        _ = withUnsafeMutablePointer(to:&stats){ $0.withMemoryRebound(to:integer_t.self,capacity:Int(count)){
            host_statistics64(mach_host_self(),HOST_VM_INFO64,$0,&count)
        }}
        let total=ProcessInfo.processInfo.physicalMemory
        let used=(UInt64(stats.active_count)+UInt64(stats.wire_count)+UInt64(stats.compressor_page_count))*UInt64(pageSize)
        let pct=total>0 ? Double(used)/Double(total)*100 : 0
        memLabel?.stringValue=String(format:"%.0f%%",pct)
        if let bar=memBar, let bg=bar.superview {
            bar.frame=NSRect(x:0,y:0,width:bg.frame.width*(CGFloat(pct)/100),height:6)
        }

        var fs=statfs(); var path="/System/Volumes/Data"
        if statfs(path,&fs) != 0 { path="/"; _ = statfs(path,&fs) }
        let bsize=UInt64(fs.f_bsize)
        let dt=bsize*UInt64(fs.f_blocks); let df=bsize*UInt64(fs.f_bfree)
        let du=dt>df ? dt-df : 0
        let dp=dt>0 ? Double(du)/Double(dt)*100 : 0
        diskLabel?.stringValue=String(format:"%.0f GB / %.0f GB",Double(du)/1_073_741_824,Double(dt)/1_073_741_824)
        if let bar=diskBar, let bg=bar.superview {
            bar.frame=NSRect(x:0,y:0,width:bg.frame.width*(CGFloat(dp)/100),height:6)
        }

        if let blob=IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let list=IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
           let src=list.first,
           let info=IOPSGetPowerSourceDescription(blob,src)?.takeUnretainedValue() as? [String:Any] {
            let pct=info[kIOPSCurrentCapacityKey as String] as? Int ?? 0
            let charging=info[kIOPSIsChargingKey as String] as? Bool ?? false
            let mins=charging ? (info[kIOPSTimeToFullChargeKey as String] as? Int ?? -1)
                              : (info[kIOPSTimeToEmptyKey as String] as? Int ?? -1)
            battLabel?.stringValue = mins > 0 ? String(format:"%dh %02dmin",mins/60,mins%60) : String(format:"%d%%",pct)
        }
    }

    @objc func done() {
        view.window?.close()
        NotificationCenter.default.post(name:NSNotification.Name("OnboardingFinished"), object:nil)
    }
    @objc func openGitHub() {
        NSWorkspace.shared.open(URL(string:"https://github.com/goiascontab-ui/macmonitor")!)
    }

    // Official GitHub Invertocat mark — converted from SVG path (viewBox 98x96) to NSBezierPath
    static func makeGitHubIcon(size: CGFloat) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        NSColor.labelColor.setFill()
        let p = NSBezierPath()
        let s = size / 24.0
        func pt(_ x: Double, _ y: Double) -> NSPoint { NSPoint(x: x*s, y: y*s) }
        p.move(to: pt(11.964, 24.0))
        p.curve(to: pt(0.0, 11.696), controlPoint1: pt(5.348, 24.0), controlPoint2: pt(0.0, 18.5))
        p.curve(to: pt(8.181, 0.023), controlPoint1: pt(0.0, 6.257), controlPoint2: pt(3.427, 1.653))
        p.curve(to: pt(8.993, 0.614), controlPoint1: pt(8.775, -0.099), controlPoint2: pt(8.993, 0.288))
        p.curve(to: pt(8.973, 2.895), controlPoint1: pt(8.993, 0.899), controlPoint2: pt(8.973, 1.877))
        p.curve(to: pt(4.952, 4.362), controlPoint1: pt(5.645, 2.163), controlPoint2: pt(4.952, 4.362))
        p.curve(to: pt(3.625, 6.155), controlPoint1: pt(4.417, 5.788), controlPoint2: pt(3.625, 6.155))
        p.curve(to: pt(3.704, 6.909), controlPoint1: pt(2.535, 6.909), controlPoint2: pt(3.704, 6.909))
        p.curve(to: pt(5.546, 5.645), controlPoint1: pt(4.912, 6.827), controlPoint2: pt(5.546, 5.645))
        p.curve(to: pt(9.033, 4.627), controlPoint1: pt(6.616, 3.771), controlPoint2: pt(8.339, 4.301))
        p.curve(to: pt(9.785, 6.277), controlPoint1: pt(9.132, 5.421), controlPoint2: pt(9.449, 5.971))
        p.curve(to: pt(4.338, 12.348), controlPoint1: pt(7.131, 6.562), controlPoint2: pt(4.338, 7.621))
        p.curve(to: pt(5.566, 15.648), controlPoint1: pt(4.338, 13.692), controlPoint2: pt(4.813, 14.792))
        p.curve(to: pt(5.685, 18.907), controlPoint1: pt(5.447, 15.953), controlPoint2: pt(5.031, 17.216))
        p.curve(to: pt(8.973, 17.644), controlPoint1: pt(5.685, 18.907), controlPoint2: pt(6.695, 19.233))
        p.curve(to: pt(11.964, 18.052), controlPoint1: pt(9.948, 17.914), controlPoint2: pt(10.954, 18.051))
        p.curve(to: pt(14.955, 17.644), controlPoint1: pt(12.974, 18.052), controlPoint2: pt(14.004, 17.909))
        p.curve(to: pt(18.243, 18.907), controlPoint1: pt(17.233, 19.233), controlPoint2: pt(18.243, 18.907))
        p.curve(to: pt(18.362, 15.648), controlPoint1: pt(18.897, 17.216), controlPoint2: pt(18.481, 15.953))
        p.curve(to: pt(19.59, 12.348), controlPoint1: pt(19.135, 14.792), controlPoint2: pt(19.59, 13.692))
        p.curve(to: pt(14.123, 6.277), controlPoint1: pt(19.59, 7.621), controlPoint2: pt(16.798, 6.583))
        p.curve(to: pt(14.935, 3.995), controlPoint1: pt(14.559, 5.89), controlPoint2: pt(14.935, 5.157))
        p.curve(to: pt(14.916, 0.614), controlPoint1: pt(14.935, 2.345), controlPoint2: pt(14.916, 1.021))
        p.curve(to: pt(15.728, 0.023), controlPoint1: pt(14.916, 0.288), controlPoint2: pt(15.134, -0.099))
        p.curve(to: pt(23.909, 11.696), controlPoint1: pt(20.482, 1.653), controlPoint2: pt(23.909, 6.257))
        p.curve(to: pt(11.964, 24.0), controlPoint1: pt(23.928, 18.5), controlPoint2: pt(18.56, 24.0))
        p.close()
        p.fill()
        img.unlockFocus()
        img.isTemplate = true
        return img
    }
}
