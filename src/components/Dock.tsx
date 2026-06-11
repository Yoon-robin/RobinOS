import { useRef } from "react";
import {
  motion,
  useMotionValue,
  useSpring,
  useTransform,
  type MotionValue,
} from "motion/react";
import { APPS, type AppDef } from "../data/apps";

const BASE_SIZE = 48;
const MAX_SIZE = 80;
const RANGE = 160;

export default function Dock({
  openApps,
  onOpen,
  onLaunchpad,
  onAppContext,
}: {
  openApps: string[];
  onOpen: (app: AppDef) => void;
  onLaunchpad: () => void;
  onAppContext: (app: AppDef, x: number, y: number) => void;
}) {
  const mouseX = useMotionValue(Infinity);

  return (
    <div className="dock-wrap">
      <motion.div
        className="dock"
        onMouseMove={(e) => mouseX.set(e.pageX)}
        onMouseLeave={() => mouseX.set(Infinity)}
      >
        <DockIcon
          mouseX={mouseX}
          icon="🚀"
          color="linear-gradient(135deg,#6366f1,#a855f7)"
          name="런치패드"
          running={false}
          onClick={onLaunchpad}
        />
        <span className="dock-sep" />
        {APPS.map((app) => (
          <DockIcon
            key={app.id}
            mouseX={mouseX}
            icon={app.icon}
            color={app.color}
            name={app.name}
            running={openApps.includes(app.id)}
            onClick={() => onOpen(app)}
            onContext={(e) => onAppContext(app, e.clientX, e.clientY)}
          />
        ))}
      </motion.div>
    </div>
  );
}

function DockIcon({
  mouseX,
  icon,
  color,
  name,
  running,
  onClick,
  onContext,
}: {
  mouseX: MotionValue<number>;
  icon: string;
  color: string;
  name: string;
  running: boolean;
  onClick: () => void;
  onContext?: (e: { clientX: number; clientY: number }) => void;
}) {
  const ref = useRef<HTMLButtonElement>(null);

  const distance = useTransform(mouseX, (val) => {
    const b = ref.current?.getBoundingClientRect() ?? { x: 0, width: 0 };
    return val - b.x - b.width / 2;
  });
  const sizeTarget = useTransform(distance, [-RANGE, 0, RANGE], [BASE_SIZE, MAX_SIZE, BASE_SIZE]);
  const size = useSpring(sizeTarget, { mass: 0.1, stiffness: 170, damping: 14 });
  const fontSize = useTransform(size, (s) => s * 0.56);
  const isImg = icon.startsWith("/");

  return (
    <motion.button
      ref={ref}
      className="dock-icon"
      style={{ width: size, height: size }}
      onClick={onClick}
      onContextMenu={(e) => {
        if (onContext) {
          e.preventDefault();
          onContext(e);
        }
      }}
      whileTap={{ scale: 0.82 }}
    >
      <span className="dock-tooltip">{name}</span>
      <motion.div
        className="dock-icon-inner"
        style={{ background: isImg ? "transparent" : color, fontSize }}
      >
        {isImg ? <img src={icon} alt={name} className="dock-icon-img" /> : icon}
      </motion.div>
      {running && <span className="dock-dot" />}
    </motion.button>
  );
}
