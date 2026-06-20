import Foundation

struct MessageComposer {
    static func compose(for date: Date,
                        assignments: [StaffAssignment],
                        outgoingE1W: StaffAssignment? = nil) -> String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "EEEE MMMM d"
        let dayAbbr = DateFormatter()
        dayAbbr.dateFormat = "EEE"   // "Mon", "Fri", etc.

        var lines = ["Good morning!", "", "\(dateFmt.string(from: date)) Staffing"]

        for a in assignments {
            if a.prefix == "E1W", let outgoing = outgoingE1W {
                // Two-line handoff: outgoing from today, incoming from target Monday
                let fromDay = dayAbbr.string(from: Date())
                lines.append("E1W (\(fromDay)): \(outgoing.displayName)")
                lines.append("E1W (Mon): \(a.displayName)")
            } else {
                lines.append("\(a.prefix): \(a.displayName)")
            }
        }
        return lines.joined(separator: "\n")
    }
}
