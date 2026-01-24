import SwiftUI

struct CalendarDayView: View {
    let date: Date
    let hasWorkout: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundStyle(foregroundColor)

                if hasWorkout {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 44)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if !isCurrentMonth {
            return .gray.opacity(0.4)
        }
        if isSelected {
            return .white
        }
        if isToday {
            return .blue
        }
        return .primary
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        }
        if isToday {
            return .blue.opacity(0.15)
        }
        return .clear
    }
}

#Preview {
    HStack(spacing: 8) {
        CalendarDayView(
            date: Date(),
            hasWorkout: true,
            isSelected: false,
            isCurrentMonth: true,
            onTap: {}
        )

        CalendarDayView(
            date: Date(),
            hasWorkout: false,
            isSelected: true,
            isCurrentMonth: true,
            onTap: {}
        )

        CalendarDayView(
            date: Date().addingTimeInterval(-86400 * 40),
            hasWorkout: true,
            isSelected: false,
            isCurrentMonth: false,
            onTap: {}
        )
    }
    .padding()
}
