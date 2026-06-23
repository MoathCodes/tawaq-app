/// Converts a global hizb quarter index (1–240) to a hizb number (1–60).
int hizbNumberFromQuarter(int hizbQuarter) =>
    ((hizbQuarter - 1) ~/ 4) + 1;

/// Converts a global hizb quarter index (1–240) to the quarter within its hizb (1–4).
int quarterInHizbFromQuarter(int hizbQuarter) =>
    ((hizbQuarter - 1) % 4) + 1;

/// First global hizb quarter index for [hizbNumber] (1–60).
int startHizbQuarterForHizb(int hizbNumber) => (hizbNumber - 1) * 4 + 1;
