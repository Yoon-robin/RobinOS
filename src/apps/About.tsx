// RobinOS 정보 창
export default function About() {
  return (
    <div className="app-about">
      <img src="/brand/logo-mark.svg" alt="RobinOS" className="about-mark" />
      <img
        src="/brand/logo-wordmark-light.svg"
        alt="RobinOS"
        className="about-wordmark"
      />
      <p className="about-version">버전 0.1 “Aurora”</p>
      <p className="about-desc">
        당신만의 데스크톱 OS 경험.
        <br />
        React + motion 으로 직접 만든 셸이에요.
      </p>
      <div className="about-specs">
        <div>
          <span>셸</span>
          <b>RobinOS Shell</b>
        </div>
        <div>
          <span>렌더러</span>
          <b>React 19</b>
        </div>
        <div>
          <span>애니메이션</span>
          <b>motion 12</b>
        </div>
        <div>
          <span>만든 사람</span>
          <b>Robin</b>
        </div>
      </div>
    </div>
  );
}
