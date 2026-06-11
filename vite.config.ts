import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Vite 설정: React 플러그인만 있으면 충분해요.
export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // 0.0.0.0 에 바인딩 → Tailscale·LAN 등 다른 기기에서 접속 가능
    port: 5173,
    allowedHosts: true, // Tailscale IP·MagicDNS 호스트네임으로 들어오는 요청 허용
  },
});
