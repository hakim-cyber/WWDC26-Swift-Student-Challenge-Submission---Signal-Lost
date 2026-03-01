import SwiftUI


@Observable class ProjectData {
    private(set) var startSteps : StartSteps = .cameraAcces
    var macSteps : MacSteps = .openEmergencyApp
    
    var notifications:[NotificationStruct] = []
    var desktopTargets: [DesktopTarget: CGRect] = [:]
   var showTip: Bool = true
    
    var finishStory:Bool = false
    
    var showSignalApp: Bool = false
 

   @MainActor
    func finishedSendingEmergency(){
      
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35){
            AudioManager.shared.playSFX(.notificationSFX)
            self.notifications.append(.init(image: Image(systemName: "antenna.radiowaves.left.and.right"), title: "Emergency Signal Sent", body: "Your visual SOS was successfully transmitted using optical input"))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            AudioManager.shared.playSFX(.notificationSFX)
            self.notifications.append(.init(image: Image(systemName: "checkmark.circle.fill"), title: "Help Is Responding", body: "A nearby relay station has received your signal and is dispatching assistance."))
            withAnimation(.easeInOut(duration: 0.35)){
                self.finishStory = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4){
            withAnimation(.easeInOut(duration: 0.35)){
                self.macSteps = .showBreakingNews
            }
        }
    }
    @MainActor
    func changeStartStep(_ step: StartSteps){
        if self.startSteps.rawValue < step.rawValue{
            self.startSteps = step
        }else{
            print("Want to go back from \(self.startSteps) to \(step)")
        }
    }
}


enum StartSteps:Int{
    case cameraAcces,showHandView,  calibrationGuide,gestureSetup1,gestureSetup2,gestureSetup3,gestureSetup4,transitionToMain,connectMacCable,powerOnMac,bootProcessMac,deskScene,finishingScene
    
}
enum MacSteps:Int,CaseIterable{
    case openEmergencyApp,showBreakingNews
}
