//
//  ContentView.swift
//  SwiftUIClock
//
//  Created by Antony Mboukou on 05/07/2020.
//

import SwiftUI
import Combine
import UserNotifications



struct ClockTickerModel {
    enum TickerType {
        case second
        case hour
        case minute
    }
    let type: TickerType
    let timeInterval: TimeInterval
    let tickScale: CGFloat
    
    var angleMultiplier: CGFloat {
        switch type {
        case .second:
            return CGFloat(self.timeInterval.remainder(dividingBy: 60)) / 60
        case .hour:
            return CGFloat(timeInterval / 3600) / 12
        case .minute:
            return CGFloat((timeInterval - Double(Int(timeInterval / 3600) * 3600)) / 60) / 60
        }
    }
    
    var tickerScale: CGFloat {
        switch type {
        case .second:
            return 0.8
        case .hour:
            return 0.4
        case .minute:
            return 0.6
        }
    }
}


struct Clock: Shape {
    var model: ClockTickerModel
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length = rect.width / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.move(to: center)
        let hoursAngle = CGFloat.pi / 2 - .pi * 2 * model.angleMultiplier
        path.addLine(to: CGPoint(x: rect.midX + cos(hoursAngle) * length * model.tickerScale,
                                 y: rect.midY - sin(hoursAngle) * length * model.tickerScale))
        return path
    }
}

final class CurrentTime: ObservableObject {
    @Published var seconds: TimeInterval = CurrentTime.currentSecond(date: Date())

    private let timer = Timer.publish(every: 0.2, on: .main, in: .default).autoconnect()
    private var store = Set<AnyCancellable>()

    init() {
        timer.map(Self.currentSecond).assign(to: \.seconds, on: self).store(in: &store)
    }

    private static func currentSecond(date: Date) -> TimeInterval {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let referenceDate = Calendar.current.date(from: DateComponents(year: components.year!, month: components.month!, day: components.day!))!
        return Date().timeIntervalSince(referenceDate)
    }
}
struct ContentView: View {
    @State var date = Date()

    @ObservedObject var time = CurrentTime()
    
    func tick(at tick: Int) -> some View {
               VStack {
                   Rectangle()
                       .fill(Color.primary)
                       .opacity(tick % 5 == 0 ? 1 : 0.4)
                       .frame(width: 2, height: tick % 5 == 0 ? 15 : 7)
                   Spacer()
           }.rotationEffect(Angle.degrees(Double(tick)/(60) * 360))
    }
    
    var body: some View {
        
        return VStack {
            ZStack {
                
                ForEach(0..<60) { tick in
                    self.tick(at: tick)
                }
                GeometryReader { geometry in
                    ZStack {
                        HStack {
                            Text("")
                            Spacer()
                            Text("")
                            EmptyView()
                        }
                        VStack {
                            EmptyView()
                            Text("")
                            Spacer()
                            Text("")
                            EmptyView()
                        }
                    }.frame(width: geometry.size.width - 40, height: geometry.size.height - 30, alignment: .center)
                }
                
                Clock(model: .init(type: .hour, timeInterval: time.seconds, tickScale: 0.4))
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .rotationEffect(Angle.degrees(360/60))
                
                Clock(model: .init(type: .minute, timeInterval: time.seconds, tickScale: 0.6))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .rotationEffect(Angle.degrees(360/60))
                
                Clock(model: .init(type: .second, timeInterval: time.seconds, tickScale: 0.8))
                .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .rotationEffect(Angle.degrees(360/60))
                
            }.frame(width: 200, height: 200, alignment: .center)
            
            Spacer()
            
            Button("Request Permissions") {
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("All set!")
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }
            
            Spacer()
            
            Button("Schedule Notification") {
                let mutable = UNMutableNotificationContent()
                mutable.title = "Bonsoir !"
                mutable.body = "Mission accomplie Monsieur !"
                mutable.sound = UNNotificationSound.default

                // Configure the recurring date.
//                var dateComponents = DateComponents()
                var date = DateComponents()
                date.hour = 16    // 16:00 hours
                date.minute = 31  // 31 minutes
                date.day = 9 // Tuesday
                date.year = 2020 // year
                date.month = 7 // July
//                _ = Calendar.current.date(from: components) ?? Date()

//                dateComponents.weekday = 4
                
                
                // Create the trigger as a repeating event.
                let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
                
                let request = UNNotificationRequest(identifier: "key", content: mutable, trigger: trigger)

                // add our notification request
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      ContentView()
   }
}



        
