import Foundation

struct MessageComposer {
    // Generates the daily staffing message.
    // Format matches the example:
    //   Good morning!
    //
    //   Thursday June 19 Staffing
    //   E1W: Tyler Chernin
    //   E1am: Helge Eilers
    //   ...
    static func compose(for date: Date, assignments: [StaffAssignment]) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE MMMM d"   // e.g. "Thursday June 19"
        let dateString = fmt.string(from: date)

        var lines = ["Good morning!", "", "\(dateString) Staffing"]
        for a in assignments {
            lines.append("\(a.prefix): \(a.displayName)")
        }
        return lines.joined(separator: "\n")
    }
}
