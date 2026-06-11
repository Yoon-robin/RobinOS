import type { ComponentType } from "react";

// 하나의 앱 정의. component 가 창 안에 그려질 실제 React 컴포넌트예요.
export type AppDef = {
  id: string;
  name: string;
  icon: string; // 이모지 또는 이미지 경로("/...")
  color: string; // 독 타일 배경 (이미지 아이콘이면 무시)
  component: ComponentType;
  size?: { w: number; h: number }; // 창 기본 크기
  // Robin 에이전트가 이 앱으로 할 수 있는 특수 동작 (선언하면 Robin이 자동 인지)
  robinTool?: { action: string; desc: string; arg: string };
};
