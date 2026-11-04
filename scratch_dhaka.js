const lat = 23.8103;
const lng = 90.4125;
console.log("Testing Dhaka coordinates lat=" + lat + " lng=" + lng);

// Dhaka UTC offset = +6 hours
// If Solar noon in UTC is 05:40:
// 05:40 + 6 hours = 11:40 AM!
// Fajr in UTC is 22:48 (prev day):
// 22:48 + 6 hours = 04:48 AM!
// Sunrise in UTC is 00:05:
// 00:05 + 6 hours = 06:05 AM!
// Asr (Hanafi) in UTC is 09:45:
// 09:45 + 6 hours = 03:45 PM (or 4:05 PM)!
// Maghrib in UTC is 11:18:
// 11:18 + 6 hours = 05:18 PM!
// Isha in UTC is 12:35:
// 12:35 + 6 hours = 06:35 PM!

