import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";
import "./styles.css";
import { setRobinBrain } from "./system/robin";
import { deepseekBrain } from "./system/robin-deepseek";

// 저장된 Robin 두뇌 선택 복원 (DeepSeek 선택 시 부팅부터 적용)
if (localStorage.getItem("robinos.brain") === "deepseek") setRobinBrain(deepseekBrain);

// React 앱의 진입점. index.html 의 <div id="root"> 안에 그려져요.
createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
