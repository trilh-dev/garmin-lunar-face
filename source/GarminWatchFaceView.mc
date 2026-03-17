import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Weather;

class GarminWatchFaceView extends WatchUi.WatchFace {

    // Cache lịch âm: chỉ tính lại khi ngày thay đổi
    var _cachedLunarDay as Number = -1;
    var _cachedLunarStr as String = "";

    function initialize() {
        WatchFace.initialize();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth(); // Should be 208 on fr55
        var height = dc.getHeight(); // Should be 208 on fr55
        var cx = width / 2;
        var cy = height / 2;
        
        var accentColor = 0x00AAFF; // Custom Cyan Color

        // Fetch Data
        var clockTime = System.getClockTime();
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var actInfo = ActivityMonitor.getInfo();
        var steps = actInfo.steps != null ? actInfo.steps : 0;
        var stepGoal = actInfo.stepGoal != null ? actInfo.stepGoal : 5000;
        var hr = "--";
        var sample = Activity.getActivityInfo();
        if (sample != null && sample.currentHeartRate != null) { hr = sample.currentHeartRate.toString(); }
        var sysStats = System.getSystemStats();
        var battery = sysStats.battery != null ? sysStats.battery.toNumber() : 0;
        var deviceSettings = System.getDeviceSettings();
        var notificationCount = deviceSettings.notificationCount;
        
        // Weather
        var weatherCond = null;
        if (Toybox has :Weather) {
            var cond = Weather.getCurrentConditions();
            if (cond != null) { weatherCond = cond.condition; }
        }

        // --- PROGRESS BARS ---
        // Left Bar: Steps
        var stepsPercent = stepGoal > 0 ? steps.toFloat() / stepGoal : 0.0;
        if (stepsPercent > 1.0) { stepsPercent = 1.0; }
        
        // Let's hardcode coordinates for 200x200 / 208x208 typical screen shapes
        var r = cx - 5; 

        // Draw Left Steps Arc: from Bottom Left (220 deg) to Top Left (140 deg)
        dc.setPenWidth(5);
        var leftSegments = 10;
        for (var i = 0; i < leftSegments; i++) {
            var startA = 220 - (i * 8);
            var endA = startA - 6; // draw 6, gap 2
            var isFilled = (i.toFloat() / leftSegments) <= stepsPercent;
            dc.setColor(isFilled ? accentColor : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, startA, endA);
        }

        // Draw Right Battery Arc: from Bottom Right (320 deg) to Top Right (40 deg)
        var batPercent = battery / 100.0;
        var rightSegments = 16;
        for (var i = 0; i < rightSegments; i++) {
            var ang = 320 + i * +5; // draw 5 degrees total space
            if (ang >= 360) { ang -= 360; }
            var startA = ang;
            var endA = (startA + 3) % 360; // draw 3, gap 2
            
            var isFilled = (i.toFloat() / rightSegments) <= batPercent;
            dc.setColor(isFilled ? accentColor : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            
            // Special handling to avoid crossing 0 deg in confusing ways for drawArc
            // If segment crosses 0, draw in two pieces just to be perfectly safe across SDK versions
            if (startA > 350 && endA < 10) {
                dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, startA, 359);
                dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 0, endA);
            } else {
                dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, startA, endA);
            }
        }

        // --- TOP HEADER (Stacked 2-Line Row - Resized Icons) ---
        var rowY = cy - 65;
        var textY = cy - 45;

        // 1. Bluetooth Column (Center cx - 69)
        var btIcon = WatchUi.loadResource(Rez.Drawables.BluetoothIcon) as BitmapResource;
        var btX = cx - 74; // cx - 69 - (11/2) 
        dc.drawBitmap(btX, rowY - 9, btIcon); // Height 19 -> rowY - 9
        if (!deviceSettings.phoneConnected) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(btX + 1, rowY - 7, btX + 10, rowY + 10); 
            //dc.drawLine(btX + 1, rowY + 10, btX + 10, rowY - 7);
        }

        // 2. Battery Column (Center cx - 23)
        // Scaled down battery icon from 22x11 to ~18x9 to match new icon scale
        drawBatteryIcon(dc, cx - 33, rowY - 4-20, 18, 9, battery);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 23, textY-20, Graphics.FONT_XTINY, battery + "%", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Heart Rate Column (Center cx + 23)
        var heartIcon = WatchUi.loadResource(Rez.Drawables.HeartIcon) as BitmapResource;
        dc.drawBitmap(cx + 15, rowY - 8-20, heartIcon); // cx + 23 - (17/2), Height 17 -> rowY - 8
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 23, textY-20, Graphics.FONT_XTINY, hr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 4. Weather Column (Center cx + 69)
        var weatherIconRes = Rez.Drawables.SunIcon;
        if (weatherCond != null) {
            if (weatherCond == Weather.CONDITION_RAIN || weatherCond == Weather.CONDITION_HEAVY_RAIN || weatherCond == Weather.CONDITION_LIGHT_RAIN) {
                weatherIconRes = Rez.Drawables.RainIcon;
            } else if (weatherCond == Weather.CONDITION_CLOUDY || weatherCond == Weather.CONDITION_MOSTLY_CLOUDY || weatherCond == Weather.CONDITION_PARTLY_CLOUDY) {
                weatherIconRes = Rez.Drawables.CloudIcon;
            }
        }
        var weatherIcon = WatchUi.loadResource(weatherIconRes) as BitmapResource;
        dc.drawBitmap(cx + 50, rowY - 12, weatherIcon); // cx + 69 - (24/2), Height 24 -> rowY - 12

        // --- CENTER ---
        // Date
        var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        var dName = days[info.day_of_week - 1];
        var mNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        var mName = mNames[info.month - 1];
        var dateStr = dName + " " + info.day + " " + mName;
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 25, Graphics.FONT_TINY, dateStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Time
        var hStr = clockTime.hour.format("%d");
        var mStr = clockTime.min.format("%02d");
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 5, cy + 5, Graphics.FONT_NUMBER_MEDIUM, hStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx + 5, cy + 5, Graphics.FONT_NUMBER_MEDIUM, mStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Seconds and chevrons
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 50, cy + 40, Graphics.FONT_MEDIUM, clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        for (var i=0; i<3; i++) {
            var startX = cx - 20 + (i * 15);
            var yOffset = cy + 40;
            dc.fillPolygon([[startX, yOffset - 4], [startX + 8, yOffset - 4], [startX + 12, yOffset], [startX + 8, yOffset + 4], [startX, yOffset + 4], [startX + 4, yOffset]]);
        }

        // --- BOTTOM ROW ---
        // Footprints
        var stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon) as BitmapResource;
        dc.drawBitmap(cx - 55, cy + 65, stepsIcon);
        // Steps / Goal
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 30, cy + 75, Graphics.FONT_XTINY, steps.toString(), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 30, cy + 90, Graphics.FONT_XTINY, stepGoal.toString(), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Lunar (cached - chỉ tính lại khi ngày thay đổi)
        if (info.day != _cachedLunarDay) {
            _cachedLunarDay = info.day;
            _cachedLunarStr = getLunarDate(info.day, info.month, info.year);
        }
        var lunarString = _cachedLunarStr;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 40, cy + 65, Graphics.FONT_XTINY, lunarString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- ICONS ON LEFT ARC ---
        // Show icons only when relevant
        // --- LEFT CURVE CONNECTIVITY ---
        // Phone status and Notifications moved here to avoid center overlap

        // 1. Phone Connection Status
        if (deviceSettings.phoneConnected) {
            var phoneIcon = WatchUi.loadResource(Rez.Drawables.PhoneIcon) as BitmapResource;
            dc.drawBitmap(cx - 95, cy - 25, phoneIcon);
        }

        // 2. Notifications / Messages
        if (notificationCount != null && notificationCount > 0) {
            var msgIcon = WatchUi.loadResource(Rez.Drawables.MessageIcon) as BitmapResource;
            dc.drawBitmap(cx - 90, cy + 5, msgIcon);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx - 70, cy + 15, Graphics.FONT_XTINY, notificationCount.toString(), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
    
    // Cleanup unused drawing functions

    function onHide() as Void {}
    function onExitSleep() as Void {}
    function onEnterSleep() as Void {}

    // ============================================================
    // Hồ Ngọc Đức Lunar Calendar Algorithm - Ported to Monkey C
    // Reference: https://www.informatik.uni-leipzig.de/~duc/amlich/
    // Timezone: +7 (Vietnam Standard Time)
    // ============================================================

    // Integer floor division (handles negative numbers correctly)
    function ifloor(a as Float) as Number {
        var n = a.toNumber();
        if (a < 0.0 && a.toFloat() != n.toFloat()) { n = n - 1; }
        return n;
    }

    // Convert Solar date to Julian Day Number
    function jdFromDate(dd as Number, mm as Number, yy as Number) as Number {
        var a = ifloor((14 - mm) / 12.0);
        var y = yy + 4800 - a;
        var m = mm + 12 * a - 3;
        var jd = dd + ifloor((153 * m + 2) / 5.0) + 365 * y
                 + ifloor(y / 4.0) - ifloor(y / 100.0) + ifloor(y / 400.0) - 32045;
        return jd;
    }

    // Convert Julian Day Number to Solar date [dd, mm, yy]
    function jdToDate(jd as Number) as Array<Number> {
        var a = jd + 32044;
        var b = ifloor((4 * a + 3) / 146097.0);
        var c = a - ifloor(146097 * b / 4.0);
        var d = ifloor((4 * c + 3) / 1461.0);
        var e = c - ifloor(1461 * d / 4.0);
        var m = ifloor((5 * e + 2) / 153.0);
        var day = e - ifloor((153 * m + 2) / 5.0) + 1;
        var month = m + 3 - 12 * ifloor(m / 10.0);
        var year = 100 * b + d - 4800 + ifloor(m / 10.0);
        return [day, month, year] as Array<Number>;
    }

    // Compute the Julian Day Number of the kth new moon after epoch
    // Uses truncated Meeus algorithm (accuracy: about 1 minute)
    function getNewMoonDay(k as Number, timeZone as Float) as Number {
        var T = k / 1236.85;
        var T2 = T * T;
        var T3 = T2 * T;
        var dr = Math.PI / 180.0;
        var Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
        Jd1 = Jd1 + 0.00033 * Math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr);
        var M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
        var Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
        var F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3;
        var C1 = (0.1734 - 0.000393 * T) * Math.sin(M * dr) + 0.0021 * Math.sin(2.0 * dr * M);
        C1 = C1 - 0.4068 * Math.sin(Mpr * dr) + 0.0161 * Math.sin(2.0 * dr * Mpr);
        C1 = C1 - 0.0004 * Math.sin(3.0 * dr * Mpr);
        C1 = C1 + 0.0104 * Math.sin(2.0 * dr * F) - 0.0051 * Math.sin((M + Mpr) * dr);
        C1 = C1 - 0.0074 * Math.sin((M - Mpr) * dr) + 0.0004 * Math.sin((2.0 * F + M) * dr);
        C1 = C1 - 0.0004 * Math.sin((2.0 * F - M) * dr) - 0.0006 * Math.sin((2.0 * F + Mpr) * dr);
        C1 = C1 + 0.0010 * Math.sin((2.0 * F - Mpr) * dr) + 0.0005 * Math.sin((M + 2.0 * Mpr) * dr);
        var deltaT;
        if (T < -11.0) {
            deltaT = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3;
        } else {
            deltaT = -0.000278 + 0.000265 * T + 0.000262 * T2;
        }
        var JdNew = Jd1 + C1 - deltaT;
        return ifloor(JdNew + 0.5 + timeZone / 24.0);
    }

    // Compute sun longitude (degrees) at Julian Day jdn
    function getSunLongitude(jdn as Number, timeZone as Float) as Number {
        var T = (jdn - 2451545.5 - timeZone / 24.0) / 36525.0;
        var T2 = T * T;
        var dr = Math.PI / 180.0;
        var M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2;
        var L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
        var DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * Math.sin(M * dr);
        DL = DL + (0.019993 - 0.000101 * T) * Math.sin(2.0 * M * dr) + 0.000290 * Math.sin(3.0 * M * dr);
        var L = L0 + DL;
        var omega = 125.04 - 1934.136 * T;
        L = L - 0.00569 - 0.00478 * Math.sin(omega * dr);
        // Return sun longitude divided into 12 sections (0-11)
        L = L * dr;
        L = L - Math.PI * 2.0 * ifloor(L / (Math.PI * 2.0)).toFloat();
        return ifloor(L / Math.PI * 6.0);
    }

    // Get the Julian Day of the start of the nth month in the lunar year containing jd
    function getLunarMonth11(yy as Number, timeZone as Float) as Number {
        var off = jdFromDate(31, 12, yy) - 2415021;
        var k = ifloor(off / 29.530588853);
        var nm = getNewMoonDay(k, timeZone);
        var sunLong = getSunLongitude(nm, timeZone);
        if (sunLong >= 9) { nm = getNewMoonDay(k - 1, timeZone); }
        return nm;
    }

    // Get the index of the leap month in the lunar year starting at month11
    function getLeapMonthOffset(a11 as Number, timeZone as Float) as Number {
        var k = ifloor((a11 - 2415021.076998695) / 29.530588853 + 0.5);
        var last = 0;
        var i = 1;
        var arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
        while (true) {
            last = arc;
            i = i + 1;
            arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
            if (arc == last || i >= 14) { break; }
        }
        return i - 1;
    }

    // Main function: convert Solar date to Lunar date [lunarDay, lunarMonth, lunarYear]
    function getLunarDate(solarDay as Number, solarMonth as Number, solarYear as Number) as String {
        var timeZone = 7.0; // Vietnam: UTC+7
        var dayNumber = jdFromDate(solarDay, solarMonth, solarYear);
        var k = ifloor((dayNumber - 2415021.076998695) / 29.530588853);
        var monthStart = getNewMoonDay(k + 1, timeZone);
        if (monthStart > dayNumber) { monthStart = getNewMoonDay(k, timeZone); }
        var a11 = getLunarMonth11(solarYear, timeZone);
        var b11 = a11;
        var lunarYear;
        if (a11 >= monthStart) {
            lunarYear = solarYear;
            a11 = getLunarMonth11(solarYear - 1, timeZone);
        } else {
            lunarYear = solarYear + 1;
            b11 = getLunarMonth11(solarYear + 1, timeZone);
        }
        var lunarDay = dayNumber - monthStart + 1;
        var diff = ifloor((monthStart - a11) / 29.0);
        var lunarLeap = false;
        var lunarMonth = diff + 11;
        if (b11 - a11 > 365) {
            var leapMonthDiff = getLeapMonthOffset(a11, timeZone);
            if (diff >= leapMonthDiff) {
                lunarMonth = diff + 10;
                if (diff == leapMonthDiff) { lunarLeap = true; }
            }
        }
        if (lunarMonth > 12) { lunarMonth = lunarMonth - 12; }
        if (lunarMonth >= 11 && diff < 4) { lunarYear = lunarYear - 1; }
        return Lang.format("$1$/$2$", [lunarDay.format("%02d"), lunarMonth.format("%02d")]);
    }

    function drawBatteryIcon(dc as Dc, x as Number, y as Number, w as Number, h as Number, level as Number) as Void {
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        // Body
        dc.drawRectangle(x, y, w, h);
        // Tip
        dc.fillRectangle(x + w, y + h/4, 2, h/2);
        
        // Fill level
        if (level > 20) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        } else if (level > 10) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        }
        
        var fillW = (w - 4) * level / 100;
        if (fillW > 0) {
            dc.fillRectangle(x + 2, y + 2, fillW, h - 4);
        }
    }
}
