import { useEffect, useState } from "react";

// 상단 메뉴바: 왼쪽엔 로고와 현재 앱 이름, 오른쪽엔 상태 아이콘과 실시간 시계.
export default function MenuBar({
  activeApp,
  onSearch,
  onControlCenter,
  onClock,
  onLogo,
}: {
  activeApp: string;
  onSearch: () => void;
  onControlCenter: () => void;
  onClock: () => void;
  onLogo: () => void;
}) {
  const [now, setNow] = useState(new Date());

  // 1초마다 시계를 갱신해요.
  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const date = now.toLocaleDateString("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "short",
  });
  const time = now.toLocaleTimeString("ko-KR", {
    hour: "2-digit",
    minute: "2-digit",
  });

  return (
    <div className="menubar">
      <div className="menubar-left">
        <button className="menubar-logo-btn" onClick={onLogo} aria-label="RobinOS 메뉴">
          <img className="menubar-logo" src="/brand/logo-mark.svg" alt="RobinOS" />
        </button>
        <span className="menubar-app">{activeApp}</span>
        <span className="menubar-menu">파일</span>
        <span className="menubar-menu">편집</span>
        <span className="menubar-menu">보기</span>
        <span className="menubar-menu">윈도우</span>
        <span className="menubar-menu">도움말</span>
      </div>
      <div className="menubar-right">
        <button className="menubar-btn" onClick={onSearch} aria-label="검색">
          🔍
        </button>
        <button className="menubar-btn cc-trigger" onClick={onControlCenter} aria-label="제어 센터">
          📶 🔋
        </button>
        <button className="menubar-btn" onClick={onClock}>
          {date} {time}
        </button>
      </div>
    </div>
  );
}
