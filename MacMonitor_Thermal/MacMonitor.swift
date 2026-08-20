import Cocoa
import IOKit.ps
import Darwin

struct MonitorSettings {
    var showCPU: Bool
    var showMemory: Bool
    var showDisk: Bool
    var showBattery: Bool

    static func load() -> MonitorSettings {
        let d = UserDefaults.standard
        return MonitorSettings(
            showCPU:    d.object(forKey:"showCPU")    as? Bool ?? true,
            showMemory: d.object(forKey:"showMemory") as? Bool ?? true,
            showDisk:   d.object(forKey:"showDisk")   as? Bool ?? true,
            showBattery:d.object(forKey:"showBattery")as? Bool ?? true
        )
    }
    func save() {
        let d = UserDefaults.standard
        d.set(showCPU,     forKey:"showCPU")
        d.set(showMemory,  forKey:"showMemory")
        d.set(showDisk,    forKey:"showDisk")
        d.set(showBattery, forKey:"showBattery")
    }
    static func restoreDefaults() {
        ["showCPU","showMemory","showDisk","showBattery"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }
}

class MetricRowView: NSView {
    var symbol:String; var title:String; var sub:String; var value:String; var pct:Double; var tint:NSColor; var isCritical:Bool
    init(frame:NSRect,symbol:String,title:String,sub:String,value:String,pct:Double,tint:NSColor,isCritical:Bool=false){
        self.symbol=symbol; self.title=title; self.sub=sub; self.value=value; self.pct=pct; self.tint=tint; self.isCritical=isCritical; super.init(frame:frame)
    }
    required init?(coder:NSCoder){fatalError()}
    override func draw(_ dirtyRect:NSRect){
        let cfg=NSImage.SymbolConfiguration(pointSize:14,weight:.medium,scale:.medium)
        if let base=NSImage(systemSymbolName:symbol,accessibilityDescription:nil)?.withSymbolConfiguration(cfg){
            let r=NSRect(x:14,y:bounds.height/2-8,width:16,height:16)
            let img=NSImage(size:r.size)
            img.lockFocus()
            tint.set()
            NSBezierPath(rect:NSRect(origin:.zero,size:r.size)).fill()
            base.draw(in:NSRect(origin:.zero,size:r.size),from:.zero,operation:.destinationIn,fraction:1.0)
            img.unlockFocus()
            img.draw(in:r)
        }
        (title as NSString).draw(at:NSPoint(x:40,y:20),withAttributes:[.font:NSFont.systemFont(ofSize:12,weight:.medium),.foregroundColor:NSColor.labelColor])
        (sub as NSString).draw(at:NSPoint(x:40,y:6),withAttributes:[.font:NSFont.systemFont(ofSize:10,weight:.regular),.foregroundColor:NSColor.secondaryLabelColor])
        let va:[NSAttributedString.Key:Any]=[.font:NSFont.monospacedSystemFont(ofSize:11,weight:.semibold),.foregroundColor:NSColor.labelColor]
        let vs=(value as NSString).size(withAttributes:va)
        (value as NSString).draw(at:NSPoint(x:bounds.width-vs.width-12,y:13),withAttributes:va)
        let bg=NSRect(x:40,y:3,width:bounds.width-52,height:3)
        NSColor.quaternaryLabelColor.set(); NSBezierPath(roundedRect:bg,xRadius:1.5,yRadius:1.5).fill()
        let fill=NSRect(x:bg.minX,y:bg.minY,width:bg.width*CGFloat(min(pct,100)/100.0),height:bg.height)
        tint.set(); NSBezierPath(roundedRect:fill,xRadius:1.5,yRadius:1.5).fill()
        if isCritical {
            NSColor.systemRed.withAlphaComponent(0.15).set()
            NSBezierPath(roundedRect:bounds.insetBy(dx:1,dy:1),xRadius:6,yRadius:6).stroke()
        }
    }
}

class HeaderView:NSView{
    override func draw(_ dirtyRect:NSRect){
        ("MacMonitor" as NSString).draw(at:NSPoint(x:14,y:24),withAttributes:[.font:NSFont.systemFont(ofSize:13,weight:.bold),.foregroundColor:NSColor.labelColor])
        let ver = ProcessInfo.processInfo.operatingSystemVersion
        let os  = "macOS \(ver.majorVersion).\(ver.minorVersion).\(ver.patchVersion)"
        #if arch(arm64)
        let chip = "Apple Silicon"
        #else
        let chip = "Intel"
        #endif
        ("\(chip) • \(os) • Open Source MIT" as NSString).draw(at:NSPoint(x:14,y:8),withAttributes:[.font:NSFont.systemFont(ofSize:10,weight:.regular),.foregroundColor:NSColor.secondaryLabelColor])
    }
}

class CoffeeBannerView: NSView {
    var onSupport: (()->Void)?
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedRed:1.0, green:0.85, blue:0.2, alpha:1.0).cgColor
        layer?.cornerRadius = 8
        let btn = NSButton(title: L("support_button"), target:self, action:#selector(tapped))
        btn.bezelStyle = .rounded
        btn.controlSize = .regular
        btn.font = .systemFont(ofSize:11, weight:.semibold)
        btn.frame = NSRect(x:frame.width-108, y:9, width:96, height:26)
        btn.wantsLayer = true
        btn.layer?.backgroundColor = NSColor.black.cgColor
        btn.layer?.cornerRadius = 6
        btn.contentTintColor = .white
        btn.isBordered = false
        addSubview(btn)
    }
    required init?(coder:NSCoder){fatalError()}
    override func draw(_ dirtyRect:NSRect){
        super.draw(dirtyRect)
        (L("support_banner") as NSString).draw(
            at:NSPoint(x:14,y:15),
            withAttributes:[.font:NSFont.systemFont(ofSize:12,weight:.semibold),.foregroundColor:NSColor.black])
    }
    @objc func tapped(){ onSupport?() }
}

func shouldShowCoffeeBanner() -> Bool {
    let d = UserDefaults.standard
    let sessions = d.integer(forKey: "coffeeSessionCount") + 1
    d.set(sessions, forKey: "coffeeSessionCount")
    if sessions <= 7 { return true }
    let lastShown = d.double(forKey: "coffeeLastShown")
    let now = Date().timeIntervalSince1970
    if now - lastShown > 7 * 86400 {
        d.set(now, forKey: "coffeeLastShown")
        return true
    }
    return false
}

func PowerSourceCallback(_ ctx: UnsafeMutableRawPointer?){
    guard let c=ctx else {return}
    let d=Unmanaged<AppDelegate>.fromOpaque(c).takeUnretainedValue()
    DispatchQueue.main.async{d.refreshBattery()}
}

class AppDelegate:NSObject,NSApplicationDelegate,NSMenuDelegate{
    var statusItem:NSStatusItem!
    var onboardingWC: OnboardingWindowController?
    var settings = MonitorSettings.load()
    var thermalState: ProcessInfo.ThermalState = .nominal
    var memPercent:Double=0; var memUsed:UInt64=0; var memTotal:UInt64=0
    var diskPercent:Double=0; var diskTotal:UInt64=0; var diskFree:UInt64=0; var diskUsed:UInt64=0
    var batteryPercent:Int=0; var batteryTime:Int = -1; var batteryCharging=false; var batteryFullyCharged=false
    var hasBattery = false
    var powerSource:CFRunLoopSource?
    var settingsWindow: NSWindow?
    var settingCheckboxes: [NSButton] = []

    let neutralIcon = NSColor.labelColor.withAlphaComponent(0.55)
    let neutralText  = NSColor.labelColor.withAlphaComponent(0.85)
    let warnOrange   = NSColor(calibratedRed:1.0, green:0.58, blue:0.0,  alpha:0.95)
    let critRed      = NSColor(calibratedRed:1.0, green:0.25, blue:0.25, alpha:0.95)
    let okGreen      = NSColor(calibratedRed:0.2, green:0.78, blue:0.35, alpha:0.9)

    func applicationDidFinishLaunching(_ notification:Notification){
        let isFirst = !UserDefaults.standard.bool(forKey:"hasLaunchedBefore")
        if isFirst {
            UserDefaults.standard.set(true, forKey:"hasLaunchedBefore")
            onboardingWC = OnboardingWindowController()
            onboardingWC?.showWindow(nil)
            NSApp.activate(ignoringOtherApps:true)
            NotificationCenter.default.addObserver(self, selector:#selector(startMonitoring), name:NSNotification.Name("OnboardingFinished"), object:nil)
            return
        }
        startMonitoring()
    }

    @objc func startMonitoring(){
        statusItem=NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        let menu=NSMenu(); menu.delegate=self
        let header=NSMenuItem(); header.view=HeaderView(frame:NSRect(x:0,y:0,width:320,height:44))
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())
        statusItem.menu=menu
        setupBatteryMonitoring(); updateDisk(); updateAll()
        Timer.scheduledTimer(timeInterval:3.0,  target:self,selector:#selector(updateAll), userInfo:nil,repeats:true)
        Timer.scheduledTimer(timeInterval:300.0, target:self,selector:#selector(updateDisk),userInfo:nil,repeats:true)
        NotificationCenter.default.addObserver(self,selector:#selector(thermalStateChanged),name:ProcessInfo.thermalStateDidChangeNotification,object:nil)
    }

    @objc func quit(){NSApp.terminate(nil)}

    func setupBatteryMonitoring(){
        let ctx=Unmanaged.passUnretained(self).toOpaque()
        if let src=IOPSNotificationCreateRunLoopSource(PowerSourceCallback,ctx)?.takeUnretainedValue(){
            powerSource=src; CFRunLoopAddSource(CFRunLoopGetCurrent(),src,CFRunLoopMode.defaultMode)
        }
    }

    @objc func updateAll(){updateThermal();updateMemory();refreshBattery()}
    @objc func thermalStateChanged(){updateThermal()}

    @objc func updateThermal(){
        thermalState=ProcessInfo.processInfo.thermalState
        updateStatusTitle(); updateMenuDetails()
    }
    @objc func updateMemory(){
        let m=fetchMemory(); memPercent=m.percent; memUsed=m.used; memTotal=m.total
        updateStatusTitle(); updateMenuDetails()
    }
    @objc func updateDisk(){
        let d=fetchDisk(); diskPercent=d.percent; diskTotal=d.total; diskFree=d.free; diskUsed=d.used
        updateStatusTitle(); updateMenuDetails()
    }
    func refreshBattery(){fetchBattery();updateStatusTitle();updateMenuDetails()}

    func fetchMemory()->(percent:Double,used:UInt64,total:UInt64){
        let totalMem=ProcessInfo.processInfo.physicalMemory
        var pageSize:vm_size_t=0; host_page_size(mach_host_self(),&pageSize)
        var stats=vm_statistics64()
        var count=mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size/MemoryLayout<integer_t>.size)
        let kerr=withUnsafeMutablePointer(to:&stats){$0.withMemoryRebound(to:integer_t.self,capacity:Int(count)){
            host_statistics64(mach_host_self(),HOST_VM_INFO64,$0,&count)
        }}
        if kerr != KERN_SUCCESS {return (0,0,totalMem)}
        let active=UInt64(stats.active_count), wired=UInt64(stats.wire_count), comp=UInt64(stats.compressor_page_count)
        let used=(active+wired+comp)*UInt64(pageSize)
        return (totalMem>0 ? Double(used)/Double(totalMem)*100.0 : 0, used, totalMem)
    }

    func fetchDisk()->(percent:Double,total:UInt64,free:UInt64,used:UInt64){
        var fs=statfs(); var path="/System/Volumes/Data"
        if statfs(path, &fs) != 0 { path="/"; _ = statfs(path, &fs) }
        let bsize=UInt64(fs.f_bsize); let total=bsize*UInt64(fs.f_blocks)
        let free=bsize*UInt64(fs.f_bfree); let used=total>free ? total-free : 0
        return (total>0 ? Double(used)/Double(total)*100.0 : 0,total,free,used)
    }

    func fetchBattery(){
        guard let blob=IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list=IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              !list.isEmpty,
              let src=list.first,
              let info=IOPSGetPowerSourceDescription(blob,src)?.takeUnretainedValue() as? [String:Any],
              let type=info[kIOPSTypeKey as String] as? String, type == kIOPSInternalBatteryType
        else { hasBattery=false; return }
        hasBattery=true
        batteryPercent=info[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        batteryCharging=info[kIOPSIsChargingKey as String] as? Bool ?? false
        batteryFullyCharged=info[kIOPSIsChargedKey as String] as? Bool ?? false
        let tE=info[kIOPSTimeToEmptyKey as String] as? Int ?? -1
        let tF=info[kIOPSTimeToFullChargeKey as String] as? Int ?? -1
        batteryTime=batteryCharging ? tF : tE
    }

    func formatBytes(_ b:UInt64)->String{
        let gb=Double(b)/1024/1024/1024
        return gb>=1 ? String(format:"%.1f GB",gb) : String(format:"%.0f MB",Double(b)/1024/1024)
    }
    func formatTime(_ m:Int)->String{
        if m<0 { return L("label_time_unknown") }
        if m==0 && batteryFullyCharged { return L("label_battery_full") }
        return String(format:"%d:%02d",m/60,m%60)
    }

    func thermalInfo()->(title:String,sub:String,value:String,pct:Double,tint:NSColor,isCrit:Bool,symbol:String){
        switch thermalState {
        case .nominal:  return (L("label_processor"),L("thermal_sub_normal"), L("thermal_normal"), 20,neutralIcon,false,"thermometer.low")
        case .fair:     return (L("label_processor"),L("thermal_sub_warm"),   L("thermal_warm"),   50,warnOrange, false,"thermometer.medium")
        case .serious:  return (L("label_processor"),L("thermal_sub_hot"),    L("thermal_hot"),    80,critRed,    true, "thermometer.high")
        case .critical: return (L("label_processor"),L("thermal_sub_critical"),L("thermal_critical"),100,critRed, true, "thermometer.sun.fill")
        @unknown default: return (L("label_processor"),L("thermal_unknown"),  L("thermal_unknown"),  0,neutralIcon,false,"thermometer.medium")
        }
    }
    func colorForMem(_ p:Double)->(tint:NSColor,isCrit:Bool){
        if p>95{return (critRed,true)}; if p>85{return (warnOrange,false)}
        return (NSColor.systemBlue.withAlphaComponent(0.9),false)
    }
    func colorForDisk(_ p:Double)->(tint:NSColor,isCrit:Bool){
        if p>90{return (critRed,true)}; if p>80{return (warnOrange,false)}
        return (neutralIcon,false)
    }

    func symbolImage(_ name:String,color:NSColor)->NSImage{
        let cfg=NSImage.SymbolConfiguration(pointSize:11,weight:.medium,scale:.medium)
        guard let base=NSImage(systemSymbolName:name,accessibilityDescription:nil)?.withSymbolConfiguration(cfg) else {return NSImage()}
        let img=NSImage(size:NSSize(width:13,height:13))
        img.lockFocus()
        color.set()
        NSBezierPath(rect:NSRect(origin:.zero,size:img.size)).fill()
        base.draw(in:NSRect(origin:.zero,size:img.size),from:.zero,operation:.destinationIn,fraction:1.0)
        img.unlockFocus()
        img.isTemplate=false
        return img
    }

    func makeSegment(symbol:String,text:String,color:NSColor,showDot:Bool=false,isCrit:Bool=false)->NSAttributedString{
        let m=NSMutableAttributedString()
        if showDot {
            let dotColor = isCrit ? critRed : warnOrange
            m.append(NSAttributedString(string:"● ",attributes:[.font:NSFont.systemFont(ofSize:7,weight:.bold),.foregroundColor:dotColor,.baselineOffset:1]))
        }
        let att=NSTextAttachment(); att.image=symbolImage(symbol,color:color); att.bounds=NSRect(x:0,y:-2,width:13,height:13)
        m.append(NSAttributedString(attachment:att)); m.append(NSAttributedString(string:" "))
        var attrs:[NSAttributedString.Key:Any]=[.font:NSFont.monospacedSystemFont(ofSize:11,weight:isCrit ? .bold : .semibold),.foregroundColor:color,.kern:0.15]
        if isCrit { attrs[.backgroundColor]=color.withAlphaComponent(0.12) }
        m.append(NSAttributedString(string:text,attributes:attrs))
        return m
    }

    func updateStatusTitle(){
        DispatchQueue.main.async{
            let sep=NSAttributedString(string:"   ",attributes:[.font:NSFont.systemFont(ofSize:11),.foregroundColor:NSColor.quaternaryLabelColor])
            var segs=[NSAttributedString]()
            if self.settings.showCPU {
                let t=self.thermalInfo()
                let tColor=(t.tint==self.neutralIcon ? self.neutralText : t.tint)
                segs.append(self.makeSegment(symbol:t.symbol,text:t.value,color:tColor,showDot:t.isCrit||t.pct>=50,isCrit:t.isCrit))
            }
            if self.settings.showMemory {
                let m=self.colorForMem(self.memPercent)
                let mCol=m.isCrit ? self.critRed : (self.memPercent>85 ? self.warnOrange : self.neutralText)
                segs.append(self.makeSegment(symbol:"memorychip",text:String(format:"%.0f%%",self.memPercent),color:mCol,showDot:m.isCrit||self.memPercent>85,isCrit:m.isCrit))
            }
            if self.settings.showDisk {
                let d=self.colorForDisk(self.diskPercent)
                let dCol=d.isCrit ? self.critRed : (self.diskPercent>80 ? self.warnOrange : self.neutralText)
                segs.append(self.makeSegment(symbol:"internaldrive",text:String(format:"%.0f%%",self.diskPercent),color:dCol,showDot:d.isCrit||self.diskPercent>80,isCrit:d.isCrit))
            }
            if self.settings.showBattery && self.hasBattery {
                let bIsLow=self.batteryPercent<15 && !self.batteryCharging
                let bCol=bIsLow ? self.critRed : (self.batteryCharging ? self.okGreen : self.neutralText)
                let bSym:String={
                    if self.batteryCharging{return "battery.100.bolt"}
                    switch self.batteryPercent{
                    case 87...100:return "battery.100"
                    case 62...86: return "battery.75"
                    case 37...61: return "battery.50"
                    case 12...36: return "battery.25"
                    default:      return "battery.0"
                    }
                }()
                segs.append(self.makeSegment(symbol:bSym,text:self.formatTime(self.batteryTime),color:bCol,showDot:bIsLow,isCrit:bIsLow))
            }
            let final=NSMutableAttributedString()
            for (i,seg) in segs.enumerated(){
                final.append(seg)
                if i<segs.count-1{final.append(sep)}
            }
            self.statusItem.button?.attributedTitle=final
        }
    }

    func updateMenuDetails(){
        guard let menu=statusItem.menu else {return}
        while menu.items.count > 2 { menu.removeItem(at:2) }
        if settings.showCPU {
            let t=thermalInfo()
            let item=NSMenuItem(); item.view=MetricRowView(frame:NSRect(x:0,y:0,width:320,height:44),symbol:t.symbol,title:t.title,sub:t.sub,value:t.value,pct:t.pct,tint:t.tint,isCritical:t.isCrit)
            menu.addItem(item)
        }
        if settings.showMemory {
            let m=colorForMem(memPercent)
            let mDetail=String(format: L("label_used_of"), formatBytes(memUsed), formatBytes(memTotal))
            let item=NSMenuItem(); item.view=MetricRowView(frame:NSRect(x:0,y:0,width:320,height:44),symbol:"memorychip",title:L("label_memory"),sub:mDetail,value:String(format:"%.0f%%",memPercent),pct:memPercent,tint:m.tint,isCritical:m.isCrit)
            menu.addItem(item)
        }
        if settings.showDisk {
            let d=colorForDisk(diskPercent)
            let dDetail=String(format: L("label_disk_detail"), formatBytes(diskUsed), formatBytes(diskFree))
            let item=NSMenuItem(); item.view=MetricRowView(frame:NSRect(x:0,y:0,width:320,height:44),symbol:"internaldrive.fill",title:L("label_disk"),sub:dDetail,value:String(format:"%.0f%%",diskPercent),pct:diskPercent,tint:d.tint,isCritical:d.isCrit)
            menu.addItem(item)
        }
        if settings.showBattery && hasBattery {
            let bDetail = batteryCharging
                ? String(format: L("label_battery_charging"), batteryPercent, formatTime(batteryTime))
                : String(format: L("label_battery_remaining"), batteryPercent, formatTime(batteryTime))
            let bTint=batteryPercent<15 && !batteryCharging ? critRed : (batteryCharging ? okGreen : neutralIcon)
            let bSym:String={
                if batteryCharging{return "battery.100.bolt"}
                switch batteryPercent{
                case 87...100:return "battery.100"
                case 62...86: return "battery.75"
                case 37...61: return "battery.50"
                case 12...36: return "battery.25"
                default:      return "battery.0"
                }
            }()
            let item=NSMenuItem(); item.view=MetricRowView(frame:NSRect(x:0,y:0,width:320,height:44),symbol:bSym,title:L("label_battery"),sub:bDetail,value:formatTime(batteryTime),pct:Double(batteryPercent),tint:bTint,isCritical:batteryPercent<15 && !batteryCharging)
            menu.addItem(item)
        }
        if shouldShowCoffeeBanner() {
            let banner=CoffeeBannerView(frame:NSRect(x:0,y:0,width:320,height:44))
            banner.onSupport={ [weak self] in self?.openCoffee() }
            let coffeeItem=NSMenuItem(); coffeeItem.view=banner
            menu.addItem(coffeeItem)
        }
        menu.addItem(NSMenuItem.separator())
        let prefs=NSMenuItem(title: L("menu_preferences"), action:#selector(openSettings),keyEquivalent:",")
        prefs.target=self
        prefs.image=NSImage(systemSymbolName:"gearshape",accessibilityDescription:nil)
        menu.addItem(prefs)
        let quit=NSMenuItem(title: L("menu_quit"), action:#selector(quit),keyEquivalent:"q")
        quit.target=self
        quit.image=NSImage(systemSymbolName:"power",accessibilityDescription:nil)
        menu.addItem(quit)
    }

    func menuWillOpen(_ menu:NSMenu){ updateMenuDetails() }

    // MARK: - Settings Window

    @objc func openSettings(){
        if settingsWindow == nil {
            let w=NSWindow(contentRect:NSRect(x:0,y:0,width:280,height:250),styleMask:[.titled,.closable],backing:.buffered,defer:false)
            w.title = L("settings_title")
            w.isReleasedWhenClosed=false
            let view=NSView(frame:NSRect(x:0,y:0,width:280,height:250))

            let lbl=NSTextField(labelWithString: L("settings_show_in_menubar"))
            lbl.frame=NSRect(x:20,y:215,width:240,height:20)
            lbl.font = .systemFont(ofSize:13,weight:.semibold)
            view.addSubview(lbl)

            let items:[(String,Bool)] = [
                (L("settings_cpu"),     settings.showCPU),
                (L("settings_memory"),  settings.showMemory),
                (L("settings_disk"),    settings.showDisk),
                (L("settings_battery"), settings.showBattery)
            ]
            settingCheckboxes=[]
            for (i,(label,state)) in items.enumerated(){
                let cb=NSButton(checkboxWithTitle:label,target:self,action:#selector(toggleSetting(_:)))
                cb.frame=NSRect(x:20,y:185-i*30,width:240,height:22)
                cb.state=state ? .on : .off
                cb.tag=i
                view.addSubview(cb)
                settingCheckboxes.append(cb)
            }

            // Language selector
            let langLabel=NSTextField(labelWithString: L("settings_language_label")+":")
            langLabel.frame=NSRect(x:20,y:72,width:90,height:20)
            langLabel.font = .systemFont(ofSize:12)
            view.addSubview(langLabel)

            let langPopup=NSPopUpButton(frame:NSRect(x:114,y:68,width:146,height:26),pullsDown:false)
            for lang in LocalizationManager.supportedLanguages {
                langPopup.addItem(withTitle: lang.name)
                langPopup.lastItem?.representedObject = lang.code
            }
            let currentCode = LocalizationManager.shared.selectedCode
            let idx = LocalizationManager.supportedLanguages.firstIndex(where:{ $0.code == currentCode }) ?? 0
            langPopup.selectItem(at: idx)
            langPopup.target = self
            langPopup.action = #selector(languageChanged(_:))
            view.addSubview(langPopup)

            let restore=NSButton(title: L("settings_restore"), target:self, action:#selector(restoreSettings))
            restore.frame=NSRect(x:20,y:20,width:160,height:28)
            restore.bezelStyle = .rounded
            view.addSubview(restore)

            w.contentView=view
            settingsWindow=w
        }
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps:true)
    }

    @objc func toggleSetting(_ sender:NSButton){
        switch sender.tag {
        case 0: settings.showCPU     = sender.state == .on
        case 1: settings.showMemory  = sender.state == .on
        case 2: settings.showDisk    = sender.state == .on
        case 3: settings.showBattery = sender.state == .on
        default: break
        }
        settings.save()
        updateStatusTitle()
        updateMenuDetails()
    }

    @objc func languageChanged(_ sender: NSPopUpButton) {
        guard let code = sender.selectedItem?.representedObject as? String else { return }
        LocalizationManager.shared.selectedCode = code
        LocalizationManager.shared.reload()
        updateStatusTitle()
        updateMenuDetails()
        settingsWindow?.close()
        settingsWindow = nil
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1){ self.openSettings() }
    }

    @objc func openCoffee(){
        NSWorkspace.shared.open(URL(string:"https://buymeacoffee.com/bulldozestore")!)
    }

    @objc func restoreSettings(){
        MonitorSettings.restoreDefaults()
        settings=MonitorSettings.load()
        settingCheckboxes[0].state=settings.showCPU     ? .on : .off
        settingCheckboxes[1].state=settings.showMemory  ? .on : .off
        settingCheckboxes[2].state=settings.showDisk    ? .on : .off
        settingCheckboxes[3].state=settings.showBattery ? .on : .off
        updateStatusTitle()
        updateMenuDetails()
    }
}
