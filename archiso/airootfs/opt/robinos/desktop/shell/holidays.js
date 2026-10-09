.pragma library

// Korean public holidays for the month calendar (Calendar.qml). The solar ones come
// every year; lunar ones (설날, 추석, 부처님오신날), substitute days and election days
// need a table, so add the next year here before it starts (2026-10-10: 2026-2028,
// checked against publicholidays.co.kr, kholidayz.com and dallyeok.com).

var fixed = {
    "01-01": "신정",
    "03-01": "삼일절",
    "05-01": "노동절",
    "05-05": "어린이날",
    "06-06": "현충일",
    "07-17": "제헌절",
    "08-15": "광복절",
    "10-03": "개천절",
    "10-09": "한글날",
    "12-25": "성탄절"
};

var byYear = {
    "2026": {
        "02-16": "설날 연휴", "02-17": "설날", "02-18": "설날 연휴",
        "03-02": "대체공휴일",
        "05-24": "부처님오신날", "05-25": "대체공휴일",
        "06-03": "지방선거일",
        "08-17": "대체공휴일",
        "09-24": "추석 연휴", "09-25": "추석", "09-26": "추석 연휴",
        "10-05": "대체공휴일"
    },
    "2027": {
        "02-06": "설날 연휴", "02-07": "설날", "02-08": "설날 연휴", "02-09": "대체공휴일",
        "05-03": "대체공휴일",
        "05-13": "부처님오신날",
        "07-19": "대체공휴일",
        "08-16": "대체공휴일",
        "09-14": "추석 연휴", "09-15": "추석", "09-16": "추석 연휴",
        "10-04": "대체공휴일",
        "10-11": "대체공휴일",
        "12-27": "대체공휴일"
    },
    "2028": {
        "01-26": "설날 연휴", "01-27": "설날", "01-28": "설날 연휴",
        "04-12": "국회의원 선거일",
        "05-02": "부처님오신날",
        "10-02": "추석 연휴", "10-03": "추석 · 개천절", "10-04": "추석 연휴",
        "10-05": "대체공휴일"
    }
};

function pad(n) {
    return n < 10 ? "0" + n : "" + n;
}

// The holiday's name on that date, or "" on an ordinary day
function name(date) {
    var key = pad(date.getMonth() + 1) + "-" + pad(date.getDate());
    var year = byYear["" + date.getFullYear()];
    return (year && year[key]) || fixed[key] || "";
}
