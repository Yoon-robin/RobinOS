import { useEffect, useState } from "react";

// 바탕화면 위젯: 큰 시계 + 날짜 (창 뒤에 은은하게 깔림).
export default function DesktopWidget() {
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  const time = now.toLocaleTimeString("ko-KR", { hour: "2-digit", minute: "2-digit" });
  const date = now.toLocaleDateString("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "long",
  });

  return (
    <div className="desk-widget">
      <div className="dw-time">{time}</div>
      <div className="dw-date">{date}</div>
    </div>
  );
}
